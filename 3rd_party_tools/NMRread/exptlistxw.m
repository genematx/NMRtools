function [parlist,headings,changedparlist,fixedparlist,pars] = exptlistxw(dataset,dirname)
%% Initialise
if nargin < 1
    dirpath = pwd;
else
    if nargin < 2
        dirname = pwd;
    end
    dirpath = fullfile(dirname,dataset);
end

%% Get experimental parameters
[changedparlist,fixedparlist,pars] = exptchangesxw(dirpath);
[Nchpar,Nexp] = size(changedparlist);
Nexp = Nexp - 1;
%% Include relevant fixed parameters
fields = {'^date$';'^exp$';'^ti$';'^pulprog$';'^td$';'^sw_h$';'^ns$';'^rg$';'^digmod$'};
fieldlocs = cellfun(@(f) find(~cellfun(@isempty,regexp(fixedparlist(:,1),f))),fields,'uniformoutput',false);
rownums = cell2mat(fieldlocs);
Nrows = length(rownums);
rownums(Nrows + 24) = 0;
for cn = 1:8
    cnstr = num2str(cn);
    rownum = find(strcmp(['nuc',cnstr],fixedparlist(:,1)));
    if ~isempty(rownum)
        if isempty(findstr(fixedparlist{rownum,2},'off'))
            Nrows = Nrows + 1;
            rownums(Nrows) = rownum;
        else
            break
        end
    end
    
    rownum = find(strcmp(['bf',cnstr],fixedparlist(:,1)));
    if ~isempty(rownum)
    Nrows = Nrows + 1;
    rownums(Nrows) = rownum;
    end
    rownum = find(strcmp(['o',cnstr],fixedparlist(:,1)));
    if ~isempty(rownum)
    Nrows = Nrows + 1;
    rownums(Nrows) = rownum;
    end
end
rownums = nonzeros(rownums);
extrarows = [fixedparlist(rownums,1),repmat(fixedparlist(rownums,2),1,Nexp)];
Npar = Nchpar + Nrows;
parlist = [changedparlist(2:end,:);extrarows;changedparlist(1,:)];
%% Find variables for calculations
fields = {'^expdir$';'^date$';'^td$'};
fieldlocs = cellfun(@(f) find(~cellfun(@isempty,regexp(parlist(:,1),f))),fields,'uniformoutput',false);
rownums = cell2mat(fieldlocs);
%% Experiment number
dirrow = rownums(1);
Npar = Npar + 1;
parlist(Npar,2:end) = cellfun(@str2num,parlist(dirrow,2:end),'uniformoutput',false);
parlist{Npar,1} = 'expnum';
%% Convert date
secsperday = (24*60*60);
refdatenum = datenum('Jan-1-1970 00:00:00');
daterow = rownums(2);
Npar = Npar + 1;
parlist(Npar,2:end) = cellfun(@(d) d./secsperday + refdatenum,parlist(daterow,2:end),'uniformoutput',false);
parlist{Npar,1} = 'datenum';
parlist(daterow,2:end) = cellfun(@datestr,parlist(Npar,2:end),'uniformoutput',false);
%% Calculate data size
tdrow = rownums(3);
Npar = Npar + 1;
parlist(Npar,2:end) = cellfun(@(s) [s(1)/2,s(2:end)],parlist(tdrow,2:end),'uniformoutput',false);
parlist{Npar,1} = 'size';
%% Remove angle brackets from string variables
isstrvar = cellfun(@ischar,parlist);
parlist(isstrvar) = regexprep(parlist(isstrvar),'[<>]','');
% isstrvar = cellfun(@ischar,parlist(:,2));
% parlist(isstrvar,2:end) = regexprep(parlist(isstrvar,2:end),'[<>]','');
%% Sort and transpose
fields = {'^expnum$';'^date$';'^exp$';'^ti$';'^pulprog$';'^size$';'^nuc\d+';'^bf\d+';'^sw_h$';'^o\d+';'^d\d+';'^p\d+';'^pl\d+';'^l\d+';'^cnst\d+';'^ns$';'^rg$';'^digmod$'};
fieldlocs = cellfun(@(f) find(~cellfun(@isempty,regexp(parlist(:,1),f))),fields,'uniformoutput',false);
rowlist = (1:Npar)';
rownums = cell2mat(fieldlocs);
sortorder = [rownums;setdiff(rowlist,rownums)];

%% Terminate
if nargout < 2
    parlist = parlist(sortorder,:)';
else
    headings = parlist(sortorder,1)';
    parlist = parlist(sortorder,2:end)';
end
end