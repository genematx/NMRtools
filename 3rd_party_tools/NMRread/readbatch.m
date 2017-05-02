function [outcell,namelist,pathlist,readcount] = readbatch(readfun,celllist,dirname,ignoreexist)
%% Initialise
if nargin < 4
    ignoreexist = false;
    if nargin < 3
        dirname = pwd;
    end
end
cellsize = size(celllist);
Nfiles = prod(cellsize);
outcell = cell(cellsize);
[pathlist,namelist] = cellfun(@genpathname,celllist,'UniformOutput',false);
displist = regexprep(pathlist,'\\','\\\');

%% Loop reading files
readcount = 0;
for cl = 1:Nfiles
%     [filepath,name] = genpathname(cellist{cl});
    filepath = pathlist{cl};
    disppath = displist{cl};
%     name = namelist{cl};
%     disppath = regexprep(filepath,'\\','\\\');
    if ignoreexist||(exist(filepath,'file') == 2)
        try
            tempentry = readfun(filepath);
        catch exception
            warning('NMRread:FileNotRead',['Could not read ',disppath]);
            tempentry = exception;
%             tempentry = 'Error reading file';
        end
        readcount = readcount + 1;
    else
        warning('NMRread:FileNotFound',['Could not find ',disppath]);
        tempentry = 'File not found';        
    end
    outcell{cl} = tempentry;
end
%% Terminate
    function [fpath,fname] = genpathname(inpath)
        [pathstr,fname] = fileparts(inpath); %[pathstr,name,ext] = fileparts(cl{1});
        if isempty(pathstr)
            fpath = fullfile(dirname,inpath);
        else
            fpath = inpath;
%             dirname = pathstr;
        end
%         fname = regexprep(fname,{'\s+','\W+'},{'_',''}); % Remove whitespace and other invalid field characters
    end
end