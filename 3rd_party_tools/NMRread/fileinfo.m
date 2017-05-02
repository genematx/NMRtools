function file = fileinfo(filepath)

file = dir(filepath);
if (~isempty(file))&&(~file.isdir)
   [dirname,filename,ext] = fileparts(filepath);
   file.name = filename;
   file.dirpath = dirname;
   file.ext = ext;
end

end