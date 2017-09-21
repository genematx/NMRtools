function [yF, ppm_scale] = loadSpectrum(type, dirname)
%% Loads the Spectrum (frequency domain data) and some parameters 
%
% Inputs:
% type - a string that specifies the type of the data to be read
%        Bruker2DFID - for pseudo 2D experiments => FT in
%                    matlab
%        Bruker2DSpectrum - for pseudo 2D experiments => FT in
%                    TopSpin 
%        BrukerFID - for 1D Bruker read data in the form of FID => FT in
%                    matlab
%        BrukerSpectrum - for processed Bruker data => FT in TopSpin
%        Spinsolve - for usual Spinsolve 1D data
% dirname - the root directory where the data resides
%
% Outputs:
% yF - an nt_x_1 vector (or nt_x_K matrix for 2D experiments) of Spectrum,
%       complex double
% ppm_scale - the vector of ppm_scale




switch type
    case 'Bruker2DFID' % Bruker2D_FID  missing Bruker2D_spectrum (needs rbnmr_2ii)
        acqus = read_acqus_new(dirname); % read acquistion parameters
        TD2 = read_TD2(dirname); % read the size of the second dimension TD2
        procs = readnmrpar(strcat(dirname,'/pdata/1/procs'));
        
        acqus.TD(2) = TD2;       
        
        ntgrp = ceil(acqus.GRPDLY);    % Number of time samples of the Bruker filter response;
        SWH = acqus.SW_h;     % Spectral width in Hz
        f0 = acqus.O1;        % Offset in Hz
        c0 = acqus.SFO1;    % Frequency of the local oscillator in MHz
        dt = 1 / SWH;         % Sampling period (dwell time) 
        tau = acqus.DE * (1e-06);   % Ringdown time delay in sec
        
        yT = read_ser_file(dirname, acqus.bytorda,acqus.TD);

        yT = yT(ntgrp+1:end,:);
        nt = size(yT,1);
        t = [0:dt:(nt-1)*dt]';      % Time in seconds   
        
        NFFT = procs.SI;
        yF = fftshift(fft(yT,NFFT,1));
        freq = 1/(dt)*linspace(-1,1,NFFT);  
        
        
        
        % Calculate x-axis
        ppm_scale = linspace( procs.OFFSET,...
                    procs.OFFSET-procs.SW_p./procs.SF,...
                    NFFT)';
                
       yF = yF.';                

    case 'Bruker2DSpectrum' % Bruker2D_FID  missing Bruker2D_spectrum (needs rbnmr_2ii)    
        allData = rbnmr(dirname);     % Reads processed Bruker data
        yF = complex(allData.Data, allData.IData);
        ppm_scale = allData.XAxis.';        
        
    case 'BrukerFID'            % Reads Bruker FID data
        acqus = read_acqus_new(dirname);
        procs = readnmrpar(strcat(dirname,'/pdata/1/procs'));
        
        ntgrp = ceil(acqus.GRPDLY);    % Number of time samples of the Bruker filter response;
        SWH = acqus.SW_h;     % Spectral width in Hz
        f0 = acqus.O1;        % Offset in Hz
        c0 = acqus.SFO1;    % Frequency of the local oscillator in MHz
        dt = 1 / SWH;         % Sampling period (dwell time) 
        tau = acqus.DE * (1e-06);   % Ringdown time delay in sec
        
        yT = read_fid_file(dirname, acqus.bytorda);
        yT = yT(ntgrp+1:end);
        nt = numel(yT);
        t = [0:dt:(nt-1)*dt]';      % Time in seconds        
        
        
        
        NFFT = procs.SI;
        yF = fftshift(fft(yT,NFFT));
        yF = yF(end:-1:1);
        
        
        freq = 1/(dt)*linspace(-1,1,NFFT);  
