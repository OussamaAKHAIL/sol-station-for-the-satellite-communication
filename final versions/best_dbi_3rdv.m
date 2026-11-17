%% =========================================================================
%  Crossed Yagi-Uda Antenna for ISS Reception at 145.8 MHz
%  Based on Balanis, Antenna Theory, 3rd ed., Table 10.4 (6-element optimum)
%  Target: LHCP, 13.41 dBi per Yagi
%  Two scripts in one:
%    Section A — uses MATLAB Antenna Toolbox (yagiUda) if available
%    Section B — manual array-factor + half-dipole element pattern (no toolbox needed)
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
fprintf(' Crossed Yagi-Uda — ISS 145.800 MHz\n');
fprintf('========================================\n');
fprintf('Frequency  : %.3f MHz\n', f0/1e6);
fprintf('Wavelength : %.4f m  (%.2f cm)\n', lambda, lambda*100);

%% =========================================================================
%  2. ELEMENT GEOMETRY (Balanis Table 10.4)
%% =========================================================================
% --- Element lengths [fraction of lambda] ---
L_frac = [0.472, 0.452, 0.436, 0.430, 0.434, 0.430];

% --- Element lengths [m] ---
L_m    = L_frac * lambda *(1.017);

% --- Element positions from reflector tip [m] ---
pos_cm = [0.00, 51.40, 110.83, 194.31, 260.72, 347.50];  % cm
pos_m  = pos_cm / 100;

% --- Spacings between consecutive elements [m] ---
% s21, s32, s43, s54, s65
spacings_m = diff(pos_m);

% --- Wire radius [m] (Balanis: a = 0.003369 lambda) ---
a_radius = 0.003369 * lambda;
d_wire   = 2 * a_radius;

% --- Element names ---
elem_names = {'Reflector','Driven','Director 1','Director 2','Director 3','Director 4'};

fprintf('\n--- Element Dimensions ---\n');
fprintf('%-14s  %8s  %12s  %14s\n','Element','L/lambda','Length (cm)','Pos from Ref (cm)');
fprintf('%s\n', repmat('-',1,55));
for i = 1:6
    fprintf('%-14s  %8.3f  %12.2f  %14.2f\n', ...
        elem_names{i}, L_frac(i), L_m(i)*100, pos_cm(i));
end
fprintf('\nWire diameter : %.2f mm (a = %.4f lambda)\n', d_wire*1e3, a_radius/lambda);
fprintf('Total boom    : %.2f cm  (%.4f lambda)\n', pos_cm(end), pos_m(end)/lambda);

%% =========================================================================
%  3. GEOMETRY PLOT — Element Map
%% =========================================================================
figure('Name','Yagi-Uda Geometry','Color','white','Position',[50 600 900 300]);
hold on; grid on; box on;

colors = {[0.8 0 0],[0 0.7 0],[0 0.3 0.9],[0 0.3 0.9],[0 0.3 0.9],[0 0.3 0.9]};
lw     = [4 4 3 3 3 3];
for i = 1:6
    xp  = pos_cm(i);
    hlf = L_m(i)/2 * 100;  % half-arm in cm
    plot([xp xp], [-hlf hlf], '-', 'Color', colors{i}, 'LineWidth', lw(i));
    text(xp, hlf + 4, elem_names{i}, 'HorizontalAlignment','center', ...
         'FontSize',8, 'Color', colors{i});
end
% Boom
plot([0 pos_cm(end)],[0 0],'k-','LineWidth',1.5);
% Lambda/2 reference lines
ref = lambda/2 * 100;
yline(ref,'--','color',[0.5 0.5 0.5],'LineWidth',1,'Label','\lambda/2 = 102.8 cm');
yline(-ref,'--','color',[0.5 0.5 0.5],'LineWidth',1);

xlabel('Position along boom (cm)','FontSize',11);
ylabel('Element half-span (cm)','FontSize',11);
title('Yagi-Uda Antenna Geometry  —  145.800 MHz  (6 Elements, Balanis Table 10.4)',...
      'FontSize',12,'FontWeight','bold');
xlim([-25 385]); ylim([-65 75]);
legend({'Reflector','Driven Element','Directors',...
        'Boom','\lambda/2 reference'}, 'Location','southeast');
