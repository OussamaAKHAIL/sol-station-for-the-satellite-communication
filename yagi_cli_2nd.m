%% Yagi-Uda for ISS reception — 145.8 MHz
c = 3e8;
f = 145.8e6;
lambda = c/f;

% Element lengths (meters)
L_reflector = 1.028;
L_driven    = 0.967;
L_directors = [0.905, 0.885, 0.864, 0.843];

% Positions along boom (meters)
P_driven    = 0.514;
P_directors = [1.152, 1.707, 2.283, 2.880];

% Build yagiUda object
ant = yagiUda;
ant.NumDirectors     = 4;
ant.ReflectorLength  = L_reflector;
ant.ReflectorSpacing = P_driven;
ant.DirectorLength   = L_directors;
ant.DirectorSpacing  = diff([P_driven, P_directors]);

% Fix the driven element length explicitly
ant.Exciter.Length = L_driven;

% Confirm all dimensions in command window
disp('=== Antenna dimensions ===')
disp(['Reflector length : ', num2str(ant.ReflectorLength), ' m'])
disp(['Driven length    : ', num2str(ant.Exciter.Length), ' m'])
disp(['Director lengths : ', num2str(ant.DirectorLength), ' m'])
disp(['Reflector spacing: ', num2str(ant.ReflectorSpacing), ' m'])
disp(['Director spacings: ', num2str(ant.DirectorSpacing), ' m'])

% Figure 1 — 3D view
figure(1); clf;
show(ant);
title('Yagi-Uda — 145.8 MHz (pre-optimization)');

% Figure 2 — S11
figure(2); clf;
freq_range = linspace(130e6, 165e6, 200);
s = sparameters(ant, freq_range);
rfplot(s);
title('S11 — Target: below -10 dB at 145.8 MHz');
xline(145.8, '--r', '145.8 MHz');
grid on;
%% Phase 4 — Smart optimization using frequency scaling + fminsearch
clc;
c = 3e8;
f0 = 145.8e6;
lambda = c/f0;
freq_range = linspace(130e6, 165e6, 300);

% Scale your original dimensions by the ratio of actual vs assumed lambda
% Your dims were computed for lambda = 205.6 cm
% Resonance was at 138 MHz → scale factor to push to 145.8 MHz
scale = 138/145.8;  % elements were too long by this ratio

L_ref = 1.028 * scale;
L_drv = 0.967 * scale;
L_dir = [0.905, 0.885, 0.864, 0.843] * scale;
P_drv = 0.514;
P_dir = [1.152, 1.707, 2.283, 2.880];

disp('=== Frequency-scaled starting point ===')
fprintf('Reflector : %.1f cm\n', L_ref*100)
fprintf('Driven    : %.1f cm\n', L_drv*100)
fprintf('Directors : %.1f  %.1f  %.1f  %.1f cm\n', L_dir*100)

% Pack into single vector [lengths(6), positions(5)]
x0 = [L_ref, L_drv, L_dir, P_drv, P_dir];

% Cost function — minimize S11 at f0
function val = cost3(x, f0)
    try
        a = yagiUda;
        a.NumDirectors    = 4;
        a.ReflectorLength = x(1);
        a.ReflectorSpacing = x(7);
        a.Exciter.Length  = x(2);
        a.DirectorLength  = x(3:6);
        a.DirectorSpacing = diff([x(7), x(8:11)]);
        % Reject physically invalid geometries
        if any(diff(x(3:6)) > 0) || x(2) >= x(1) || x(3) >= x(2)
            val = 0; return;
        end
        if any(diff(x(7:11)) <= 0)
            val = 0; return;
        end
        s = sparameters(a, f0);
        val = 20*log10(abs(s.Parameters(1,1,1)));
    catch
        val = 0;
    end
end

% Run fminsearch — no constraints needed
disp('Running optimization... (3-5 min)')
opts = optimset('Display','iter','MaxIter',500,'TolX',1e-6,'TolFun',1e-6);
xopt = fminsearch(@(x) cost3(x, f0), x0, opts);

% Build result
ant3 = yagiUda;
ant3.NumDirectors    = 4;
ant3.ReflectorLength = xopt(1);
ant3.ReflectorSpacing = xopt(7);
ant3.Exciter.Length  = xopt(2);
ant3.DirectorLength  = xopt(3:6);
ant3.DirectorSpacing = diff([xopt(7), xopt(8:11)]);

% Print final dimensions
disp(' ')
disp('=== FINAL OPTIMIZED DIMENSIONS ===')
fprintf('Reflector : %.1f cm\n', xopt(1)*100)
fprintf('Driven    : %.1f cm\n', xopt(2)*100)
fprintf('Director 1: %.1f cm\n', xopt(3)*100)
fprintf('Director 2: %.1f cm\n', xopt(4)*100)
fprintf('Director 3: %.1f cm\n', xopt(5)*100)
fprintf('Director 4: %.1f cm\n', xopt(6)*100)
fprintf('Pos driven   : %.1f cm\n', xopt(7)*100)
fprintf('Pos direct. 1: %.1f cm\n', xopt(8)*100)
fprintf('Pos direct. 2: %.1f cm\n', xopt(9)*100)
fprintf('Pos direct. 3: %.1f cm\n', xopt(10)*100)
fprintf('Pos direct. 4: %.1f cm\n', xopt(11)*100)

% Plot S11
figure(5); clf;
s3 = sparameters(ant3, freq_range);
rfplot(s3);
title('S11 — Smart optimization result');
xline(145.8,'--r','145.8 MHz');
yline(-10,'--g','-10 dB threshold');
grid on;