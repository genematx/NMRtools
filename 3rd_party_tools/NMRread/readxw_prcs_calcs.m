function calcs = readxw_prcs_calcs(dirname,filenames)

%% Initialise
dirname = checkdir(dirname,'Open Bruker process number');
if nargin < 2
    filenames = {'simfit.txt','ct1t2.txt'};
end

%% Read simfit files, in batch mode if necessary
calcs = readsimfit(filenames,dirname);

%% Terminate
end