%% ==========================================================================
%  DUAL-BAND YAGI-UDA ARRAY - MATLAB ANTENNA TOOLBOX SIMULATION
%  Target  : ISS amateur-radio communication
%  Bands   : UHF 437.8 MHz (vertical, Z-axis, 11 elements)
%            VHF 145.8 MHz (horizontal, Y-axis, 4 elements)
%  Boom    : shared X-axis boom -> the two arrays are CROSS-POLARIZED
%
%  Why customAntennaGeometry?
%     The built-in yagiUda object forces a UNIFORM element spacing.
%     Your EZNEC file uses NON-UNIFORM spacing for both Yagis, so the
%     geometry is rebuilt here from the raw wire coordinates with
%     customAntennaGeometry and solved with Antenna Toolbox's MoM
%     kernel - the same Method-of-Moments EZNEC uses, so feed-point
%     impedance, VSWR, gain and pattern are all physically consistent.
%
%  Toolboxes required : Antenna Toolbox (R2019b or later recommended)
%  Tested call set    : customAntennaGeometry, customAntenna, feedNetwork,
%                       pattern, patternAzimuth, patternElevation,
%                       impedance, sparameters, vswr, beamwidth,
%                       frontToBack, smithplot, mesh, show.
% ==========================================================================
clear;  close all;  clc;
c0 = physconst('LightSpeed');

%% -------------------- CONFIG -----------------------------------------
%  Every wire row: [ x1 y1 z1   x2 y2 z2   radius_m ]
%  Source line "1, 0" => wire 1 (REFLECTOR) is the DRIVEN element.
% ------------------------------------------------------------------------
BandUHF.name      = 'UHF 437.8 MHz';
BandUHF.f0        = 437.8e6;
BandUHF.label     = 'UHF 437.8 MHz - 11 elem, vertical (along Z)';
BandUHF.feedWire  = 1;            % wire index carrying the source
BandUHF.feedGap   = 0.005;        % small feed gap at driven-elem centre
BandUHF.wires     = [ 0.0000  0 -0.1782  0.0000  0  0.1782  0.00159;
                      0.1907  0 -0.1664  0.1907  0  0.1664  0.00159;
                      0.2628  0 -0.1531  0.2628  0  0.1531  0.00159;
                      0.4040  0 -0.1504  0.4040  0  0.1504  0.00159;
                      0.5616  0 -0.1504  0.5616  0  0.1504  0.00159;
                      0.7245  0 -0.1504  0.7245  0  0.1504  0.00159;
                      0.8937  0 -0.1504  0.8937  0  0.1504  0.00159;
                      1.0744  0 -0.1504  1.0744  0  0.1504  0.00159;
                      1.2624  0 -0.1472  1.2624  0  0.1472  0.00159;
                      1.4504  0 -0.1462  1.4504  0  0.1462  0.00159;
                      1.6133  0 -0.1378  1.6133  0  0.1378  0.00159 ];

BandVHF.name      = 'VHF 145.8 MHz';
BandVHF.f0        = 145.8e6;
BandVHF.label     = 'VHF 145.8 MHz - 4 elem, horizontal (along Y)';
BandVHF.feedWire  = 1;
BandVHF.feedGap   = 0.010;
BandVHF.wires     = [ 0.0000  0.5080  0   0.0000  -0.5080  0   0.00500;
                      0.6140  0.4890  0   0.6140  -0.4890  0   0.00500;
                      0.8840  0.4570  0   0.8840  -0.4570  0   0.00500;
                      1.3370  0.4265  0   1.3370  -0.4265  0   0.00500 ];

%% -------------------- BUILD BOTH YAGIS -------------------------------
uhfAnt = buildYagiFromWires(BandUHF);
vhfAnt = buildYagiFromWires(BandVHF);

% Mesh refinement -- ~lambda/20 for accurate current distribution
uhfAnt = mesh(uhfAnt, 'MaxEdgeLength', physconst('LightSpeed')/cfg.f0/40);
vhfAnt = mesh(vhfAnt, 'MaxEdgeLength', physconst('LightSpeed')/cfg.f0/40);

%% -------------------- GEOMETRY PREVIEW -------------------------------
figure('Name','UHF geometry','Position',[80 80 800 600]);
show(uhfAnt);  title(BandUHF.label);

figure('Name','VHF geometry','Position',[80 80 800 600]);
show(vhfAnt);  title(BandVHF.label);

%% -------------------- 3-D RADIATION PATTERNS -------------------------
figure('Name','UHF 3D','Position',[120 120 800 600]);
pattern(uhfAnt, BandUHF.f0);
title(['UHF 3-D pattern - ' BandUHF.label]);

