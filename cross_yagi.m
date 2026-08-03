%% Cross Yagi Antenna Visualization
% Based on Table 2 dimensions (before optimisation)
% Two Yagi arrays sharing the same boom, one rotated 90° around the boom axis
%
% Element dimensions (in cm):
%   Réflecteur : 102.8 cm at position   0.0 cm
%   Driven     :  96.7 cm at position  51.4 cm
%   Directeur 1:  90.5 cm at position 115.2 cm
%   Directeur 2:  88.5 cm at position 170.7 cm
%   Directeur 3:  86.4 cm at position 228.3 cm
%   Directeur 4:  84.3 cm at position 288.0 cm

clear; clc; close all;

%% ---- Antenna parameters ------------------------------------------------
% Element names
names = {'Réflecteur','Driven','Dir. 1','Dir. 2','Dir. 3','Dir. 4'};

% Half-lengths of each element (cm)  →  full length / 2
full_lengths = [102.8, 96.7, 90.5, 88.5, 86.4, 84.3];
half_len     = full_lengths / 2;          % half-element length

% Position along boom (cm)
boom_pos = [0.0, 51.4, 115.2, 170.7, 228.3, 288.0];

n_elem   = numel(boom_pos);
boom_len = max(boom_pos) + 10;            % a bit longer than last element

%% ---- Colour scheme -----------------------------------------------------
col_boom    = [0.20 0.45 0.70];   % steel blue  – boom
col_H       = [0.15 0.15 0.15];   % dark grey   – H-plane Yagi (horizontal)
col_V       = [0.80 0.20 0.10];   % red         – V-plane Yagi (vertical, +90°)
col_driven  = [0.00 0.60 0.00];   % green       – driven elements

lw_boom  = 4;
lw_elem  = 2;
lw_driv  = 3;

%% ---- Figure & axes -----------------------------------------------------
fig = figure('Name','Cross Yagi Antenna','NumberTitle','off', ...
             'Color','white','Position',[100 80 1100 700]);

ax = axes('Parent',fig);
hold(ax,'on');  grid(ax,'on');  box(ax,'on');
axis(ax,'equal');
set(ax,'Color','white','GridColor',[0.8 0.8 0.8], ...
       'FontSize',11,'FontName','Arial');
xlabel(ax,'Boom axis  X  (cm)','FontSize',12);
ylabel(ax,'Horizontal  Y  (cm)','FontSize',12);
zlabel(ax,'Vertical  Z  (cm)','FontSize',12);
title(ax,'Cross Yagi – 6 elements (H-plane + V-plane)', ...
      'FontSize',14,'FontWeight','bold');

%% ---- Helper: draw one element ------------------------------------------
% draw_element(ax, x_boom, half, angle_deg, colour, lw)
%   x_boom    : position along boom (X axis)
%   half      : half-length
%   angle_deg : 0° → horizontal (Y), 90° → vertical (Z)
draw_element = @(xb, hl, ang, col, lw) ...
    plot3(ax, [xb xb], ...
              hl*[-cosd(ang) cosd(ang)], ...
              hl*[-sind(ang) sind(ang)], ...
          '-','Color',col,'LineWidth',lw);

%% ---- Draw boom ---------------------------------------------------------
plot3(ax, [0 boom_len], [0 0], [0 0], '-','Color',col_boom,'LineWidth',lw_boom);

%% ---- Draw elements for BOTH Yagis -------------------------------------
for k = 1:n_elem
    xb = boom_pos(k);
    hl = half_len(k);
    
    % Identify driven element
    is_driven = (k == 2);
    
    % ── Yagi H (horizontal, 0°) ──────────────────────────────────────────
    if is_driven
        col_h = col_driven;   lw_h = lw_driv;
        col_v = col_driven;   lw_v = lw_driv;
    else
        col_h = col_H;        lw_h = lw_elem;
        col_v = col_V;        lw_v = lw_elem;
    end
    draw_element(xb, hl,  0, col_h, lw_h);   % horizontal element
    draw_element(xb, hl, 90, col_v, lw_v);   % vertical element (90° rotated)
    
    % Label (only for the horizontal Yagi to avoid clutter)
    text(ax, xb, hl + 4, 0, names{k}, ...
         'HorizontalAlignment','center','FontSize',9, ...
         'Color',[0.3 0.3 0.3],'FontName','Arial');
end

%% ---- Driven-element gap (symbolic) ------------------------------------
% Draw a small gap at the feed point of the driven element
gap = 2;   % cm
xd  = boom_pos(2);
hl  = half_len(2);

% Horizontal driven – show gap
plot3(ax, [xd xd], [-hl -gap], [0 0], '-','Color',col_driven,'LineWidth',lw_driv);
plot3(ax, [xd xd], [ gap  hl], [0 0], '-','Color',col_driven,'LineWidth',lw_driv);
% Vertical driven – show gap
plot3(ax, [xd xd], [0 0], [-hl -gap], '-','Color',col_driven,'LineWidth',lw_driv);
plot3(ax, [xd xd], [0 0], [ gap  hl], '-','Color',col_driven,'LineWidth',lw_driv);

% Feed point markers
plot3(ax, xd, 0, 0, 'ko','MarkerSize',7,'MarkerFaceColor','yellow');

