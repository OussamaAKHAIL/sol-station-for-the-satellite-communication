%% Phase 5 — Full validation of optimized antenna
clc;
f0        = 145.8e6;
freq_plot = linspace(130e6, 165e6, 300);

% Use your optimized dimensions from particle swarm
ant_final = yagiUda;
ant_final.NumDirectors    = 4;
ant_final.ReflectorLength  = 0.965;
ant_final.ReflectorSpacing = 0.452;
ant_final.Exciter.Length   = 0.935;
ant_final.DirectorLength   = [0.913, 0.874, 0.844, 0.731];
ant_final.DirectorSpacing  = diff([0.452, 0.914, 1.774, 1.960, 2.623]);

%--------------------------------------------------
% 1. S11 + VSWR
%--------------------------------------------------
figure(10); clf;
s = sparameters(ant_final, freq_plot);
rfplot(s);
title('S11 — Validated optimized Yagi | 145.8 MHz');
xline(145.8,'--r','145.8 MHz');
yline(-10,'--g','-10 dB');
grid on;

% VSWR at 145.8 MHz
s11_lin = s.Parameters(1,1,:);
freq_vec = freq_plot;
[~,idx]  = min(abs(freq_vec - f0));
s11_f0   = abs(s11_lin(idx));
vswr     = (1 + s11_f0)/(1 - s11_f0);
s11_db   = 20*log10(s11_f0);
fprintf('\n=== VALIDATION REPORT ===\n')
fprintf('S11 at 145.8 MHz : %.2f dB\n', s11_db)
fprintf('VSWR at 145.8 MHz: %.2f  (target < 2.0)\n', vswr)

%--------------------------------------------------
% 2. Impedance
%--------------------------------------------------
figure(11); clf;
impedance(ant_final, freq_plot);
title('Input impedance vs frequency');
xline(145.8,'--r','145.8 MHz');
grid on;

% Read impedance at f0
Z = impedance(ant_final, f0);
fprintf('Impedance at 145.8 MHz: %.1f + %.1fj Ohm\n', real(Z), imag(Z))

%--------------------------------------------------
% 3. Gain + 3D radiation pattern
%--------------------------------------------------
figure(12); clf;
pattern(ant_final, f0);
title('3D radiation pattern | 145.8 MHz');

% Read gain value
G = pattern(ant_final, f0, 0, 90); % broadside direction
fprintf('Gain (broadside)  : %.1f dBi  (target >= 10 dBi)\n', G)

%--------------------------------------------------
% 4. Azimuth pattern (horizontal cut)
%--------------------------------------------------
figure(13); clf;
patternAzimuth(ant_final, f0);
title('Azimuth pattern (elevation = 0°)');
grid on;

%--------------------------------------------------
% 5. Elevation pattern (vertical cut)
%--------------------------------------------------
figure(14); clf;
patternElevation(ant_final, f0);
title('Elevation pattern (azimuth = 0°)');
grid on;

%--------------------------------------------------
% 6. Efficiency
%--------------------------------------------------
eff = efficiency(ant_final, f0);
fprintf('Radiation efficiency: %.1f %%  (target > 80%%)\n', eff*100)

%--------------------------------------------------
% Summary
%--------------------------------------------------
fprintf('\n========= FULL VALIDATION SUMMARY =========\n')
fprintf('S11          : %.1f dB   ', s11_db)
if s11_db < -10, fprintf('[PASS]\n'); else, fprintf('[FAIL]\n'); end
fprintf('VSWR         : %.2f      ', vswr)
if vswr < 2, fprintf('[PASS]\n'); else, fprintf('[FAIL]\n'); end
fprintf('Gain         : %.1f dBi  ', G)
if G >= 10, fprintf('[PASS]\n'); else, fprintf('[FAIL - need more directors or reoptimize]\n'); end
fprintf('Efficiency   : %.0f %%    ', eff*100)
if eff > 0.8, fprintf('[PASS]\n'); else, fprintf('[FAIL]\n'); end
fprintf('============================================\n')
%% Phase 6 — Fabrication export
clc;

% Final dimensions
names = {'Reflector','Driven','Director 1','Director 2',...
         'Director 3','Director 4'};
lengths_cm = [96.5, 93.5, 91.3, 87.4, 84.4, 73.1];
pos_cm     = [0, 45.2, 91.4, 177.4, 196.0, 262.3];
half_cm    = lengths_cm / 2; % each side to cut from center

fprintf('\n')
fprintf('╔══════════════════════════════════════════════════════╗\n')
fprintf('║     FABRICATION SHEET — ISS Yagi 145.8 MHz          ║\n')
fprintf('╠══════════════════════════════════════════════════════╣\n')
fprintf('║ Material : Aluminum tube, 10-12 mm diameter          ║\n')
fprintf('║ Boom     : Non-conductive (PVC or wood) OR           ║\n')
fprintf('║            aluminum with insulated element mounts    ║\n')
fprintf('║ Feed     : 50 Ω coaxial cable (RG-58 or RG-213)     ║\n')
fprintf('╠══════════╦══════════╦══════════╦══════════╦══════════╣\n')
fprintf('║ Element  ║ Total(cm)║ Each side║ Pos on   ║ Spacing  ║\n')
fprintf('║          ║          ║  (cm)    ║ boom(cm) ║ from prev║\n')
fprintf('╠══════════╬══════════╬══════════╬══════════╬══════════╣\n')
for i = 1:6
    if i == 1
        spacing = 0;
    else
        spacing = pos_cm(i) - pos_cm(i-1);
    end
    fprintf('║ %-9s║  %6.1f  ║  %6.1f  ║  %6.1f  ║  %6.1f  ║\n',...
        names{i}, lengths_cm(i), half_cm(i), pos_cm(i), spacing)
end
fprintf('╠══════════╩══════════╩══════════╩══════════╩══════════╣\n')
fprintf('║ Total boom length: 262.3 cm                          ║\n')
fprintf('║ Add 10 cm each end for mounting = 282.3 cm total     ║\n')
fprintf('╠══════════════════════════════════════════════════════╣\n')
fprintf('║ ELECTRICAL RESULTS                                   ║\n')
fprintf('║  S11  : -11.45 dB at 145.8 MHz                      ║\n')
fprintf('║  VSWR : 1.73 (excellent — no tuner needed)           ║\n')
fprintf('║  Gain : 10.5 dBi                                     ║\n')
fprintf('║  Zin  : 55.9 - 29.6j Ω → use gamma match to 50 Ω   ║\n')
fprintf('╠══════════════════════════════════════════════════════╣\n')
fprintf('║ NEXT STEP: Crossed Yagi                              ║\n')
fprintf('║  Build 2 identical Yagis on same boom                ║\n')
fprintf('║  Rotate second by 90° around boom axis               ║\n')
fprintf('║  Feed with 90° phase shift for circular polarization ║\n')
fprintf('╚══════════════════════════════════════════════════════╝\n')