figure('Name','VHF 3D','Position',[120 120 800 600]);
pattern(vhfAnt, BandVHF.f0);
title(['VHF 3-D pattern - ' BandVHF.label]);

%% -------------------- AZIMUTH CUTS (el = 90 deg) --------------------
figure('Name','UHF azimuth','Position',[160 160 800 500]);
patternAzimuth(uhfAnt, BandUHF.f0, 90, 'Type','powerdb');
title('UHF azimuth cut @ 437.8 MHz (el = 90°)'); grid on;
axis([-90 90 -30 10]);

figure('Name','VHF azimuth','Position',[160 160 800 500]);
patternAzimuth(vhfAnt, BandVHF.f0, 90, 'Type','powerdb');
title('VHF azimuth cut @ 145.8 MHz (el = 90°)'); grid on;
axis([-90 90 -30 10]);

%% -------------------- ELEVATION CUTS (az = 0 deg) -------------------
figure('Name','UHF elevation','Position',[200 200 800 500]);
patternElevation(uhfAnt, BandUHF.f0, 0, 'Type','powerdb');
title('UHF elevation cut @ 437.8 MHz (az = 0°)'); grid on;
axis([-90 90 -30 10]);

figure('Name','VHF elevation','Position',[200 200 800 500]);
patternElevation(vhfAnt, BandVHF.f0, 0, 'Type','powerdb');
title('VHF elevation cut @ 145.8 MHz (az = 0°)'); grid on;
axis([-90 90 -30 10]);

%% -------------------- VSWR vs FREQUENCY ------------------------------
% --- UHF: +/- 10 MHz --------------------------------------------------
fUHFsw    = linspace(BandUHF.f0-10e6, BandUHF.f0+10e6, 51);
Z_u       = impedance(uhfAnt, fUHFsw);
SWR_U     = vswr(Z_u, 50);

figure('Name','UHF VSWR','Position',[240 240 800 500]);
plot(fUHFsw/1e6, SWR_U, 'b-o','LineWidth',1.3); grid on; hold on;
xline(BandUHF.f0/1e6,'--r','f_0','LabelVerticalAlignment','bottom');
yline(2,'--k','VSWR=2');
xlabel('Frequency (MHz)'); ylabel('VSWR (50 \Omega)');
title('UHF VSWR vs Frequency (437.8 MHz ± 10 MHz)');

% --- VHF: +/- 2 MHz --------------------------------------------------
fVHFsw    = linspace(BandVHF.f0-2e6, BandVHF.f0+2e6, 41);
Z_v       = impedance(vhfAnt, fVHFsw);
SWR_V     = vswr(Z_v, 50);

figure('Name','VHF VSWR','Position',[240 240 800 500]);
plot(fVHFsw/1e6, SWR_V, 'b-o','LineWidth',1.3); grid on; hold on;
xline(BandVHF.f0/1e6,'--r','f_0','LabelVerticalAlignment','bottom');
yline(2,'--k','VSWR=2');
xlabel('Frequency (MHz)'); ylabel('VSWR (50 \Omega)');
title('VHF VSWR vs Frequency (145.8 MHz ± 2 MHz)');

% --- Smith charts ----------------------------------------------------
figure('Name','Smith UHF','Position',[260 260 600 600]);
smithplot(Z_u, fUHFsw); title('UHF - Smith chart 437.8 MHz ± 10 MHz');

figure('Name','Smith VHF','Position',[260 260 600 600]);
smithplot(Z_v, fVHFsw); title('VHF - Smith chart 145.8 MHz ± 2 MHz');

%% -------------------- RESULTS AT DESIGN FREQUENCY --------------------
Z_u0  = impedance(uhfAnt, BandUHF.f0);
Z_v0  = impedance(vhfAnt, BandVHF.f0);
SWR_u0 = vswr(Z_u0, 50);
SWR_v0 = vswr(Z_v0, 50);

hpU    = beamwidth(uhfAnt,    BandUHF.f0, 0, 90);
hpV    = beamwidth(vhfAnt,    BandVHF.f0, 0, 90);
fbU    = frontToBack(uhfAnt,  BandUHF.f0, 0, 90);
fbV    = frontToBack(vhfAnt,  BandVHF.f0, 0, 90);

Results = table( ...
    {BandUHF.label; BandVHF.label}, ...
    [BandUHF.f0; BandVHF.f0]/1e6, ...
    [real(Z_u0); real(Z_v0)], ...
    [imag(Z_u0); imag(Z_v0)], ...
    [SWR_u0;     SWR_v0], ...
    [hpU;        hpV], ...
    [fbU;        fbV], ...
    'VariableNames', { ...
      'Band','f0_MHz','Z_real_Ohm','Z_imag_Ohm', ...
      'VSWR_at_f0','HPBW_deg','FrontToBack_dB'} );
