function K = gc_metrics(R, L, G, Ekwh, D, P)
% GC_METRICS  Community indicators of one dispatch result (trimmed set).
%
% Part of FairPool Sydney: a cooperative energy pool with optimised shared storage and Shapley
% settlement for the ComErgy benchmark community (entry to the ComErgy Grand Challenge 2026).
% Author: Hammad Masood, Khalifa University of Science and Technology. Licence: MIT (see LICENSE).
% Repository: https://github.com/ED-Hammad/fairpool-sydney-comergy-2026
%
K.cost_energy = R.cost_energy; K.import_kwh = sum(R.imp); K.export_kwh = sum(R.exp); K.load_kwh = sum(L); K.pv_kwh = sum(G);
K.self_consumption = 1 - K.export_kwh/max(K.pv_kwh, 1e-9); K.self_sufficiency = 1 - K.import_kwh/K.load_kwh;
K.peak_import_kw = max(R.imp); K.efc = sum(R.dis)/max(P.bat.soc_max - P.bat.soc_min, 1e-9)/max(Ekwh, 1e-9);
K.import_in_peak_window_kwh = sum(R.imp(D.price > 0.5)); K.emissions_kg = sum(D.ef.*R.imp);
end
