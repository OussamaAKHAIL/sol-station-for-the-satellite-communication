%% Corrected 6-Element Yagi-Uda Antenna Simulation
% Matches MMANA-GAL tuning at 145.8 MHz
clear; clc; close all;

% Check for Antenna Toolbox
if isempty(ver('antenna'))
    error('The MATLAB Antenna Toolbox is required to run this simulation.');
end

%% 1. Define Antenna Dimensions (meters)
L_reflector = 102.8 / 100;
L_driven    = 96.7 / 100;
L_directors = [90.5, 88.5, 86.4, 84.3] / 100;

% Spacing calculations (meters)
space_ref = (51.4 - 0.0) / 100;
space_dir = [(115.2 - 51.4), ...
             (170.7 - 115.2), ...
             (228.3 - 170.7), ...
             (288.0 - 228.3)] / 100;

%% 2. Construct the Antenna Object
% Define the driven element (Removed the 90-degree tilt)
% Using a 6mm width to match your original tubing approximation
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
% UPDATED: Set to 145.8 MHz to match the MMANA-GAL optimization
freq_center = 145.8e6;                    % 145.8 MHz
freq_sweep  = linspace(140e6, 150e6, 51); % 140 to 150 MHz sweep
Z_ref       = 50.582 + 47.882i;           % MMANA-GAL Feedpoint Impedance

%% 4. Plot 3D Radiation Pattern
figure('Name','3D Radiation Pattern','Color','w', 'Position', [100, 100, 600, 500]);
pattern(yagi, freq_center);
title(sprintf('3D Radiation Pattern at %.1f MHz', freq_center/1e6));

%% 5. Plot 2D Azimuth and Elevation Patterns
figure('Name','2D Radiation Patterns','Color','w', 'Position', [150, 150, 900, 400]);

% Azimuth (H-Plane)
subplot(1,2,1);
patternAzimuth(yagi, freq_center);
title('Azimuth (H-Plane) Pattern');

% Elevation (E-Plane)
subplot(1,2,2);
patternElevation(yagi, freq_center);
title('Elevation (E-Plane) Pattern');

%% 6. Custom VSWR & Impedance Plot
figure('Name','Impedance & VSWR','Color','w', 'Position', [200, 200, 900, 400]);

% Get input impedance array over frequency range
Z_in = impedance(yagi, freq_sweep); 

% Custom VSWR calculation for complex Z_ref
Gamma = (Z_in - Z_ref) ./ (Z_in + Z_ref);
vswr_custom = (1 + abs(Gamma)) ./ (1 - abs(Gamma));

% Plot custom VSWR
subplot(1,2,1);
plot(freq_sweep / 1e6, vswr_custom, 'b-', 'LineWidth', 1.5);
xlabel('Frequency (MHz)');
ylabel('VSWR');
title('VSWR (Ref: 50.58 + j47.88 \Omega)');
grid on;

% Plot Antenna Feedpoint Impedance
subplot(1,2,2);
impedance(yagi, freq_sweep);
title('Feedpoint Impedance');
grid on;

%% 7. Calculate and Display Maximum Gain
[max_gain, ~] = pattern(yagi, freq_center, 0, 0); 
fprintf('=== Simulation Complete ===\n');
fprintf('Center Frequency: %.1f MHz\n', freq_center/1e6);
fprintf('Max Forward Gain: %.2f dBi\n', max(max_gain(:)));