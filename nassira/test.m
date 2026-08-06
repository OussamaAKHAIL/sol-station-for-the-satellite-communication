%% =========================================================================
% CUSTOM DUAL-BAND ARROW-STYLE YAGI FOR SATELLITE WORK
%
% Geometry imported from MMANA-GAL wire coordinates:
% UHF: 437.800 MHz, 11 elements, elements along Z
% VHF: 145.800 MHz, 4 elements, elements along Y
%
% Coordinate convention:
% +X = forward direction along boom
% UHF element axis = Z
% VHF element axis = Y
%
% IMPORTANT:
% This is a DUAL-BAND, ORTHOGONAL LINEAR-POLARIZATION antenna:
% VHF Yagi = Y-polarized
% UHF Yagi = Z-polarized
%
% It is NOT a crossed-Yagi circular-polarization feed arrangement.
% Do NOT use a 90-degree phasing cable between VHF and UHF feeds:
% they are different frequencies and should be fed independently through
% separate feedlines or a suitable duplexer/diplexer.
%
% Manual-pattern section:
% - Computes a physically reasonable element-factor × array-factor model.
% - Derives lossless directivity numerically from the resulting pattern.
% - Does NOT replace MMANA-GAL/NEC for final gain, impedance, SWR,
% matching-network, coupling, or current-distribution predictions.
%
% Requires only base MATLAB for manual plots.
% Antenna Toolbox path runs automatically if available.
%% =========================================================================
clear; clc; close all;

fprintf('============================================================\n');
fprintf(' CUSTOM DUAL-BAND ARROW-STYLE YAGI — SATELLITE ANTENNA\n');
fprintf('============================================================\n');

%% =========================================================================
% 1. FUNDAMENTAL CONSTANTS
%% =========================================================================
c = 299792458; % speed of light [m/s]

fV = 145.8e6; % VHF design frequency [Hz]
fU = 437.8e6; % UHF design frequency [Hz]

lambdaV = c / fV;
lambdaU = c / fU;

fprintf('\n--- Frequency Summary ---\n');
fprintf('VHF frequency : %.3f MHz\n', fV/1e6);
fprintf('VHF wavelength: %.4f m\n', lambdaV);
fprintf('UHF frequency : %.3f MHz\n', fU/1e6);
fprintf('UHF wavelength: %.4f m\n', lambdaU);

%% =========================================================================
% 2. MMANA-GAL GEOMETRY IMPORT
%
% MMANA wire format:
% x1,y1,z1, x2,y2,z2, wire-radius, ...
%
% The source is "w2c" in both models:
% wire 2, centre-fed
%
% In this script:
% x_pos = element location along the boom
% elem_len = total element length
%% =========================================================================

% -------------------------------------------------------------------------
% 2A. UHF YAGI — 437.8 MHz
% 11 elements: reflector, driven element, 9 directors
% MMANA elements run along Z.
% -------------------------------------------------------------------------
U.name = 'UHF 11-element Yagi';
U.f0 = fU;
U.lambda = lambdaU;
U.k = 2*pi/lambdaU;

U.elem_names = { ...
'Reflector', 'Driven', ...
'Director 1', 'Director 2', 'Director 3', ...
'Director 4', 'Director 5', 'Director 6', ...
'Director 7', 'Director 8', 'Director 9'};

% X coordinates taken directly from your MMANA wire endpoints.
U.x_pos = [ ...
0.0000, ...
0.1907, ...
0.2628, ...
0.4040, ...
0.5616, ...
0.7245, ...
0.8937, ...
1.0744, ...
1.2624, ...
1.4504, ...
1.6133];

% Full wire lengths: 2 × listed half length in your MMANA geometry.
U.elem_len = [ ...
2*0.1782, ...
2*0.1664, ...
2*0.1531, ...
2*0.1504, ...
2*0.1504, ...
2*0.1504, ...
2*0.1504, ...
2*0.1504, ...
2*0.1472, ...
2*0.1462, ...
2*0.1378];

