function info = readpv_info(dirname,acqspars)

%% Initialise
dirname = checkdir(dirname,'Open Bruker experiment number');
if (nargin < 2)||isempty(acqspars)
    acqspars = readpv_acqs_pars(dirname);
end

%% User, dataset, experiment number
info.user = regexprep(acqspars.acqp.acq_operator,'<|>','');
[pathstr,exptstr] = fileparts(dirname);
[pathstr,info.dataset] = fileparts(pathstr);
info.expt = exptstr;
%% Spectrometer, software
info.software = 'Paravision';
gammabar1 = gmr(acqspars.acqp.nuc1,true);
larmor1 = (acqspars.acqp.bf1).*1e6;
info.field = larmor1./gammabar1;
info.H1freq = gmr('H1',true).*(info.field)./1e6;
%% Acquisition parameters
info.sequence = regexprep(acqspars.acqp.pulprog,'<|>','');
info.numdims = acqspars.acqp.acq_dim;
info.acqssize = acqspars.data.datasize;
info.acqsdate = acqspars.acqp.info.file.date;

%% Terminate
end