%         yF = yF(:).*exp(-1i*2*pi*acqus.GRPDLY*freq(:)*dt);
        
       
        procs = readnmrpar(strcat(dirname,'/pdata/1/procs'));       
        
        % Calculate x-axis
        ppm_scale = linspace( procs.OFFSET,...
                    procs.OFFSET-procs.SW_p./procs.SF,...
                    NFFT)';        
        
    case 'BrukerSpectrum'       % Reads processed Bruker data

        % Read the spectrum data and take its iFFT
        allData = rbnmr(dirname);     % Reads processed Bruker data
        yF = complex(allData.Data, allData.IData);
        ppm_scale = allData.XAxis.';

    case 'Spinsolve'

        [ yF, ppm_scale ] = read_1d_data_magritek( folder_path );
        
end

end

function acqus = read_acqus_new( loc_data )
%=========================================================================%
% Inputs:
%   loc_data: path of the folder containing the FID files [string] 
%
% Outputs:
%   acqus: structure containing information about the FID signal
%
% Description:
%   Read the 'acqus' file in the specified location and set up a structure
%   'acqus' containing information about the FID signal
%
% Possible problems/Bugs:
% - the O1 value is different from the function by Erik (in Erik's function
% the first character is skipped)
%=========================================================================%

key_format = {'##[$]', '='};
% brackets around $ are needed for regexp but don't represent the actual
% string in the file to be searched
nr_of_regexp_chars = 2; % 2 chars in key format do not correspond to the actual string
keys ={...
    'BYTORDA',  'inline',               'bytorda';...
    'CNST',          'nextline' ,          'cnst';...
    'D',                  'next2lines' ,     'D';...
    'DE',               'inline',               'DE';...
    'L',                  'nextline' ,          'L';...
    'NBL',             'inline',               'NBL';...
    'NS'                'inline',               'NS';...
    'O1',               'inline',               'O1';...
    'P',                  'nextline' ,          'P' ;...
    'SP',               'nextline' ,          'SP';...
    'SPOFFS',    'nextline' ,          'SPOFFS';...
    'SW_h',          'inline',               'SW_h';...
    'TD',               'inline',               'TD';...
    'GRPDLY',       'inline',                 'GRPDLY';...    
    'SFO1',       'inline',                 'SFO1';...
    };
% format: { Key string to find in file, location of the data w.r.t. the key
% string location,  datatype of the data,  name of the structure element
% to contain the data }

%% SETUP EXPRESSION FOR SEARCH FROM KEYS
keys{1,1} = strcat(key_format{1},keys{1,1},key_format{2});
key_expr = keys{1,1} ;
for i=2:length(keys)
    keys{i,1} = strcat(key_format{1},keys{i,1},key_format{2});
    key_expr=strcat(key_expr,'|',keys{i,1});
end
    
%% READ WHOLE ACQUS FILE INTO STRING CELL FOR SEARCH
acqus_path = strcat(loc_data,'/acqus');
fid_acqus = fopen(acqus_path);
acqus_cell = textscan(fid_acqus, '%s', 'Delimiter', '\n');
acqus_cell=acqus_cell{:};
fclose(fid_acqus);

%% FIND ALL CELLS CORRESPONDING TO THE KEYS
cell_regexp= regexp(acqus_cell,key_expr);
cell_idx = find(~cellfun('isempty',cell_regexp));
key_lines = acqus_cell(cell_idx);

for i=1:size(keys,1)
    key_idx = cell_idx(~cellfun('isempty',regexp(key_lines,keys{i,1})));
    switch keys{i,2}
        case 'inline'
            line = acqus_cell{key_idx};
            acqus.(keys{i,3})=str2num(line(length(keys{i,1})-nr_of_regexp_chars+1:end));    
        case 'nextline'
            line = acqus_cell{key_idx+1};
            acqus.(keys{i,3})=str2num(line);
        case 'next2lines'
            line1 = acqus_cell{key_idx+1};
            line2 = acqus_cell{key_idx+2};
            acqus.(keys{i,3})=[str2num(line1),str2num(line2)];
    end
end

end

function fid_data = read_fid_file(loc_data,bytorda)
%=========================================================================%
% Calculate the vector of signal intensities for the sample times
%=========================================================================%