U.wire_radius = 0.00159; % m, imported from MMANA
U.driven_idx = 2;
U.elem_axis = [0 0 1]; % UHF elements oriented along Z
U.plot_color = [0.10 0.32 0.88];

% Approximate passive-element current taper for MANUAL pattern only.
% Replace with MMANA current magnitudes/phases if available.
U.I_amp = [0.62 1.00 0.88 0.80 0.74 0.69 0.65 0.60 0.56 0.50 0.42];


% -------------------------------------------------------------------------
% 2B. VHF YAGI — 145.8 MHz
% 4 elements: reflector, driven element, 2 directors
% MMANA elements run along Y.
% -------------------------------------------------------------------------
V.name = 'VHF 4-element Yagi';
V.f0 = fV;
V.lambda = lambdaV;
V.k = 2*pi/lambdaV;

V.elem_names = {'Reflector', 'Driven', 'Director 1', 'Director 2'};

V.x_pos = [ ...
0.000, ...
0.614, ...
0.884, ...
1.337];

V.elem_len = [ ...
2*0.5080, ...
2*0.4890, ...
2*0.4570, ...
2*0.4265];

V.wire_radius = 0.00500; % m, imported from MMANA
V.driven_idx = 2;
V.elem_axis = [0 1 0]; % VHF elements oriented along Y
V.plot_color = [0.82 0.08 0.12];

% Approximate passive-element current taper for MANUAL pattern only.
% Replace with MMANA current magnitudes/phases if available.
V.I_amp = [0.68 1.00 0.80 0.62];

%% =========================================================================
% 3. PRINT DIMENSIONS
%% =========================================================================
printYagiDimensions(U);
printYagiDimensions(V);

fprintf('\n--- Polarization / Feed Summary ---\n');
fprintf('VHF elements are directed along +Y / -Y.\n');
fprintf('UHF elements are directed along +Z / -Z.\n');
fprintf('The two antenna systems are orthogonal linear polarizations.\n');
fprintf('Use separate VHF and UHF feeds or a correctly rated duplexer.\n');
fprintf('Do NOT use a VHF/UHF quarter-wave cable as a CP phasing harness.\n');

%% =========================================================================
% 4. COMBINED 3-D GEOMETRY VIEW
%% =========================================================================
figure('Name','Combined Dual-Band Yagi Geometry', ...
'Color','white','Position',[70 500 1050 560]);
hold on; grid on; box on;

% Boom along X.
boom_end = max([U.x_pos(end), V.x_pos(end)]);
plot3([0 boom_end], [0 0], [0 0], 'k-', 'LineWidth', 2.0);

% VHF elements in Y direction.
for n = 1:numel(V.x_pos)
x = V.x_pos(n);
halfL = V.elem_len(n)/2;

if n == V.driven_idx
lw = 3.7;
elseif n == 1
lw = 3.2;
else
lw = 2.4;
end

plot3([x x], [-halfL halfL], [0 0], ...
'-', 'Color', V.plot_color, 'LineWidth', lw);

text(x, halfL + 0.05, 0, V.elem_names{n}, ...
'Color', V.plot_color, ...
'FontSize', 8, ...
'HorizontalAlignment','center');
end

% UHF elements in Z direction.
for n = 1:numel(U.x_pos)
x = U.x_pos(n);
halfL = U.elem_len(n)/2;

if n == U.driven_idx
lw = 3.7;
elseif n == 1
lw = 3.2;
else
lw = 2.2;
end

plot3([x x], [0 0], [-halfL halfL], ...
'-', 'Color', U.plot_color, 'LineWidth', lw);

text(x, 0, halfL + 0.035, U.elem_names{n}, ...
'Color', U.plot_color, ...
'FontSize', 8, ...
'HorizontalAlignment','center');
end

