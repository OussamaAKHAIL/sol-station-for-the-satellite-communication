%% =========================================================================
%  Crossed Yagi-Uda Antenna for ISS Reception at 145.8 MHz
%  Based on Balanis, Antenna Theory, 3rd ed., Table 10.4 (6-element optimum)
%  Target: LHCP, 13.41 dBi per Yagi
%
%  CORRECTIONS vs original script:
%    1. Z_driven corrected from 25 Ω to 8.7 Ω (MoM/MMANA-GAL result)
%    2. Matching network redesigned: gamma match instead of folded dipole
%    3. Element pattern formula corrected for x-directed dipole (end-fire boom)
%    4. Antenna Toolbox section adds wire radius to Exciter
%    5. Gamma match physical dimensions computed
%    6. CP phasing section clarified and expanded
%
%  Two parallel paths:
%    Section 4A — Antenna Toolbox (yagiUda) if licence present
%    Section 4B — Manual array-factor + element pattern (no toolbox needed)
%% =========================================================================
clear; clc; close all;

%% =========================================================================
%  1. PHYSICAL PARAMETERS
%% =========================================================================
c      = 299792458;        % Speed of light [m/s]
f0     = 145.8e6;          % Design frequency [Hz]
lambda = c / f0;           % Wavelength [m]
k      = 2*pi / lambda;    % Wavenumber [rad/m]

fprintf('========================================\n');
fprintf(' Crossed Yagi-Uda  —  ISS 145.800 MHz\n');
fprintf('========================================\n');
fprintf('Frequency  : %.3f MHz\n', f0/1e6);
fprintf('Wavelength : %.4f m  (%.2f cm)\n', lambda, lambda*100);

%% =========================================================================
%  2. ELEMENT GEOMETRY  (Balanis Table 10.4)
%% =========================================================================
% --- Element lengths [fraction of lambda] ---
L_frac = [0.508,0.489, 0.457, 0.4265];

% --- Correction factor for finite wire diameter (Balanis uses thin-wire) ---
% The ×1.017 factor approximates the end-shortening for ~10 mm Al tube
L_m    = L_frac * lambda ;        % element lengths [m]

% --- Element positions from reflector tip [m] ---
pos_cm = [0.00,0.614, 0.884, 1.337];   % cm
pos_m  = pos_cm / 1;

% --- Spacings between consecutive elements ---
spacings_m = diff(pos_m);   % [s21 s32 s43 s54 s65]

% --- Wire diameter — edit to match your tubing stock ---
d_wire   = 0.010;           % metres  (10 mm Al tube)
a_radius = d_wire / 2;      % radius [m]

% --- Element names ---
elem_names = {'Reflector','Driven','Director 1','Director 2','Director 3','Director 4'};

fprintf('\n--- Element Dimensions ---\n');
fprintf('%-14s  %8s  %12s  %14s\n','Element','L/lambda','Length (cm)','Pos (cm)');
fprintf('%s\n', repmat('-',1,55));
for i = 1:4
    fprintf('%-14s  %8.3f  %12.2f  %14.2f\n', ...
        elem_names{i}, L_frac(i), L_m(i)*100, pos_cm(i));
end
fprintf('\nWire diameter : %.2f mm  (d/λ = %.5f)\n', d_wire*1e3, d_wire/lambda);
fprintf('Total boom    : %.2f cm  (%.4f λ)\n', pos_cm(end), pos_m(end)/lambda);

%% =========================================================================
%  3. GEOMETRY PLOT — Element Map
%% =========================================================================
figure('Name','Yagi Geometry','Color','white','Position',[50 600 900 300]);
hold on; grid on; box on;

colors = {[0.8 0 0],[0 0.7 0],[0 0.3 0.9],[0 0.3 0.9],[0 0.3 0.9],[0 0.3 0.9]};
lw     = [4 4 3 3];
for i = 1:4
    xp  = pos_cm(i);
    hlf = L_m(i)/2 * 100;   % half-arm in cm
    plot([xp xp], [-hlf hlf], '-', 'Color', colors{i}, 'LineWidth', lw(i));
    text(xp, hlf+4, elem_names{i}, 'HorizontalAlignment','center', ...
         'FontSize',8, 'Color', colors{i});