if bytorda == 0
    datatyp = 'l';
elseif bytorda == 1
    datatyp = 'b';
end 
file_name = strcat(loc_data,'/fid');
fid = fopen(file_name,'r',datatyp);
A = fread(fid,inf,'int=>int');
fclose(fid);

A = double(A);
B = reshape(A,[2,size(A,1)/2]); % Each recorded complex value is saved by real part followed by imaginary part -> A looks like [r1,i1,r2,i2,r3,i3,r4,i4,.....]
fid_data = transpose(complex(B(1,:),B(2,:)));
end

function ser_data = read_ser_file(loc_data,bytorda,TD)
%% Read the FID of 2D data

if bytorda == 0
    datatyp = 'l';
elseif bytorda == 1
    datatyp = 'b';
end 
file_name = strcat(loc_data,'/ser');
ser = fopen(file_name,'r',datatyp);
%[A,count] = fread(ser,inf,'int=>int');
A=fread(ser,'int32');
fclose(ser);

A = double(A);
B = reshape(A,[2,size(A,1)/2]); % Each recorded complex value is saved by real part followed by imaginary part -> A looks like [r1,i1,r2,i2,r3,i3,r4,i4,.....]
C = complex(B(1,:),B(2,:));

% N = [TD(1)/2 TD(2)];
N = [length(C)/TD(2) TD(2)];


C = C(1:(N(1)*N(2))); % rest of C consists of zeros
ser_data = reshape(C,N);

end


function SI = read_procs(dirname)

%% Get TD2
file_name = strcat(dirname,'/procs');
fid_procs = fopen(file_name);


% read in line after line
% Search for NBL
tline = fgetl(fid_procs);
key = '##$SI=';
end_read = min(length(key),length(tline));
str_found = strcmp(tline(1:end_read),key);
while ~str_found
    % Read the next line
    tline = fgetl(fid_procs);
    end_read = min(length(key),length(tline));
    str_found = strcmp(tline(1:end_read),key);
end    
SI = str2double(tline(length(key)+1:end));

fclose(fid_procs);
end


function TD2 = read_TD2(dirname)

%% Get TD2
file_name = strcat(dirname,'/acqu2s');
fid_acqus2 = fopen(file_name);


% read in line after line
% Search for NBL
tline = fgetl(fid_acqus2);
key = '##$TD=';
end_read = min(length(key),length(tline));
str_found = strcmp(tline(1:end_read),key);
while ~str_found
    % Read the next line
    tline = fgetl(fid_acqus2);
    end_read = min(length(key),length(tline));
    str_found = strcmp(tline(1:end_read),key);
end    
TD2 = str2double(tline(length(key)+1:end));

fclose(fid_acqus2);
end


function [ Y, ppm_scale ] = read_1d_data_magritek( folder_path )
%READ_1D_DATA_MAGRITEK reads info from the data.1d binary file
fsep = filesep;

binary_data = get_binary_1d([folder_path, [fsep 'Enhanced' fsep 'data.1d']]);
data_L = size(binary_data,1)/3;

%separating data
time_scale = binary_data(1:data_L,1);
fid_data(1,:) = complex(binary_data(data_L+1:2:end,1), binary_data(data_L+2:2:end,1));

%do FFT
NFFT = 2^(nextpow2(length(fid_data)+1));
%Y = fftshift(fft(fid_data,NFFT)/length(fid_data));
Y = fftshift(fft(fid_data,NFFT));

%open acqu.par file
param_data = get_file_sliced([folder_path, [fsep 'acqu.par']]);

%extraction of meaningful parameters
%   where :
%       acqu_p(1) : b1Freq
%       acqu_p(2) : bandwith (kHz?)
%       acqu_p(3) : lowestFrequency
param_str = char('b1Freq', 'bandwidth', 'lowestFrequency');
acqu_p = zeros(1,size(param_str,1));

