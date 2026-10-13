function [pv_spec, poa] = gc_pv_model(ghi, temp, time, P)
% GC_PV_MODEL  Hourly AC yield per kWp from the benchmark GHI and temperature: Spencer solar position,
% Erbs decomposition into beam and diffuse, isotropic transposition to the tilted plane, NOCT cell temperature,
% linear power temperature coefficient, DC loss derate and inverter efficiency.
%
% Part of FairPool Sydney: a cooperative energy pool with optimised shared storage and Shapley
% settlement for the ComErgy benchmark community (entry to the ComErgy Grand Challenge 2026).
% Author: Hammad Masood, Khalifa University of Science and Technology. Licence: MIT (see LICENSE).
% Repository: https://github.com/ED-Hammad/fairpool-sydney-comergy-2026
%
n = numel(ghi); doy = day(time, 'dayofyear'); hr = hour(time) + 0.5;  % mid-hour local standard time
if P.pv.dst  % if the series is in local clock time, clock hours during NSW daylight saving are one hour ahead of standard time
    dst = (time < datetime(P.year, 4, 4, 3, 0, 0)) | (time >= datetime(P.year, 10, 3, 2, 0, 0)); hr(dst) = hr(dst) - 1;  % 2021: AEDT until 4 Apr 03:00 and from 3 Oct 02:00
end
B = 2*pi*(doy - 1)/365;
decl = 0.006918 - 0.399912*cos(B) + 0.070257*sin(B) - 0.006758*cos(2*B) + 0.000907*sin(2*B) - 0.002697*cos(3*B) + 0.00148*sin(3*B);
eot = 229.18*(0.000075 + 0.001868*cos(B) - 0.032077*sin(B) - 0.014615*cos(2*B) - 0.04089*sin(2*B));  % minutes
solar_time = hr + (4*(P.lon - 15*P.tz) + eot)/60; ha = deg2rad(15*(solar_time - 12)); lat = deg2rad(P.lat);
cosz = max(sin(lat).*sin(decl) + cos(lat).*cos(decl).*cos(ha), 0);
I0 = 1367*(1 + 0.033*cos(2*pi*doy/365)).*cosz;
kt = zeros(n,1); m = I0 > 10; kt(m) = min(ghi(m)./I0(m), 1);
fd = ones(n,1);
a = kt <= P.pv.erbs_kt_limits(1); fd(a) = 1 - 0.09*kt(a);
b = kt > P.pv.erbs_kt_limits(1) & kt <= P.pv.erbs_kt_limits(2); fd(b) = 0.9511 - 0.1604*kt(b) + 4.388*kt(b).^2 - 16.638*kt(b).^3 + 12.336*kt(b).^4;
c = kt > P.pv.erbs_kt_limits(2); fd(c) = P.pv.erbs_overcast_fd;
dhi = fd.*ghi; bhi = ghi - dhi; dni = zeros(n,1); dni(m) = bhi(m)./max(cosz(m), P.pv.min_cosz);
beta = deg2rad(P.pv.tilt_deg); gam = deg2rad(P.pv.azimuth_deg); sinz = sqrt(max(1 - cosz.^2, 0));
az = pi - atan2(sin(ha).*cos(decl), cos(ha).*cos(decl).*sin(lat) - sin(decl).*cos(lat));  % from north, east positive
cosaoi = max(cosz.*cos(beta) + sinz.*sin(beta).*cos(az - gam), 0);
poa = dni.*cosaoi + dhi.*(1 + cos(beta))/2 + ghi.*P.pv.albedo.*(1 - cos(beta))/2; poa(ghi <= 0) = 0;  % W/m2
tcell = temp + (P.pv.noct - 20)/800 .* poa;
pv_spec = max(poa/1000 .* (1 + P.pv.gamma*(tcell - 25)) * P.pv.derate_dc, 0) * P.pv.eta_inv;  % kWh per kWp per hour
end
