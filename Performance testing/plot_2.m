clear
clc

%% =========================
% paths
%% =========================

base = "D:\2022.8.15起我的资料(有些已经导进了硬盘)\刘杰\2025年6月9日收到\Han-Hao-s-Undergraduate-Thesis-Benchmark\Performance testing\";

file_juli = base + "JuliVQC\.benchmarks\JuliVQC\variational_circuit_test.json";
file_my   = base + "MyJuliVQC\.benchmarks\MyJuliVQC\variational_circuit_test.json";

%% =========================
% read json
%% =========================

J = jsondecode(fileread(file_juli));
M = jsondecode(fileread(file_my));

%% =========================
% data
%% =========================

J_n_vqc_all = J.vqc.nqubits;
J_n_ad_all  = J.ad.nqubits;

M_n_vqc = M.vqc.nqubits;
M_n_ad  = M.ad.nqubits;

J_vqc_all = J.vqc.meantimes;
J_ad_all  = J.ad.meantimes;

M_vqc = M.vqc.meantimes;
M_ad  = M.ad.meantimes;

%% =========================
% truncate JuliVQC to <= 25 qubits
%% =========================

mask_vqc = (J_n_vqc_all <= 25);
mask_ad  = (J_n_ad_all  <= 25);

J_n_vqc = J_n_vqc_all(mask_vqc);
J_n_ad  = J_n_ad_all(mask_ad);

J_vqc = J_vqc_all(mask_vqc);
J_ad  = J_ad_all(mask_ad);

%% =========================
% align nqubits for ratios
%% =========================

[n_vqc_common, iJ_vqc, iM_vqc] = intersect(J_n_vqc, M_n_vqc);
J_vqc_c = J_vqc(iJ_vqc);
M_vqc_c = M_vqc(iM_vqc);

[n_ad_common, iJ_ad, iM_ad] = intersect(J_n_ad, M_n_ad);
J_ad_c = J_ad(iJ_ad);
M_ad_c = M_ad(iM_ad);

%% =========================
% ratios
%% =========================

R_vqc = M_vqc_c ./ J_vqc_c;
R_ad  = M_ad_c  ./ J_ad_c;

%% =========================
% unified y limits
%% =========================

all_time = [J_vqc(:); M_vqc(:); J_ad(:); M_ad(:)];
time_min = min(all_time);
time_max = max(all_time);

all_ratio = [R_vqc(:); R_ad(:)];
ratio_max = max(all_ratio);

ratio_pad = 0.05 * ratio_max;
if ratio_pad == 0
    ratio_pad = 0.1;
end
ratio_ylim = [0, ratio_max + ratio_pad];

k_min = floor(log10(time_min));
k_max = ceil(log10(time_max));

% 每隔10倍保留一个tick（用于网格线）
time_ticks = 10.^(k_min:k_max);

%% =========================
% figure
%% =========================

figure('Units','normalized','Position',[0.08 0.08 0.84 0.72])

lw = 1.5;
ms = 5;

%% =========================
% VQC log
%% =========================

ax1 = subplot(2,2,1);

semilogy(J_n_vqc, J_vqc,'-o','LineWidth',lw,'MarkerSize',ms)
hold on
semilogy(M_n_vqc, M_vqc,'-s','LineWidth',lw,'MarkerSize',ms)

xlim([min([J_n_vqc(:); M_n_vqc(:)]) max([J_n_vqc(:); M_n_vqc(:)])])
ylim([time_min time_max])

yticks(time_ticks)

ax1.YMinorTick = 'off';
ax1.YMinorGrid = 'off';

grid on

ylabel('Time (s)')
xlabel('Number of qubits')
title('Random circuit time (log scale)')

lgd = legend('JuliVQC','MyJuliVQC','Location','northwest');
pos = lgd.Position;
pos(1) = pos(1) + 0.002;
lgd.Position = pos;

%% =========================
% AD log
%% =========================

ax2 = subplot(2,2,2);

semilogy(J_n_ad, J_ad,'-o','LineWidth',lw,'MarkerSize',ms)
hold on
semilogy(M_n_ad, M_ad,'-s','LineWidth',lw,'MarkerSize',ms)

xlim([min([J_n_ad(:); M_n_ad(:)]) max([J_n_ad(:); M_n_ad(:)])])
ylim([time_min time_max])

yticks(time_ticks)

ax2.YMinorTick = 'off';
ax2.YMinorGrid = 'off';

grid on

title('Gradient time (log scale)')

%% =========================
% 自定义Y轴标签：每隔10^2显示一次数字
%% =========================

labels = strings(size(time_ticks));

for i = 1:length(time_ticks)
    expo = round(log10(time_ticks(i)));

    if mod(expo - k_min,2)==0
        labels(i) = "$10^{" + string(expo) + "}$";
    else
        labels(i) = "";
    end
end

ax1.YTickLabel = labels;
ax2.YTickLabel = labels;

ax1.TickLabelInterpreter = 'latex';
ax2.TickLabelInterpreter = 'latex';

%% =========================
% VQC ratio
%% =========================

ax3 = subplot(2,2,3);

plot(n_vqc_common, R_vqc,'-o','Color','g','LineWidth',lw,'MarkerSize',ms)

xlim([min(n_vqc_common) max(n_vqc_common)])
ylim(ratio_ylim)

grid on

ylabel('My / Juli')
xlabel('Number of qubits')
title('Random circuit ratio')

%% =========================
% AD ratio
%% =========================

ax4 = subplot(2,2,4);

plot(n_ad_common, R_ad,'-o','Color','g','LineWidth',lw,'MarkerSize',ms)

xlim([min(n_ad_common) max(n_ad_common)])
ylim(ratio_ylim)

grid on

title('Gradient ratio')

%% =========================
% style
%% =========================

set(gcf,'Color','w')
set(findall(gcf,'-property','FontSize'),'FontSize',18)
set(findall(gcf,'-property','FontName'),'FontName','Times New Roman')

ax = [ax1, ax2, ax3, ax4];

left_margin   = 0.08;
right_margin  = 0.04;
bottom_margin = 0.10;
top_margin    = 0.07;
col_gap       = 0.10;
row_gap       = 0.15;

max_w_horiz = (1 - left_margin - right_margin - col_gap) / 2;
max_w_vert  = (1 - bottom_margin - top_margin - row_gap) / (2 * (3.5/4));

sp_w = min(max_w_horiz, max_w_vert);
sp_h = sp_w * 3.5/4;

x1 = left_margin;
x2 = 1 - right_margin - sp_w;

y1 = bottom_margin;
y2 = y1 + sp_h + row_gap;

ax1.Position = [x1, y2, sp_w, sp_h];
ax2.Position = [x2, y2, sp_w, sp_h];
ax3.Position = [x1, y1, sp_w, sp_h];
ax4.Position = [x2, y1, sp_w, sp_h];

for k = 1:numel(ax)
    ax(k).LooseInset = ax(k).TightInset;
end

%% =========================
% export
%% =========================

set(gcf,'PaperUnits','inches')
set(gcf,'PaperSize',[10 7.8])
set(gcf,'PaperPosition',[0 0 10 7.8])

print(gcf, base + "fig_variational_test.pdf", '-dpdf', '-fillpage')
print(gcf, base + "fig_variational_test.png", '-dpng', '-r300')