end
plot([0 pos_cm(end)],[0 0],'k-','LineWidth',1.5);           % boom 
ref = lambda/2 * 100;
yline( ref,'--','color',[.5 .5 .5],'LineWidth',1,'Label','\lambda/2');
yline(-ref,'--','color',[.5 .5 .5],'LineWidth',1);

xlabel('Position along boom (cm)','FontSize',11);
ylabel('Element half-span (cm)','FontSize',11);
title('Yagi-Uda Geometry  —  145.800 MHz  (6 Elements, Balanis Table 10.4)', ...
      'FontSize',12,'FontWeight','bold');
xlim([-25 385]); ylim([-65 75]);
legend({'Reflector','Driven Element','Directors','Boom','\lambda/2 ref'}, ...
       'Location','southeast');
set(gca,'FontSize',10);

%% =========================================================================
%  4A. ANTENNA TOOLBOX PATH  (requires Antenna Toolbox licence)
%% =========================================================================
if license('test','Antenna_Toolbox')
    fprintf('\n[Antenna Toolbox detected — running full EM simulation]\n');

    % Build the Yagi object
    ant                       = yagiUda();
    ant.Exciter               = dipole();         % Override the default folded dipole
    ant.Exciter.Length        = L_m(2);           % driven    0.452 λ
    ant.Exciter.Width         = d_wire;           % Toolbox uses Width instead of Radius
    ant.ReflectorLength       = L_m(1);            % reflector 0.472 λ
    ant.ReflectorSpacing      = spacings_m(1);     % s21
    ant.NumDirectors          = 4;
    ant.DirectorLength        = L_m(3:end);        % [0.436 0.430 0.434 0.430] λ
    ant.DirectorSpacing       = spacings_m(2:end); % [s32 s43 s54 s65]
    ant.Exciter.Tilt          = 90;               % Rotate 90 degrees
    ant.Exciter.TiltAxis      = [0 1 0];          % Rotate around the X-axis

    fprintf('Exciter width  : %.2f mm (w/λ = %.5f)\n', ...
            ant.Exciter.Width*1e3, ant.Exciter.Width/lambda);
    % 3D pattern
    figure('Name','3D Pattern (Toolbox)','Color','white');
    pattern(ant, f0);
    title('3D Radiation Pattern — Single Yagi  145.8 MHz','FontSize',12);
    colorbar;


    % E-plane
    figure('Name','E-plane (Toolbox)','Color','white');
    patternElevation(ant, f0, 0);
    title('E-plane (φ=0°)  —  Yagi 145.8 MHz','FontSize',12);

    % H-plane
    figure('Name','H-plane (Toolbox)','Color','white');
    patternAzimuth(ant, f0, 0);
    title('H-plane (elev=0°)  —  Yagi 145.8 MHz','FontSize',12);

    % Boresight directivity
    D_boresight = pattern(ant, f0, 0, 90);
    fprintf('Toolbox directivity (boresight): %.2f dBi\n', D_boresight);
    fprintf('Expected (Balanis Table 10.4)  : 13.41 dBi\n');

    % Input impedance sweep
    f_sweep = linspace(130e6, 165e6, 201);
    figure('Name','Input Impedance (Toolbox)','Color','white');
    impedance(ant, f_sweep);
    xline(f0/1e6,'r--','145.8 MHz','LabelVerticalAlignment','bottom');
    title('Input Impedance vs Frequency  (Toolbox — simple dipole exciter)','FontSize',12);
    fprintf('\nNOTE: Toolbox Z_in uses simplified mutual coupling.\n');
    fprintf('      For accurate Z_driven use MMANA-GAL or NEC2 result: 8.7+j28.7 Ω\n');

    % S11
    figure('Name','S11 (Toolbox)','Color','white');
    s = sparameters(ant, f_sweep, 50);
    rfplot(s);
    xline(f0/1e6,'r--','145.8 MHz');
    title('S_{11} vs Frequency  (ref 50 Ω)','FontSize',12);

else
    fprintf('\n[Antenna Toolbox NOT available — using manual array-factor method]\n');
end

%% =========================================================================
%  4B. MANUAL ARRAY FACTOR + ELEMENT PATTERN  (no toolbox needed)
%% =========================================================================
fprintf('\n--- Manual Array-Factor Calculation ---\n');

theta_deg = linspace(0, 180, 3601);   % 0° = end-fire boresight
theta_rad = deg2rad(theta_deg);

