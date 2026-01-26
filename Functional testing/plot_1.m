%% Global font + LaTeX
set(groot,'defaultAxesFontName','Times New Roman');
set(groot,'defaultTextFontName','Times New Roman');
set(groot,'defaultTextInterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');
set(groot,'defaultAxesTickLabelInterpreter','latex');

%% Locate log files (same folder as this m-file)
thisFile = mfilename('fullpath');
[thisDir, ~, ~] = fileparts(thisFile);

file_juli = fullfile(thisDir, 'grad_desc_log_notmy.txt'); % JuliVQC
file_my   = fullfile(thisDir, 'grad_desc_log.txt');       % MyJuliVQC

%% Read and parse logs
[x_JuliVQC, y_JuliVQC] = read_loss_log(file_juli);
[x_MyJuliVQC, y_MyJuliVQC] = read_loss_log(file_my);
%% Keep only the first N points
Nkeep = 1000;

nJ = min(Nkeep, numel(x_JuliVQC));
x_JuliVQC = x_JuliVQC(1:nJ);
y_JuliVQC = y_JuliVQC(1:nJ);

nM = min(Nkeep, numel(x_MyJuliVQC));
x_MyJuliVQC = x_MyJuliVQC(1:nM);
y_MyJuliVQC = y_MyJuliVQC(1:nM);



%% Common part for difference
Ncommon = min(numel(x_JuliVQC), numel(x_MyJuliVQC));
x_diff  = x_JuliVQC(1:Ncommon);
y_diff  = y_JuliVQC(1:Ncommon) - y_MyJuliVQC(1:Ncommon);

%% -------- Plot styling (paper-friendly) --------
fs_label = 13;   % axis labels
fs_tick  = 11;   % tick labels
lw       = 1.0;  % line width (paper)
ms       = 3.0;  % marker size (sparse)
markStep = max(1, floor(Nkeep/50));  % show ~50 markers at most

% To compare (a) and (b) fairly, unify y-limits:
ymin_ab = min([y_JuliVQC(:); y_MyJuliVQC(:)]);
ymax_ab = max([y_JuliVQC(:); y_MyJuliVQC(:)]);
ypad    = 0.03 * (ymax_ab - ymin_ab + eps);
yl_ab   = [ymin_ab-ypad, ymax_ab+ypad];

%% -------- Figure layout: tighter than subplot --------
fig = figure('Units','centimeters','Position',[2 2 18 6.2]); % width x height
tlo = tiledlayout(fig, 1, 3, 'TileSpacing','compact', 'Padding','compact');

% ---------- (a) JuliVQC ----------
ax1 = nexttile(tlo, 1);
hold(ax1,'on');

plot(ax1, x_JuliVQC, y_JuliVQC, '-', ...
    'LineWidth', lw, ...
    'Color', 'r');

plot(ax1, x_JuliVQC(1:markStep:end), y_JuliVQC(1:markStep:end), 'o', ...
    'MarkerSize', ms, ...
    'MarkerEdgeColor', 'r', ...
    'MarkerFaceColor', 'r');

grid(ax1,'off');
box(ax1,'on');
xlabel(ax1,'epoch','FontSize',fs_label);
ylabel(ax1,'loss','FontSize',fs_label);
set(ax1,'FontSize',fs_tick,'LineWidth',1.0);
ylim(ax1, yl_ab);

text(ax1, 0.03, 0.95, '(a)', ...
    'Units','normalized', 'FontSize',fs_tick+1, ...
    'BackgroundColor','w', 'Margin',1);

hold(ax1,'off');

% ---------- (b) MyJuliVQC ----------
ax2 = nexttile(tlo, 2);
hold(ax2,'on');

plot(ax2, x_MyJuliVQC, y_MyJuliVQC, '-', ...
    'LineWidth', lw, ...
    'Color', 'g');

plot(ax2, x_MyJuliVQC(1:markStep:end), y_MyJuliVQC(1:markStep:end), 'o', ...
    'MarkerSize', ms, ...
    'MarkerEdgeColor', 'g', ...
    'MarkerFaceColor', 'g');

grid(ax2,'off');
box(ax2,'on');
xlabel(ax2,'epoch','FontSize',fs_label);
ylabel(ax2,'loss','FontSize',fs_label);
set(ax2,'FontSize',fs_tick,'LineWidth',1.0);
ylim(ax2, yl_ab);

text(ax2, 0.03, 0.95, '(b)', ...
    'Units','normalized', 'FontSize',fs_tick+1, ...
    'BackgroundColor','w', 'Margin',1);

hold(ax2,'off');

% ---------- (c) Difference ----------
ax3 = nexttile(tlo, 3);
hold(ax3,'on');

plot(ax3, x_diff, y_diff, '-', ...
    'LineWidth', lw, ...
    'Color', 'b');

plot(ax3, x_diff(1:markStep:end), y_diff(1:markStep:end), 'o', ...
    'MarkerSize', ms, ...
    'MarkerEdgeColor', 'b', ...
    'MarkerFaceColor', 'b');

yline(ax3, 0, '--k', 'LineWidth', 0.9);

grid(ax3,'off');
box(ax3,'on');
xlabel(ax3,'epoch','FontSize',fs_label);
ylabel(ax3,'$\Delta$loss','FontSize',fs_label);
set(ax3,'FontSize',fs_tick,'LineWidth',1.0);

text(ax3, 0.03, 0.95, '(c)', ...
    'Units','normalized', 'FontSize',fs_tick+1, ...
    'BackgroundColor','w', 'Margin',1);

hold(ax3,'off');

%% -------- Export (for LaTeX) --------
% PDF vector is best for LaTeX; name matches your LaTeX placeholder
out_pdf = fullfile(thisDir, 'fig_grad_desc_compare.pdf');
% --- Fix PDF margins: make paper size match figure size ---
set(fig, 'PaperUnits','centimeters');
pos = get(fig,'Position');   % [x y width height]
set(fig, 'PaperSize', [pos(3) pos(4)]);
set(fig, 'PaperPosition', [0 0 pos(3) pos(4)]);

print(fig, out_pdf, '-dpdf', '-r300');

fprintf('Saved figure to: %s\n', out_pdf);

%% -------- local function: parse "Epoch k: loss = v" --------
function [x, y] = read_loss_log(filepath)
    if ~isfile(filepath)
        error('Log file not found: %s', filepath);
    end

    lines = readlines(filepath);

    % Match: Epoch <int>: loss = <float>
    % float pattern supports scientific notation too
    pat = 'Epoch\s+(\d+):\s+loss\s*=\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)';

    x = [];
    y = [];

    for i = 1:numel(lines)
        t = regexp(lines(i), pat, 'tokens', 'once');
        if ~isempty(t)
            x(end+1,1) = str2double(t{1}); %#ok<AGROW>
            y(end+1,1) = str2double(t{2}); %#ok<AGROW>
        end
    end

    if isempty(x)
        error('No "Epoch ...: loss = ..." lines found in %s', filepath);
    end
end