%% ---- Legend ------------------------------------------------------------
h1 = plot3(ax, NaN,NaN,NaN,'-','Color',col_H,'LineWidth',lw_elem);
h2 = plot3(ax, NaN,NaN,NaN,'-','Color',col_V,'LineWidth',lw_elem);
h3 = plot3(ax, NaN,NaN,NaN,'-','Color',col_driven,'LineWidth',lw_driv);
h4 = plot3(ax, NaN,NaN,NaN,'-','Color',col_boom,'LineWidth',lw_boom);
legend(ax,[h1 h2 h3 h4], ...
    {'Yagi H-plane (horizontal elements)', ...
     'Yagi V-plane (rotated 90°)', ...
     'Driven elements (both)', ...
     'Boom'}, ...
    'Location','northeast','FontSize',10);

%% ---- Dimension annotations (first Yagi only) --------------------------
% Annotate full lengths along the top
for k = 1:n_elem
    xb  = boom_pos(k);
    hl  = half_len(k);
    yTop = hl + 12;
    % Arrow from element tip to label
    text(ax, xb, -hl - 8, 0, sprintf('%.1f cm', full_lengths(k)), ...
         'HorizontalAlignment','center','FontSize',8, ...
         'Color',[0.5 0.5 0.5],'FontName','Arial','Rotation',0);
end

%% ---- Boom spacing dimension line --------------------------------------
% Show spacing between reflector and driven
x1 = boom_pos(1);  x2 = boom_pos(2);
y_dim = -max(half_len) - 20;
plot3(ax,[x1 x2],[y_dim y_dim],[0 0],'k-','LineWidth',1);
plot3(ax,[x1 x1],[y_dim-3 y_dim+3],[0 0],'k-','LineWidth',1);
plot3(ax,[x2 x2],[y_dim-3 y_dim+3],[0 0],'k-','LineWidth',1);
text(ax,(x1+x2)/2, y_dim-7, 0, sprintf('%.1f cm',x2-x1), ...
    'HorizontalAlignment','center','FontSize',9,'FontName','Arial');

%% ---- Nice 3D view ------------------------------------------------------
view(ax, 35, 25);
xlim(ax, [-15,  boom_len + 15]);
ylim(ax, [-max(half_len)-35,  max(half_len)+35]);
zlim(ax, [-max(half_len)-10,  max(half_len)+10]);

%% ---- Second figure: top view (XY plane) --------------------------------
fig2 = figure('Name','Cross Yagi – Top View (XY)','NumberTitle','off', ...
              'Color','white','Position',[200 100 900 400]);
ax2 = axes('Parent',fig2);
hold(ax2,'on');  grid(ax2,'on');  box(ax2,'on');
set(ax2,'Color','white','GridColor',[0.8 0.8 0.8],'FontSize',11);
title(ax2,'Top View  (XY plane)  –  Horizontal Yagi elements','FontSize',13,'FontWeight','bold');
xlabel(ax2,'Boom axis  X  (cm)'); ylabel(ax2,'Y  (cm)');

% Boom
plot(ax2,[0 boom_len],[0 0],'-','Color',col_boom,'LineWidth',lw_boom);
% Elements
for k = 1:n_elem
    xb = boom_pos(k);  hl = half_len(k);
    col = col_driven;   lw = lw_driv;
    if k ~= 2
        col = col_H;    lw = lw_elem;
    end
    plot(ax2,[xb xb],[-hl hl],'-','Color',col,'LineWidth',lw);
    text(ax2, xb, hl+4, names{k},'HorizontalAlignment','center','FontSize',9);
end
axis(ax2,'equal');
xlim(ax2,[-15 boom_len+15]);

%% ---- Third figure: front view (YZ plane) – cross section ---------------
fig3 = figure('Name','Cross Yagi – Front View (YZ)','NumberTitle','off', ...
              'Color','white','Position',[300 100 500 500]);
ax3 = axes('Parent',fig3);
hold(ax3,'on');  grid(ax3,'on');  box(ax3,'on');
set(ax3,'Color','white','FontSize',11);
title(ax3,'Front View  (YZ plane)  –  Driven elements cross','FontSize',13,'FontWeight','bold');
xlabel(ax3,'Y  (cm)');  ylabel(ax3,'Z  (cm)');

xd = boom_pos(2);  hl = half_len(2);
% Horizontal driven (Y axis)
plot(ax3,[-hl hl],[0 0],'-','Color',col_driven,'LineWidth',lw_driv+1);
% Vertical driven (Z axis)
plot(ax3,[0 0],[-hl hl],'-','Color',col_driven,'LineWidth',lw_driv+1);
% Feed point
plot(ax3,0,0,'ko','MarkerSize',10,'MarkerFaceColor','yellow');
axis(ax3,'equal');  axis(ax3,'square');
text(ax3, hl+2, 0, 'H-plane','FontSize',10,'Color',col_H);
text(ax3, 2, hl+2,'V-plane','FontSize',10,'Color',col_V);
legend(ax3,{'H driven','V driven','Feed point'},'Location','southeast');

disp('=== Cross Yagi script completed ===');
disp('Three figures generated:');
disp('  Fig 1 – 3D perspective view');
disp('  Fig 2 – Top view (XY plane)');
disp('  Fig 3 – Front view, driven elements cross (YZ plane)');