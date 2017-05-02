function list = readlist(listname,dirname)

%% Initialise
if nargin < 2
    dirname = pwd;
end

%% Batch mode
if iscellstr(listname) % Recursive calls in read mode
    list = readstruct(@readlist,listname,dirname);
    return
end
%% Read mode (single file)
pathstr = fileparts(listname); %[pathstr,name,ext] = fileparts(listname);
if isempty(pathstr)
    filepath = fullfile(dirname,listname);
else
%     dirname = pathstr;
    filepath = listname;
end
fileid = fopen(filepath);
list = textscan(fileid,'%s','delimiter',' ');
fclose(fileid);
list = vertcat(list{:});
list = regexprep(list,{'(?<=\d)s','(?<=\d)m','(?<=\d)u','[^\d\.\+\-e]+'},{'e+00','e-03','e-06',''});
list = str2double(list);
list = list(~isnan(list));
if isvector(list)
    list = reshape(list,1,[]);
end

%% Terminate
end