function [record,numfields,strfields,cellfields] = readdx(filepath)

%% Initialise
searchexpr = {'#+([ \-\w]+)=[\s\$]*(\(([^\f\n\r\t]+?)\)+)?\s*([^#\f\n\r\t]*)','#+\$([ \-\w]+)=\s*(\(([ ,\.\d]+)\)+)?\s*([^#\f\n\r\t]+)'};
descstr = {'$$','#'};

%% Check path
if (nargin < 1)||(exist(filepath,'file') ~= 2)
    [filename,dirname] = uigetfile('*.*','Open JCAMP-DX parameter file');
    if dirname
        filepath = fullfile(dirname,filename);
    else
        return
    end    
end
%% Read file without comments
fileid = fopen(filepath);
strcols = textscan(fileid,'%s','commentStyle',descstr,'whitespace','\b');
fclose(fileid);
strcols = vertcat(strcols{:});
file = fileinfo(filepath);
%% Remove unwanted line breaks and extract fields/ values
charcol = char(strcols).';
charcol = charcol(:).';
charcol = regexprep(charcol,{'\s{2,}',' ?#+','<\s+?>'},{' ','#','<>'});
searchtoks = regexp(charcol,searchexpr,'tokens');
%% Parse JCAMP-DX information fields
info = vertcat(searchtoks{1}{:});
infoend = strmatch('OWNER',info);
if isempty(infoend)
    infoend = min(size(info,1) - 1,5);
end
info = info([1:infoend,end],:);
info(:,1) = lower(info(:,1));
info(:,1) = regexprep(info(:,1),{'\s+','\W+'},{'_',''}); % Remove whitespace and other invalid field characters %regexprep(info(:,1),{'\s+','\-'},'');
info = cell2struct([{file},info(:,3)'],[{'file'},info(:,1)'],2);
%% Parse parameter fields
params = vertcat(searchtoks{1}{(infoend + 1):(end - 1)},searchtoks{2}{:});
params(:,2) = regexprep(params(:,2),{'(\()','(\))','0\.\.'},{'','','1+'});
params(:,2) = cellfun(@str2num,params(:,2),'UniformOutput',false); % str2num required to evaluate e.g. '1+31'
nosize = cellfun(@isempty,params(:,2));
[params{nosize,2}] = deal(0);
params(:,1) = lower(params(:,1));
params(:,1) = regexprep(params(:,1),{'\s+','\W+'},{'_',''}); % Remove whitespace and other invalid field characters
%% Convert parameter datatypes
isbrukercell = ~cellfun(@isempty,regexp(params(:,3),'^[\(]')); % Might fail if an intended text string begins with '('
[params(:,3),isnum] = numcells(params(:,3));
isstrcell = cellfun(@(a,b) all(a > 0)&(prod(a) < numel(b)),params(:,2),params(:,3))&(~isbrukercell)&(~isnum);
params(isbrukercell,3) = regexp(params(isbrukercell,3),'\(([^\)]+)','tokens');
params(isbrukercell,3) = cellfun(@(c) vertcat(c{:}),params(isbrukercell,3),'UniformOutput',false);
params(isbrukercell,3) = cellfun(@(c) regexp(c,'<[^>]*?,?[^<]*?>|[^<>,\s]*','match'),params(isbrukercell,3),'UniformOutput',false);
params(isbrukercell,3) = cellfun(@(c) numcells(vertcat(c{:})),params(isbrukercell,3),'UniformOutput',false);
params(isstrcell,3) = regexp(params(isstrcell,3),'\S+','match'); 
isresize = cellfun(@(a,b) (prod(a) == numel(b))&(numel(a) > 1),params(:,2),params(:,3));
params(isresize,3) = cellfun(@(c,d) squeeze(reshape(c,d(end:-1:1))),params(isresize,3),params(isresize,2),'UniformOutput',false);
%% Create record structure
record = cell2struct([{info},params(:,3)'],[{'info'},params(:,1)'],2);
numfields = params(isnum,1);
strfields = params(isstrcell,1);
cellfields = params(isbrukercell,1);

%% Terminate
    function [cellout,isnumcell] = numcells(cellin)
        cellout = cellin;
        isnumcell = cellfun(@isempty,regexp(cellin,'[^ e\-\+\.\d]')); % Might fail if an intended text string begins with '-'
        cellout(isnumcell) = cellfun(@str2num,cellin(isnumcell),'UniformOutput',false); % cellfun required since the arrays are of different sizes
    end
end