xlabel('Boom direction X (m)','FontSize',11);
ylabel('VHF element axis Y (m)','FontSize',11);
zlabel('UHF element axis Z (m)','FontSize',11);
title({'Custom Dual-Band Arrow-Style Yagi Geometry', ...
'Red = VHF 145.8 MHz; Blue = UHF 437.8 MHz'}, ...
'FontSize',12,'FontWeight','bold');

axis equal;
view(37,25);
legend({'Boom','VHF elements (145.8 MHz)','UHF elements (437.8 MHz)'}, ...
'Location','northeast');
set(gca,'FontSize',10);

%% =========================================================================
% 5. ANTENNA TOOLBOX PATH
%
% This models the physical Yagi dimensions using yagiUda if available.
% The toolbox orientation convention need not match the combined 3-D
% drawing; directivity and impedance are independent of display rotation.
%% =========================================================================
if license('test','Antenna_Toolbox')
fprintf('\n[Antenna Toolbox detected — creating physical Yagi models]\n');

antV = createToolboxYagi(V);
antU = createToolboxYagi(U);

figure('Name','VHF 3D Pattern — Antenna Toolbox','Color','white');
pattern(antV, V.f0);
title('VHF 4-Element Yagi — 145.800 MHz','FontSize',12);

figure('Name','UHF 3D Pattern — Antenna Toolbox','Color','white');
pattern(antU, U.f0);
title('UHF 11-Element Yagi — 437.800 MHz','FontSize',12);

fV_sweep = linspace(136e6, 155e6, 161);
fU_sweep = linspace(420e6, 450e6, 201);

figure('Name','VHF Input Impedance — Antenna Toolbox','Color','white');
impedance(antV, fV_sweep);
xline(V.f0/1e6,'r--','145.8 MHz');
title('VHF Input Impedance — Geometry Model','FontSize',12);

figure('Name','UHF Input Impedance — Antenna Toolbox','Color','white');
impedance(antU, fU_sweep);
xline(U.f0/1e6,'r--','437.8 MHz');
title('UHF Input Impedance — Geometry Model','FontSize',12);

fprintf('NOTE: compare Toolbox impedance with MMANA-GAL before\n');
fprintf('building any matching network. MMANA/NEC results should\n');
fprintf('be the authority for your final physical construction.\n');
else
fprintf('\n[Antenna Toolbox unavailable — manual pattern path enabled]\n');
end

%% =========================================================================
% 6. MANUAL FULL-SPHERE PATTERN + NUMERICAL DIRECTIVITY
%
% The pattern uses:
% Total field = element factor × array factor
%
% The element factor is the exact thin half-wave dipole far-field pattern
% for the relevant dipole axis. The array factor uses an end-fire phase
% progression and approximate current taper.
%
% This is useful for geometry visualisation and trend analysis. It is NOT
% a replacement for the full MoM current solution from MMANA-GAL.
%% =========================================================================
fprintf('\n============================================================\n');
fprintf(' MANUAL PATTERN / DIRECTIVITY ESTIMATES\n');
fprintf('============================================================\n');

resV = manualYagiPattern(V);
resU = manualYagiPattern(U);

fprintf('\n--- Lossless Manual Estimates ---\n');
fprintf('VHF estimated directivity : %.2f dBi\n', resV.D_dBi);
fprintf('VHF estimated HPBW : %.1f degrees\n', resV.HPBW_deg);
fprintf('UHF estimated directivity : %.2f dBi\n', resU.D_dBi);
fprintf('UHF estimated HPBW : %.1f degrees\n', resU.HPBW_deg);
fprintf('\nThese values are analytic estimates only.\n');
fprintf('Use MMANA-GAL/NEC calculated gain and F/B for build decisions.\n');

%% =========================================================================
% 7. E-PLANE CARTESIAN AND POLAR PLOTS
%
% The plotted cut is the boom-element plane:
% VHF cut: X-Y plane
% UHF cut: X-Z plane
%% =========================================================================
plotYagiCuts(V, resV);
plotYagiCuts(U, resU);

