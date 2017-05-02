function expt = readxw(dirname,parsin)

%% Initialise
dirname = checkdir(dirname,'Open Bruker experiment number');
if isempty(dirname)
    expt = struct([]);
    return
end
if nargin < 2
    parsin = struct([]);
end
pars = checkin(parsin,...
    {'acqs','prcs'},...
    {struct([]),struct([])});
prcspath = fullfile(dirname,'pdata');

%% Read acquisition data
expt.acqs = readxw_acqs(dirname,pars.acqs);
%% Get experiment information
try
	expt.info = readxw_info(dirname,expt.acqs.pars);
catch

end
%% Find and read processed data
prcslist = getnumdirlist(prcspath);
for cp = numel(prcslist):-1:1
    expt.prcs(cp) = readxw_prcs(fullfile(prcspath,prcslist{cp}),pars.prcs);
end

%% Terminate
end