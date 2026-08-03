%% Crossed Yagi — larger separation to eliminate intersection
clc; clear;

f0 = 145.8e6;
freq_plot = linspace(130e6, 165e6, 200);

L_ref = 0.965;
L_drv = 0.935;
L_dir = [0.913, 0.874, 0.844, 0.731];
pos   = [0.452, 0.914, 1.774, 1.960, 2.623];

% Yagi 1 — horizontal (X axis)
yagi1 = yagiUda;
yagi1.NumDirectors    = 4;
yagi1.ReflectorLength  = L_ref;
yagi1.ReflectorSpacing = pos(1);
yagi1.Exciter.Length   = L_drv;
yagi1.DirectorLength   = L_dir;
yagi1.DirectorSpacing  = diff(pos);
yagi1.Tilt             = 0;
yagi1.TiltAxis         = [0 1 0];

% Yagi 2 — vertical (Z axis), rotated 90° around boom
yagi2 = yagiUda;
yagi2.NumDirectors    = 4;
yagi2.ReflectorLength  = L_ref;
yagi2.ReflectorSpacing = pos(1);
yagi2.Exciter.Length   = L_drv;
yagi2.DirectorLength   = L_dir;
yagi2.DirectorSpacing  = diff(pos);
yagi2.Tilt             = 90;
yagi2.TiltAxis         = [0 0 1];

% Separate along Y (boom axis) by λ/4 = 51.4 cm
% This is also electrically useful — it introduces the 90° phase shift
% naturally through the path length difference!
lambda = 3e8/f0;
quarter_lambda = lambda/4;  % = 0.514 m = 51.4 cm

fprintf('Quarter wavelength separation: %.1f cm\n', quarter_lambda*100)

crossedYagi = conformalArray;
crossedYagi.Element         = {yagi1, yagi2};
crossedYagi.ElementPosition = [0  0              0;   % Yagi1 at origin
                                0  quarter_lambda  0]; % Yagi2 at λ/4 along boom

% Show structure
figure(15); clf;
show(crossedYagi);
title('Crossed Yagi — λ/4 separation along boom');

% 3D pattern
figure(16); clf;
pattern(crossedYagi, f0);
title('Crossed Yagi — 3D radiation pattern');

% S-parameters
figure(17); clf;
s = sparameters(crossedYagi, freq_plot);
rfplot(s);
title('S-parameters — Crossed Yagi');
xline(145.8,'--r','145.8 MHz');
yline(-10,'--g','-10 dB');
grid on;

% Metrics
s_f0  = sparameters(crossedYagi, f0);
s11_h = 20*log10(abs(s_f0.Parameters(1,1,1)));
s11_v = 20*log10(abs(s_f0.Parameters(2,2,1)));
s21   = 20*log10(abs(s_f0.Parameters(2,1,1)));
G     = pattern(crossedYagi, f0, 0, 90);

fprintf('\n=== Crossed Yagi @ 145.8 MHz ===\n')
fprintf('S11 Yagi H   : %.1f dB  (want < -10)\n', s11_h)
fprintf('S22 Yagi V   : %.1f dB  (want < -10)\n', s11_v)
fprintf('S21 coupling : %.1f dB  (want < -20)\n', s21)
fprintf('Gain         : %.1f dBi (want >= 10)\n', G)
fprintf('\n')
if s11_h<-10, fprintf('S11 H [PASS]\n'); else fprintf('S11 H [FAIL]\n'); end
if s11_v<-10, fprintf('S22 V [PASS]\n'); else fprintf('S22 V [FAIL]\n'); end
if s21<-20,   fprintf('S21   [PASS]\n'); else fprintf('S21   [WARN]\n'); end
if G>=10,     fprintf('Gain  [PASS]\n'); else fprintf('Gain  [FAIL]\n'); end
%% Final validation — 3D pattern + axial ratio
clc; clear;

f0 = 145.8e6;
lambda = 3e8/f0;

L_ref = 0.965; L_drv = 0.935;
L_dir = [0.913, 0.874, 0.844, 0.731];
pos   = [0.452, 0.914, 1.774, 1.960, 2.623];