%% =========================================================================
% 8. 3-D PATTERN PLOTS
%% =========================================================================
plotYagi3D(V, resV);
plotYagi3D(U, resU);

%% =========================================================================
% 9. FEEDPOINT IMPEDANCE / MATCHING PLACEHOLDERS
%
% The text pasted from MMANA specifies "w2c" source placement but does
% not include the computed feedpoint impedance. Enter those values below
% after reading the MMANA "Calculate" / "View" result.
%
% Example format:
% ZinV_MMANAGAL = 22.5 + 1j*14.7;
% ZinU_MMANAGAL = 18.1 - 1j*7.2;
%
% Do not use example numbers above as design values.
%% =========================================================================
ZinV_MMANAGAL = []; % Enter MMANA result, e.g. R + 1j*X
ZinU_MMANAGAL = []; % Enter MMANA result, e.g. R + 1j*X
Z0_feed = 50; % nominal feedline reference impedance [ohm]

fprintf('\n============================================================\n');
fprintf(' FEEDPOINT / MATCHING STATUS\n');
fprintf('============================================================\n');

reportImpedance('VHF', ZinV_MMANAGAL, Z0_feed);
reportImpedance('UHF', ZinU_MMANAGAL, Z0_feed);

fprintf('\nMatching guidance:\n');
fprintf(' • Tune each Yagi at its own feedpoint independently.\n');
fprintf(' • Add a 1:1 common-mode choke near each driven element.\n');
fprintf(' • Use the MMANA feedpoint Z and a VNA measurement to determine\n');
fprintf(' whether the original gamma/direct match needs adjustment.\n');
fprintf(' • A diplexer combines VHF/UHF only after each antenna presents\n');
fprintf(' an acceptable 50-ohm match at its own feedpoint.\n');

%% =========================================================================
% 10. SATELLITE OPERATION SUMMARY
%% =========================================================================
fprintf('\n============================================================\n');
fprintf(' DUAL-BAND SATELLITE OPERATION SUMMARY\n');
fprintf('============================================================\n');
fprintf('VHF Yagi frequency : %.3f MHz\n', V.f0/1e6);
fprintf('UHF Yagi frequency : %.3f MHz\n', U.f0/1e6);
fprintf('VHF elements : %d\n', numel(V.x_pos));
fprintf('UHF elements : %d\n', numel(U.x_pos));
fprintf('VHF boom length : %.3f m (%.2f lambda)\n', ...
V.x_pos(end), V.x_pos(end)/V.lambda);
fprintf('UHF boom length : %.3f m (%.2f lambda)\n', ...
U.x_pos(end), U.x_pos(end)/U.lambda);
fprintf('VHF polarization : linear, Y-axis element orientation\n');
fprintf('UHF polarization : linear, Z-axis element orientation\n');
fprintf('Polarization angle : 90 degrees between VHF and UHF arrays\n');
fprintf('============================================================\n');
fprintf('SIMULATION SCRIPT COMPLETE\n');

%% =========================================================================
% LOCAL FUNCTIONS
%% =========================================================================

function printYagiDimensions(A)

fprintf('\n============================================================\n');
fprintf('%s — %.3f MHz\n', upper(A.name), A.f0/1e6);
fprintf('============================================================\n');

fprintf('%-13s %11s %13s %13s %13s\n', ...
'Element','Position m','Length m','Length cm','Length/lambda');
fprintf('%s\n',repmat('-',1,70));

for n = 1:numel(A.x_pos)
fprintf('%-13s %11.4f %13.4f %13.2f %13.4f\n', ...
A.elem_names{n}, ...
A.x_pos(n), ...
A.elem_len(n), ...
A.elem_len(n)*100, ...
A.elem_len(n)/A.lambda);
end

