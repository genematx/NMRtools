function pars = readbrukerpars(partype,dirname)

%% Initialise
if nargin < 2
    dirname = pwd;
end

%% Batch mode
if iscellstr(partype) % Recursive calls in read mode
    pars = readstruct(@readbrukerpars,partype,dirname);
    return
end

%% Read mode (single file)
[pathstr,name,ext] = fileparts(partype);
if isempty(pathstr)
    filepath = fullfile(dirname,partype);
else
    filepath = partype;
    dirname = pathstr;
    partype = name;
end
if any(strncmpi(partype,{'acqu','proc'},4))
    pars = readdimpars(partype);
else % Default
    pars = readparfile(filepath);
end

%% Terminate, nested functions
    function npars = readdimpars(partype)        
        %% Read acqu(s) or proc(s)
        filepath = fullfile(dirname,partype);
        [parset{1},fields{1}] = readparfile(filepath);
        switch lower(partype(1:4))
            case 'acqu'
                numdims = parset{1}.parmode + 1;
            case 'proc'
                numdims = parset{1}.pparmod + 1;
        end
        %% Read other dimension files if necessary
        if numdims > 1
            for cdim = 2:numdims
                filename = [partype(1:4),num2str(cdim)];
                if partype(end) == 's'
                    filename = [filename,'s'];
                end
                filepath = fullfile(dirname,filename);
                if exist(filepath,'file') ==  2
                    [parset{cdim},fields{cdim}] = readparfile(filepath);
                else
                    numdims = cdim - 1;
                    break
%                     parset{cdim} = struct;
                end
            end
        end
        %% Merge fields
        allfields = vertcat(fields{:});
        [allfields2,idx] = unique(allfields);
        %% Fill field gaps
        for cdim = 1:numdims
            extrafields = setdiff(allfields2,fields{cdim});
            for cf = extrafields.'
                parset{cdim}.(char(cf)) = 0;
            end
        end
        %% Concatenate parameter sets to form structure array
        npars = horzcat(parset{:});
    end
    function [outstruct,outfields] = readparfile(filepath)
        outstruct = readdx(filepath);
        outfields = fieldnames(outstruct);
        for fld = outfields.'
            if isempty(strfind(fld{1},'_'))
                outstruct.(fld{1}) = shiftarray(outstruct.(fld{1}));
            end
        end
    end
    function outvar = shiftarray(invar)
        N = size(invar,2);
        if ischar(invar)||(N < 8)
            outvar = invar;
        else
            shifts = zeros(1,N);
            shifts(2) = -1;
            outvar = circshift(invar,shifts);
        end
    end
end