% Approximate excitation amplitudes and end-fire progressive phase
alpha  = -k;    % exact end-fire: max at theta=0
I_amp  = [0.70, 1.00, 0.82, 0.72, 0.68, 0.62];
excit  = I_amp .* exp(1j * alpha * pos_m);

% Array Factor (boom along z, end-fire toward theta=0)
AF = zeros(size(theta_rad));
for n = 1:6
    AF = AF + excit(n) .* exp(1j * k * pos_m(n) .* cos(theta_rad));
end
AF_norm = abs(AF) ./ max(abs(AF));

% CORRECT element pattern for x-directed half-dipole, boom along z:
%   EP(theta) = |cos(pi/2 * sin(theta)) / cos(theta)|
%   — gives EP=1 at theta=0 (boresight, along boom)
%   — gives EP=0 at theta=90° (broadside, dipole null in its own plane)
% NOTE: the formula cos(pi/2*cos(theta))/sin(theta) is for a z-directed
%       dipole and wrongly produces EP=0 at boresight — do NOT use it here.
EP      = abs( cos(pi/2 .* sin(theta_rad)) ./ (cos(theta_rad) + 1e-12) );
EP      = EP ./ max(EP);

% Total normalised pattern
Total       = AF_norm .* EP;
Total       = Total ./ max(Total);
Total_dB    = 20*log10(Total + 1e-12);
D0_dBi      = 13.41;                          % Balanis peak directivity
Total_dBi   = Total_dB + D0_dBi;

% Approximate HPBW
half_pow = Total_dB - max(Total_dB) + 3;
idx_hp   = find(half_pow >= 0);
if ~isempty(idx_hp)
    HPBW = abs(theta_deg(idx_hp(end)) - theta_deg(idx_hp(1)));
    fprintf('Approximate HPBW (E-plane): %.1f°\n', HPBW);
end

% --- E-plane polar plot ---
figure('Name','E-plane Pattern (Manual AF)','Color','white','Position',[50 50 700 600]);
ax = polaraxes;
polarplot(ax, theta_rad,        Total_dBi, 'b-', 'LineWidth', 2.5); hold(ax,'on');
polarplot(ax, 2*pi-theta_rad,   Total_dBi, 'b-', 'LineWidth', 2.5);
ax.ThetaZeroLocation = 'top';
ax.ThetaDir          = 'clockwise';
ax.RLim              = [-20  D0_dBi+1];
ax.RTick             = -20:5:15;
ax.RTickLabel        = arrayfun(@(x) sprintf('%d dBi',x),-20:5:15,'UniformOutput',false);
ax.ThetaTick         = 0:30:330;
ax.FontSize          = 10;
title(ax,'E-plane Radiation Pattern — Single Yagi  145.8 MHz', ...
      'FontSize',12,'FontWeight','bold');
legend(ax,{'Forward','Back'},'Location','southeast');

% --- Cartesian dBi vs angle ---
figure('Name','E-plane Cartesian','Color','white','Position',[760 50 700 400]);
plot(theta_deg, Total_dBi, 'b-', 'LineWidth', 2); hold on;
yline(D0_dBi-3,'r--','LineWidth',1.2,'Label','-3 dB');
yline(0,'k:','LineWidth',1);
xlabel('θ (degrees)','FontSize',11);
ylabel('Directivity (dBi)','FontSize',11);
title('E-plane Pattern (Cartesian)  —  Yagi 145.8 MHz','FontSize',12,'FontWeight','bold');
grid on; ylim([-30 15]); xlim([0 180]);
set(gca,'FontSize',10);

%% =========================================================================
%  5. CROSSED YAGI — CIRCULAR POLARISATION
%% =========================================================================
fprintf('\n========================================\n');
fprintf(' Crossed Yagi — LHCP Analysis\n');
fprintf('========================================\n');

% Feed phasing convention
% V-Yagi: reference (0°)
% H-Yagi: −90° for LHCP  |  +90° for RHCP
phase_V_deg =   0;
phase_H_deg = -90;    % change to +90 for RHCP

fprintf('V-pol phase : %+d°  (reference)\n', phase_V_deg);
fprintf('H-pol phase : %+d°  → LHCP\n', phase_H_deg);
fprintf('Swap to +90° for RHCP\n');

% λ/4 phasing cable lengths
cables = {'RG-58  (VF=0.66)', 'RG-213 (VF=0.66)', 'Aircell-7 (VF=0.84)', ...
          'LMR-400 (VF=0.85)'};
