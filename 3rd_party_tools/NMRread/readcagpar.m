function cagpar = readcagpar(filepath)

fileid = fopen(filepath);
strin = textscan(fileid,'%f',3);
cagpar.scale = vertcat(strin{:});
strin = textscan(fileid,'%f %f %f',3,'delimiter',' ');
cagpar.rotate = horzcat(strin{:});
fclose(fileid);

end