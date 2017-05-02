function out = exptfind(searchstr,dirname,filename)

%% Initialise
curdir = pwd;
if nargin < 3
    filename = 'acqus';
    if nargin < 3
        dirname = curdir;
    end
end
%% Directory search
cd(dirname)
[status,result] = dos(['findstr /S /P /R "',searchstr,'" ',filename]);
cd(curdir)
%% File list from regular expressions
filelist = regexp(result,['([^\f\n\r\t]+)(?=\\',filename,')'],'tokens');
filelist = vertcat(filelist{:});
%% Pulse program list from regular expressions
searchlist = regexp(result,[':([^\f\n\r\t]+',searchstr,'[^\f\n\r\t]+)'],'tokens').';
searchlist = vertcat(searchlist{:});
%% Terminate
out = horzcat(filelist,searchlist);