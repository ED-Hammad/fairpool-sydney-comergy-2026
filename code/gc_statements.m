function gc_statements(D, SA, CO, K, P, tag)
% GC_STATEMENTS  One-page annual statement per household (Markdown): stand-alone bill, pooled share, saving,
% what the household contributed, and its Shapley share in words. Written to results/statements_<tag>/member_<i>.md.
%
% Part of FairPool Sydney: a cooperative energy pool with optimised shared storage and Shapley
% settlement for the ComErgy benchmark community (entry to the ComErgy Grand Challenge 2026).
% Author: Hammad Masood, Khalifa University of Science and Technology. Licence: MIT (see LICENSE).
% Repository: https://github.com/ED-Hammad/fairpool-sydney-comergy-2026
%
outdir = fullfile(P.res_dir, ['statements_' tag]); if ~exist(outdir, 'dir'), mkdir(outdir); end
vN = CO.vN; n = 9; sur = max(D.pv - D.load, 0); def = max(D.load - D.pv, 0);
names = {'Member 1','Member 2','Member 3','Member 4','Member 5','Member 6','Member 7','Member 8','Member 9'};
for i = 1:n
    g = CO.hybrid(i); settled = SA.bill(i) - g; rel = g/SA.bill(i); shap = CO.shapley(i); sol = CO.solidarity(i);
    pv_i = sum(D.pv(:,i)); load_i = sum(D.load(:,i)); surplus_i = sum(sur(:,i)); deficit_i = sum(def(:,i));
    fid = fopen(fullfile(outdir, sprintf('member_%d.md', i)), 'w', 'n', 'UTF-8');
    fprintf(fid, '# Annual energy statement: %s\n\n', names{i});
    fprintf(fid, 'Community energy pool, benchmark year (%d). Household: %s (%d occupants).\n\n', P.year, regexprep(char(D.htype(i)), '[\s\.]+$', ''), D.occupants(i));
    fprintf(fid, '## Your bill\n\n| Item | AUD per year |\n|---|---|\n');
    fprintf(fid, '| Bill with no solar or battery (for context) | %.0f |\n', SA.bill_noder(i));
    fprintf(fid, '| Bill on your own, with your own solar and battery (your guaranteed ceiling) | %.0f |\n', SA.bill(i));
    fprintf(fid, '| Your share of the pooled community bill | %.0f |\n', settled);
    fprintf(fid, '| **Your saving from the pool** | **%.0f (%.0f %% of your own bill)** |\n\n', g, 100*rel);
    fprintf(fid, 'Guarantee: your pooled share can never exceed the bill you would pay on your own. The community as a whole saved %.0f AUD this year (%.1f %% of what the nine households would have paid separately).\n\n', vN, 100*vN/sum(SA.bill));
    fprintf(fid, '## What you contributed\n\n| Contribution | Amount |\n|---|---|\n');
    fprintf(fid, '| Solar installed | %.1f kWp (%d modules), producing %.0f kWh |\n', D.pv_kwp(i), D.pv_modules(i), pv_i);
    fprintf(fid, '| Solar beyond your own hourly use, offered to the pool | %.0f kWh |\n', surplus_i);
    fprintf(fid, '| Battery capacity placed in the shared store | %.1f kWh (%d modules) |\n', D.bat_kwh(i), D.bat_modules(i));
    fprintf(fid, '| Your electricity use | %.0f kWh, of which %.0f kWh in hours when your own solar could not cover it |\n\n', load_i, deficit_i);
    fprintf(fid, '## How your share was worked out\n\n');
    fprintf(fid, 'Every possible group of households was costed as if it ran its own pool (511 groups). Your fair share is the average amount the saving grew whenever you joined a group, taken over every order in which the community could have formed. That average is %.0f AUD, which is %.1f %% of the community saving (this is the Shapley value).\n\n', shap, 100*shap/vN);
    if sol > 0
        fprintf(fid, 'Because your household income is below the community threshold, you also receive %.0f AUD from the solidarity share (%.0f %% of the community saving set aside for lower-income members). Your total gain is 90 %% of your Shapley share plus this amount.\n\n', sol, 100*P.alloc.solidarity_share);
    else
        fprintf(fid, 'Ten percent of the community saving is set aside for lower-income members; your gain is 90 %% of your Shapley share.\n\n');
    end
    fprintf(fid, 'For comparison, a rule that gives everyone the same percentage saving would give you %.0f AUD.\n\n', CO.prop_bill(i));
    fprintf(fid, '## The community this year\n\nPooled import from the grid %.0f kWh, export %.0f kWh, %.0f %% of solar used locally, %.0f %% of demand met locally, highest hourly draw from the grid %.1f kW (no higher than without the pool).\n', K.import_kwh, K.export_kwh, 100*K.self_consumption, 100*K.self_sufficiency, K.peak_import_kw);
    fclose(fid);
end
end
