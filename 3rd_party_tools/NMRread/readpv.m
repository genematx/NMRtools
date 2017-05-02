function expt = readpv(dirname,parsin)

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
expt.acqs = readpv_acqs(dirname,pars.acqs);
% if ~isempty(strmatch('Spectroscopic',expt.acqs.pars.acqp.acq_dim_desc)) % Spectroscopic, read as XWinNMR
%     expt.acqs = updatestruct(expt.acqs,readxw_acqs(dirname,pars.acqs));
% end
%% Get experiment information
expt.info = readpv_info(dirname,expt.acqs.pars);
%% Find and read processed data
prcslist = getnumdirlist(prcspath);
for cp = numel(prcslist):-1:1
    expt.prcs(cp) = readpv_prcs(fullfile(prcspath,prcslist{cp}),pars.prcs);
end

%% Terminate
end