VFs    = [0.66, 0.66, 0.84, 0.85];

fprintf('\n--- λ/4 Phase-Delay Cable Lengths ---\n');
for i = 1:length(VFs)
    L_delay = VFs(i) * lambda / 4 * 100;
    fprintf('  %-22s : %.2f cm\n', cables{i}, L_delay);
end

% --- Full-sphere 3-D CP pattern ---
th = linspace(0, pi,  181);
ph = linspace(0, 2*pi,361);
[TH, PH] = meshgrid(th, ph);

AF_3D = zeros(size(TH));
for n = 1:6
    AF_3D = AF_3D + excit(n) .* exp(1j * k * pos_m(n) .* cos(TH));
end
AF_3D_norm = abs(AF_3D) ./ max(abs(AF_3D(:)));

% Correct element pattern on full sphere (x-directed dipole, boom=z)
EP_3D = abs( cos(pi/2 .* sin(TH)) ./ (cos(TH) + 1e-12) );
EP_3D = EP_3D ./ max(EP_3D(:));

P_single   = (AF_3D_norm .* EP_3D).^2;
P_CP       = 2 * P_single;                   % both Yagis, orthogonal → add powers
P_CP_norm  = P_CP ./ max(P_CP(:));

X = P_CP_norm .* sin(TH) .* cos(PH);
Y = P_CP_norm .* sin(TH) .* sin(PH);
Z = P_CP_norm .* cos(TH);

figure('Name','Crossed Yagi 3D Pattern','Color','white','Position',[50 350 700 600]);
surf(X, Y, Z, 20*log10(P_CP_norm + 1e-6), 'EdgeColor','none');
colormap(jet); colorbar;
clim([-20 0]);
cb = colorbar; cb.Label.String = 'Normalised Level (dB)';
axis equal; axis off;
title('Crossed Yagi-Uda  3D Pattern  —  LHCP  145.8 MHz', ...
      'FontSize',12,'FontWeight','bold');
view(45,30); lighting gouraud; camlight('headlight');

%% =========================================================================
%  6. IMPEDANCE MATCHING  —  corrected with MoM / MMANA-GAL result
%% =========================================================================
fprintf('\n========================================\n');
fprintf(' Impedance Matching  (MoM-corrected)\n');
fprintf('========================================\n');

% -------------------------------------------------------------------------
%  Measured / simulated values from MMANA-GAL (full MoM):
%    Z_driven = 8.7 + j28.7 Ω   at 145.8 MHz
%  The Antenna Toolbox "impedance" plot gives ~85+j30 Ω because it uses a
%  simplified exciter and underestimates mutual coupling from parasitic
%  elements.  MMANA-GAL (and NEC2) are authoritative for the driven-element
%  impedance in the presence of all other elements.
% -------------------------------------------------------------------------
R_MoM = 8.7;     % Ω  — MMANA-GAL resistance
X_MoM = 28.7;    % Ω  — MMANA-GAL reactance (inductive → shorten driven element)

fprintf('MoM/MMANA-GAL driven element Z : %.1f + j%.1f Ω\n', R_MoM, X_MoM);
fprintf('(Antenna Toolbox value ~85+j30 Ω is inaccurate — see notes)\n\n');

% -------------------------------------------------------------------
%  Step 1 — Tune out reactance by shortening driven element
%  Empirical rule: ~15 Ω per mm of shortening per arm at 145 MHz
% -------------------------------------------------------------------
dX_per_mm = 15;                         % Ω/mm per arm (empirical, ~10 mm Al)
delta_mm  = X_MoM / dX_per_mm;
fprintf('Shorten each arm by ~%.1f mm to resonate driven element\n', delta_mm);
fprintf('New estimated Z_driven (after trim) : %.1f + j0 Ω\n\n', R_MoM);

