function data = readxw_acqs_data(dirname,datapars)

%% Initialise
dirname = checkdir(dirname,'Open Bruker experiment number');
if nargin < 2
    datapars = readxw_acqs_pars(dirname);
    datapars = datapars.data;
end
pars = checkin(datapars,...
    {'directshift','datasize','storesize','storeorder','datatype','iscomplex','byteswap','zerofill'},...
    {[],[],[],[],'int32',false,false,[]});

%% Parse parameters
filepath = fullfile(dirname,'ser');
if (exist(filepath,'file') == 0)
    filepath = fullfile(dirname,'fid');
end
%% Read in data
data = readKb(filepath,pars);
%% Reorganise data
if ~isempty(pars.directshift) % Circular shift for filter group delay
    cshift = sign(pars.directshift)*ceil(abs(pars.directshift));
    data = circshift(data,[cshift,zeros(1,ndims(data) - 1)]);
end
if length(pars.datasize) > 1 % Reshape to output size
    data = reshape(data,pars.datasize);
end
if length(pars.dataorder) > 1 % Permute to output shape
    data = ipermute(data,pars.dataorder);
end

%% Terminate
data = single(data);
end