function prcs = readxw_prcs(dirname,prcspars)

%% Initialise
dirname = checkdir(dirname,'Open Bruker process number');
if nargin < 2
    prcspars = struct([]);
end

%% Get parameters
prcs.pars = readxw_prcs_pars(dirname,prcspars);
prcs.axes = readxw_prcs_axes(dirname,prcs.pars);
%% Read processed data
prcsfiles = getfilelist(dirname,'-regexp','^\dr');
if ~isempty(prcsfiles)
    prcs.data = readxw_prcs_data(dirname,prcs.pars.data);
else
    warning('NMRread:FileNotFound','No processed data: ?r* files are missing.')
end
prcs.calcs = readxw_prcs_calcs(dirname);

%% Terminate
end