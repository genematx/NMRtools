function data = readpv_acqs_data(dirname,datapars)

%% Initialise
dirname = checkdir(dirname,'Open Bruker experiment number');
if nargin < 2
    datapars = readpv_acqs_pars(dirname);
    datapars = datapars.data;
end
pars = checkin(datapars,...
    {'phaseorder','objectorder','directshift','datasize','storesize','storeorder','datatype','iscomplex','byteswap','zerofill'},...
    {[],[],[],[],[],[],'int32',false,false,[]});

%% Parse parameters
filepath = fullfile(dirname,'ser');
if (exist(filepath,'file') == 0)
    filepath = fullfile(dirname,'fid');
end
numobjectdims = numel(pars.phaseorder);

%% Read in data
data = readKb(filepath,pars);
%% Reorganise data
if ~isempty(pars.directshift) % Circular shift for filter group delay
    data = circshift(data,[ceil(pars.directshift),zeros(1,ndims(data) - 1)]);
end
if length(pars.datasize) > 1 % Reshape to output size
    data = reshape(data,pars.datasize);
end
numdatadims = ndims(data); % Should be greater than numobjectdims
for cdim = 2:numobjectdims
    if ~issorted(pars.phaseorder{cdim}(:))
        data = reorder(data,pars.phaseorder{cdim},cdim);
    end
end
if (~isempty(pars.objectorder))&&(numobjectdims < numdatadims) % Reorder object (NI) dimension
    objectdim = max(numobjectdims + 1,numdatadims - 1); % Typically the penultimate dimension
    data = reorder(data,pars.objectorder,objectdim);
end

%% Terminate
data = single(data);
end