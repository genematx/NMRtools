function info = readxw_info(dirname,acqspars)

%% Initialise
dirname = checkdir(dirname,'Open Bruker experiment number');
if (nargin < 2)||isempty(acqspars)
    acqspars = readxw_acqs_pars(dirname);
end

%% Read audita.txt
warning off MATLAB:textscan:SkipComments
audita = readdx(fullfile(dirname,'audita.txt'));
warning on MATLAB:textscan:SkipComments
%% User, dataset, experiment number
info.user = audita.info.owner;
% info.user = regexprep(audita.audit_trail{1,3},'<|>','');
[pathstr,exptstr] = fileparts(dirname);
[pathstr,info.dataset] = fileparts(pathstr);
info.expt = exptstr; % strtrim(num2str(audita.audit_trail{1}));
%% Spectrometer, software
soft = regexp(audita.info.title,'Audit trail, (\S+)\s+Version (\S+)','Tokens');
soft = horzcat(soft{:});
if strcmp(soft{1},'TOPSPIN')
    info.software = 'Topspin';
else
    info.software = 'XWinNMR';
end
info.software = [info.software,' ',soft{2}];
nucleus1 = regexprep(acqspars.acqus(1).nuc1,'<|>','');
gammabar1 = gmr(nucleus1,true);
larmor1 = acqspars.acqus(1).bf1;
info.field = (larmor1.*1e6)./gammabar1;
info.H1freq = gmr('H1',true).*(info.field)./1e6;
%% Acquisition parameters
info.nucleus = nucleus1;
info.nucfreq = larmor1;
info.sequence = regexprep(acqspars.acqus(1).pulprog,'<|>','');
info.acqsdims = acqspars.acqus(1).parmode + 1;
info.acqssize = acqspars.data.datasize;
info.acqsdate = acqspars.acqus(1).info.file.date;

%% Terminate
end