function pars = readxw_prcs_pars(dirname,prcspars)

%% Initialise
dirname = checkdir(dirname,'Open Bruker process number');
if nargin < 2
    prcspars = struct([]);
end

%% Read parameters
pars = readbrukerpars({'proc','procs'},dirname);
%% Override parameters
if ~isempty(prcspars)
    pars = updatestruct(pars,prcspars);
end
%% Parse parameters
pars.data.dirname = dirname;
pars.data.iscomplex = true;
pars.data.byteswap = logical(pars.procs(1).bytordp);
pars.data.datatype = 'int32';
pars.data.datasize = max([pars.procs(:).stsi;pars.procs(:).si]);
numdims = length(pars.data.datasize);
pars.data.dataorder = [2,1,3:numdims]; % i.e. transpose
pars.data.storesize = min(([pars.procs(:).xdim;pars.procs(:).si]),[],1);
pars.data.storesize = [pars.data.storesize;(pars.data.datasize)./(pars.data.storesize)]; %prod(pars.data.storesize,1) == pars.data.datasize
pars.data.storeorder{1} = (pars.data.datasize(1):-1:1).'; % XWinNMR stores direct dimension as high frequency to low frequency
for cdim = 2:numdims;
    pars.data.storeorder{cdim} = (1:pars.data.datasize(cdim)).';
end
pars.data.scale = pow2(pars.procs(1).nc_proc);

%% Terminate
end