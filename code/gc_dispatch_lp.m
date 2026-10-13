function R = gc_dispatch_lp(load, pv, Ekwh, Pkw, price, fit, P, opts)
% GC_DISPATCH_LP  Linear programme for one pooled store: each day a two-day plan is solved (the second day only
% so that energy kept overnight has a use), the first day is committed, and the state of charge is carried over.
% Grid charging optional; import capped at the coalition's own uncoordinated load peak (natural cap) or at an
% explicit value (opts.peak_cap_kw for the cap sweep). Infeasibility is an error, never relaxed.
%
% Part of FairPool Sydney: a cooperative energy pool with optimised shared storage and Shapley
% settlement for the ComErgy benchmark community (entry to the ComErgy Grand Challenge 2026).
% Author: Hammad Masood, Khalifa University of Science and Technology. Licence: MIT (see LICENSE).
% Repository: https://github.com/ED-Hammad/fairpool-sydney-comergy-2026
%
n = numel(load); eta = sqrt(P.bat.eta_rt); Emin = P.bat.soc_min*Ekwh; Emax = P.bat.soc_max*Ekwh;
cap = max(load); if nargin > 7 && isfield(opts, 'peak_cap_kw'), cap = opts.peak_cap_kw; end
if Ekwh <= 0, R = gc_dispatch_rule(load, pv, 0, 0, price, fit, P); return; end
imp = zeros(n,1); expo = zeros(n,1); ch = zeros(n,1); dis = zeros(n,1); S = zeros(n,1); soc = P.bat.soc_init*Ekwh;
lpopt = optimoptions('linprog', 'Display', 'none', 'Algorithm', P.lp.algorithm);
step = 24; ix = @(k,j) (j-1)*5 + k;  % variables per hour: imp exp ch dis soc
for t0 = 1:step:n
    idx = t0:min(t0+2*step-1, n); m = numel(idx); nv = 5*m; L = load(idx); G = pv(idx); pr = price(idx); ft = fit(idx);
    f = zeros(nv,1); lb = zeros(nv,1); ub = inf(nv,1); Aeq = zeros(2*m, nv); beq = zeros(2*m, 1);
    for j = 1:m
        f(ix(1,j)) = pr(j); f(ix(2,j)) = -ft(j); f(ix(4,j)) = P.bat.cycle_cost;
        ub(ix(1,j)) = cap; ub(ix(3,j)) = Pkw; ub(ix(4,j)) = Pkw; lb(ix(5,j)) = Emin; ub(ix(5,j)) = Emax;
        if ~P.disp.grid_charging, ub(ix(3,j)) = min(Pkw, max(G(j) - L(j), 0)); end
        Aeq(j, [ix(1,j) ix(4,j) ix(2,j) ix(3,j)]) = [1 1 -1 -1]; beq(j) = L(j) - G(j);  % balance
        Aeq(m+j, [ix(5,j) ix(3,j) ix(4,j)]) = [1, -eta*P.dt, P.dt/eta];  % SOC recursion
        if j == 1, beq(m+j) = soc; else, Aeq(m+j, ix(5,j-1)) = -1; end
    end
    [x, ~, flag] = linprog(f, [], [], Aeq, beq, lb, ub, lpopt);
    assert(flag == 1, 'LP infeasible or failed at hour %d (flag %d, cap %.2f kW)', t0, flag, cap);
    for j = 1:min(step, m), h = idx(j); imp(h) = x(ix(1,j)); expo(h) = x(ix(2,j)); ch(h) = x(ix(3,j)); dis(h) = x(ix(4,j)); soc = x(ix(5,j)); S(h) = soc; end  % commit the first day only
end
assert(max(abs(pv + imp + dis - load - expo - ch)) < 1e-6, 'hourly energy balance violated in LP dispatch');
assert(all(S >= Emin - 1e-6 & S <= Emax + 1e-6), 'SOC bounds violated in LP dispatch');
R.imp = imp; R.exp = expo; R.ch = ch; R.dis = dis; R.soc = S;
R.cost_energy = sum(price.*imp) - sum(fit.*expo) + P.bat.cycle_cost*sum(dis);
end
