%% =========================================================================
% CUSTOM DUAL-BAND ARROW-STYLE YAGI FOR SATELLITE WORK
%
% Geometry imported from MMANA-GAL wire coordinates:
% UHF: 437.800 MHz, 10 elements, elements along Z
% VHF: 145.800 MHz, 4 elements, elements along Y
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
%% =========================================================================

% -------------------------------------------------------------------------
% 2A. UHF YAGI — 437.8 MHz (10 Elements)
% -------------------------------------------------------------------------
U.name = 'UHF 10-element Yagi';
U.f0 = fU;
U.lambda = lambdaU;
U.k = 2*pi/lambdaU;
U.elem_names = { ...
    'Reflector', 'Driven', ...
    'Director 1', 'Director 2', 'Director 3', ...
    'Director 4', 'Director 5', 'Director 6', ...
    'Director 7', 'Director 8'};

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
    1.4504];

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
    2*0.1462];

U.wire_radius = 0.00159; 
U.driven_idx = 2;
U.elem_axis = [0 0 1];
U.plot_color = [0.10 0.32 0.88];
U.I_amp = [0.62 1.00 0.88 0.80 0.74 0.69 0.65 0.60 0.56 0.50];

% -------------------------------------------------------------------------
% 2B. VHF YAGI — 145.8 MHz (4 Elements)
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

V.wire_radius = 0.00500; 
V.driven_idx = 2;
V.elem_axis = [0 1 0];
V.plot_color = [0.82 0.08 0.12];
V.I_amp = [0.68 1.00 0.80 0.62];

%% =========================================================================
% 3. PRINT DIMENSIONS
%% =========================================================================
printYagiDimensions(U);
printYagiDimensions(V);

%% =========================================================================
% 4. COMBINED 3-D GEOMETRY VIEW
%% =========================================================================
figure('Name','Combined Dual-Band Yagi Geometry', ...
    'Color','white','Position',[70 500 1050 560]);
hold on; grid on; box on;

boom_end = max([U.x_pos(end), V.x_pos(end)]);
plot3([0 boom_end], [0 0], [0 0], 'k-', 'LineWidth', 2.0);

% VHF elements in Y direction
for n = 1:numel(V.x_pos)
    x = V.x_pos(n);
    halfL = V.elem_len(n)/2;
    lw = (n == V.driven_idx)*3.7 + (n == 1)*3.2 + (n > 2)*2.4;
    plot3([x x], [-halfL halfL], [0 0], '-', 'Color', V.plot_color, 'LineWidth', lw);
    text(x, halfL + 0.05, 0, V.elem_names{n}, 'Color', V.plot_color, ...
        'FontSize', 8, 'HorizontalAlignment','center');
end

% UHF elements in Z direction
for n = 1:numel(U.x_pos)
    x = U.x_pos(n);
    halfL = U.elem_len(n)/2;
    lw = (n == U.driven_idx)*3.7 + (n == 1)*3.2 + (n > 2)*2.2;
    plot3([x x], [0 0], [-halfL halfL], '-', 'Color', U.plot_color, 'LineWidth', lw);
    text(x, 0, halfL + 0.035, U.elem_names{n}, 'Color', U.plot_color, ...
        'FontSize', 8, 'HorizontalAlignment','center');
end

xlabel('Boom direction X (m)','FontSize',11);
ylabel('VHF element axis Y (m)','FontSize',11);
zlabel('UHF element axis Z (m)','FontSize',11);
title({'Custom Dual-Band Arrow-Style Yagi Geometry (10-Elem UHF / 4-Elem VHF)', ...
    'Red = VHF 145.8 MHz; Blue = UHF 437.8 MHz'}, ...
    'FontSize',12,'FontWeight','bold');
axis equal; view(37,25);
legend({'Boom','VHF elements (145.8 MHz)','UHF elements (437.8 MHz)'}, 'Location','northeast');
set(gca,'FontSize',10);

