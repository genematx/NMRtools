function [dirlist,textdirlist] = exptdir(dirname)

%% Get directory list
result = dir(dirname);
dirlist = {result.name}';
templist = str2double(dirlist);
istext = isnan(templist);
%% Sort numeric directory names
sortorder1 = find(~istext);
[templist,sortorder2] = sort(templist(sortorder1));
sortorder1 = sortorder1(sortorder2);
%% Sort text directory names
sortorder2 = find(istext);
[templist,sortorder3] = sort(dirlist(istext));
sortorder2 = sortorder2(sortorder3);
%% Output directory lists
if nargout > 1
    textdirlist = dirlist(sortorder2);
    dirlist = dirlist(sortorder1);
else
    sortorder = [sortorder1;sortorder2];
    dirlist = dirlist(sortorder);
end

%% Terminate
end