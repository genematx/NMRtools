function record = readsimfit(filename,dirname)

%% Initialise, batch mode
if nargin < 2
    dirname = pwd;
end
if iscellstr(filename) % Recursive calls in read mode
    record = readstruct(@readsimfit,filename,dirname);
    return
end
% Regular expression for '[name] = [number in scientific format]' or
% '[name] = [number][s,m, or u]'
compparamexpr = '^[^\=]+|\s[+\-]?(?:0|[1-9]\d*)(?:\.\d*)?(?:[eE][+\-]?\d+|[smu])?';

%% Open file, read mode from here
record.file = fileinfo(filename);
if isempty(record.file.dirpath)
    filepath = fullfile(dirname,filename);
    record.file = fileinfo(filepath);
else
    filepath = filename;
end
fileid = fopen(filepath);
%% Read file header
strin = textscan(fileid,'%s',3,'headerLines',3,'delimiter',':');
header = vertcat(strin{:});
while isempty(findstr('=',header{end}))
    strin = textscan(fileid,'%s',1,'delimiter',':');
    header = vertcat(header{:},strin{:});
end
record.dataset = header{2};
record.fittype = strtrim(lower(regexprep(header{3},' fit','')));
if length(header) > 4
    record.description = header(4:(end - 1));
end
record.equation = header{end};
%% Read peaks
peaknum = 0;
strin = textscan(fileid,'%s',1,'whitespace','\b'); % Read single line
while ~isempty(strin{1}) %~feof(fileid)
    peaknum = peaknum + 1;
    record.peakdata(peaknum) = readpeak(strin{1}{1});
    strin = textscan(fileid,'%s',1,'whitespace','\b');
end
%% Close file
fclose(fileid);

%% Terminate, Nested functions
    function peak = readpeak(peakin)
        %% Read peak header
        peakinfo = regexp(peakin,'[\-\d\.]+(e[\+\-]\d+)*','match');
        peak.index = str2double(peakinfo{2});
        switch length(peakinfo)
            case 5
                peak.cursor = str2double(peakinfo{3});
                peak.freq_Hz = str2double(peakinfo{4});
                peak.shift_ppm = str2double(peakinfo{5});
            case 4
                peak.shift_ppm = str2double({peakinfo{3:4}});  
        end
        peak.numpoints = str2double(peakinfo{1});
        %% Read results header
        strin = textscan(fileid,'%s',1,'whitespace','\b');
        if ~isempty(findstr('iteration',strin{1}{1}))
            peak.numiterations = regexp(strin{1},'[\-\d\.]+(e[\+\-]\d+)*','match');
            peak.numiterations = str2double(peak.numiterations{1}{1});
            strin = textscan(fileid,'%s',1,'whitespace','\b');
        end
        tableheader = vertcat(strin{:});
        tableheader = regexp(tableheader,'(\w+|\w+\. \d)(?= {2,})','match');
        tableheader = horzcat(tableheader{:});
        peak.numcomponents = length(tableheader) - 1;
        %% Read results and data table
        peak.results = readpeak_results(peak.numcomponents);
        peak.data = readpeak_data(peak.numpoints);
    end
    function results = readpeak_results(numcomps)
        numcols = numcomps + 1; % max length of tablerow
        strin = textscan(fileid,'%s',1,'whitespace','\b');
        while ~isempty(findstr('=',strin{1}{1}))
            tablerow = regexp(strin{1},compparamexpr,'match');
            tablerow = horzcat(tablerow{:});
            tablerow{1} = regexprep(tablerow{1},'\W','');  
            tablerow = converttimes(tablerow);
            results.(tablerow{1}) = str2double(tablerow(2:end));
            strin = textscan(fileid,'%s',1,'whitespace','\b');
        end
    end
    function data = readpeak_data(numpoints)
        tableheader = regexp([strin{:}],'\S+','match');
        tableheader = horzcat(tableheader{:});
        numcols = length(tableheader);
        searchstr = repmat('%s',1,numcols);
        table = textscan(fileid,searchstr,numpoints);
        table = horzcat(table{:});
        tablerow = textscan(fileid,searchstr,1); % Should be a line of '=' characters
        tablerow = horzcat(tablerow{:});
        while isempty(findstr('=',tablerow{1})) % numpoints is wrong - loop for more rows
            table = vertcat(table,tablerow);
            tablerow = textscan(fileid,searchstr,1);
            tablerow = horzcat(tablerow{:});
        end
        table = converttimes(table);
        table = str2double(table);
        data = cell2struct(num2cell(table,1),tableheader,2);
    end
    function cellout = converttimes(cellin)
        cellout = regexprep(cellin,{'(?<=\d)s','(?<=\d)m','(?<=\d)u','(?<=nan)s','\*+'},{'e+00','e-03','e-06','','nan'},'ignorecase');
    end
end
