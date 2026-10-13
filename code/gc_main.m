function gc_main(mode, scenario)
% GC_MAIN  Driver: data, counterfactual, pooled dispatch (daily LP, rule as
% lower bound, LP without grid charging as safe mode), 511 coalition values, Shapley and hybrid settlement, fairness,
% cap sweep, tornado, household statements, outputs and figures. mode = 'full' or 'quick'; scenario from the workbook.
%
% Part of FairPool Sydney: a cooperative energy pool with optimised shared storage and Shapley
% settlement for the ComErgy benchmark community (entry to the ComErgy Grand Challenge 2026).
% Author: Hammad Masood, Khalifa University of Science and Technology. Licence: MIT (see LICENSE).
% Repository: https://github.com/ED-Hammad/fairpool-sydney-comergy-2026
%
if nargin < 1, mode = 'full'; end; if nargin < 2, scenario = 'Base'; end
P = gc_config(scenario); tAll = tic;
if strcmp(mode, 'quick'), P.disp.method = 'rule'; P.alloc.coalition_method = 'rule'; P.run.peak_sweep = false; P.run.sensitivity = false; end
fprintf('GC RUN START %s  mode=%s  scenario=%s  dispatch=%s  inputs=%s\n', P.run_tag, mode, scenario, P.disp.method, P.inputs_file);
D = gc_load_data(P); SA = gc_standalone(D, P);
fprintf('Data: load %.0f kWh/y, PV %.0f kWh/y (%.0f kWh/kWp), peak load %.1f kW\n', sum(D.load(:)), sum(D.pv(:)), sum(D.pv_spec), max(sum(D.load, 2)));
fprintf('Standalone bills: %s  sum %.0f; no-DER sum %.0f\n', mat2str(round(SA.bill')), sum(SA.bill), sum(SA.bill_noder));
L = sum(D.load, 2); G = sum(D.pv, 2); E = sum(D.bat_kwh); Pk = sum(D.bat_kw); fee9 = 9*(P.fee_conn_day*365 + P.fee_operator_year);
RES.rule = gc_dispatch_rule(L, G, E, Pk, D.price, D.fit, P);
RES.lp = gc_dispatch_lp(L, G, E, Pk, D.price, D.fit, P);
Pn = P; Pn.disp.grid_charging = false; RES.lp_nogrid = gc_dispatch_lp(L, G, E, Pk, D.price, D.fit, Pn);
vars = {'rule', 'lp', 'lp_nogrid'}; K = struct();
for k = 1:3, K.(vars{k}) = gc_metrics(RES.(vars{k}), L, G, E, D, P); fprintf('%-10s cost %.0f  imp %.0f  exp %.0f  SC %.3f  SS %.3f  peak %.1f  EFC %.0f\n', vars{k}, K.(vars{k}).cost_energy + fee9, K.(vars{k}).import_kwh, K.(vars{k}).export_kwh, K.(vars{k}).self_consumption, K.(vars{k}).self_sufficiency, K.(vars{k}).peak_import_kw, K.(vars{k}).efc); end
CO = gc_coalitions(D, SA, P, P.alloc.coalition_method);
fprintf('v(N) = %.0f AUD/y (%.1f%% of standalone sum)\n', CO.vN, 100*CO.vN/sum(SA.bill));
rules = {'shapley', 'hybrid', 'prop_bill', 'nucleolus'}; FA = struct(); fprintf('%-10s %8s %8s %8s %4s %8s\n', 'rule', 'min_rel', 'min_abs', 'gini', 'IR', 'excess');
for k = 1:4, g = CO.(rules{k}); F = gc_fairness(g, SA.bill); F.excess = CO.excess(g); FA.(rules{k}) = F; fprintf('%-10s %8.3f %8.0f %8.3f %4d %8.1f\n', rules{k}, F.min_rel, F.min_abs, F.gini, F.ir_ok, F.excess); end
PR = gc_pricing(D);
SWEEP = [];
if P.run.peak_sweep
    caps = P.sweep.caps; SWEEP.cap = caps; SWEEP.cost = nan(size(caps)); SWEEP.peak = nan(size(caps));
    for c = 1:numel(caps)
        try  % a cap that cannot be met without grid charging is reported as infeasible, not as a failure of the run
            Rc = gc_dispatch_lp(L, G, E, Pk, D.price, D.fit, P, struct('peak_cap_kw', caps(c))); SWEEP.cost(c) = Rc.cost_energy + fee9; SWEEP.peak(c) = max(Rc.imp); fprintf('  cap %5.1f kW: cost %.0f peak %.1f\n', caps(c), SWEEP.cost(c), SWEEP.peak(c));
        catch err, SWEEP.cost(c) = NaN; SWEEP.peak(c) = NaN; fprintf('  cap %5.1f kW: infeasible (%s)\n', caps(c), err.message); end
    end
end
SE = []; if P.run.sensitivity, SE = gc_sensitivity(P); end
tag = P.run_tag;
T = table(D.time, L, G, RES.lp.imp, RES.lp.exp, RES.lp.ch, RES.lp.dis, RES.lp.soc, D.price, D.fit, PR.p_buy, PR.p_sell, PR.sdr, ...
    'VariableNames', {'time','load_kw','pv_kw','import_kw','export_kw','charge_kw','discharge_kw','store_kwh','price','fit','p_buy_sdr','p_sell_sdr','sdr'});
writetable(T, fullfile(P.res_dir, ['hourly_dispatch_' tag '.csv']));
Ta = table((1:9)', D.income, D.pv_kwp, D.bat_kwh, SA.bill_noder, SA.bill, CO.shapley, CO.solidarity, CO.hybrid, CO.prop_bill, SA.bill - CO.hybrid, CO.hybrid./SA.bill, CO.nucleolus, ...
    'VariableNames', {'member','income','pv_kwp','bat_kwh','bill_noder','bill_standalone','gain_shapley','solidarity_received','gain_recommended','gain_same_percentage','bill_settled','rel_saving','gain_nucleolus_footnote'});
writetable(Ta, fullfile(P.res_dir, ['allocations_' tag '.csv']));
Tc = array2table([double(CO.mask), CO.size, CO.v, CO.cost], 'VariableNames', [arrayfun(@(i) sprintf('m%d', i), 1:9, 'UniformOutput', false), {'size', 'v', 'cost'}]);
writetable(Tc, fullfile(P.res_dir, ['coalition_values_' tag '.csv']));
Km = rows2vars(struct2table([K.rule; K.lp; K.lp_nogrid])); Km.Properties.VariableNames = [{'metric'}, vars]; writetable(Km, fullfile(P.res_dir, ['kpi_summary_' tag '.csv']));
Tf = table(rules', cellfun(@(r) FA.(r).min_rel, rules)', cellfun(@(r) FA.(r).min_abs, rules)', cellfun(@(r) FA.(r).gini, rules)', cellfun(@(r) FA.(r).ir_ok, rules)', cellfun(@(r) FA.(r).excess, rules)', 'VariableNames', {'rule','min_rel_saving','min_abs_gain','gini','ir_ok','max_excess_footnote'});
writetable(Tf, fullfile(P.res_dir, ['fairness_' tag '.csv']));
if ~isempty(SWEEP), writetable(table(SWEEP.cap', SWEEP.cost', SWEEP.peak', 'VariableNames', {'cap_kw','cost','peak_kw'}), fullfile(P.res_dir, ['peak_sweep_' tag '.csv'])); end
if ~isempty(SE), writetable(table(SE.names', SE.lo', SE.hi', squeeze(SE.out(:,1,1)), squeeze(SE.out(:,2,1)), squeeze(SE.out(:,1,2)), squeeze(SE.out(:,2,2)), squeeze(SE.out(:,1,3)), squeeze(SE.out(:,2,3)), 'VariableNames', {'param','lo','hi','surplus_lo','surplus_hi','gini_lo','gini_hi','minrel_lo','minrel_hi'}), fullfile(P.res_dir, ['tornado_' tag '.csv'])); end
gc_statements(D, SA, CO, K.lp, P, tag);
save(fullfile(P.res_dir, ['gc_results_' tag '.mat']), 'P', 'D', 'SA', 'RES', 'K', 'CO', 'FA', 'PR', 'SWEEP', 'SE', '-v7.3');
copyfile(P.inputs_file, fullfile(P.res_dir, ['inputs_used_' tag '.xlsx']));
if P.run.figures, gc_figures(D, SA, RES, CO, SWEEP, SE, P); end
fprintf('GC RUN COMPLETE: %s  (%.0f s)\n', tag, toc(tAll));
end
