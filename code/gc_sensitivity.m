function SE = gc_sensitivity(P0)
% GC_SENSITIVITY  One-at-a-time tornado over the five parameters of sheet Parameters (sens.names, sens.lo,
% sens.hi): outputs community surplus, Gini and minimum relative saving under the hybrid rule, rule dispatch for speed.
%
% Part of FairPool Sydney: a cooperative energy pool with optimised shared storage and Shapley
% settlement for the ComErgy benchmark community (entry to the ComErgy Grand Challenge 2026).
% Author: Hammad Masood, Khalifa University of Science and Technology. Licence: MIT (see LICENSE).
% Repository: https://github.com/ED-Hammad/fairpool-sydney-comergy-2026
%
names = P0.sens.names; lo = P0.sens.lo; hi = P0.sens.hi; base = gc_eval(P0);
SE.base = base; SE.names = names; SE.lo = lo; SE.hi = hi; SE.out = nan(numel(names), 2, 3);
for k = 1:numel(names)
    for side = 1:2
        P = P0; val = lo(k); if side == 2, val = hi(k); end; parts = strsplit(names{k}, '.'); P = setfield(P, parts{:}, val);
        o = gc_eval(P); SE.out(k, side, :) = [o.surplus, o.gini, o.min_rel];
        fprintf('  tornado %s = %g: surplus %.0f gini %.3f minrel %.3f\n', names{k}, val, o.surplus, o.gini, o.min_rel);
    end
end
end

function o = gc_eval(P)
P.disp.method = 'rule'; P.alloc.coalition_method = 'rule'; P.write_csv = false;
D = gc_load_data(P); SA = gc_standalone(D, P); CO = gc_coalitions(D, SA, P, 'rule'); F = gc_fairness(CO.hybrid, SA.bill);
o.surplus = CO.vN; o.gini = F.gini; o.min_rel = F.min_rel;
end