set(gca,'FontSize',10);

%% =========================================================================
%  4A. ANTENNA TOOLBOX PATH (requires Antenna Toolbox licence)
%% =========================================================================
if license('test','Antenna_Toolbox')
    fprintf('\n[Antenna Toolbox detected — running full EM simulation]\n');

    % -----------------------------------------------------------------------
    % yagiUda property map (Antenna Toolbox):
    %   Exciter          — driven dipole object  (element 2 in our array)
    %   Reflector        — scalar: reflector length [m]  (element 1)
    %   ReflectorSpacing — scalar: reflector-to-driven spacing [m]  (s21)
    %   NumDirectors     — integer: number of directors  (4 in our case)
    %   DirectorLength   — vector [1 x NumDirectors]: director lengths [m]
    %   DirectorSpacing  — vector [1 x NumDirectors]: driven-to-dir1, dir1-to-dir2… [m]
    % -----------------------------------------------------------------------

    % Build the Yagi — modify the default Exciter in-place (do NOT replace it
    % with a new dipole() object; that breaks the internal element alignment)
    ant                       = yagiUda();
    ant.Exciter.Length        = L_m(2);          % driven element  0.452 λ
    ant.ReflectorLength       = L_m(1);          % reflector       0.472 λ
    ant.ReflectorSpacing      = spacings_m(1);   % s21 = 0.250 λ
    ant.NumDirectors          = 4;               % Dir1…Dir4
    ant.DirectorLength        = L_m(3:end);      % [0.436 0.430 0.434 0.430] λ
    ant.DirectorSpacing       = spacings_m(2:end);% [s32 s43 s54 s65]

    % --- 3D Radiation Pattern ---
    figure('Name','3D Pattern (Toolbox)','Color','white');
    pattern(ant, f0);
    title('3D Radiation Pattern — Single Yagi  145.8 MHz','FontSize',12);
    colorbar;

    % --- E-plane (elevation, phi = 0°) ---
    figure('Name','E-plane','Color','white');
    patternElevation(ant, f0, 0);
    title('E-plane Pattern (φ = 0°)  —  Yagi 145.8 MHz','FontSize',12);

    % --- H-plane (azimuth at theta = 90°) ---
    figure('Name','H-plane','Color','white');
    patternAzimuth(ant, f0, 90);
    title('H-plane Pattern (θ = 90°)  —  Yagi 145.8 MHz','FontSize',12);

    % --- Boresight directivity ---
    % yagiUda boom is along z; end-fire boresight = azimuth=0°, elevation=90°
    D_boresight = pattern(ant, f0, 0, 90);
    fprintf('Computed directivity (boresight): %.2f dBi\n', D_boresight);
    fprintf('Expected (Balanis Table 10.4)   : 13.41 dBi\n');

    % --- Input impedance sweep ---
    f_sweep = linspace(130e6, 165e6, 201);
    figure('Name','Input Impedance','Color','white');
    impedance(ant, f_sweep);
    xline(f0/1e6, 'r--', '145.8 MHz', 'LabelVerticalAlignment','bottom');
    title('Input Impedance vs Frequency  (simple dipole driven element)','FontSize',12);

    % --- S11 vs frequency (ref 50 Ω) ---
    figure('Name','S11','Color','white');
    s = sparameters(ant, f_sweep, 50);
    rfplot(s);
    xline(f0/1e6, 'r--', '145.8 MHz');
    title('S_{11} vs Frequency  (ref 50 Ω)','FontSize',12);

else
    fprintf('\n[Antenna Toolbox NOT available — using manual array-factor method]\n');
    fprintf(' Install the Antenna Toolbox for full EM simulation (Sections 4B below).\n');
end

%% =========================================================================
%  4B. MANUAL ARRAY FACTOR + ELEMENT PATTERN (works WITHOUT Antenna Toolbox)
%% =========================================================================
fprintf('\n--- Manual Array-Factor Calculation ---\n');

%  Angular sweep
theta_deg = linspace(0, 180, 3601);   % 0 = end-fire boresight
theta_rad = deg2rad(theta_deg);

%  --- Approximate excitation of each element ---
%  alpha = -k gives exact end-fire condition: AF maximises at theta=0.
alpha   = -k;
I_amp   = [0.70, 1.00, 0.82, 0.72, 0.68, 0.62];
excit   = I_amp .* exp(1j * alpha * pos_m);

