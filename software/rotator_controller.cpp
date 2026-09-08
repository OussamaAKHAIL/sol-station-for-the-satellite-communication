/*
  ISS Antenna Rotator Controller
  ------------------------------
  Emulates the Yaesu GS-232B protocol (Hamlib rotator model 602) so it
  can be driven directly by rotctld.exe, which SkyRoof talks to over TCP.

  Serial link: via FTDI USB-Serial module, 9600 baud, 8N1, line-end = '\r'

  Commands understood:
    Wxxx yyy\r   -> move to azimuth xxx (0-360), elevation yyy (0-180)
    C2\r         -> reply "AZ=xxx  EL=yyy\r" (current position)
    S\r          -> stop motion (target = current position)

  Position feedback comes from a BNO055 9-DOF IMU (gyro + accel + mag,
  with onboard sensor fusion), read over I2C. This gives an absolute
  heading (azimuth) and pitch (elevation) reference instead of trusting
  open-loop step counting, which drifts with any belt/gear slip.

  IMPORTANT CALIBRATION NOTES (read before use):
  - A bare gyroscope alone cannot give an absolute azimuth: it only
    measures rotation RATE and drifts over time. The BNO055 fixes this
    by fusing its magnetometer, so its heading is referenced to
    magnetic north, not step count.
  - Mount the BNO055 away from the stepper motors/drivers: their coils
    and current draw distort the magnetometer reading. Test by rotating
    the mast slowly and comparing the heading to a known compass
    bearing before trusting it.
  - True-north azimuth = magnetic heading + local magnetic declination
    (see noaa.gov declination calculator for your location). Add that
    offset below if you want true-north tracking; SkyRoof's own
    "Azimuth Offset" rotator setting can also absorb this instead.
  - Mount the sensor so the BNO055's own Z axis is vertical (parallel to
    the az rotation axis) and its X/Y plane rotates with the boom, so
    getEvent() yaw = azimuth and pitch = elevation directly. If your
    mechanical mounting differs, adjust the axis mapping below.
*/

#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BNO055.h>
#include <utility/imumaths.h>
#include <AccelStepper.h>

// ---------- user-tunable parameters ----------
const float MAGNETIC_DECLINATION = 0.0;   // degrees, add for your location
const float POSITION_TOLERANCE   = 1.0;   // degrees; stop moving once inside this band
const float NUDGE_DEGREES        = 0.2;   // physical angle moved per control-loop pass (both axes)
const unsigned long CONTROL_PERIOD_MS = 50; // how often the feedback loop runs

// ---------- gear train (converts motor steps <-> real output-shaft degrees) ----------
// Azimuth uses a 100:12 reduction (motor pulley/gear = 12 teeth, output = 100 teeth),
// so the motor must turn 100/12 times for the output shaft to turn once.
// Elevation is direct 1:1 (motor shaft = output shaft).
const float MOTOR_STEPS_PER_REV = 200.0;        // 1.8 deg/step motor, full-step; edit if different
const float MICROSTEPS          = 1.0;          // driver microstepping (1,2,4,8,16...); edit to match jumpers
const float AZ_GEAR_RATIO       = 100.0 / 12.0; // motor revs per 1 output rev
const float EL_GEAR_RATIO       = 1.0;          // motor revs per 1 output rev

const float AZ_STEPS_PER_DEG = (MOTOR_STEPS_PER_REV * MICROSTEPS * AZ_GEAR_RATIO) / 360.0;
const float EL_STEPS_PER_DEG = (MOTOR_STEPS_PER_REV * MICROSTEPS * EL_GEAR_RATIO) / 360.0;

// desired *physical* (output-shaft) slew rate; steps/sec for each motor are derived from this
const float MAX_ANGULAR_SPEED_DEG_S = 20.0;
const float MAX_ANGULAR_ACCEL_DEG_S2 = 15.0;

// ---------- pin assignments (STEP/DIR driver boards, e.g. A4988/DRV8825) ----------
const int AZ_STEP_PIN = 3;
const int AZ_DIR_PIN   = 4;
const int EL_STEP_PIN  = 5;
const int EL_DIR_PIN   = 6;
const int ENABLE_PIN   = 7;   // shared enable, active LOW on most driver boards

Adafruit_BNO055 bno = Adafruit_BNO055(55, 0x28);
AccelStepper azStepper(AccelStepper::DRIVER, AZ_STEP_PIN, AZ_DIR_PIN);
AccelStepper elStepper(AccelStepper::DRIVER, EL_STEP_PIN, EL_DIR_PIN);

