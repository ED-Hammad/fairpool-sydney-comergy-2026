function gc_figures(D, SA, RES, CO, SWEEP, SE, P)
% GC_FIGURES  Figures of the simplified model (white background, 300 dpi) into figures/<run tag>/.
%
% Part of FairPool Sydney: a cooperative energy pool with optimised shared storage and Shapley
% settlement for the ComErgy benchmark community (entry to the ComErgy Grand Challenge 2026).
% Author: Hammad Masood, Khalifa University of Science and Technology. Licence: MIT (see LICENSE).
% Repository: https://github.com/USERNAME/fairpool-sydney-comergy-2026
%
outdir = fullfile(P.fig_dir, P.run_tag); if ~exist(outdir, 'dir'), mkdir(outdir); end
ex = @(f, name) exportgraphics(f, fullfile(outdir, [name '.png']), 'Resolution', 300, 'BackgroundColor', 'white');
L = sum(D.load, 2); G = sum(D.pv, 2); R = RES.lp;
f = figure('Color', 'w', 'Position', [100 100 1000 600]);  % fig01 dispatch weeks
for k = 1:numel(P.fig.weeks)
    subplot(numel(P.fig.weeks), 1, k); d0 = datetime(P.fig.weeks{k}); i0 = find(D.time >= d0, 1); r = i0:i0+167;
    yyaxis left; plot(D.time(r), L(r), 'k-', D.time(r), G(r), 'Color', [0.9 0.6 0]); hold on; plot(D.time(r), R.imp(r), 'b-', D.time(r), -R.exp(r), 'g-'); ylabel('kW');
    yyaxis right; plot(D.time(r), R.soc(r), 'r--'); ylabel('Pooled store (kWh)');
    title(['Week from ' char(datetime(d0, 'Format', 'd MMM yyyy'))]); legend({'Load','PV','Import','Export (negative)','Store'}, 'Location', 'northwest', 'NumColumns', 5); grid on;
end
gc_style(f); ex(f, 'fig01_dispatch_weeks'); close(f);
f = figure('Color', 'w', 'Position', [100 100 800 450]); bar([SA.bill_noder, SA.bill, SA.bill - CO.hybrid]); ylabel('Annual bill (AUD)'); xlabel('Member');  % fig02 bills
legend({'No solar or battery', 'On your own with own assets', 'Community pool, recommended rule'}, 'Location', 'northwest'); grid on; gc_style(f); ex(f, 'fig02_bills'); close(f);
A = [CO.shapley, CO.hybrid, CO.prop_bill] ./ SA.bill * 100; rules = {'Shapley', 'Recommended (Shapley with solidarity share)', 'Same percentage for everyone'};
f = figure('Color', 'w', 'Position', [100 100 900 450]); bar(A); ylabel('Saving relative to own bill (%)'); xlabel('Member'); ylim([0, 1.25*max(A(:))]); legend(rules, 'Location', 'northeast'); grid on; gc_style(f); ex(f, 'fig03_allocation_rules'); close(f);
f = figure('Color', 'w', 'Position', [100 100 500 450]); hold on;  % fig04 Lorenz
for k = 1:3, x = sort(max(A(:,k), 0)); plot((0:9)/9, [0; cumsum(x)/sum(x)], '-o', 'MarkerSize', 3); end
plot([0 1], [0 1], 'k:'); xlabel('Cumulative share of households'); ylabel('Cumulative share of relative savings'); legend(rules, 'Location', 'northwest'); grid on; axis square; gc_style(f); ex(f, 'fig04_lorenz'); close(f);
if ~isempty(SWEEP)  % fig05 cap sweep
    f = figure('Color', 'w', 'Position', [100 100 600 400]); plot(SWEEP.cap, SWEEP.cost, '-o'); ylabel('Community cost (AUD/y)'); xlabel('Import cap (kW)'); grid on; gc_style(f); ex(f, 'fig05_peak_cap'); close(f);
end
f = figure('Color', 'w', 'Position', [100 100 600 400]); plot(sort(sum(SA.imp, 2), 'descend'), 'k-'); hold on; plot(sort(RES.rule.imp, 'descend'), 'b-'); plot(sort(R.imp, 'descend'), 'r-');  % fig06
xlim([0 2000]); xlabel('Hours'); ylabel('Community import (kW)'); legend({'Sum of households alone', 'Pool, simple rule', 'Pool, daily optimisation'}); grid on; gc_style(f); ex(f, 'fig06_import_duration'); close(f);
if ~isempty(SE)  % fig07 tornado
    f = figure('Color', 'w', 'Position', [100 100 900 400]); lab = {'Community saving (AUD/y)', 'Gini of relative savings', 'Minimum relative saving'};
    for q = 1:3
        subplot(1, 3, q); b0 = [SE.base.surplus, SE.base.gini, SE.base.min_rel]; b0 = b0(q); lo = squeeze(SE.out(:,1,q)) - b0; hi = squeeze(SE.out(:,2,q)) - b0; [~, ord] = sort(abs(hi - lo), 'ascend');
        barh(1:numel(ord), lo(ord), 'FaceColor', [0.3 0.5 0.8]); hold on; barh(1:numel(ord), hi(ord), 'FaceColor', [0.9 0.5 0.3]);
        set(gca, 'YTick', 1:numel(ord), 'YTickLabel', strrep(SE.names(ord), '_', ' ')); xlabel(['Change in ' lab{q}]); grid on;
    end
    gc_style(f); ex(f, 'fig07_tornado'); close(f);
end
end

function gc_style(f)
try, f.Theme = 'light'; catch, end; f.Color = 'w'; ax = findall(f, 'Type', 'axes');
for k = 1:numel(ax), ax(k).Color = 'w'; ax(k).XColor = 'k'; ax(k).GridColor = [0.15 0.15 0.15]; ax(k).Title.Color = 'k'; end
set(findall(f, '-property', 'FontName'), 'FontName', 'Times New Roman', 'FontSize', 10); set(findall(f, 'Type', 'legend'), 'TextColor', 'k', 'Color', 'w');
end