fprintf('\nWire radius : %.3f mm\n', A.wire_radius*1e3);
fprintf('Wire diameter : %.3f mm\n', 2*A.wire_radius*1e3);
fprintf('Boom length : %.4f m\n', A.x_pos(end));
fprintf('Boom length : %.3f lambda\n', A.x_pos(end)/A.lambda);
fprintf('Driven element : %s at x = %.4f m\n', ...
A.elem_names{A.driven_idx}, A.x_pos(A.driven_idx));
end


function ant = createToolboxYagi(A)

ant = yagiUda();

% Replace default folded dipole with the MMANA-style simple dipole.
ant.Exciter = dipole();
ant.Exciter.Length = A.elem_len(A.driven_idx);
ant.Exciter.Width = 2*A.wire_radius;

ant.ReflectorLength = A.elem_len(1);
ant.ReflectorSpacing = A.x_pos(A.driven_idx) - A.x_pos(1);

nDirectors = numel(A.x_pos) - 2;
ant.NumDirectors = nDirectors;

ant.DirectorLength = A.elem_len(3:end);
ant.DirectorSpacing = diff(A.x_pos(2:end));

end


function R = manualYagiPattern(A)

% Full sphere sampled in conventional spherical coordinates:
% theta = angle away from +X boom axis
% phi = rotation around +X axis
theta = linspace(0, pi, 181);
phi = linspace(0, 2*pi, 361);
[TH, PH] = meshgrid(theta, phi);

% Observation-unit-vector with +X as the forward/boresight direction.
rx = cos(TH);
ry = sin(TH).*cos(PH);
rz = sin(TH).*sin(PH);

% Dot product rhat · dipole axis.
u = A.elem_axis / norm(A.elem_axis);
cosGamma = rx*u(1) + ry*u(2) + rz*u(3);

% Thin half-wave dipole element factor.
sinGamma = sqrt(max(1 - cosGamma.^2, 0));
EP = abs(cos((pi/2).*cosGamma) ./ max(sinGamma, 1e-12));
EP = EP ./ max(EP(:));

% Manual end-fire current model:
% alpha = -k creates constructive interference in +X direction.
alpha = -A.k;
I = A.I_amp .* exp(1j*alpha*A.x_pos);

AF = zeros(size(TH));
for n = 1:numel(A.x_pos)
AF = AF + I(n) .* exp(1j*A.k*A.x_pos(n).*rx);
end

AF = abs(AF);
AF = AF ./ max(AF(:));

E = AF .* EP;
E = E ./ max(E(:));

U = E.^2;

% Numerical directivity:
% D = 4*pi*Umax / integral(U dOmega)
dTheta = theta(2) - theta(1);
dPhi = phi(2) - phi(1);
PradNorm = sum(sum(U .* sin(TH))) * dTheta * dPhi;

Dlin = 4*pi / PradNorm;
DdBi = 10*log10(Dlin);

% Boom-element plane cut:
% phi = 0 places rhat in +X / +element-axis plane.
thetaCut = linspace(0, pi, 3601);
rdotuCut = sin(thetaCut);
sinGammaCut = abs(cos(thetaCut));

EPCut = abs(cos((pi/2).*rdotuCut) ./ max(sinGammaCut, 1e-12));
EPCut = EPCut ./ max(EPCut);

AFCut = zeros(size(thetaCut));
for n = 1:numel(A.x_pos)
AFCut = AFCut + I(n).*exp(1j*A.k*A.x_pos(n).*cos(thetaCut));
end

Ecut = abs(AFCut);
Ecut = Ecut ./ max(Ecut);
Ecut = Ecut .* EPCut;
Ecut = Ecut ./ max(Ecut);

Ecut_dB = 20*log10(Ecut + 1e-12);
Pcut_dBi = Ecut_dB + DdBi;

% Forward-lobe HPBW only: find first -3 dB crossing from boresight.
idxRight = find(Ecut_dB(thetaCut >= 0) <= -3, 1, 'first');
if isempty(idxRight)
HPBW = NaN;
else
thetaPositive = thetaCut(thetaCut >= 0);
HPBW = 2*rad2deg(thetaPositive(idxRight));
end

