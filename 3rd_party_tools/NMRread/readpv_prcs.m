function prcs = readpv_prcs(dirname,prcspars)

%% Initialise
dirname = checkdir(dirname,'Open Bruker process number');
if nargin < 2
    prcspars = struct([]);
end

%% Get parameters
prcs.pars = readpv_prcs_pars(dirname,prcspars);
prcs.axes = readpv_prcs_axes(dirname,prcs.pars);
%% Read processed data
prcsfile = fullfile(dirname,'2dseq');
if (exist(prcsfile,'file') == 2);
    prcs.data = readpv_prcs_data(dirname,prcs.pars.data);
else
    warning('NMRread:FileNotFound','No processed data: %s is missing.',prcsfile)
end

%% Terminate
end