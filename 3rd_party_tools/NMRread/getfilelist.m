function [Filenames,Filedates] = getfilelist(InDir,ext,filter)
% Find either files or directories with a given extension or name pattern.
% e.g. getfilelist(pwd,'.txt') returns files ending with '.txt' in the
% current directory.
% Only files are found, unless ext contains '-dir' (directories only).
% Filter is interpreted as a regular expression if ext contains '-regexp'.
% Otherwise is interpreted as a literal part of the filename.
% In the latter case, filter can include wildcards ('*','?').

%% Initialise
if nargin < 3
    filter = '*';
    if nargin < 2
        ext = '';
        if nargin < 1
            InDir = pwd;
        end
    end
end
isregexp = ~isempty(strfind(ext,'-regexp'));
isdirs = ~isempty(strfind(ext,'-dir'));
ext = regexprep(ext,{'\-\w+','\s+'},'');

%% Get file list.
if isregexp
    InFiles = dir(InDir);
    Filenames = {InFiles.name}.';
    if ~isempty(filter)
        ismatch = regexp(Filenames,filter,'ONCE');
        ismatch = ~cellfun(@isempty,ismatch);
        InFiles = InFiles(ismatch);
    end
else
    InFiles = dir(fullfile(InDir,[filter,ext]));
end
Filenames = {InFiles.name}.';
ismatch = regexp(Filenames,'[^\.]','ONCE');
ismatch = ~cellfun(@isempty,ismatch);
InFiles = InFiles(ismatch);
%% Filter files/ directories
isdir = [InFiles.isdir];
if isdirs
    InFiles = InFiles(isdir);
else
    InFiles = InFiles(~isdir);    
end
%% Sort by date.
if ~isempty(InFiles)
    Filedates = {InFiles.date}.';
    Filedates = datenum(Filedates,0);
    [Filedates,sortorder] = sort(Filedates);
    Filenames = {InFiles(sortorder).name}.';
else % No matches
    Filedates = [];
    Filenames = {};
end

%% Terminate
end