for param_index = 1:size(param_str,1)
    tmp = ~cellfun('isempty',regexp(param_data, param_str(param_index,:))); 
    tmp = strsplit(param_data{tmp});
    acqu_p(param_index) = str2double(tmp{3});
end

%calculate the ppm scale
ppm_scale = linspace(acqu_p(3)/acqu_p(1),...
                    (acqu_p(3)+acqu_p(2)*1000)/acqu_p(1),...
                     size(Y,2));
% PLEASE check if good
Y = fliplr(Y);
                 
end


function [ file_data ] = get_file_sliced( file_path )
%GET_FILE_SLICED reads a file and slice it using \n as delimiter
%   DATA = GET_FILE_SLICED(FILE_PATH) returns an array of cells (N x 1)
%   containing the N lines of the file. 

file_id = fopen(file_path);
file_data = textscan(file_id, '%s', 'Delimiter', '\n');
file_data = file_data{:};
fclose(file_id);
end

function [ file_data ] = get_binary_1d( file_path )
%GET_BINARY_1D gets binary data from .1d file, and cuts the header

endian = 'l';
[A, message] = fopen(file_path, 'r', endian);
file_data = fread(A, 'float32');
file_data = file_data(9:end);
end


function P = readnmrpar(FileName)
% RBNMRPAR      Reads BRUKER parameter files to a struct
%
% SYNTAX        P = readnmrpar(FileName);
%
% IN            FileName:	Name of parameterfile, e.g., acqus
%
% OUT           Structure array with parameter/value-pairs
%

% Read file
A = textread(FileName,'%s','whitespace','\n');

% Det. the kind of entry
TypeOfRow = cell(length(A),2);
    
R = {   ...
    '^##\$*(.+)=\ \(\d\.\.\d+\)(.+)', 'ParVecVal' ; ...
    '^##\$*(.+)=\ \(\d\.\.\d+\)$'   , 'ParVec'    ; ...
    '^##\$*(.+)=\ (.+)'             , 'ParVal'    ; ...
    '^([^\$#].*)'                   , 'Val'       ; ...
    '^\$\$(.*)'                     , 'Stamp'     ; ...
    '^##\$*(.+)='                   , 'EmptyPar'  ; ...
	'^(.+)'							, 'Anything'	...
    };

for i = 1:length(A)
    for j=1:size(R,1)
        [s,t]=regexp(A{i},R{j,1},'start','tokens');
        if (~isempty(s))
            TypeOfRow{i,1}=R{j,2};
            TypeOfRow{i,2}=t{1};
        break;
        end
    end
end

% Set up the struct
i=0;
while i < length(TypeOfRow)
    i=i+1;
    switch TypeOfRow{i,1}
        case 'ParVal'
            LastParameterName = TypeOfRow{i,2}{1};
            P.(LastParameterName)=TypeOfRow{i,2}{2};
        case {'ParVec','EmptyPar'}
            LastParameterName = TypeOfRow{i,2}{1};
            P.(LastParameterName)=[];
        case 'ParVecVal'
            LastParameterName = TypeOfRow{i,2}{1};
            P.(LastParameterName)=TypeOfRow{i,2}{2};
        case 'Stamp'
            if ~isfield(P,'Stamp') 
                P.Stamp=TypeOfRow{i,2}{1};
            else
                P.Stamp=[P.Stamp ' ## ' TypeOfRow{i,2}{1}];
            end
        case 'Val'
			if isempty(P.(LastParameterName))
				P.(LastParameterName) = TypeOfRow{i,2}{1};
			else
				P.(LastParameterName) = [P.(LastParameterName),' ',TypeOfRow{i,2}{1}];
			end
        case {'Empty','Anything'}
            % Do nothing
    end
end
    

% Convert strings to values
Fields = fieldnames(P);

for i=1:length(Fields);
    trystring = sprintf('P.%s = [%s];',Fields{i},P.(Fields{i}));
    try
        eval(trystring);
	catch %#ok<CTCH>
        % Let the string P.(Fields{i}) be unaltered
    end
end

end