function pars = readpv_acqs_pars(dirname,acqspars)

%% Initialise
dirname = checkdir(dirname,'Open Bruker experiment number');
if nargin < 2
    acqspars = struct([]);
end

%% Read parameters
pars = readbrukerpars({'acqu','acqus','acqp','imnd'},dirname);
if (exist(fullfile(dirname,'cag_pars'),'file') == 2)
    pars.cag = readcagpar(fullfile(dirname,'cag_pars'));
end
pars.acqp.acq_trim = circshift(pars.acqp.acq_trim,[0,-1]);
%% Override parameters
if ~isempty(acqspars)
    pars = updatestruct(pars,acqspars);
end
%% Parse parameters
pars.data.dirname = dirname;
pars.data.iscomplex = true;
numdims = pars.acqp.acq_dim;
isKblock = strcmp(pars.acqp.go_block_size,'Standard_KBlock_Format');
isdigital = ~isempty(strfind(pars.acqp.digmod,'digital'));
if isfield(pars.acqp,'acq_word_size');
    blocksize = 1024*8/str2double(regexprep(pars.acqp.acq_word_size,'\D','')); % Number of data in a 1Kb block, typically 256 (i.e. 128 complex)
else
    blocksize = 256;
end
pars.data.byteswap = ~strcmp(pars.acqp.bytorda,'little');
switch pars.acqp.go_raw_data_format
    case 'GO_8BIT_UNSGN_INT'
        pars.data.datatype = 'uint8';
    case 'GO_16BIT_SGN_INT'
        pars.data.datatype = 'int16';
    case 'GO_32BIT_SGN_INT'
        pars.data.datatype = 'int32';
    case 'GO_32BIT_FLOAT'
        pars.data.datatype = 'float32'; % single precision
end
pars.data.scansize = pars.acqp.acq_scan_size;
if isdigital&&(pars.acqp.acq_scan_shift > 0) % Unlikely case
    if isfield(pars.acqp,'grpdly')
        pars.data.directshift = -pars.acqp.grpdly;
    elseif strcmp(pars.acqp.aq_mod,'qdig')
        pars.data.directshift = -brukergroupdelay(pars.acqp.decim,12);
    else
        pars.data.directshift = -brukergroupdelay(pars.acqp.decim,pars.acqp.dspfvs); % This line alone would probably work - the surrounding if block shouldn't be necessary
    end
else % Expect shift to be done by Paravision already
    pars.data.directshift = 0;
end
pars.data.datasize = [pars.acqp.acq_size,pars.acqp.ni,pars.acqp.nr];
if isKblock  % Direct dimension starts on 1 Kb boundaries in fid/ ser file
    pars.data.zerofill = mod(blocksize - rem(pars.data.datasize(1),blocksize),blocksize); % N.B Real and imaginary points separate
else
    pars.data.zerofill = 0;
end
pars.data.rarefactor = pars.acqp.acq_rare_factor; % Increment in phase list
pars.data.phasefactor = pars.acqp.acq_phase_factor; % Number of consecutive phase steps acquired per object
if numdims == 1 % Separate real and imaginary points + zero filling, NI, NR
    pars.data.storesize = [pars.data.datasize(1) + pars.data.zerofill,pars.data.datasize(2:end)];
    pars.data.storeorder = 1:3;
else % Separate real and imaginary points + zero filling, phase factor, NI, phase factor blocks, NR
    pars.data.storesize = [pars.data.datasize(1) + pars.data.zerofill,pars.data.phasefactor,...
        pars.data.datasize(end - 1),prod(pars.data.datasize(2:numdims))./(pars.data.phasefactor),...
        pars.data.datasize(end)];
    pars.data.storeorder = [1,2,4,3,5];
