% dirname = 'D:\users\tcc\Work\Data\NMR\tcc_02_11c';
filename = 'acqus';
%%
curdir = pwd;
cd(fullfile(dirname,dataset))
[status,result] = dos(['findstr /S /P /R "PULPROG" ',filename]);
[status2,result2] = dos(['dir /S ',filename]);
cd(curdir)
%%
filelist = regexp(result,['([^\f\n\r\t]+)(?=\\',filename,')'],'tokens');
filelist = vertcat(filelist{:});
%%
pulproglist = regexp(result,['(?<=\\',filename,':##\$PULPROG= <)(\S+)(?=>)'],'tokens');
pulproglist = vertcat(pulproglist{:});
%%
dirlist = regexp(result2,'(?<=\s+Directory of )(\S+)\s+([^\f\n\r]+)(?= {2,})','tokens');
dirlist = vertcat(dirlist{:});
%%
datelist = {dirlist{:,2}}.';
datelist = cellfun(@datestr,datelist,'UniformOutput',false);
%%
out = horzcat(filelist,datelist,pulproglist);
