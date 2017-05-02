function [dirlist,dirnums] = getnumdirlist(dirname)
% List numbered directories.

dirlist = getfilelist(dirname,'-dir -regexp','[^\D]');
dirnums = str2double(dirlist);
[dirnums,sortorder] = sort(dirnums);
dirlist = dirlist(sortorder);

end