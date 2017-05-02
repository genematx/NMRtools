function pars = getbrukerpars(partype,dirpath)

%% Initialise
pars = [];
if nargin < 2
    dirpath = '';
end

%% Get parameters.
switch partype
    case {'acqu','proc'}
        %% Read acqus or procs.
        filename = [partype,'s'];
        filepath = fullfile(dirpath,filename);
        parset{1} = readbrukerpar(filepath);
        switch partype
            case 'acqu'
                numdims = parset{1}.parmode + 1;
            case 'proc'
                numdims = parset{1}.pparmod + 1;
        end
        fields{1} = fieldnames(parset{1});
%         classes{1} = struct2cell(structfun(@class,parset{1},'UniformOutput',false));
        if numdims > 1
            for cdim = 2:numdims
                filename = [partype,num2str(cdim),'s'];
                filepath = fullfile(dirpath,filename);
                if exist(filepath,'file') ==  2
                    parset{cdim} = readbrukerpar(filepath);
                    fields{cdim} = fieldnames(parset{cdim});
%                     classes{cdim} = struct2cell(structfun(@class,parset{cdim},'UniformOutput',false));
                else
                    parset{cdim} = struct;
                end
            end
        end
        %% Merge fields.
%         allclasses = vertcat(classes{:});
        allfields = vertcat(fields{:});
        [allfields2,idx] = unique(allfields);
%         allclasses2 = {allclasses{idx}}.';
%         classstruct = cell2struct(allclasses2,allfields2);
        %% Fill field gaps
        for cdim = 1:numdims
            extrafields = setdiff(allfields2,fields{cdim});
            for cf = extrafields.'
                parset{cdim}.(char(cf)) = []; %cast([],classstruct.(char(cf)));
            end
        end
        %% Concatenate parameter sets to form structure array.
        pars = horzcat(parset{:});
    otherwise
        filename = partype;
        filepath = fullfile(dirpath,filename);
        pars = readbrukerpar(filepath);
end

%% Terminate
end