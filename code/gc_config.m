function P = gc_config(scenario, xlsxfile)
% GC_CONFIG  Parameter structure, read from data/GC_inputs.xlsx.
% Paths and the run tag are set here; every tunable value comes from sheet Parameters, then the overrides
% of the chosen row of sheet Scenarios are applied. Parsing: 'true'/'false' -> logical; numbers, Inf and
% [vectors] -> numeric; 'a;b;c' -> cell array of char; otherwise char.
%
% Part of FairPool Sydney: a cooperative energy pool with optimised shared storage and Shapley
% settlement for the ComErgy benchmark community (entry to the ComErgy Grand Challenge 2026).
% Author: Hammad Masood, Khalifa University of Science and Technology. Licence: MIT (see LICENSE).
% Repository: https://github.com/USERNAME/fairpool-sydney-comergy-2026
%
if nargin < 1 || isempty(scenario), scenario = 'Base'; end
P.build_root = fileparts(fileparts(mfilename('fullpath')));  % repository folder
P.src_xlsx = fullfile(P.build_root, 'data', 'ComErgy Benchmark Dataset 2026.xlsx');
P.data_dir = fullfile(P.build_root, 'data'); P.res_dir = fullfile(P.build_root, 'results'); P.fig_dir = fullfile(P.build_root, 'figures');
if nargin < 2, xlsxfile = fullfile(P.data_dir, 'GC_inputs.xlsx'); end  % inputs workbook
assert(isfile(xlsxfile), 'inputs workbook not found: %s', xlsxfile);
T = readtable(xlsxfile, 'Sheet', 'Parameters', 'TextType', 'string');
for r = 1:height(T)
    name = strtrim(T.parameter(r)); if strlength(name) == 0, continue; end
    P = gc_setpath(P, char(name), gc_parse(T.value(r)));
end
if ~strcmpi(scenario, 'Base')
    S = readtable(xlsxfile, 'Sheet', 'Scenarios', 'TextType', 'string');
    row = find(strcmpi(strtrim(S.scenario), scenario), 1); assert(~isempty(row), 'scenario %s not found', scenario);
    ov = strtrim(S.overrides(row));
    if strlength(ov) > 0
        items = strsplit(char(ov), ';');
        for k = 1:numel(items), kv = strsplit(strtrim(items{k}), '='); if numel(kv) == 2, P = gc_setpath(P, strtrim(kv{1}), gc_parse(string(strtrim(kv{2})))); end, end
    end
end
P.scenario = scenario; P.inputs_file = xlsxfile; P.dt = 1;  % hourly data
if isfield(P, 'out') && isfield(P.out, 'subdir') && ~isempty(P.out.subdir)  % optional sub-folders for results and figures
    P.res_dir = fullfile(P.res_dir, P.out.subdir); P.fig_dir = fullfile(P.fig_dir, P.out.subdir);
    if ~exist(P.res_dir, 'dir'), mkdir(P.res_dir); end; if ~exist(P.fig_dir, 'dir'), mkdir(P.fig_dir); end
end
if ~isfield(P.pv, 'dst'), P.pv.dst = false; end  % daylight-saving alignment of the solar position (optional)
P.run_tag = [datestr(now, 'yyyymmdd_HHMMSS') '_' regexprep(scenario, '[^A-Za-z0-9]', '')];
assert(strcmp(P.alloc.coalition_method, P.disp.method), 'alloc.coalition_method must equal disp.method');
end

function v = gc_parse(s)
if ismissing(s) || strlength(s) == 0, v = ''; return; end  % blank cell
s = strtrim(char(s)); if isempty(s), v = ''; return; end
if strcmpi(s, 'true'), v = true; return; end; if strcmpi(s, 'false'), v = false; return; end
if contains(s, ';') && ~startsWith(s, '['), v = cellfun(@strtrim, strsplit(s, ';'), 'UniformOutput', false); return; end
[num, ok] = str2num(s); %#ok<ST2NM>
if ok && isnumeric(num) && ~isempty(num), v = num; else, v = s; end
end

function P = gc_setpath(P, name, v)
parts = strsplit(name, '.'); P = setfield(P, parts{:}, v);
end
