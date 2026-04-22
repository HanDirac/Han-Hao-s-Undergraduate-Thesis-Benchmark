clear
clc

%% =========================
% paths
%% =========================

base = "D:\2022.8.15起我的资料(有些已经导进了硬盘)\刘杰\2025年6月9日收到\Han-Hao-s-Undergraduate-Thesis-Benchmark\Performance testing\";

file_juli = base + "JuliVQC\.benchmarks\JuliVQC\noisy_ad_performance.json";
file_my   = base + "MyJuliVQC\.benchmarks\MyJuliVQC\noisy_ad_performance.json";

%% =========================
% read json
%% =========================

J = jsondecode(fileread(file_juli));
M = jsondecode(fileread(file_my));

%% =========================
% data
%% =========================

J_n = cellfun(@(x) x(1), num2cell(J.vqc_thread1.nqubits, 2));
M_n = cellfun(@(x) x(1), num2cell(M.vqc_thread1.nqubits, 2));

J_t = J.vqc_thread1.meantimes;
M_t = M.vqc_thread1.meantimes;

%% =========================
% align nqubits for ratio
%% =========================

[n_common, iJ, iM] = intersect(J_n, M_n);

J_tc = J_t(iJ);
M_tc = M_t(iM);

R = M_tc ./ J_tc;

%% =========================
% unified limits
%% =========================

all_time = [J_t(:); M_t(:)];
time_min = min(all_time);
time_max = max(all_time);

ratio_max = max(R);
ratio_pad = 0.05 * ratio_max;
if ratio_pad == 0
    ratio_pad = 0.1;
end
ratio_ylim = [0, ratio_max + ratio_pad];

k_min = floor(log10(time_min));
k_max = ceil(log10(time_max));
time_ticks = 10.^(k_min:k_max);

%% =========================
% figure
%% =========================

figure('Units','normalized','Position',[0.10 0.20 0.80 0.42])

lw = 1.5;
ms = 5;

%% =========================
% noisy AD time (左)
%% =========================

ax1 = subplot(1,2,1);

semilogy(J_n, J_t, '-o', 'LineWidth', lw, 'MarkerSize', ms)
hold on
semilogy(M_n, M_t, '-s', 'LineWidth', lw, 'MarkerSize', ms)

ylim([time_min time_max])
yticks(time_ticks)
xlim([min([J_n(:); M_n(:)]) max([J_n(:); M_n(:)])])   % 修改2
grid on

ax1.YMinorTick = 'off';   % 修改1
ax1.YMinorGrid = 'off';   % 修改1

xlabel('Number of qubits')
ylabel('Time (s)')
title('Noisy gradient time (log scale)')

lgd = legend('JuliVQC','MyJuliVQC','Location','northwest');
pos = lgd.Position;
pos(1) = pos(1) - 0.01;
pos(2) = pos(2) - 0.06;
lgd.Position = pos;

%% =========================
% noisy AD ratio (右)
%% =========================

ax2 = subplot(1,2,2);

plot(n_common, R, '-o', 'Color', 'g', 'LineWidth', lw, 'MarkerSize', ms)

ylim(ratio_ylim)
xlim([min(n_common) max(n_common)])   % 修改2
grid on

ylabel('My/Juli')
title('Noisy gradient ratio')

%% =========================
% style
%% =========================

set(gcf, 'Color', 'w')
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 15)
set(findall(gcf, '-property', 'FontName'), 'FontName', 'Times New Roman')

ax = [ax1, ax2];

% 修改3：强制子图高宽比为...，并重新排布避免重叠
left_margin   = 0.08;
right_margin  = 0.04;
bottom_margin = 0.18;
top_margin    = 0.10;
col_gap       = 0.10;

max_w_horiz = (1 - left_margin - right_margin - col_gap) / 2;
max_w_vert  = (1 - bottom_margin - top_margin) / (7/4);

sp_w = min(max_w_horiz, max_w_vert);
sp_h = sp_w * 7/4;

x1 = left_margin;
x2 = 1 - right_margin - sp_w;
y1 = bottom_margin;

ax1.Position = [x1, y1, sp_w, sp_h];
ax2.Position = [x2, y1, sp_w, sp_h];

for k = 1:numel(ax)
    ax(k).LooseInset = ax(k).TightInset;
end

%% =========================
% export
%% =========================

set(gcf, 'PaperUnits', 'inches')
set(gcf, 'PaperSize', [8.8 3.8])
set(gcf, 'PaperPosition', [0 0 8.8 3.8])

print(gcf, base + "fig_noisy_ad_test.pdf", '-dpdf', '-fillpage')
print(gcf, base + "fig_noisy_ad_test.png", '-dpng', '-r300')