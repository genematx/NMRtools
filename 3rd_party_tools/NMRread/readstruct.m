function [outstruct,paths] = readstruct(readfun,filelist,dirname)
if nargin < 3
    dirname = pwd;
end

ws = warning('off','NMRread:FileNotFound');
[contents,names,paths,readcount] = readbatch(readfun,filelist,dirname);
warning(ws)
if readcount > 0
    isread = cellfun(@isstruct,contents);
    contents = contents(isread);
    names = names(isread);
    names = regexprep(names,{'\s+','\W+'},{'_',''}); % Remove whitespace and other invalid field characters
    outstruct = cell2struct(contents(:),names(:),1);
else
    outstruct = []; %struct; %
end

end