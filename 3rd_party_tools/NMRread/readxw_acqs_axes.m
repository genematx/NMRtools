function lists = readxw_acqs_axes(dirname,acqspars,listnames,rampnames)

%% Initialise
dirname = checkdir(dirname,'Open Bruker experiment number');
if nargin < 4
    rampnames = getfilelist(dirname,'','*ramp*');
%     rampnames = {'diff_ramp','ramp_up','ramp_down','rampup','rampdown'};
    if nargin < 3
        listnames = getfilelist(dirname,'','*list');
%         listnames = {'vdlist','vclist','valist','difflist',...
%             'fq1list','fq2list','fq3list','fq4list','fq5list','fq6list','fq7list','fq8list'};
    end
    if (nargin < 2)||isempty(acqspars)
        acqspars = readxw_acqs_pars(dirname);
    end
end

%% Read available lists
lists = readlist(listnames,dirname);
ramps = readstruct(@readdx,rampnames,dirname);
lists = updatestruct(lists,ramps);
%% Generate time axes
if isfield(acqspars,'acqus')
    lists.time1 = (0:((acqspars.acqus(1).td)/2 - 1))./(acqspars.acqus(1).sw_h);
    for cdim = 2:numel(acqspars.acqus)
        dimname = ['time',strtrim(num2str(cdim))];
        lists.(dimname) = (0:(acqspars.acqus(cdim).td - 1))./(acqspars.acqus(cdim).sw_h);
    end
end

%% Terminate
end