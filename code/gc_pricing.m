function PR = gc_pricing(D)
% GC_PRICING  Illustrative hourly internal prices by the supply-demand ratio (Liu et al. 2017): the selling price
% falls from the retail price towards the FiT as the community surplus grows relative to the deficit. Reported with
% the hourly dispatch only; settlement is annual by the Shapley-based rule.
%
% Part of FairPool Sydney: a cooperative energy pool with optimised shared storage and Shapley
% settlement for the ComErgy benchmark community (entry to the ComErgy Grand Challenge 2026).
% Author: Hammad Masood, Khalifa University of Science and Technology. Licence: MIT (see LICENSE).
% Repository: https://github.com/ED-Hammad/fairpool-sydney-comergy-2026
%
n = D.n; sur = max(D.pv - D.load, 0); def = max(D.load - D.pv, 0); TS = sum(sur, 2); TD = sum(def, 2);
sdr = zeros(n,1); m = TD > 0; sdr(m) = TS(m)./TD(m); pr = D.price; ft = D.fit; p_sell = ft; p_buy = ft;
k = m & sdr <= 1; p_sell(k) = (ft(k).*pr(k)) ./ ((pr(k) - ft(k)).*sdr(k) + ft(k)); p_buy(k) = p_sell(k).*sdr(k) + pr(k).*(1 - sdr(k));
k2 = ~m; p_sell(k2) = ft(k2); p_buy(k2) = pr(k2);
PR.sdr = sdr; PR.p_sell = p_sell; PR.p_buy = p_buy;
end