end
pars.data.datasize(1) = pars.data.datasize(1)./2; % Number of complex points in direct dimension
pars.data.objectorder = pars.acqp.acq_obj_order + 1; % Order of the NI objects
for cdim = numdims:-1:1
    k = linspace(-1,1,pars.data.datasize(cdim) + 1);
    if strcmp(pars.acqp.acq_dim_desc{cdim},'Spatial')&&(pars.data.datasize(cdim) > 1)
        startidx = find((k(1:(end - 1)) > pars.acqp.acq_phase_enc_start(cdim) - eps),1,'first'); % '> ... - eps' works better for fractions and recurring decimals than '>='
        switch pars.acqp.acq_phase_encoding_mode{cdim}
            case 'Read'
                [pars.data.phaseorder{cdim},pars.data.phaseencode{cdim}] = linearorder(pars.data.datasize(cdim),1,pars.data.datasize(cdim));
            case 'Linear'
                [pars.data.phaseorder{cdim},pars.data.phaseencode{cdim}] = linearorder(pars.data.datasize(cdim),startidx,pars.data.phasefactor);
            case 'Centred'
                [pars.data.phaseorder{cdim},pars.data.phaseencode{cdim}] = centreorder(pars.data.datasize(cdim),startidx,pars.data.phasefactor);
            case 'Rare'
                [pars.data.phaseorder{cdim},pars.data.phaseencode{cdim}] = rareorder(pars.data.datasize(cdim),startidx,pars.data.phasefactor,pars.data.rarefactor);
            otherwise % User-defined
                if pars.acqp.(strcat('acq_spatial_size_',strtrim(num2str(cdim - 1)))) == pars.data.datasize(cdim)
                    [pars.data.phaseorder{cdim},pars.data.phaseencode{cdim}] = userorder(cdim,pars.acqp.acq_phase_enc_start(cdim),pars.data.phasefactor);
                else % Inconsistent, assume linear
                    [pars.data.phaseorder{cdim},pars.data.phaseencode{cdim}] = linearorder(pars.data.datasize(cdim),startidx,pars.data.phasefactor);
                end
        end
    else
        pars.data.phaseencode{cdim} = k(1:(end - 1));
        pas.data.phaseorder{cdim} = 1:numel(pars.data.phaseencode);
    end
end

%% Terminate, nested functions
    function [order,encode] = linearorder(dimsize,start,phasefactor)
        order = [start:dimsize,1:(start - 1)]; % numel(order) == dimsize
        order = reshape(order,phasefactor,[]); % size(order,1) == phasefactor
        encode = k(order);
        encode = reshape(encode,size(order));
    end
    function [order,encode] = centreorder(dimsize,start,phasefactor)
        order = [start:-1:1,dimsize:-1:(start + 1)]; % numel(order) == dimsize
        halfsize = floor(dimsize./2);
        neworder = order([1:halfsize;dimsize:-1:(dimsize - halfsize + 1)]); % numel(order) == dimsize
        order = [neworder(:).',order((halfsize + 1):(dimsize - halfsize))]; % only neworder contributes if dimsize is even
        order = reshape(order,phasefactor,[]); % size(order,1) == phasefactor
        encode = k(order);
        encode = reshape(encode,size(order));
    end
    function [order,encode] = rareorder(dimsize,start,phasefactor,rarefactor)
        order = [start:dimsize,1:(start - 1)];
        order = reshape(order,[],rarefactor); % phase increments are across the columns (dimension 2)
        remainder = rem(rarefactor,phasefactor); % in some cases the final phase factor acquisition are just the remaining phase encodings (not rare factor incremented)
        divisor = (rarefactor - remainder)./phasefactor; % integer division
        numrows = size(order,1);
        numcols = nonzeros([repmat(phasefactor,1,divisor),remainder]); % remainder does not contribute if phasefactor is a factor of rarefactor; sum(numcols) == rarefactor
        subarrays = mat2cell(order,numrows,numcols); % cells containing adjacent subarrays (each of numrows rows) from order
        subarrays = cellfun(@(c) reshape(c,[],phasefactor),subarrays,'UniformOutput',false); % rearrange each subarray to have same number of columns
        order = cell2mat(subarrays.').'; % restack subarrays; size(order,1) == phasefactor
        encode = k(order);
        encode = reshape(encode,size(order));
    end
    function [order,encode] = userorder(dim,startval,phasefactor)
        encode = pars.acqp.(strcat('acq_spatial_phase_',strtrim(num2str(dim - 1))));
%         start = find(encode == startval,1,'first'); % '> ... - eps' works better for fractions and recurring decimals than '>='
%         encode = encode([start:end,1:(start - 1)]);
        [tmp,order] = sort(encode);
        [tmp,order] = sort(order);
        order = reshape(order,phasefactor,[]); % size(order,1) == phasefactor
        encode = reshape(encode,phasefactor,[]); % size(encode,1) == phasefactor
    end
end