%  Array Factor (boom = z-axis, end-fire toward theta=0)
AF = zeros(size(theta_rad));
for n = 1:6
    AF = AF + excit(n) .* exp(1j * k * pos_m(n) .* cos(theta_rad));
end
AF_norm = abs(AF) ./ max(abs(AF));

%  CORRECT element pattern for x-directed half-dipole in xz E-plane:
%    EP = |cos(pi/2 * sin(theta)) / cos(theta)|
%  Gives EP=1 at theta=0 (boresight) and EP->0 at theta=90 (dipole null).
%  The formula cos(pi/2*cos(theta))/sin(theta) is for a Z-directed dipole
%  and wrongly gives EP=0 at boresight, killing the end-fire beam.
EP       = abs( cos(pi/2 .* sin(theta_rad)) ./ (cos(theta_rad) + 1e-12) );
EP       = EP ./ max(EP);

%  Total normalised pattern
Total    = AF_norm .* EP;
Total    = Total ./ max(Total);
Total_dB = 20*log10(Total + 1e-12);

%  Apply known peak directivity offset from Balanis
D0_dBi        = 13.41;
Total_abs_dBi = Total_dB + D0_dBi;

%  --- Compute approximate HPBW ---
half_pow = Total_dB - max(Total_dB) + 3;   % points where pattern > -3 dB from peak
idx_hp   = find(half_pow >= 0);
if ~isempty(idx_hp)
    HPBW = abs(theta_deg(idx_hp(end)) - theta_deg(idx_hp(1)));
    fprintf('Approximate HPBW (E-plane): %.1f°\n', HPBW);
end

%  --- E-plane polar plot ---
%  E-plane is symmetric about the boom axis (phi=0/180 plane).
%  Right half: polar angle 0→π (theta=0 at top, theta=180 at bottom, clockwise).
%  Left half:  mirror at polar angle 2π-theta (same values, counter-clockwise from top).
figure('Name','E-plane Pattern (Manual AF)','Color','white','Position',[50 50 700 600]);
ax = polaraxes;
polarplot(ax, theta_rad,           Total_abs_dBi, 'b-', 'LineWidth', 2.5);
hold(ax,'on');
polarplot(ax, 2*pi - theta_rad,    Total_abs_dBi, 'b-', 'LineWidth', 2.5);  % left mirror
ax.ThetaZeroLocation = 'top';
ax.ThetaDir          = 'clockwise';
ax.RLim              = [-20  D0_dBi + 1];
ax.RTick             = -20:5:15;
ax.RTickLabel        = arrayfun(@(x) sprintf('%d dBi',x), -20:5:15,'UniformOutput',false);
ax.ThetaTick         = 0:30:330;
ax.FontSize          = 10;
title(ax,'E-plane Radiation Pattern — Single Yagi  145.8 MHz',...
      'FontSize',12,'FontWeight','bold');
legend(ax,{'Forward','Back'},'Location','southeast');

%  --- Cartesian dBi vs angle ---
figure('Name','E-plane Cartesian','Color','white','Position',[760 50 700 400]);
plot(theta_deg, Total_abs_dBi, 'b-', 'LineWidth', 2); hold on;
yline(D0_dBi - 3,'r--','LineWidth',1.2,'Label','-3 dB half-power');
yline(0,'k:','LineWidth',1);
xlabel('θ (degrees)','FontSize',11);
ylabel('Directivity (dBi)','FontSize',11);
title('E-plane Pattern  (Cartesian)  —  Yagi 145.8 MHz','FontSize',12,'FontWeight','bold');
grid on; ylim([-30 15]); xlim([0 180]);
set(gca,'FontSize',10);

%% =========================================================================
%  5. CROSSED YAGI — CIRCULAR POLARIZATION
%% =========================================================================
fprintf('\n========================================\n');
fprintf(' Crossed Yagi — LHCP Analysis\n');
fprintf('========================================\n');

%  Feed phasing
phase_V_deg  =   0;    % Vertical Yagi   (reference)
phase_H_deg  = -90;    % Horizontal Yagi (LHCP: H lags V by 90°)
%  → Swap to +90° for RHCP

