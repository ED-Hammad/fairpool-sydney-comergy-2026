function R = gc_dispatch_rule(load, pv, Ekwh, Pkw, price, fit, P)
% GC_DISPATCH_RULE  Myopic merit-order dispatch of one store (own or pooled): PV serves load; surplus charges
% the store; deficit discharges it; grid last; no grid charging; no look-ahead.
%
% Part of FairPool Sydney: a cooperative energy pool with optimised shared storage and Shapley
% settlement for the ComErgy benchmark community (entry to the ComErgy Grand Challenge 2026).
% Author: Hammad Masood, Khalifa University of Science and Technology. Licence: MIT (see LICENSE).
% Repository: https://github.com/USERNAME/fairpool-sydney-comergy-2026
%
n = numel(load); eta = sqrt(P.bat.eta_rt); Emin = P.bat.soc_min*Ekwh; Emax = P.bat.soc_max*Ekwh; soc = P.bat.soc_init*Ekwh;
imp = zeros(n,1); expo = zeros(n,1); ch = zeros(n,1); dis = zeros(n,1); S = zeros(n,1);
for h = 1:n
    net = pv(h) - load(h);
    if net >= 0, c = min([net, Pkw, (Emax - soc)/eta/P.dt]); soc = soc + c*eta*P.dt; ch(h) = c; expo(h) = net - c;
    else, d = min([-net, Pkw, (soc - Emin)*eta/P.dt]); soc = soc - d/eta*P.dt; dis(h) = d; imp(h) = -net - d; end
    S(h) = soc;
end
assert(max(abs(pv + imp + dis - load - expo - ch)) < 1e-8, 'hourly energy balance violated in rule dispatch');
assert(all(S >= Emin - 1e-9 & S <= Emax + 1e-9), 'SOC bounds violated in rule dispatch');
R.imp = imp; R.exp = expo; R.ch = ch; R.dis = dis; R.soc = S;
R.cost_energy = sum(price.*imp) - sum(fit.*expo) + P.bat.cycle_cost*sum(dis);  % AUD before fees
end