% -------------------------------------------------------------------
%  Step 2 — Gamma Match: transforms R_driven (≈ 8.7 Ω) to 50 Ω
%
%  The gamma match consists of:
%    - A tap point on the driven element at distance  d  from centre
%    - A series capacitor C_s in the gamma arm
%    - Coax inner connects to tap point via gamma arm
%    - Coax outer connects to element centre (balun recommended)
%
%  At resonance (X_MoM ≈ 0 after trimming):
%    Z_in = R_tap + j*X_cap   where R_tap = Z0 if chosen correctly
%
%  Simple design formula (Balanis / ARRL Antenna Book):
%    R_tap  = Z0 * (d / (L_driven/2))^2 * (Z0_dipole / Z0)
%  — or iteratively: tap position d ≈ 0.04–0.08 λ from centre
%
%  Here we use the T-network equivalent (exact):
%    Z_gamma = j * k * d * Z0_wire     (approximate transmission-line)
%    Z_s     = Z0 * Z_driven / (Z0 - Z_driven)  — not exact, see below
%
%  The most reliable approach is to use the following standard formula:
%    d   (gamma arm length)    ≈ 0.05–0.07 λ
%    C_s (series capacitor)    determined by X_gamma at d
% -------------------------------------------------------------------
Z0_coax  = 50;                % Ω target
R_driven = R_MoM;             % Ω (after trimming X→0)

% Gamma arm length (start with 0.05λ and iterate during build)
d_gamma_lambda = 0.055;                     % fraction of λ
d_gamma_m      = d_gamma_lambda * lambda;   % metres

% Approximate characteristic impedance of gamma arm above element
%   Z0_gamma ≈ 60 * ln(2*s/a_rod) where s = spacing between arm and element
s_gamma  = 0.020;      % m — gap between gamma arm conductor and driven element
a_gamma  = 0.003;      % m — radius of gamma arm conductor (3 mm tube)
Z0_gamma = 60 * log(2 * s_gamma / a_gamma);
fprintf('Gamma arm spacing   : %.0f mm\n', s_gamma*1e3);
fprintf('Gamma arm Z0        : %.1f Ω\n', Z0_gamma);

% Input impedance seen at feed point (gamma arm = short TL)
beta_d       = k * d_gamma_m;
Z_gamma_in   = 1j * Z0_gamma * tan(beta_d);

% Combined parallel impedance of gamma arm and driven element (at tap)
% Driven element from tap to short: short stub of electrical length beta_d
Z_stub       = 1j * Z0_gamma * tan(beta_d);   % same for symmetric element
Z_tap        = (R_driven * Z_stub) / (R_driven + Z_stub);   % parallel

% Series capacitor to tune out residual reactance
X_cap_needed = -imag(Z_tap);   % Ω (negative reactance needed from cap)
if X_cap_needed < 0
    C_s = -1 / (2*pi*f0 * X_cap_needed);   % Farad
    fprintf('Series capacitor Cs : %.1f pF\n', C_s*1e12);
else
    fprintf('No series capacitor needed (reactance already negative)\n');
    C_s = NaN;
end
fprintf('Gamma arm length    : %.1f mm  (%.3f λ)\n', d_gamma_m*1e3, d_gamma_lambda);

% Practical guidance
fprintf('\nGamma Match Summary:\n');
fprintf('  Tap point  : %.1f mm from driven element centre\n', d_gamma_m*1e3);
fprintf('  Arm spacing: %.0f mm between arm and element\n',    s_gamma*1e3);
if ~isnan(C_s)
    fprintf('  Cs         : %.0f pF series capacitor in gamma arm\n', C_s*1e12);
end
fprintf('  Adjust Cs and tap position for SWR < 1.3 at 145.8 MHz\n');
fprintf('  Use a 1:1 choke balun (coax coil, 6–8 turns, 100 mm dia) at feed\n');

% -------------------------------------------------------------------
%  Alternative: Folded dipole (for reference only)
% -------------------------------------------------------------------
Z_folded   = 4 * R_driven;           % Ω (still only ~35 Ω — not 50 Ω)
Z_qwt_req  = sqrt(Z_folded * Z0_coax);   % Ω required λ/4 transformer
L_qwt_cm   = 0.66 * lambda / 4 * 100;   % cm for VF=0.66

fprintf('\n--- Alternative: Folded Dipole ---\n');
fprintf('Z_folded (×4)           : %.1f Ω\n', Z_folded);
fprintf('Required λ/4 transformer: %.1f Ω  (non-standard — needs custom line)\n', Z_qwt_req);
fprintf('Gamma match is simpler for R_driven ≈ %.1f Ω\n', R_driven);

%% =========================================================================
%  7. SWR vs FREQUENCY  (gamma match model)
%% =========================================================================
f_sw  = linspace(130e6, 165e6, 1001);
Q_dip = 5;                                        % element Q (~10 mm Al, Yagi-loaded)

