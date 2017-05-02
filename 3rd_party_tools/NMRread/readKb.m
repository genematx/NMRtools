function data = readKb(filepath,parsin)
% Read Kblock format

%% Initialise
pars = checkin(parsin,...
    {'storesize','storeorder','datatype','iscomplex','byteswap','zerofill'},...
    {[],[],'int32',false,false,[]});

%% Parse parameters
if pars.byteswap
    byteformat = 'ieee-be'; % IEEE Big-Endian (can use 'b' instead)
else
    byteformat = 'ieee-le'; % IEEE Little-Endian (can use 'l' instead)
end
bytesize = numbytes(pars.datatype);
sizein = [pars.storesize(1),prod(pars.storesize(2:end))];
datatype = ['*',pars.datatype];

%% Read in file.
fileid = fopen(filepath,'r',byteformat); % Alternatively, byteformat can be supplied to fread
if isempty(pars.zerofill) % Read and strip padded zeros
    data = fread(fileid,sizein,datatype);
    data = data(any(data,2),:);
elseif pars.zerofill == 0 % No zero padding to remove
    data = fread(fileid,sizein,datatype);
else % Omit reading the zeros, given the amount of padding
    sizein(1) = sizein(1) - pars.zerofill;
    data = fread(fileid,sizein,[strtrim(num2str(sizein(1))),datatype],bytesize*pars.zerofill);
end
fclose(fileid);
%% Reorganise data
if pars.iscomplex % Combine interleaved real and imaginary parts
    sizein(1) = sizein(1)/2; % Number of complex points in direct dimension
    realdata = data(1:2:end,:);
    imagdata = data(2:2:end,:);
    data = complex(realdata,imagdata);
    clear realdata imagdata
%     data = reshape(data,[2,sizein]);
%     data = complex(data(1,:,:),data(2,:,:));
end
if length(pars.storesize) > 1
    data = reshape(data,[sizein(1),pars.storesize(2:end)]);
else
    data = data(:);
end
if length(pars.storeorder) > 1
    data = ipermute(data,pars.storeorder);
end

%% Terminate, nested functions
    function bytes = numbytes(dataclass)
        scalar = zeros(1,dataclass);
        scalarinfo = whos('scalar');
        bytes = scalarinfo.bytes;
    end
end
