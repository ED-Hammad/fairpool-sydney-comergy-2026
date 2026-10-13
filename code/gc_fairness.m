function F = gc_fairness(gain, bill_sa)
% GC_FAIRNESS  Fairness indicators of a gain vector against stand-alone bills: relative saving, its minimum,
% the minimum absolute gain, the Gini coefficient of relative savings and the individual-rationality flag.
%
% Part of FairPool Sydney: a cooperative energy pool with optimised shared storage and Shapley
% settlement for the ComErgy benchmark community (entry to the ComErgy Grand Challenge 2026).
% Author: Hammad Masood, Khalifa University of Science and Technology. Licence: MIT (see LICENSE).
% Repository: https://github.com/ED-Hammad/fairpool-sydney-comergy-2026
%
r = gain ./ bill_sa; F.rel = r; F.min_rel = min(r); F.min_abs = min(gain);
x = sort(max(r, 0)); nn = numel(x); F.gini = (2*sum((1:nn)'.*x)/(nn*sum(x))) - (nn + 1)/nn;
F.ir_ok = all(gain >= -1e-9);
end