fprintf('V-pol Yagi phase : %+d°\n', phase_V_deg);
fprintf('H-pol Yagi phase : %+d°  → LHCP\n', phase_H_deg);
fprintf('(Change H phase to +90° for RHCP)\n');

%  --- λ/4 Phasing Cable Lengths ---
cables = {'RG-58 (VF=0.66)', 'RG-213 (VF=0.66)', 'Aircell-7 (VF=0.84)'};
VFs    = [0.66, 0.66, 0.84];

fprintf('\n--- λ/4 Phase-Delay Cable Lengths ---\n');
for i = 1:length(VFs)
    L_delay = VFs(i) * lambda / 4 * 100;  % cm
    fprintf('  %-20s : %.2f cm\n', cables{i}, L_delay);
end

%  --- Full-sphere pattern of crossed Yagi (2D grid) ---
%  E_V (V-pol Yagi) and E_H (H-pol Yagi) combine with 90° phase
th = linspace(0, pi, 181);
ph = linspace(0, 2*pi, 361);
[TH, PH] = meshgrid(th, ph);

%  Array factor on full sphere (same AF for both Yagis, same geometry)
AF_3D = zeros(size(TH));
for n = 1:6
    % Boom along z for V-Yagi: elements in xz-plane
    AF_3D = AF_3D + excit(n) .* exp(1j * k * pos_m(n) .* cos(TH));
end
AF_3D_norm = abs(AF_3D) ./ max(abs(AF_3D(:)));

%  CORRECT element pattern for x-directed dipole (boom along z):
%  EP = |cos(pi/2 * sin(TH)) / cos(TH)|  — maximum at TH=0 (boresight)
EP_3D = abs( cos(pi/2 .* sin(TH)) ./ (cos(TH) + 1e-12) );
EP_3D = EP_3D ./ max(EP_3D(:));

P_single = (AF_3D_norm .* EP_3D).^2;

%  For crossed Yagi with ideal 90° feed and equal amplitudes:
%  Total power = |E_V|^2 + |E_H|^2  (orthogonal → add powers, not amplitudes)
%  Both Yagis have the same pattern magnitude (same geometry), so:
P_CP = 2 * P_single;   % coherent combination for CP on-axis
P_CP_norm = P_CP ./ max(P_CP(:));

%  Convert to spherical coordinates for surf plot
X = P_CP_norm .* sin(TH) .* cos(PH);
Y = P_CP_norm .* sin(TH) .* sin(PH);
Z = P_CP_norm .* cos(TH);

figure('Name','Crossed Yagi 3D Pattern','Color','white','Position',[50 350 700 600]);
surf(X, Y, Z, 20*log10(P_CP_norm + 1e-6), 'EdgeColor','none');
colormap(jet); colorbar;
clim([-20 0]);
cb = colorbar; cb.Label.String = 'Normalized Level (dB)';
axis equal; axis off;
title('Crossed Yagi-Uda  3D Radiation Pattern  —  LHCP  145.8 MHz',...
      'FontSize',12,'FontWeight','bold');
view(45,30); lighting gouraud; camlight('headlight');

%% =========================================================================
%  6. IMPEDANCE MATCHING CALCULATIONS
%% =========================================================================
fprintf('\n========================================\n');
fprintf(' Impedance Matching\n');
fprintf('========================================\n');

Z_driven   = 25;                          % Ω — approximate from Balanis (with reflector)
Z_folded   = 4 * Z_driven;               % Ω — folded dipole 4:1 step-up
Z_coax_tgt = 50;                          % Ω — target (standard coax)
Z_qwt      = sqrt(Z_folded * Z_coax_tgt); % Ω — required λ/4 transformer
L_qwt_cm   = 0.66 * lambda / 4 * 100;    % cm — (VF=0.66, RG-6 or RG-11, 75 Ω)

fprintf('Simple dipole Z_in         : %.1f Ω\n', Z_driven);
fprintf('Folded dipole Z_in (×4)    : %.1f Ω\n', Z_folded);
fprintf('λ/4 transformer impedance  : %.1f Ω  → use 75 Ω coax (RG-6 / RG-11)\n', Z_qwt);
fprintf('λ/4 transformer length     : %.2f cm  (VF = 0.66)\n', L_qwt_cm);

