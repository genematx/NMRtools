function [yT, t, c0, f0, dt, tau, theta] = loadFID(type, dirname)
% Loads the FIDs and some parameters (most importantly, the scaling factor
% c0 (spectrometer frequency) and the reference frequency f0 (offset) used 
% to convert between Hz and ppm as [Hz]=[ppm]*c0-f0. Clearly, c0=SFO1, i.e. the receiver frequency in
% MHZ, and f0=O1, ther offset frequency in Hz. Furthermore, need to know
% the spectral width in Hz swh, which is sw=1/dt to generate the time scale.
%
% Inputs:
% type - a string that specifies the type of the data to be read
%        Bruker2D - for pseudo 2D experiments
%        BrukerFID - for 1D Bruker data in the form of FID
%        BrukerSpectrum - for processed Bruker data; will take IFT
%        Spinsolve - for usual Spinsolve 1D data
%        SpinsolveShimming - for spectra acquired during the shimming
%        procedure on Spinsolve instruments
%        Varian - for Varian data
% dirname - the root directory where the data resides
%
% Outputs:
% yT - an nt_x_1 vector (or nt_x_K matrix for 2D experiments) of FID,
%       complex double
% t - the vector of time samples
% c0 - reciever frequency
% f0 - offset frequency
% dt - dwell time
% tau and theta - first and zero order phase corre3ction terms, if available


tau = 0; theta = 0;

switch type
    case 'Bruker2D'
        readin = readxw(dirname);       % Read the signals
        yT = double(readin.acqs.data);
        t = readin.acqs.axes.time1';
        dt = t(2) - t(1);   % Sampling period (dwell time)
        nt = size(yT, 1);
        
        % reference frequency w_0
        c0 = readin.prcs.pars.procs.sf; %Hz->ppm
        swh = readin.acqs.pars.acqu.sw_h; % sweep width(Hz)
        O1 = readin.acqs.pars.acqu.o1; %Hz
        proc_offset = readin.prcs.pars.procs.offset; %ppm
        SR = swh/2+O1-c0*proc_offset; %Hz
        f0 = O1-SR; %Hz
        
        % Phasing
        ph0 = readin.prcs.pars.proc.phc0; % degree
        theta = -ph0*2*pi/360;
        ph1 = readin.prcs.pars.proc.phc1;     % dead time
        tau = -ph1/360/swh; % from ph1 (real)
    case 'BrukerFID'            % Reads Bruker FID data
        acqus = read_acqus_new(dirname);
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
    case 'BrukerSpectrum'       % Reads processed Bruker data
        ntgrp = 76;    % Number of time samples of the Bruker filter response;
        % Read the spectrum data and take its iFFT
        allData = rbnmr(dirname);     % Reads processed Bruker data
        yF = allData.Data - 1i * allData.IData;
        yT = ifft(ifftshift(yF));
        yT = yT(end:-1:1);
        nt = numel(yT);
        yT = [yT(end-ntgrp:end); yT];               % Cut zero-filling
        yT = yT(1:floor(nt/2));
        nt = numel(yT);
        SWH = allData.Acqus.SW_h;     % Spectral width in Hz
        SFO1 = allData.Acqus.SFO1;    % Frequency of the local oscillator in MHz
        O1 = allData.Acqus.O1;        % Offset in Hz
        BF1 = allData.Acqus.BF1;      % Spectrometer frequecy in MHz
        DE = allData.Acqus.DE;        % Time delay before acquisition in microseconds
        
        f0 = O1;
        c0 = SFO1;
        dt = 1 / SWH;         % Sampling period (dwell time)
        t = [0:dt:(nt-1)*dt]';      % Time in seconds
        tau = DE * (1e-06);   % Ringdown time delay in sec
    case 'Spinsolve'
        fileID = fopen(fullfile(dirname, 'data.1d'));
        head = fread(fileID, 8, 'int');   % Read the header
        data = fread(fileID, inf, 'single');  % Read the data
        fclose(fileID);
        
        % Rearrange the data
        n1 = head(5); n2 = head(6); n3 = head(7); n4 = head(8);   % Dimensions of the data array
        t1 = reshape(data(1:n1*n2*n3*n4), n1, n2, n3, n4);        % Imported time vector
        yT = data(n1*n2*n3*n4+1 : 2 : end) - 1i*data(n1*n2*n3*n4+2 : 2 : end);
        yT = reshape(yT, n1, n2, n3, n4);
        yT(1) = 2*yT(1);
        nt = numel(yT);
        % Set up the frequency scale
        fileID = fopen(fullfile(dirname, 'acqu.par'));
        tline = fgetl(fileID);
        while ischar(tline)
            if strfind(tline, 'acqDelay')
                DE = str2num(tline(strfind(tline, '=')+1:end));
            elseif strfind(tline, 'b1Freq')
                SFO = str2num(tline(strfind(tline, '=')+1:end));
            elseif strfind(tline, 'bandwidth')
                SWH = str2num(tline(strfind(tline, '=')+1:end));
            elseif strfind(tline, 'dwellTime')
                dt = str2num(tline(strfind(tline, '=')+1:end));
            elseif strfind(tline, 'lowestFrequency')
                fmin = str2num(tline(strfind(tline, '=')+1:end));
%             elseif strfind(tline, 'nrPnts')
%                 nt = str2num(tline(strfind(tline, '=')+1:end));
            end;
            tline = fgetl(fileID);
        end
        fclose(fileID);
        sw = SWH*(1e+03);    % Spectral window in Hz
        f0 = sw/2+fmin;      % Frequency shift in Hz
        c0 = SFO;
        dt = 1 / sw;         % Sampling period (dwell time)
        t = [0:dt:(nt-1)*dt]';      % Time array in seconds
        tau = DE * (1e-06);   % Ringdown time delay in sec
    case 'SpinsolveShimming'
        fileID = fopen(fullfile(dirname, 'spectrum.1d'));
        head = fread(fileID, 8, 'int');   % Read the header
        data = fread(fileID, inf, 'single');  % Read the data
        fclose(fileID);
        % Rearrange the data
        n1 = head(5); n2 = head(6); n3 = head(7); n4 = head(8);   % Dimensions of the data array
        d = reshape(data(1:n1*n2*n3*n4), n1, n2, n3, n4);         % ppm scale
        yF = data(n1*n2*n3*n4+1 : 2 : end) - 1i*data(n1*n2*n3*n4+2 : 2 : end);
        yF = reshape(yF, n1, n2, n3, n4);
        % Set up the frequency scale
        fileID = fopen(fullfile(dirname, 'shim.par'));
        tline = fgetl(fileID);
        while ischar(tline)
            if strfind(tline, 'shim_ppmOffset')
                OFppm = str2num(tline(strfind(tline, '=')+1:end));
            elseif strfind(tline, 'proton_Frequency')
                SFO = str2num(tline(strfind(tline, '=')+1:end));
            elseif strfind(tline, 'shim_Width50')
                peakWidth50 = str2num(tline(strfind(tline, '=')+1:end));
            elseif strfind(tline, 'shim_Width10')
                peakWidth10 = str2num(tline(strfind(tline, '=')+1:end));
            elseif strfind(tline, 'shim_Width2')
                peakWidth2 = str2num(tline(strfind(tline, '=')+1:end));
            elseif strfind(tline, 'shim_Width055')
                peakWidth055 = str2num(tline(strfind(tline, '=')+1:end));
            end;
            tline = fgetl(fileID);
        end
        fclose(fileID);
        c0 = SFO / (1e+06);
        f0 = OFppm*c0;      % Frequency shift in Hz
        SWppm = max(d) - min(d);       % Spectral width in ppm
        SWH = SWppm*c0;       % Spectral window in Hz
        dt = 1 / SWH;         % Sampling period (dwell time)
        % Move to the time domain
        yT = ifft(ifftshift(yF));
        yT = yT(1:32768);  % Remove zero-filling
        yT(1) = 2*yT(1);
        nt = numel(yT);
        t = [0:dt:(nt-1)*dt]';      % Time array in seconds
    case 'Varian'
        fileID = fopen(fullfile(dirname, 'fid'));
        head = fread(fileID, 15, 'uint32', 'b');   % Read the header
        data = fread(fileID, inf, 'float32', 'b');  % Read the data
        fclose(fileID);
        % Rearrange the data
        yT = data(1:2:end) - 1i * data(2:2:end);
        % Read the parameters and set up the frequency scale
        fileID = fopen(fullfile(dirname, 'procpar'));
        tline = fgetl(fileID);
        while ischar(tline)
            if strfind(tline, 'sfrq')
                tline = fgetl(fileID);
                SFO = str2num(tline(strfind(tline, ' ')+1:end));
            elseif strfind(tline, 'reffrq')      % or 'H1reffrq', 'sreffrq'
                tline = fgetl(fileID);
                SFref = str2num(tline(strfind(tline, ' ')+1:end));
            elseif strfind(tline, 'sw')
                tline = fgetl(fileID);
                sw = str2num(tline(strfind(tline, ' ')+1:end));    % Spectral window in Hz
            elseif strfind(tline, 'rp ')
                tline = fgetl(fileID);
                PH0 = str2num(tline(strfind(tline, ' ')+1:end));   % Zero-order phase shift (degrees)
            elseif strfind(tline, 'pw ')
                tline = fgetl(fileID);
                DE = str2num(tline(strfind(tline, ' ')+1:end));    % Pulse width in microseconds
            end;
            tline = fgetl(fileID);
        end
        fclose(fileID);
        f0 = (SFO - SFref)*(1e+06);      % Frequency shift in Hz
        c0 = SFO;
        dt = 1 / sw;         % Sampling period (dwell time)
        nt = numel(yT);
        t = [0:dt:(nt-1)*dt]';      % Time array in seconds
        tau = DE * (1e-06);   % Ringdown time delay in sec
        theta = pi*PH0/180;   % Zero-order phase shift in radians
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
