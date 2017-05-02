function data = readpv_prcs_data(dirname,datapars)

%% Initialise
dirname = checkdir(dirname,'Open Bruker process number');
if nargin < 2
    datapars = readpv_prcs_pars(dirname);
    datapars = datapars.data;
end
pars = checkin(datapars,...
    {'storesize','datasize','dataorder','datatype','iscomplex','byteswap','slope','offset'},...
    {[],[],[],'int16',false,false,1,0});

%% Parse parameters
filepath = fullfile(dirname,'2dseq');
if pars.byteswap
    byteformat = 'ieee-be'; % IEEE Big-Endian (can use 'b' instead)
else
    byteformat = 'ieee-le'; % IEEE Little-Endian (can use 'l' instead)
end
datatype = ['*',pars.datatype];
arraysize = [mean(prod(pars.storesize,2),1),size(pars.storesize,1)]; % [length,number] of images
%% Read in data
fileid = fopen(filepath,'r',byteformat);
data = fread(fileid,arraysize,datatype);
if pars.iscomplex
    data = complex(data,fread(fileid,arraysize,datatype));
end
fclose(fileid);
%% Map data
if ~isempty(pars.slope)
    data = single(data);
    if isscalar(pars.slope)&&isscalar(pars.offset)
        slope = pars.slope;
        offset = pars.offset;
    else
        slope = repmat(pars.slope(:).',arraysize(1),1);
        offset = repmat(pars.offset(:).',arraysize(1),1);
    end
    data = data./slope + offset;
end
%% Reorganise data
if size(pars.dataorder,1) == 1
    dimorder = pars.dataorder;
    if length(pars.datasize) > 1
        data = reshape(data,pars.storesize);
    end
    data = ipermute(data,dimorder);
else
    dimorder = num2cell(pars.dataorder,2).';
    objsize = num2cell(pars.storesize,2).';
    cellsize = pars.datasize;
    cellsize(1:(end - 2)) = 1;
    data = num2cell(data,1);
    data = cellfun(@reshape,data,objsize,'UniformOutput',false);
    data = cellfun(@ipermute,data,dimorder,'UniformOutput',false);
    data = reshape(data,cellsize);
    data = cell2mat(data);
end
data = squeeze(data);

%% Terminate
end