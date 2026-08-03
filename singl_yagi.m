%% Single 6-Element Yagi-Uda Antenna Simulation
% Requires the MATLAB Antenna Toolbox
clear; clc; close all;

% Check for Antenna Toolbox
if isempty(ver('antenna'))
    error('The MATLAB Antenna Toolbox is required to run this simulation.');
end

%% 1. Define Antenna Dimensions (converted to meters)
% Original full lengths (cm) -> meters
L_reflector = 102.8 / 100;
L_driven    = 96.7 / 100;
L_directors = [90.5, 88.5, 86.4, 84.3] / 100;

% Original Boom Positions (cm): 0.0, 51.4, 115.2, 170.7, 228.3, 288.0
% The Antenna Toolbox requires relative spacings, not absolute boom positions.

% Reflector to Driven Element spacing
space_ref = (51.4 - 0.0) / 100;

% Driven to D1, D1 to D2, D2 to D3, D3 to D4
space_dir = [(115.2 - 51.4), ...
             (170.7 - 115.2), ...
             (228.3 - 170.7), ...
             (288.0 - 228.3)] / 100;

%% 2. Construct the Antenna Object
% Define the driven element (a simple dipole)
% We use a width of 6mm (0.006m) to approximate the tubing thickness
exciter = dipole('Length', L_driven, ...
                 'Width', 0.006, ...
                 'Tilt', 90, ...
                 'TiltAxis', 'Y');

% Assemble the Yagi array
yagi = yagiUda('Exciter', exciter, ...
               'NumDirectors', 4, ...
               'ReflectorLength', L_reflector, ...
               'DirectorLength', L_directors, ...
               'ReflectorSpacing', space_ref, ...
               'DirectorSpacing', space_dir);

%% 3. Define Simulation Parameters
% Based on the driven element length, this is a VHF 2-meter band antenna
freq_center = 144e6; % 144 MHz
freq_sweep = linspace(140e6, 148e6, 51); % 140 to 148 MHz sweep
Z0 = 50; % 50 Ohm reference impedance

%% 4. Plot Geometry
figure('Name','Antenna Geometry','Color','w', 'Position', [100, 100, 600, 400]);
show(yagi);
title('6-Element Yagi-Uda Geometry');

%% 5. Plot 3D Radiation Pattern
figure('Name','3D Radiation Pattern','Color','w', 'Position', [150, 150, 600, 500]);
pattern(yagi, freq_center);
title(sprintf('3D Radiation Pattern at %.1f MHz', freq_center/1e6));

%% 6. Plot 2D Azimuth and Elevation Patterns
figure('Name','2D Radiation Patterns','Color','w', 'Position', [200, 200, 900, 400]);

% Azimuth (H-Plane)
subplot(1,2,1);
patternAzimuth(yagi, freq_center);
title('Azimuth (H-Plane) Pattern');

% Elevation (E-Plane)
subplot(1,2,2);
patternElevation(yagi, freq_center);
title('Elevation (E-Plane) Pattern');

%% 7. Plot Impedance and VSWR
figure('Name','Impedance & VSWR','Color','w', 'Position', [250, 250, 900, 400]);

% VSWR Plot
subplot(1,2,1);
vswr(yagi, freq_sweep, Z0);
title('VSWR (Reference: 50 \Omega)');
grid on;

% Impedance Plot (Real and Imaginary)
subplot(1,2,2);
impedance(yagi, freq_sweep);
title('Feedpoint Impedance');
grid on;

%% 8. Calculate and Display Maximum Gain
% Calculate maximum directivity/gain at the center frequency
[max_gain, ~] = pattern(yagi, freq_center, 0, 0); 
fprintf('=== Simulation Complete ===\n');
fprintf('Center Frequency: %.1f MHz\n', freq_center/1e6);
fprintf('Max Forward Gain: %.2f dBi\n', max(max_gain(:)));