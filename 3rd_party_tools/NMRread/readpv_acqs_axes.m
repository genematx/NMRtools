function lists = readpv_acqs_axes(dirname,acqspars,listnames,rampnames)

%% Initialise
dirname = checkdir(dirname,'Open Bruker experiment number');
if nargin < 4
    rampnames = getfilelist(dirname,'','*ramp*');
    if nargin < 3
        listnames = getfilelist(dirname,'','*list');
    end
    if (nargin < 2)||isempty(acqspars)
        acqspars = readpv_acqs_pars(dirname);
    end
end

%% Generate time axes
lists = readxw_acqs_axes(dirname,acqspars,listnames,rampnames); % Start like XWinNMR; reads in lists as well
if ~isfield(lists,'time1')
    if isempty(lists)
        clear lists
    end
    lists.time1 = (0:((acqspars.acqp.acq_size(1))/2 - 1))./(acqspars.acqp.sw_h);
end
%% Generate k axes
for cdim = 1:numel(acqspars.data.phaseencode)
    dimname = ['k',strtrim(num2str(cdim))];
    nmax = acqspars.data.datasize(cdim)/2;
    lists.(dimname) = (-nmax:(nmax - 1))./(acqspars.acqp.acq_fov(cdim)); % cm^-1
end

%% Terminate
end