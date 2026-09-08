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
const int   AZ_STEP_CHUNK        = 4;     // motor steps issued per control-loop pass
const int   EL_STEP_CHUNK        = 4;
const unsigned long CONTROL_PERIOD_MS = 50; // how often the feedback loop runs

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

  azStepper.setMaxSpeed(800);
  azStepper.setAcceleration(400);
  elStepper.setMaxSpeed(800);
  elStepper.setAcceleration(400);

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
    azStepper.move(azErr > 0 ? AZ_STEP_CHUNK : -AZ_STEP_CHUNK);
  }
  if (fabs(elErr) > POSITION_TOLERANCE) {
    elStepper.move(elErr > 0 ? EL_STEP_CHUNK : -EL_STEP_CHUNK);
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