%  SWR vs frequency — correct transmission-line λ/4 transformer formula:
%    Z_in(f) = Z0t * (ZL + j*Z0t*tan(βl)) / (Z0t + j*ZL*tan(βl))
%  where βl = (π/2)*(f/f0) is the electrical length of the λ/4 section.
f_sw     = linspace(130e6, 165e6, 1001);
Z75      = 75;                               % transformer characteristic impedance
ZL       = Z_folded;                         % load = folded dipole (real, 100 Ω)
beta_l   = (pi/2) .* (f_sw ./ f0);          % electrical length at each frequency
tanBL    = tan(beta_l);
Z_in_match = Z75 .* (ZL + 1j.*Z75.*tanBL) ./ (Z75 + 1j.*ZL.*tanBL);
Gamma    = (Z_in_match - Z_coax_tgt) ./ (Z_in_match + Z_coax_tgt);
SWR      = (1 + abs(Gamma)) ./ max(1 - abs(Gamma), 1e-9);

figure('Name','SWR vs Frequency','Color','white','Position',[760 400 700 400]);
plot(f_sw/1e6, SWR, 'b-', 'LineWidth', 2); hold on;
yline(1.5, 'r--', 'LineWidth',1.2, 'Label','SWR = 1.5');
yline(2.0, 'm--', 'LineWidth',1.2, 'Label','SWR = 2.0');
xline(f0/1e6,'k:','LineWidth',1.5,'Label','145.8 MHz');
xlabel('Frequency (MHz)','FontSize',11);
ylabel('SWR (ref 50 Ω)','FontSize',11);
title('SWR vs Frequency — Folded Dipole + 75 Ω λ/4 Transformer','FontSize',12,'FontWeight','bold');
grid on; ylim([1 4]); xlim([130 165]);
set(gca,'FontSize',10);

%% =========================================================================
%  7. LINK BUDGET SUMMARY
%% =========================================================================
fprintf('\n========================================\n');
fprintf(' Expected Link Performance\n');
fprintf('========================================\n');

G_yagi       = 13.41;    % dBi per Yagi
G_CP_circ    = G_yagi;   % dBi — CP signal (both Yagis add coherently, no loss)
G_CP_linear  = G_yagi - 3.0;  % dBi — LP signal (−3 dB penalty)
G_LP_worst   = -Inf;     % dBi — LP Yagi, polarisation 90° off
G_LP_aligned = G_yagi;   % dBi — LP Yagi, perfectly aligned

fprintf('Antenna type           Gain (dBi)   Note\n');
fprintf('%s\n', repmat('-',1,60));
fprintf('Single Yagi (LP)        %6.2f     best case (full alignment)\n', G_LP_aligned);
fprintf('Single Yagi (LP)          -Inf     worst case (90° misalign)\n');
fprintf('Crossed Yagi (CP, LP in)%6.2f     always — 3 dB penalty only\n', G_CP_linear);
fprintf('Crossed Yagi (CP, CP in)%6.2f     full gain, no Faraday loss\n', G_CP_circ);

fprintf('\n--- Phasing Delay Line Summary ---\n');
for i = 1:length(VFs)
    L_delay = VFs(i) * lambda / 4 * 100;
    fprintf('  %-20s : %.2f cm  (90° delay for LHCP)\n', cables{i}, L_delay);
end

fprintf('\n========================================\n');
fprintf(' SIMULATION COMPLETE\n');
fprintf('========================================\n');
fprintf('Figures generated:\n');
fprintf('  1. Yagi Geometry (element map)\n');
fprintf('  2. E-plane Pattern — polar  (manual AF)\n');
fprintf('  3. E-plane Pattern — Cartesian\n');
fprintf('  4. Crossed Yagi 3D Pattern  (LHCP)\n');
fprintf('  5. SWR vs Frequency\n');
if license('test','Antenna_Toolbox')
    fprintf('  6. 3D Pattern (Toolbox — full EM)\n');
    fprintf('  7. E-plane (Toolbox)\n');
    fprintf('  8. H-plane (Toolbox)\n');
    fprintf('  9. Input Impedance (Toolbox)\n');
    fprintf(' 10. S11 (Toolbox)\n');
end