function [pars,allfields] = readbatchbrukerpars(parfile,dirlist,dirroot)
%% Initialise
if nargin < 3
    dirroot = pwd;
end
[subdir,filename] = fileparts(parfile);
Nexp = length(dirlist);
pathlist = cellfun(@(d) fullfile(dirroot,d,subdir),dirlist,'UniformOutput',false);

%% Read parameter files
pars = readbatch(@getpars,pathlist,'',true);
%% Merge parameter structs
fields = cellfun(@fieldnames,pars,'UniformOutput',false);
allfields = vertcat(fields{:});
allfields = unique(allfields);
for cdir = Nexp:-1:1
    extrafields = setdiff(allfields,fields{cdir});
    for cf = extrafields'
        pars{cdir}.(char(cf)) = 0;
    end
    pars{cdir} = orderfields(pars{cdir});
end
pars = vertcat(pars{:});

%% Terminate
    function parsout = getpars(filepath)
        temppars = readbrukerpars(filename,filepath);
        parsout = temppars(1);
        if isfield(temppars,'td')
    %         parsout.td = [temppars(end:-1:1).td];
            parsout.td = [temppars.td];
        end
        if isfield(temppars,'si')
    %         parsout.si = [temppars(end:-1:1).si];
            parsout.si = [temppars.si];
        end
    end
end