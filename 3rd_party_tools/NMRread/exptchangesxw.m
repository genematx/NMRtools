function [changedparlist,fixedparlist,pars] = exptchangesxw(dirname)
%% Initialise
if nargin < 1
    dirname = pwd;
end

%% Read fixed and changed parameters
[dirlist,textdirlist] = exptdir(dirname);
[pars.acqs.changed,pars.acqs.fixed] = brukerparchanges('acqus',dirlist,dirname);
[pars.prcs.changed,pars.prcs.fixed] = brukerparchanges('pdata\1\proc',dirlist,dirname);

%% Format output
fixednamesa = strrep(fieldnames(pars.acqs.fixed),'info','infoa');
fixednamesp = strrep(fieldnames(pars.prcs.fixed),'info','infop');
fixedparlist = [fixednamesa,struct2cell(pars.acqs.fixed); ...
    fixednamesp,struct2cell(pars.prcs.fixed)];
changednamesa = strrep(fieldnames(pars.acqs.changed),'info','infoa');
changednamesp = strrep(fieldnames(pars.prcs.changed),'info','infop');
changedparlist = [changednamesa,squeeze(struct2cell(pars.acqs.changed)); ...
    changednamesp,squeeze(struct2cell(pars.prcs.changed))];
changedparlist = [{'expdir'},dirlist';changedparlist];

%% Terminate
end