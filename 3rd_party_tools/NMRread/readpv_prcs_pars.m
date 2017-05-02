function pars = readpv_prcs_pars(dirname,prcspars)

%% Initialise
dirname = checkdir(dirname,'Open Bruker process number');
if nargin < 2
    prcspars = struct([]);
end

%% Read parameters
pars = readbrukerpars({'proc','procs','d3proc','reco'},dirname);
%% Override parameters
if ~isempty(prcspars)
    pars = updatestruct(pars,prcspars);
end
%% Parse parameters
pars.data.dirname = dirname;
transposition = pars.reco.reco_transposition;
recosize = pars.reco.reco_size(:).';
numdims = length(recosize);
numobjs = length(transposition);
numreps = length(pars.reco.reco_globex)./numobjs;
pars.data.iscomplex = strcmp(pars.reco.reco_image_type,'COMPLEX_IMAGE');
pars.data.byteswap = ~strcmp(pars.reco.reco_byte_order,'littleEndian');
switch pars.reco.reco_wordtype
    case '_8BIT_UNSGN_INT'
        pars.data.datatype = 'uint8';
    case '_16BIT_SGN_INT'
        pars.data.datatype = 'int16';
    case '_32BIT_SGN_INT'
        pars.data.datatype = 'int32';
    otherwise % 32 bit float
        pars.data.datatype = 'float';
end
for ct = numobjs:-1:1
    switch transposition(ct)
        case 0
            pars.data.dataorder(ct,:) = 1:numdims;
        case numdims
            pars.data.dataorder(ct,:) = unique([numdims,2:(numdims - 1),1]);
        otherwise
            pars.data.dataorder(ct,:) = [1:(transposition(ct) - 1),transposition(ct) + 1,transposition(ct),(transposition(ct) + 2):numdims];
    end
end
pars.data.datasize = [recosize,numobjs,numreps];
if (numobjs == 1)||isvector(unique(pars.data.dataorder,'rows')) %all(all(diff(pars.data.dataorder,1,2) == 0,2),1)
    pars.data.storesize = [recosize(pars.data.dataorder(1,:)),numobjs,numreps];
    pars.data.dataorder = [pars.data.dataorder(1,:),numdims + [1,2]];
else
    pars.data.storesize = repmat(recosize(pars.data.dataorder),numreps,1);
%     pars.data.storesize(end + 1,:) = numreps;
end
if isfield(pars.reco,'reco_map_slope')
    unq = unique(pars.reco.reco_map_slope);
    if numel(unq) <= 1
        pars.data.slope = unq;
    else
        pars.data.slope = pars.reco.reco_map_slope(:);
    end
    unq = unique(pars.reco.reco_map_offset);
    if numel(unq) <= 1
        pars.data.offset = unq;
    else
        pars.data.offset = pars.reco.reco_map_offset(:);
    end
end

%% Terminate
end