% Frequency-dependent driven element impedance (after shortening to resonance)
X_f    = 2 * R_MoM * Q_dip .* (f_sw - f0) ./ f0;
ZL_f   = R_MoM + 1j .* X_f;

% Gamma match frequency response (simplified: treat as reactive transformation)
beta_f     = k .* (f_sw./f0) .* d_gamma_m;
Z_stub_f   = 1j .* Z0_gamma .* tan(beta_f);
Z_tap_f    = (ZL_f .* Z_stub_f) ./ (ZL_f + Z_stub_f);

% Series capacitor (fixed value)
if ~isnan(C_s)
    X_Cs_f = -1 ./ (2*pi.*f_sw .* C_s);
else
    X_Cs_f = zeros(size(f_sw));
end
Z_in_f  = Z_tap_f + 1j .* X_Cs_f;

Gamma_f = (Z_in_f - Z0_coax) ./ (Z_in_f + Z0_coax);
SWR_f   = (1 + abs(Gamma_f)) ./ max(1 - abs(Gamma_f), 1e-9);

figure('Name','SWR vs Frequency (Gamma Match)','Color','white','Position',[760 400 700 400]);
plot(f_sw/1e6, SWR_f, 'b-', 'LineWidth', 2); hold on;
yline(1.5,'r--','LineWidth',1.2,'Label','SWR = 1.5');
yline(2.0,'m--','LineWidth',1.2,'Label','SWR = 2.0');
xline(f0/1e6,'k:','LineWidth',1.5,'Label','145.8 MHz');
xlabel('Frequency (MHz)','FontSize',11);
ylabel('SWR (ref 50 Ω)','FontSize',11);
title('SWR vs Frequency — Gamma Match  (R_{driven} ≈ 8.7 Ω, Q ≈ 5)','FontSize',12,'FontWeight','bold');
grid on; ylim([1 5]); xlim([130 165]);
set(gca,'FontSize',10);

% Bandwidth summary
idx_15 = find(SWR_f <= 1.5);
idx_20 = find(SWR_f <= 2.0);
if ~isempty(idx_15)
    BW15 = (f_sw(idx_15(end)) - f_sw(idx_15(1)))/1e6;
    fprintf('\nSWR ≤ 1.5 bandwidth : %.1f MHz\n', BW15);
end
if ~isempty(idx_20)
    BW20 = (f_sw(idx_20(end)) - f_sw(idx_20(1)))/1e6;
    fprintf('SWR ≤ 2.0 bandwidth : %.1f MHz\n', BW20);
end

%% =========================================================================
%  8. LINK BUDGET SUMMARY
%% =========================================================================
fprintf('\n========================================\n');
fprintf(' Expected Link Performance\n');
fprintf('========================================\n');

G_yagi      = 13.41;          % dBi per Yagi (Balanis)
G_CP_LP_in  = G_yagi - 3.0;  % dBi CP antenna, LP signal (always −3 dB)
G_LP_best   = G_yagi;         % dBi LP Yagi perfectly aligned
G_LP_worst  = -Inf;           % dBi LP Yagi 90° misaligned (null)

fprintf('Antenna configuration            Gain (dBi)   Notes\n');
fprintf('%s\n', repmat('-',1,65));
fprintf('Single Yagi (LP rx)              %6.2f      Best case, full alignment\n', G_LP_best);
fprintf('Single Yagi (LP rx)               -Inf      Worst case, 90° miss\n');
fprintf('Crossed Yagi LHCP (LP signal)   %6.2f      Always, 3 dB CP penalty\n', G_CP_LP_in);
fprintf('Crossed Yagi LHCP (LHCP signal) %6.2f      Full gain, no Faraday\n', G_yagi);

fprintf('\n--- ISS downlink notes ---\n');
fprintf('ISS APRS downlink   : 145.825 MHz  (5 W, whip, linear/elliptic)\n');
fprintf('ISS packet voice    : 145.800 MHz\n');
fprintf('Doppler shift (max) : ±3.5 kHz\n');
fprintf('Max elevation pass  : 90° (overhead) — antenna must track or use wide beam\n');

