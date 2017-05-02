function lists = readpv_prcs_axes(dirname,prcspars)

%% Initialise
dirname = checkdir(dirname,'Open Bruker process number');
if (nargin < 2)||isempty(prcspars)
    prcspars = readpv_prcs_pars(dirname);
end

%% Generate frequency and shift axes
lists = readxw_prcs_axes(dirname,prcspars); % Start like XWinNMR; reads in lists as well
if isempty(lists)
    clear lists
end
%% Generate image axes
for cdim = 1:numel(prcspars.reco.reco_size)
    dimname = ['position',strtrim(num2str(cdim))]; %['position',strtrim(num2str(prcspars.data.dataorder(cdim,1)))];
    nmax = prcspars.data.datasize(1,cdim)/2;
    lists.(dimname) = (prcspars.reco.reco_fov(prcspars.data.dataorder(1,cdim))).*(-nmax:(nmax - 1))./(prcspars.data.datasize(1,cdim)); % cm
end

%% Terminate
end