R.theta = theta;
R.phi = phi;
R.TH = TH;
R.PH = PH;
R.E = E;
R.U = U;
R.Dlin = Dlin;
R.D_dBi = DdBi;
R.thetaCut = thetaCut;
R.Ecut_dB = Ecut_dB;
R.Pcut_dBi = Pcut_dBi;
R.HPBW_deg = HPBW;
R.rx = rx;
R.ry = ry;
R.rz = rz;

end


function plotYagiCuts(A, R)

thetaDeg = rad2deg(R.thetaCut);

% Cartesian pattern.
figure('Name',[A.name ' — Cartesian Pattern'], ...
'Color','white','Position',[90 80 760 410]);

plot(thetaDeg, R.Pcut_dBi, ...
'Color',A.plot_color,'LineWidth',2.2);
hold on; grid on;

yline(R.D_dBi - 3, 'r--', 'LineWidth',1.1, ...
'Label','-3 dB');
xline(0,'k:','LineWidth',1.0);

xlabel('\theta from forward +X boom axis (degrees)','FontSize',11);
ylabel('Estimated directivity (dBi)','FontSize',11);
title(sprintf('%s — Boom/Element-Plane Pattern', A.name), ...
'FontSize',12,'FontWeight','bold');
xlim([0 180]);
ylim([max(-35,R.D_dBi-40), ceil(R.D_dBi+2)]);
set(gca,'FontSize',10);

% Polar pattern.
figure('Name',[A.name ' — Polar Pattern'], ...
'Color','white','Position',[890 80 610 530]);

ax = polaraxes;
polarplot(ax, R.thetaCut, R.Pcut_dBi, ...
'Color',A.plot_color,'LineWidth',2.2);
hold(ax,'on');
polarplot(ax, 2*pi-R.thetaCut, R.Pcut_dBi, ...
'Color',A.plot_color,'LineWidth',2.2);

ax.ThetaZeroLocation = 'top';
ax.ThetaDir = 'clockwise';
ax.RLim = [max(-35, floor(R.D_dBi-40)) ceil(R.D_dBi+2)];
ax.FontSize = 10;

title(ax, sprintf('%s — Polar Pattern', A.name), ...
'FontSize',12,'FontWeight','bold');

end


function plotYagi3D(A, R)

% Scale radial surface by normalized field magnitude.
X = R.E .* R.rx;
Y = R.E .* R.ry;
Z = R.E .* R.rz;

figure('Name',[A.name ' — 3D Pattern'], ...
'Color','white','Position',[155 160 720 570]);

surf(X, Y, Z, 20*log10(R.E + 1e-8), ...
'EdgeColor','none');

axis equal off;
view(42,28);
colormap(turbo);
clim([-25 0]);

cb = colorbar;
cb.Label.String = 'Normalised field level (dB)';

camlight('headlight');
lighting gouraud;

title(sprintf('%s — Manual 3D Radiation Pattern', A.name), ...
'FontSize',12,'FontWeight','bold');

end


function reportImpedance(label, Zin, Z0)

if isempty(Zin)
fprintf('%s MMANA impedance: not entered yet.\n', label);
fprintf(' Paste the calculated MMANA value into Zin%s_MMANAGAL.\n', ...
upper(label(1)));
return;
end

Gamma = (Zin - Z0) ./ (Zin + Z0);
SWR = (1 + abs(Gamma)) ./ max(1 - abs(Gamma), 1e-12);

fprintf('%s MMANA impedance : %.2f %+.2fj ohm\n', ...
label, real(Zin), imag(Zin));
fprintf('%s raw SWR at 50 ohm: %.2f\n', label, SWR);

if imag(Zin) > 0
fprintf(' Reactance is inductive: matching/tuning needs capacitive compensation.\n');
elseif imag(Zin) < 0
fprintf(' Reactance is capacitive: matching/tuning needs inductive compensation.\n');
else
fprintf(' Feedpoint is approximately resonant at the entered frequency.\n');
end
end