function D = gc_load_data(P)
% GC_LOAD_DATA  Read the benchmark workbook, build the 2021 calendar, derive member assets, compute PV, write CSV twins.
%
% Part of FairPool Sydney: a cooperative energy pool with optimised shared storage and Shapley
% settlement for the ComErgy benchmark community (entry to the ComErgy Grand Challenge 2026).
% Author: Hammad Masood, Khalifa University of Science and Technology. Licence: MIT (see LICENSE).
% Repository: https://github.com/USERNAME/fairpool-sydney-comergy-2026
%
M = readmatrix(P.src_xlsx, 'Sheet', 'ComErgy Benchmark Dataset 2026', 'Range', 'A3:M8762');
assert(size(M,1) == 8760 && ~any(isnan(M(:))), 'benchmark block must be 8760 x 13 without gaps');
D.load = M(:,1:9) * P.load_scale; D.price = M(:,10) * P.price_scale; D.fit = M(:,11) * P.fit_scale; D.temp = M(:,12); D.ghi = M(:,13);
D.n = 8760; D.nh = 9;
t0 = datetime(P.year, 1, 1, 0, 0, 0); D.time = t0 + hours(0:D.n-1)';
D.hour = hour(D.time); D.month = month(D.time); D.weekend = isweekend(D.time);
assert(~any(D.price > 0.5 & D.weekend), 'tariff calendar check: no 0.55 peak expected at weekends under the 2021 calendar');
C = readcell(P.src_xlsx, 'Sheet', 'ComErgy Benchmark Dataset 2026', 'Range', 'P9:T17');  % members 1 to 9
D.member = (1:9)'; D.pv_modules = zeros(9,1); D.bat_modules = zeros(9,1); D.income = zeros(9,1); D.occupants = zeros(9,1); D.htype = strings(9,1);
for i = 1:9
    s = char(string(C{i,2}));
    tok = regexp(s, '(\d+)\s*PV', 'tokens', 'once'); if ~isempty(tok), D.pv_modules(i) = str2double(tok{1}); end
    tok = regexp(s, '(\d+)\s*battery', 'tokens', 'once'); if ~isempty(tok), D.bat_modules(i) = str2double(tok{1}); end
    D.htype(i) = strtrim(string(C{i,3}));
    tok = regexp(char(string(C{i,4})), '(\d+)\s*people', 'tokens', 'once'); D.occupants(i) = str2double(tok{1});
    tok = regexp(char(string(C{i,5})), '([\d,]+)', 'tokens', 'once'); D.income(i) = str2double(strrep(tok{1}, ',', ''));
end
assert(sum(D.pv_modules) == 112 && sum(D.bat_modules) == 14, 'side-table parse check: 112 PV and 14 battery modules expected');
D.pv_kwp = D.pv_modules * P.pv.module_kw; D.bat_kwh = D.bat_modules * P.bat.module_kwh; D.bat_kw = D.bat_kwh * P.bat.c_rate;
[D.pv_spec, D.poa] = gc_pv_model(D.ghi, D.temp, D.time, P);  % kWh per kWp per hour (AC)
D.pv = zeros(D.n, 9);
for i = 1:9, D.pv(:,i) = min(D.pv_spec * D.pv_kwp(i), D.pv_kwp(i) / P.pv.dc_ac_ratio) * P.pv_scale; end  % inverter clipping
D.ef = P.ef.flat_kg_per_kwh * ones(D.n, 1);  % flat grid emission factor
if isfield(P, 'write_csv') && ~P.write_csv, return; end
T = table(D.time, D.load(:,1), D.load(:,2), D.load(:,3), D.load(:,4), D.load(:,5), D.load(:,6), D.load(:,7), D.load(:,8), D.load(:,9), D.price, D.fit, D.temp, D.ghi, D.pv_spec, ...
    'VariableNames', {'time','L1','L2','L3','L4','L5','L6','L7','L8','L9','price','fit','temp_C','ghi','pv_kwh_per_kwp'});
writetable(T, fullfile(P.data_dir, 'benchmark_hourly_2021.csv'));
Tm = table(D.member, D.htype, D.occupants, D.income, D.pv_modules, D.pv_kwp, D.bat_modules, D.bat_kwh, D.bat_kw, ...
    'VariableNames', {'member','household_type','occupants','income_aud','pv_modules','pv_kwp','bat_modules','bat_kwh','bat_kw'});
writetable(Tm, fullfile(P.data_dir, 'members.csv'));
end