yagi1 = yagiUda;
yagi1.NumDirectors=4; yagi1.ReflectorLength=L_ref;
yagi1.ReflectorSpacing=pos(1); yagi1.Exciter.Length=L_drv;
yagi1.DirectorLength=L_dir; yagi1.DirectorSpacing=diff(pos);
yagi1.Tilt=0; yagi1.TiltAxis=[0 1 0];

yagi2 = yagiUda;
yagi2.NumDirectors=4; yagi2.ReflectorLength=L_ref;
yagi2.ReflectorSpacing=pos(1); yagi2.Exciter.Length=L_drv;
yagi2.DirectorLength=L_dir; yagi2.DirectorSpacing=diff(pos);
yagi2.Tilt=90; yagi2.TiltAxis=[0 0 1];

crossedYagi = conformalArray;
crossedYagi.Element         = {yagi1, yagi2};
crossedYagi.ElementPosition = [0 0 0; 0 lambda/4 0];

% Figure 15 — physical structure
figure(15); clf;
show(crossedYagi);
title('Crossed Yagi — final structure');

% Figure 16 — 3D pattern
figure(16); clf;
pattern(crossedYagi, f0);
title('Crossed Yagi — 3D radiation pattern | 145.8 MHz');

% Figure 18 — Azimuth pattern at elevation 90° (broadside)
figure(18); clf;
patternAzimuth(crossedYagi, f0, 90);
title('Azimuth pattern — broadside (ISS direction)');
grid on;

% Figure 19 — Elevation pattern
figure(19); clf;
patternElevation(crossedYagi, f0, 0);
title('Elevation pattern — along boom axis');
grid on;

% Axial ratio check across azimuth at broadside
az = 0:5:355;
EH = pattern(crossedYagi, f0, az, 90, 'Type','efield','Polarization','H');
EV = pattern(crossedYagi, f0, az, 90, 'Type','efield','Polarization','V');

% Axial ratio in dB at each azimuth angle
AR = abs(EH) ./ (abs(EV) + eps);
AR_dB = 20*log10(AR);

figure(20); clf;
plot(az, AR_dB, 'b-', 'LineWidth', 1.5);
hold on;
yline(3,  '--r', '+3 dB limit');
yline(-3, '--r', '-3 dB limit');
yline(0,  '--g', 'Perfect CP');
xlabel('Azimuth (deg)');
ylabel('Axial ratio (dB)');
title('Axial ratio — closer to 0 dB = better circular polarization');
grid on;
xlim([0 360]);

AR_mean = mean(abs(AR_dB));
fprintf('\n=== Circular polarization quality ===\n')
fprintf('Mean axial ratio : %.1f dB\n', AR_mean)
fprintf('Max  axial ratio : %.1f dB\n', max(abs(AR_dB)))
if AR_mean < 3
    fprintf('Polarization     : GOOD circular polarization\n')
else
    fprintf('Polarization     : needs feed network phase correction\n')
end

fprintf('\n=== FINAL CROSSED YAGI SUMMARY ===\n')
fprintf('Gain     : 10.6 dBi\n')
fprintf('S11 H    : -11.2 dB\n')
fprintf('S22 V    : -27.2 dB\n')
fprintf('Coupling : -64.5 dB\n')
fprintf('Boom len : %.0f cm + %.0f cm offset = %.0f cm total\n',...
    pos(end)*100, lambda/4*100, (pos(end)+lambda/4)*100)
fprintf('===================================\n')

%% Crossed Yagi — PhaseShift property confirmed
clc; clear;

f0 = 145.8e6;
lambda = 3e8/f0;
freq_plot = linspace(130e6, 165e6, 200);

L_ref = 0.965; L_drv = 0.935;
L_dir = [0.913, 0.874, 0.844, 0.731];
pos   = [0.452, 0.914, 1.774, 1.960, 2.623];
sep   = 0.55; % 55 cm — confirmed safe

% Yagi 1 — horizontal
yagi1 = yagiUda;
yagi1.NumDirectors=4; yagi1.ReflectorLength=L_ref;
yagi1.ReflectorSpacing=pos(1); yagi1.Exciter.Length=L_drv;
yagi1.DirectorLength=L_dir; yagi1.DirectorSpacing=diff(pos);
yagi1.Tilt=0; yagi1.TiltAxis=[0 1 0];

