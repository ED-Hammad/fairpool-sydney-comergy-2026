function CO = gc_coalitions(D, SA, P, method)
% GC_COALITIONS  Value of every one of the 511 coalitions with the same dispatch as the community, exact
% Shapley value, the recommended hybrid rule (Shapley with solidarity share and individual-rationality floor),
% the proportional-to-bill baseline, and, as footnote material only, the nucleolus and the maximum core excess.
%
% Part of FairPool Sydney: a cooperative energy pool with optimised shared storage and Shapley
% settlement for the ComErgy benchmark community (entry to the ComErgy Grand Challenge 2026).
% Author: Hammad Masood, Khalifa University of Science and Technology. Licence: MIT (see LICENSE).
% Repository: https://github.com/ED-Hammad/fairpool-sydney-comergy-2026
%
n = 9; N = 2^n - 1; mask = fliplr(dec2bin(1:N, n) == '1'); sz = sum(mask, 2);
v = zeros(N,1); cost = zeros(N,1); fee = P.fee_conn_day*365 + P.fee_operator_year; tS = tic;
for s = 1:N
    idx = find(mask(s,:)); k = numel(idx); L = sum(D.load(:,idx), 2); G = sum(D.pv(:,idx), 2); E = sum(D.bat_kwh(idx)); Pk = sum(D.bat_kw(idx));
    if strcmp(method, 'lp'), R = gc_dispatch_lp(L, G, E, Pk, D.price, D.fit, P); else, R = gc_dispatch_rule(L, G, E, Pk, D.price, D.fit, P); end
    cost(s) = R.cost_energy + k*fee; v(s) = sum(SA.bill(idx)) - cost(s);
    if mod(s, 64) == 0, fprintf('  coalition %d/%d  (%.0f s)\n', s, N, toc(tS)); end
end
CO.mask = mask; CO.v = v; CO.cost = cost; CO.size = sz; CO.method = method; CO.vN = v(N);
phi = zeros(n,1);  % exact Shapley value
for i = 1:n
    for s = 1:N, if ~mask(s,i), k = sz(s); phi(i) = phi(i) + factorial(k)*factorial(n-k-1)/factorial(n)*(v(s + 2^(i-1)) - v(s)); end, end
    phi(i) = phi(i) + factorial(n-1)/factorial(n)*v(2^(i-1));  % empty-set term
end
assert(abs(sum(phi) - v(N)) < 1e-6, 'Shapley efficiency check failed'); CO.shapley = phi;
CO.excess = @(x) max(v(1:N-1) - mask(1:N-1,:)*x);  % footnote: largest gain any subgroup could obtain by leaving
CO.nucleolus = gc_nucleolus(v, mask, n);  % footnote: core-stable alternative
CO.prop_bill = v(N)*SA.bill/sum(SA.bill);  % baseline: same percentage saving for everyone
low = D.income < P.alloc.income_threshold; sol = P.alloc.solidarity_share*v(N); hyb = (1 - P.alloc.solidarity_share)*phi;
CO.solidarity = zeros(n,1); if any(low), CO.solidarity(low) = sol/sum(low); end
hyb = hyb + CO.solidarity;
neg = hyb < 0; if any(neg), hyb(neg) = 0; pos = hyb > 0; hyb(pos) = hyb(pos)*(v(N)/sum(hyb(pos))); end  % individual-rationality floor
CO.hybrid = hyb; CO.low_income = low;
end

function x = gc_nucleolus(v, mask, n)
N = 2^n - 1; A = double(mask(1:N-1,:)); b = v(1:N-1); fixed = false(N-1,1); eqA = ones(1,n); eqb = v(N); opt = optimoptions('linprog', 'Display', 'none'); x = [];
for it = 1:n
    free = ~fixed; nf = sum(free); if nf == 0, break; end
    [z, ~, flag] = linprog([zeros(n,1); -1], [-A(free,:), ones(nf,1)], -b(free), [eqA, zeros(size(eqA,1),1)], eqb, [], [], opt);
    assert(flag == 1, 'nucleolus LP failed at stage %d', it); x = z(1:n); eps = z(n+1);
    ex = A(free,:)*x - b(free); tight = find(free); tight = tight(abs(ex - eps) < 1e-7); if isempty(tight), break; end
    fixed(tight) = true; eqA = [eqA; A(tight,:)]; eqb = [eqb; b(tight) + eps]; if rank(eqA) >= n, break; end
end
end