float targetAz = 0, targetEl = 0;
float currentAz = 0, currentEl = 0;
bool  tracking = false;

String rxLine = "";
unsigned long lastControlMs = 0;

void setup() {
  Serial.begin(9600);

  pinMode(ENABLE_PIN, OUTPUT);
  digitalWrite(ENABLE_PIN, LOW);   // enable drivers

  // az has an 8.33:1 reduction vs el's 1:1, so its motor must spin ~8.33x
  // faster in raw steps/sec to achieve the same real-world deg/s
  azStepper.setMaxSpeed(MAX_ANGULAR_SPEED_DEG_S * AZ_STEPS_PER_DEG);
  azStepper.setAcceleration(MAX_ANGULAR_ACCEL_DEG_S2 * AZ_STEPS_PER_DEG);
  elStepper.setMaxSpeed(MAX_ANGULAR_SPEED_DEG_S * EL_STEPS_PER_DEG);
  elStepper.setAcceleration(MAX_ANGULAR_ACCEL_DEG_S2 * EL_STEPS_PER_DEG);

  Wire.begin();
  if (!bno.begin()) {
    // BNO055 not found: blink built-in LED forever as a hard fault signal
    pinMode(LED_BUILTIN, OUTPUT);
    while (1) {
      digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN));
      delay(200);
    }
  }
  delay(1000);
  bno.setExtCrystalUse(true);

  readPosition();       // seed target with current position so we don't
  targetAz = currentAz; // jump on power-up before the first command
  targetEl = currentEl;
}

void loop() {
  readSerialCommands();

  if (millis() - lastControlMs >= CONTROL_PERIOD_MS) {
    lastControlMs = millis();
    readPosition();
    if (tracking) driveTowardTarget();
  }

  azStepper.run();
  elStepper.run();
}

// ---- reads BNO055 Euler angles into currentAz / currentEl ----
void readPosition() {
  sensors_event_t event;
  bno.getEvent(&event);
  // event.orientation.x = heading (0-360, magnetic), y = roll, z = pitch
  currentAz = event.orientation.x + MAGNETIC_DECLINATION;
  if (currentAz >= 360.0) currentAz -= 360.0;
  if (currentAz < 0.0)    currentAz += 360.0;
  currentEl = event.orientation.z;   // adjust sign/axis to your mounting
}

// ---- shortest signed angular error, handles the 0/360 wrap ----
float angleError(float target, float current) {
  float diff = target - current;
  while (diff > 180.0)  diff -= 360.0;
  while (diff < -180.0) diff += 360.0;
  return diff;
}

// ---- closed-loop nudge: step a fixed chunk toward the target each pass ----
void driveTowardTarget() {
  float azErr = angleError(targetAz, currentAz);
  float elErr = targetEl - currentEl;

  if (fabs(azErr) > POSITION_TOLERANCE) {
    long azChunkSteps = lround(NUDGE_DEGREES * AZ_STEPS_PER_DEG);
    azStepper.move(azErr > 0 ? azChunkSteps : -azChunkSteps);
  }
  if (fabs(elErr) > POSITION_TOLERANCE) {
    long elChunkSteps = lround(NUDGE_DEGREES * EL_STEPS_PER_DEG);
    elStepper.move(elErr > 0 ? elChunkSteps : -elChunkSteps);
  }
}

// ---- GS-232B command parser ----
void readSerialCommands() {
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\r' || c == '\n') {
      if (rxLine.length() > 0) handleCommand(rxLine);
      rxLine = "";
    } else {
      rxLine += c;
    }
  }
}

void handleCommand(String line) {
  line.trim();
  line.toUpperCase();

  if (line.startsWith("W")) {
    // format: "Wxxx yyy"  (az, el separated by a space)
    int spaceIdx = line.indexOf(' ');
    if (spaceIdx > 0) {
      targetAz = line.substring(1, spaceIdx).toFloat();
      targetEl = line.substring(spaceIdx + 1).toFloat();
      tracking = true;
    }
  }
  else if (line.startsWith("C2")) {
    char reply[32];
    snprintf(reply, sizeof(reply), "AZ=%03d  EL=%03d\r",
             (int)round(currentAz), (int)round(currentEl));
    Serial.print(reply);
  }
  else if (line.startsWith("C")) {
    // legacy azimuth-only query
    char reply[16];
    snprintf(reply, sizeof(reply), "AZ=%03d\r", (int)round(currentAz));
    Serial.print(reply);
  }
  else if (line.startsWith("S")) {
    tracking = false;
    targetAz = currentAz;
    targetEl = currentEl;
    azStepper.stop();
    elStepper.stop();
  }
}
