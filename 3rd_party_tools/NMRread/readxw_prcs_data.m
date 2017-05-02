function data = readxw_prcs_data(dirname,datapars)

%% Initialise
dirname = checkdir(dirname,'Open Bruker process number');
if nargin < 2
    datapars = readxw_prcs_pars(dirname);
    datapars = datapars.data;
end
pars = checkin(datapars,...
    {'storesize','storeorder','datasize','dataorder','datatype','byteswap','scale'},...
    {[],{},[],[],'int32',false,1});
if isempty(pars.storesize)
    numdims = size(pars.datasize,2); % Length should be at most 2
else
    numdims = size(pars.storesize);
    if numdims(1) == 1
        pars.storesize = [pars.storesize;pars.datasize(1:numdims(end))];
    end
    numdims = numdims(end);
end

%% Parse parameters
realfilename = [strtrim(num2str(numdims)),repmat('r',1,numdims)];
imagfile = dir(fullfile(dirname,[realfilename(1),'*i*'])); % Should be at most 1 file
if isempty(imagfile)
    imagfilename = '';
else % Complex data
    imagfilename = imagfile(1).name;
end
arraysize = prod(pars.storesize,2).'; % [length,number] of subarrays
if pars.byteswap
    byteformat = 'ieee-be'; % IEEE Big-Endian (can use 'b' instead)
else
    byteformat = 'ieee-le'; % IEEE Little-Endian (can use 'l' instead)
end
datatype = ['*',pars.datatype];
%% Read in data
fileid = fopen(fullfile(dirname,realfilename),'r',byteformat);
data = fread(fileid,arraysize,datatype);
fclose(fileid);
if pars.iscomplex&&~isempty(imagfilename) % Read imaginary part
    fileid = fopen(fullfile(dirname,imagfilename),'r',byteformat);
    data = complex(data,fread(fileid,arraysize,datatype));
    fclose(fileid);
end

%% Reorganise subarrays
if numdims > 1
    data = num2cell(data,1); % Split data into cells, each containing a subarray
    data = cellfun(@(c) reshape(c,pars.storesize(1,:)),data,'UniformOutput',false); % Reshape each subarray
    data = reshape(data,pars.storesize(2,:)); % Arrange subarrays
    data = cell2mat(data); % Merge into single array; size(data) == pars.datasize
else
    data = data(:); % Unfold/ stack subarrays as a vector
end
for cdim = 1:numel(pars.storeorder)
    data = reorder(data,pars.storeorder{cdim},cdim);
end
if length(pars.dataorder) > 1
    data = ipermute(data,pars.dataorder);
end
%% Map data
data = single(data);
data = data.*(pars.scale); % Rescale (map data)

%% Terminate
end