%% =========================================================================
% 5. ANTENNA TOOLBOX PATH
%% =========================================================================
if license('test','Antenna_Toolbox')
    fprintf('\n[Antenna Toolbox detected — generating physical Yagi models]\n');
    antV = createToolboxYagi(V);
    antU = createToolboxYagi(U);
    
    % --- VHF Radiation Patterns ---
    figure('Name','VHF 3D Total Pattern — Antenna Toolbox','Color','white');
    pattern(antV, V.f0);
    title('VHF 4-Element Yagi — Total Directivity (145.8 MHz)','FontSize',12);
    
    figure('Name','VHF 3D RHCP Pattern — Antenna Toolbox','Color','white');
    pattern(antV, V.f0, 'Polarization', 'RHCP');
    title('VHF 4-Element Yagi — 3D RHCP Pattern (145.8 MHz)','FontSize',12);
    
    figure('Name','VHF 3D LHCP Pattern — Antenna Toolbox','Color','white');
    pattern(antV, V.f0, 'Polarization', 'LHCP');
    title('VHF 4-Element Yagi — 3D LHCP Pattern (145.8 MHz)','FontSize',12);
    
    % --- UHF Radiation Patterns ---
    figure('Name','UHF 3D Total Pattern — Antenna Toolbox','Color','white');
    pattern(antU, U.f0);
    title('UHF 10-Element Yagi — Total Directivity (437.8 MHz)','FontSize',12);
    
    figure('Name','UHF 3D RHCP Pattern — Antenna Toolbox','Color','white');
    pattern(antU, U.f0, 'Polarization', 'RHCP');
    title('UHF 10-Element Yagi — 3D RHCP Pattern (437.8 MHz)','FontSize',12);
    
    figure('Name','UHF 3D LHCP Pattern — Antenna Toolbox','Color','white');
    pattern(antU, U.f0, 'Polarization', 'LHCP');
    title('UHF 10-Element Yagi — 3D LHCP Pattern (437.8 MHz)','FontSize',12);

    % --- Input Impedance Sweeps ---
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
else
    fprintf('\n[Antenna Toolbox unavailable — manual pattern path enabled]\n');
end

%% =========================================================================
% 6. MANUAL FULL-SPHERE PATTERN + NUMERICAL DIRECTIVITY
%% =========================================================================
fprintf('\n============================================================\n');
fprintf(' MANUAL PATTERN / DIRECTIVITY ESTIMATES\n');
fprintf('============================================================\n');
resV = manualYagiPattern(V);
resU = manualYagiPattern(U);

%% =========================================================================
% 7. E-PLANE CARTESIAN AND POLAR PLOTS
%% =========================================================================
plotYagiCuts(V, resV);
plotYagiCuts(U, resU);

%% =========================================================================
% 8. 3-D MANUAL PATTERN PLOTS
%% =========================================================================
plotYagi3D(V, resV);
plotYagi3D(U, resU);

%% =========================================================================
% 9. FEEDPOINT IMPEDANCE BEFORE OPTIMIZATION
%% =========================================================================
ZinV_MMANAGAL = 32.73 + 1j*14.79; 
ZinU_MMANAGAL = 20.06 + 1j*11.73; 
Z0_feed = 50; 

fprintf('\n============================================================\n');
fprintf(' FEEDPOINT / MATCHING STATUS (BEFORE OPTIMIZATION)\n');
fprintf('============================================================\n');
reportImpedance('VHF', ZinV_MMANAGAL, Z0_feed);
reportImpedance('UHF', ZinU_MMANAGAL, Z0_feed);

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
            A.elem_names{n}, A.x_pos(n), A.elem_len(n), ...
            A.elem_len(n)*100, A.elem_len(n)/A.lambda);
    end
    fprintf('\nWire radius : %.3f mm\n', A.wire_radius*1e3);
    fprintf('Boom length : %.4f m (%.3f lambda)\n', A.x_pos(end), A.x_pos(end)/A.lambda);
end

function ant = createToolboxYagi(A)
    ant = yagiUda();
    
    % Driven element dipole configuration
    ant.Exciter = dipole();
    ant.Exciter.Length = A.elem_len(A.driven_idx);
    ant.Exciter.Width = 2*A.wire_radius;
    
    % FIXED TILT AXIS: 
    % Tilt around Y-axis (or [0 1 0]) rotates the exciter 90° out-of-plane
    % relative to the reflector/directors without rotating down the boom line.
    ant.Exciter.Tilt = 90;
    ant.Exciter.TiltAxis = [0 1 0];
    
    % Reflector and Directors setup
    ant.ReflectorLength = A.elem_len(1);
    ant.ReflectorSpacing = A.x_pos(A.driven_idx) - A.x_pos(1);
    ant.NumDirectors = numel(A.x_pos) - 2;
    ant.DirectorLength = A.elem_len(3:end);
    ant.DirectorSpacing = diff(A.x_pos(2:end));
end