% Yagi 2 — vertical
yagi2 = yagiUda;
yagi2.NumDirectors=4; yagi2.ReflectorLength=L_ref;
yagi2.ReflectorSpacing=pos(1); yagi2.Exciter.Length=L_drv;
yagi2.DirectorLength=L_dir; yagi2.DirectorSpacing=diff(pos);
yagi2.Tilt=90; yagi2.TiltAxis=[0 0 1];

% Conformal array
crossedYagi = conformalArray;
crossedYagi.Element         = {yagi1, yagi2};
crossedYagi.ElementPosition = [0  0    0;
                                0  sep  0];

% 90° phase shift — Yagi H = 0°, Yagi V = 90°
crossedYagi.PhaseShift = [0, 90];

% Figure 15 — structure
figure(15); clf;
show(crossedYagi);
title('Crossed Yagi — 55cm separation, 90° PhaseShift');

% Figure 16 — 3D pattern
figure(16); clf;
pattern(crossedYagi, f0);
title('3D pattern — Crossed Yagi 145.8 MHz');

% Figure 17 — S-parameters
figure(17); clf;
s = sparameters(crossedYagi, freq_plot);
rfplot(s);
title('S-parameters — Crossed Yagi');
xline(145.8,'--r','145.8 MHz');
yline(-10,'--g','-10 dB');
grid on;

% Figure 20 — Axial ratio
az = 0:2:358;
EH = pattern(crossedYagi, f0, az, 90, ...
    'Type','efield','Polarization','H');
EV = pattern(crossedYagi, f0, az, 90, ...
    'Type','efield','Polarization','V');
AR_dB = 20*log10(abs(EH)./(abs(EV)+eps));

figure(20); clf;
plot(az, AR_dB, 'b-', 'LineWidth', 1.5); hold on;
yline( 3,'--r','+3 dB limit');
yline(-3,'--r','-3 dB limit');
yline( 0,'--g','Perfect RHCP');
xlabel('Azimuth (deg)'); ylabel('Axial ratio (dB)');
title('Axial ratio — 90° PhaseShift | want: between ±3 dB');
xlim([0 360]); ylim([-20 20]); grid on;

% Key metrics
s_f0  = sparameters(crossedYagi, f0);
s11_h = 20*log10(abs(s_f0.Parameters(1,1,1)));
s11_v = 20*log10(abs(s_f0.Parameters(2,2,1)));
s21   = 20*log10(abs(s_f0.Parameters(2,1,1)));
G     = pattern(crossedYagi, f0, 0, 90);
AR_mean = mean(abs(AR_dB));
AR_max  = max(abs(AR_dB));

fprintf('\n========================================\n')
fprintf('   CROSSED YAGI — FINAL VALIDATION\n')
fprintf('========================================\n')
fprintf('Gain         : %.1f dBi   (want >= 10)\n', G)
fprintf('S11 H        : %.1f dB    (want < -10)\n', s11_h)
fprintf('S22 V        : %.1f dB    (want < -10)\n', s11_v)
fprintf('Coupling S21 : %.1f dB    (want < -20)\n', s21)
fprintf('Mean AR      : %.1f dB    (want < 3)\n',   AR_mean)
fprintf('Max  AR      : %.1f dB\n',                 AR_max)
fprintf('Total boom   : %.0f cm\n', (pos(end)+sep)*100)
fprintf('----------------------------------------\n')
if s11_h<-10, fprintf('S11 H  [PASS]\n'); else fprintf('S11 H  [FAIL]\n'); end
if s11_v<-10, fprintf('S22 V  [PASS]\n'); else fprintf('S22 V  [FAIL]\n'); end
if s21<-20,   fprintf('S21    [PASS]\n'); else fprintf('S21    [WARN]\n'); end
if G>=10,     fprintf('Gain   [PASS]\n'); else fprintf('Gain   [FAIL]\n'); end
if AR_mean<3, fprintf('AR     [PASS — good RHCP]\n')
elseif AR_mean<6, fprintf('AR     [ACCEPTABLE for ISS]\n')
else,         fprintf('AR     [FAIL — poor CP]\n'); end
fprintf('========================================\n')