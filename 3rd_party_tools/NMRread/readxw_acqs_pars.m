function pars = readxw_acqs_pars(dirname,acqspars)

%% Initialise
dirname = checkdir(dirname,'Open Bruker experiment number');
if nargin < 2
    acqspars = struct([]);
end

%% Read parameters
pars = readbrukerpars({'acqu','acqus'},dirname);
if (exist(fullfile(dirname,'acqum'),'file') == 2)
    pars.acqum = readdx(fullfile(dirname,'acqum'));
end
if (exist(fullfile(dirname,'cag_pars'),'file') == 2)
    pars.cag = readcagpar(fullfile(dirname,'cag_pars'));
end
%% Override parameters
if ~isempty(acqspars)
    pars = updatestruct(pars,acqspars);
end
%% Parse parameters
pars.data.dirname = dirname;
pars.data.iscomplex = true;
isdigital = (pars.acqus(1).digmod > 0);
pars.data.byteswap = logical(pars.acqus(1).bytorda);
pars.data.datatype = 'int32';
blocksize = 256; % 1024*8/32
if isdigital
    if isfield(pars.acqus,'grpdly')&&(pars.acqus(1).grpdly ~= -1)
        pars.data.directshift = -pars.acqus(1).grpdly;
    elseif strcmp(pars.acqus(1).aq_mod,'qdig')
        pars.data.directshift = -brukergroupdelay(pars.acqus(1).decim,12);
    else
        pars.data.directshift = -brukergroupdelay(pars.acqus(1).decim,pars.acqus(1).dspfvs); % This line alone would probably work - the surrounding if block shouldn't be necessary
    end
else
    pars.data.directshift = [];
end
pars.data.datasize = [pars.acqus(:).td];
numdims = length(pars.data.datasize);
pars.data.dataorder = 1:numdims;
% Direct dimension starts on 1 KB boundaries in fid/ ser file
pars.data.zerofill = mod(blocksize - rem(pars.data.datasize(1),blocksize),blocksize); % N.B Real and imaginary points separate
pars.data.storesize = [pars.data.datasize(1) + pars.data.zerofill,pars.data.datasize(2:end)];
if (numdims == 3)&&logical(pars.acqus(1).aqseq) %any(logical([pars.acqus(:).aqseq]))
    pars.data.storeorder = [1,3,2];
    pars.data.storesize = pars.data.storesize(pars.data.storeorder);
else
    pars.data.storeorder = 1:numdims;
end
pars.data.datasize(1) = pars.data.datasize(1)./2; % Number of complex points in direct dimension

%% Terminate
end