function R = manualYagiPattern(A)
    theta = linspace(0, pi, 181);
    phi = linspace(0, 2*pi, 361);
    [TH, PH] = meshgrid(theta, phi);

    rx = cos(TH);
    ry = sin(TH).*cos(PH);
    rz = sin(TH).*sin(PH);

    u = A.elem_axis / norm(A.elem_axis);
    cosGamma = rx*u(1) + ry*u(2) + rz*u(3);

    sinGamma = sqrt(max(1 - cosGamma.^2, 0));
    EP = abs(cos((pi/2).*cosGamma) ./ max(sinGamma, 1e-12));
    EP = EP ./ max(EP(:));

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

    dTheta = theta(2) - theta(1);
    dPhi = phi(2) - phi(1);
    PradNorm = sum(sum(U .* sin(TH))) * dTheta * dPhi;
    Dlin = 4*pi / PradNorm;
    DdBi = 10*log10(Dlin);

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

    idxRight = find(Ecut_dB(thetaCut >= 0) <= -3, 1, 'first');
    if isempty(idxRight)
        HPBW = NaN;
    else
        thetaPositive = thetaCut(thetaCut >= 0);
        HPBW = 2*rad2deg(thetaPositive(idxRight));
    end

    R.theta = theta; R.phi = phi; R.TH = TH; R.PH = PH;
    R.E = E; R.U = U; R.Dlin = Dlin; R.D_dBi = DdBi;
    R.thetaCut = thetaCut; R.Ecut_dB = Ecut_dB; R.Pcut_dBi = Pcut_dBi;
    R.HPBW_deg = HPBW; R.rx = rx; R.ry = ry; R.rz = rz;
end

function plotYagiCuts(A, R)
    thetaDeg = rad2deg(R.thetaCut);

    figure('Name',[A.name ' — Cartesian Pattern'], 'Color','white','Position',[90 80 760 410]);
    plot(thetaDeg, R.Pcut_dBi, 'Color',A.plot_color,'LineWidth',2.2);
    hold on; grid on;
    yline(R.D_dBi - 3, 'r--', 'LineWidth',1.1, 'Label','-3 dB');
    xline(0,'k:','LineWidth',1.0);
    xlabel('\theta from forward +X boom axis (degrees)','FontSize',11);
    ylabel('Estimated directivity (dBi)','FontSize',11);
    title(sprintf('%s — Boom/Element-Plane Pattern', A.name), 'FontSize',12,'FontWeight','bold');
    xlim([0 180]); ylim([max(-35,R.D_dBi-40), ceil(R.D_dBi+2)]);
    set(gca,'FontSize',10);

    figure('Name',[A.name ' — Polar Pattern'], 'Color','white','Position',[890 80 610 530]);
    ax = polaraxes;
    polarplot(ax, R.thetaCut, R.Pcut_dBi, 'Color',A.plot_color,'LineWidth',2.2);
    hold(ax,'on');
    polarplot(ax, 2*pi-R.thetaCut, R.Pcut_dBi, 'Color',A.plot_color,'LineWidth',2.2);
    ax.ThetaZeroLocation = 'top'; ax.ThetaDir = 'clockwise';
    ax.RLim = [max(-35, floor(R.D_dBi-40)) ceil(R.D_dBi+2)];
    ax.FontSize = 10;
    title(ax, sprintf('%s — Polar Pattern', A.name), 'FontSize',12,'FontWeight','bold');
end

function plotYagi3D(A, R)
    X = R.E .* R.rx;
    Y = R.E .* R.ry;
    Z = R.E .* R.rz;

    figure('Name',[A.name ' — 3D Pattern'], 'Color','white','Position',[155 160 720 570]);
    surf(X, Y, Z, 20*log10(R.E + 1e-8), 'EdgeColor','none');
    axis equal off; view(42,28); colormap(turbo); clim([-25 0]);
    cb = colorbar; cb.Label.String = 'Normalised field level (dB)';
    camlight('headlight'); lighting gouraud;
    title(sprintf('%s — Manual 3D Radiation Pattern', A.name), 'FontSize',12,'FontWeight','bold');
end

function reportImpedance(label, Zin, Z0)
    if isempty(Zin)
        fprintf('%s MMANA impedance: not entered yet.\n', label);
        return;
    end
    Gamma = (Zin - Z0) ./ (Zin + Z0);
    SWR = (1 + abs(Gamma)) ./ max(1 - abs(Gamma), 1e-12);
    fprintf('%s Pre-Optimization Impedance : %.2f %+.2fj ohm\n', label, real(Zin), imag(Zin));
    fprintf('%s Raw SWR relative to 50 ohm: %.2f\n', label, SWR);
end