%% =========================================================================
%  9. PHASING CABLE SUMMARY TABLE
%% =========================================================================
fprintf('\n--- Phasing Cable Summary (90° delay = λ/4) ---\n');
fprintf('%-24s  %10s  %10s\n','Cable type','VF','Length (cm)');
fprintf('%s\n', repmat('-',1,50));
for i = 1:length(VFs)
    L_d = VFs(i) * lambda / 4 * 100;
    fprintf('%-24s  %10.2f  %10.2f\n', cables{i}, VFs(i), L_d);
end
fprintf('\nAdd connectors at both ends and verify 90° phase with an antenna analyser.\n');

%% =========================================================================
%  10. CROSSED YAGI — AXIAL RATIO ESTIMATE
%% =========================================================================
fprintf('\n========================================\n');
fprintf(' Axial Ratio & Polarisation Purity\n');
fprintf('========================================\n');

% For ideal crossed Yagi with equal-amplitude, 90°-quadrature feed:
%   AR = 1 (0 dB) exactly on boresight
%   AR degrades off-boresight due to pattern asymmetry
% Approximate AR in dB vs theta using pattern inequality:

AR_theta = zeros(size(theta_deg));
for ti = 1:length(theta_deg)
    th_i = theta_rad(ti);
    % E_V component (V-Yagi pattern at this angle)
    EV = Total(ti);
    % H-Yagi has identical pattern (same geometry, rotated 90°)
    % In E-plane of V-Yagi, H-Yagi is in H-plane → use same Total
    EH = Total(ti);
    if (EV + EH) > 1e-9
        AR_theta(ti) = 20*log10( max(EV,EH) / (min(EV,EH) + 1e-12) );
    else
        AR_theta(ti) = 40;
    end
end
AR_theta(AR_theta > 40) = 40;

figure('Name','Axial Ratio vs Angle','Color','white','Position',[50 50 700 380]);
plot(theta_deg, AR_theta, 'r-', 'LineWidth', 2); hold on;
yline(3,'k--','LineWidth',1.2,'Label','AR = 3 dB');
xlabel('θ (degrees)','FontSize',11);
ylabel('Axial Ratio (dB)','FontSize',11);
title('Approximate Axial Ratio vs θ  —  Crossed Yagi  145.8 MHz','FontSize',12,'FontWeight','bold');
grid on; ylim([0 15]); xlim([0 90]);
set(gca,'FontSize',10);

idx_ar3 = find(AR_theta(1:length(theta_deg)/2) <= 3, 1, 'last');
if ~isempty(idx_ar3)
    fprintf('AR ≤ 3 dB beamwidth : ±%.1f° (approx, equal-pattern assumption)\n', theta_deg(idx_ar3));
end

%% =========================================================================
%  11. FINAL SUMMARY
%% =========================================================================
fprintf('\n========================================\n');
fprintf(' SIMULATION COMPLETE\n');
fprintf('========================================\n');
fprintf('Figures generated:\n');
fprintf('  1.  Yagi Geometry (element map)\n');
fprintf('  2.  E-plane Pattern — polar   (manual AF)\n');
fprintf('  3.  E-plane Pattern — Cartesian\n');
fprintf('  4.  Crossed Yagi 3D Pattern   (LHCP)\n');
fprintf('  5.  SWR vs Frequency          (gamma match)\n');
fprintf('  6.  Axial Ratio vs Angle\n');
if license('test','Antenna_Toolbox')
    fprintf('  7.  3D Pattern (Toolbox)\n');
    fprintf('  8.  E-plane (Toolbox)\n');
    fprintf('  9.  H-plane (Toolbox)\n');
    fprintf(' 10.  Input Impedance (Toolbox — see accuracy note)\n');
    fprintf(' 11.  S11 (Toolbox)\n');
end

fprintf('\nKey design values:\n');
fprintf('  f0              : 145.800 MHz\n');
fprintf('  λ               : %.4f m\n', lambda);
fprintf('  Directivity     : %.2f dBi per Yagi (Balanis)\n', D0_dBi);
fprintf('  Z_driven (MoM) : %.1f + j%.1f Ω  ← use MMANA-GAL value\n', R_MoM, X_MoM);
fprintf('  Matching        : Gamma match (tap %.1f mm, Cs ≈ %.0f pF)\n', ...
        d_gamma_m*1e3, C_s*1e12);
fprintf('  CP phasing      : λ/4 delay line on H-Yagi feed\n');
fprintf('  Polarisation    : LHCP (H lags V by 90°)\n');
fprintf('========================================\n');