function SA = gc_standalone(D, P)
% GC_STANDALONE  Counterfactual: each household alone with its own PV and battery, rule dispatch, no exchange,
% no grid charging, benchmark tariff and FiT, connection fee. Also the no-DER bill as context.
%
% Part of FairPool Sydney: a cooperative energy pool with optimised shared storage and Shapley
% settlement for the ComErgy benchmark community (entry to the ComErgy Grand Challenge 2026).
% Author: Hammad Masood, Khalifa University of Science and Technology. Licence: MIT (see LICENSE).
% Repository: https://github.com/USERNAME/fairpool-sydney-comergy-2026
%
n = D.n; fee = P.fee_conn_day*365; SA.bill = zeros(9,1); SA.bill_noder = zeros(9,1);
SA.imp = zeros(n,9); SA.exp = zeros(n,9); SA.dis = zeros(n,9);
for i = 1:9
    R = gc_dispatch_rule(D.load(:,i), D.pv(:,i), D.bat_kwh(i), D.bat_kw(i), D.price, D.fit, P);
    SA.bill(i) = R.cost_energy + fee; SA.imp(:,i) = R.imp; SA.exp(:,i) = R.exp; SA.dis(:,i) = R.dis;
    SA.bill_noder(i) = sum(D.price.*D.load(:,i)) + fee;
end
SA.peak_imp = max(SA.imp)';
end