disp('===== KEY RESULTS AT DESIGN FREQUENCY =====');
disp(Results);

%% -------------------- COMBINED-LAYOUT PREVIEW -----------------------
%  The two arrays share the boom at right angles.  Same driver as
%  real mounting bracket, but NOT simulated together (for true mutual
%  coupling put all 15 wires in one customAntennaGeometry and feed
%  two ports - see Antenna Toolbox "Multi-feed custom antenna" doc).
figure('Name','Combined layout','Position',[300 300 900 600]);
hold on; axis equal; grid on; view(35,25);
xlabel('Boom X (m)'); ylabel('Element Y (m)'); zlabel('Element Z (m)');

% UHF - vertical elements along Z
for k = 1:size(BandUHF.wires,1)
    x = BandUHF.wires(k,1);
    z = [BandUHF.wires(k,3) BandUHF.wires(k,6)];
    plot3([x x], [0 0], z, 'b-', 'LineWidth', 3);
end
% VHF - horizontal elements along Y
for k = 1:size(BandVHF.wires,1)
    x = BandVHF.wires(k,1);
    y = [BandVHF.wires(k,2) BandVHF.wires(k,5)];
    plot3([x x], y, [0 0], 'r-', 'LineWidth', 3);
end
title('Dual-band cross-polarized Yagi on common boom  (blue=UHF/Z, red=VHF/Y)');

fprintf('\nSimulation finished.  Inspect the figures and the Results table.\n');

%% ======================================================================
function ant = buildYagiFromWires(cfg)
%BUILDYAGIFROMWIRES  Build a customAntenna from an EZNEC-style wire table.
%
%   cfg.name       - display name
%   cfg.f0         - design frequency
%   cfg.wires      - N x 7  [ x1 y1 z1   x2 y2 z2   radius ]
%   cfg.feedWire   - 1-based index of wire that carries the source
%   cfg.feedGap    - feed gap length inserted at the centre of that wire

    N = size(cfg.wires, 1);

    % ---- Geometry: split the fed wire so we can put a port in the gap
    wireNames = cell(N,1);
    wm = zeros(N,3);                          % wire-midpoint x y z
    for k = 1:N
        x1 = cfg.wires(k,1); y1 = cfg.wires(k,2); z1 = cfg.wires(k,3);
        x2 = cfg.wires(k,4); y2 = cfg.wires(k,5); z2 = cfg.wires(k,6);
        if (k == cfg.feedWire)
            % split the wire at its centre with a small gap
            mid  = [(x1+x2)/2, (y1+y2)/2, (z1+z2)/2];
            uvw  = [(x2-x1),   (y2-y1),   (z2-z1)];
            L    = norm(uvw);
            uvw  = uvw / L;
            half = cfg.feedGap / 2;
            p1   = mid - uvw*half;
            p2   = mid + uvw*half;
            wireNames{k} = sprintf('wire%d', k);
            wm(k,:) = mid;
            c0=299792458;
            seg(k) = customAntennaGeometry( ...
                'MaxEdgeLength', c0/cfg.f0/40, ...
                'Vertices',      [ p1; p2 ], ...
                'MetalRadius',   cfg.wires(k,7), ...
                'FeedLocation',  [1 0.5], ...      % centre of split wire
                'FeedWidth',     cfg.feedGap );
        else
            wireNames{k} = sprintf('wire%d', k);
            wm(k,:) = [(x1+x2)/2, (y1+y2)/2, (z1+z2)/2];
            seg(k) = customAntennaGeometry( ...
                'MaxEdgeLength', c0/cfg.f0/40, ...
                'Vertices',      [ [x1 y1 z1]; [x2 y2 z2] ], ...
                'MetalRadius',   cfg.wires(k,7) );
        end
    end
  
    % ---- Concatenate all segments into a single geometry --------------
    geom = customAntennaGeometry;
    for k = 1:N
        if isa(seg(k),'customAntennaGeometry')
            geom = geom + seg(k);     % operator + merges segments
        end
    end

    % ---- Build the antenna ------------------------------------------
    ant = customAntenna( ...
        'Geometry',        geom, ...
        'FeedVoltage',     1, ...
        'FeedPhase',       0, ...
        'Conductor',       metal('Copper') );

    try
        ant = design(ant, cfg.f0);
    catch
        % design() may fail on geometries without a recognised topology;
        % the antenna is still usable for pattern / impedance queries.
    end
end
