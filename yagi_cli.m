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
%% Phase 4 — Optimization
disp('Starting optimization... please wait (5-10 min)');

% Starting point: your analytical dimensions
x0 = [L_reflector, L_driven, L_directors, ...
      P_driven, P_directors];

% Bounds: allow ±15% variation around each value
lb = x0 * 0.85;
ub = x0 * 1.15;

% Objective: minimize S11 at exactly 145.8 MHz
function val = costFcn(x, f0)
    try
        a = yagiUda;
        a.NumDirectors    = 4;
        a.ReflectorLength = x(1);
        a.ReflectorSpacing = x(7) - 0;
        a.Exciter.Length  = x(2);
        a.DirectorLength  = x(3:6);
        a.DirectorSpacing = diff([x(7), x(8:11)]);
        s = sparameters(a, f0);
        val = real(s.Parameters(1,1,1));
        val = 20*log10(abs(val));
    catch
        val = 0; % penalize invalid geometry
    end
end

opts = optimoptions('fmincon', ...
    'Display','iter', ...
    'MaxIterations', 100, ...
    'StepTolerance', 1e-6);

xopt = fmincon(@(x) costFcn(x, 145.8e6), ...
               x0, [], [], [], [], lb, ub, [], opts);

% Apply optimized dimensions
ant_opt = yagiUda;
ant_opt.NumDirectors    = 4;
ant_opt.ReflectorLength = xopt(1);
ant_opt.ReflectorSpacing = xopt(7);
ant_opt.Exciter.Length  = xopt(2);
ant_opt.DirectorLength  = xopt(3:6);
ant_opt.DirectorSpacing = diff([xopt(7), xopt(8:11)]);

% Show optimized results
disp('=== Optimized dimensions ===')
disp(['Reflector : ', num2str(xopt(1)*100,'%.1f'), ' cm'])
disp(['Driven    : ', num2str(xopt(2)*100,'%.1f'), ' cm'])
disp(['Director 1: ', num2str(xopt(3)*100,'%.1f'), ' cm'])
disp(['Director 2: ', num2str(xopt(4)*100,'%.1f'), ' cm'])
disp(['Director 3: ', num2str(xopt(5)*100,'%.1f'), ' cm'])
disp(['Director 4: ', num2str(xopt(6)*100,'%.1f'), ' cm'])

% Plot optimized S11
figure(3); clf;
s_opt = sparameters(ant_opt, freq_range);
rfplot(s_opt);
title('S11 after optimization — Target: below -10 dB at 145.8 MHz');
xline(145.8,'--r','145.8 MHz');
grid on;