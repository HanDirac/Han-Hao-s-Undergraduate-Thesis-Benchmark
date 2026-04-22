clear
clc

%% =========================
% paths
%% =========================

base = "D:\2022.8.15起我的资料(有些已经导进了硬盘)\刘杰\2025年6月9日收到\Han-Hao-s-Undergraduate-Thesis-Benchmark\Performance testing\";

file_juli = base + "JuliVQC\.benchmarks\JuliVQC\single_gate_test.json";
file_my   = base + "MyJuliVQC\.benchmarks\MyJuliVQC\single_gate_test.json";

%% =========================
% read json
%% =========================

txt = fileread(file_juli);
J = jsondecode(txt);

txt = fileread(file_my);
M = jsondecode(txt);

n = J.H.nqubits;

%% =========================
% mean times
%% =========================

J_H  = J.H.meantimes;
J_RX = J.RX.meantimes;
J_C  = J.CNOT.meantimes;

M_H  = M.H.meantimes;
M_RX = M.RX.meantimes;
M_C  = M.CNOT.meantimes;

%% =========================
% ratios
%% =========================

R_H  = M_H  ./ J_H;
R_RX = M_RX ./ J_RX;
R_C  = M_C  ./ J_C;

%% =========================
% unified y-limits
%% =========================

all_time = [J_H(:); M_H(:); J_RX(:); M_RX(:); J_C(:); M_C(:)];
time_min = min(all_time);
time_max = max(all_time);

all_ratio = [R_H(:); R_RX(:); R_C(:)];
ratio_min = min(all_ratio);
ratio_max = max(all_ratio);

% 给线性坐标留一点上下边距
ratio_pad = 0.05 * (ratio_max - ratio_min);
if ratio_pad == 0
    ratio_pad = 0.1;
end
ratio_ylim = [0, ratio_max + ratio_pad];

%% =========================
% figure
%% =========================

figure('Units','normalized','Position',[0.08 0.10 0.84 0.62])

lw = 1;
ms = 2.5;

%% =========================
% H log (左上)
%% =========================

subplot(2,3,1)

semilogy(n, J_H,'-o','LineWidth',lw,'MarkerSize',ms)
hold on
semilogy(n, M_H,'-s','LineWidth',lw,'MarkerSize',ms)

grid on
ylim([time_min, time_max])

yticks([1e-5 1e0])
yticklabels({'10^{-5}','10^{0}'})

ylabel('Time (s)')
title('H gate time (log scale)')

lgd = legend('JuliVQC','MyJuliVQC','Location','northwest');

pos = lgd.Position;
pos(1) = pos(1) + 0.007;
pos(2) = pos(2) + 0.011;
lgd.Position = pos;

%% =========================
% Rx log (中上)
%% =========================

subplot(2,3,2)

semilogy(n, J_RX,'-o','LineWidth',lw,'MarkerSize',ms)
hold on
semilogy(n, M_RX,'-s','LineWidth',lw,'MarkerSize',ms)

grid on
ylim([time_min, time_max])

yticks([1e-5 1e0])
yticklabels({'10^{-5}','10^{0}'})

xlabel('Number of qubits')
title('Rx gate time (log scale)')

%% =========================
% CNOT log (右上)
%% =========================

subplot(2,3,3)

semilogy(n, J_C,'-o','LineWidth',lw,'MarkerSize',ms)
hold on
semilogy(n, M_C,'-s','LineWidth',lw,'MarkerSize',ms)

grid on
ylim([time_min, time_max])

yticks([1e-5 1e0])
yticklabels({'10^{-5}','10^{0}'})

title('CNOT gate time (log scale)')

%% =========================
% H ratio (左下)
%% =========================

subplot(2,3,4)

plot(n, R_H,'-o','LineWidth',lw,'MarkerSize',ms,'Color','g')

grid on
ylim(ratio_ylim)

ylabel('My / Juli')
title('H gate ratio')

%% =========================
% Rx ratio (中下)
%% =========================

subplot(2,3,5)

plot(n, R_RX,'-o','LineWidth',lw,'MarkerSize',ms,'Color','g')

grid on
ylim(ratio_ylim)

xlabel('Number of qubits')
title('Rx gate ratio')

%% =========================
% CNOT ratio (右下)
%% =========================

subplot(2,3,6)

plot(n, R_C,'-o','LineWidth',lw,'MarkerSize',ms,'Color','g')

grid on
ylim(ratio_ylim)

title('CNOT gate ratio')

%% =========================
% style for paper
%% =========================

set(gcf,'Color','w')
set(findall(gcf,'-property','FontSize'),'FontSize',15)
lgd.FontSize = 12;
set(findall(gcf,'-property','FontName'),'FontName','Times New Roman')

% tighten subplot layout a bit
ax = findall(gcf,'type','axes');
for k = 1:numel(ax)
    ax(k).LooseInset = ax(k).TightInset;
end

ax = findall(gcf,'type','axes');

for k = 1:numel(ax)
    pos = ax(k).Position;

    % 上排子图上移
    if pos(2) > 0.5
        pos(2) = pos(2) + 0.01;
    else
        % 下排子图下移
        pos(2) = pos(2) - 0.04;
    end

    ax(k).Position = pos;
end

% make exported page match figure size
set(gcf,'PaperUnits','inches')
set(gcf,'PaperSize',[11 5.8])
set(gcf,'PaperPosition',[0 0 11 5.8])

print(gcf, base + "fig_sing_gate_test.pdf", '-dpdf', '-fillpage')
print(gcf, base + "fig_sing_gate_test.png", '-dpng', '-r300')

%% =========================
% save
%% =========================

