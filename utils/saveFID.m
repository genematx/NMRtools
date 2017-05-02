function saveFID(type, dirname, yT, c0, f0, dt, varargin)
% Saves FID in a specified format
% Currently only Spinsolve format is supported

tau = 0; theta = 0;
for i = 1 : 2 : numel(varargin)
    switch varargin{i}
        case 'tau'
            tau = varargin{i+1};
        case 'theta'
            theta = varargin{i+1};
    end;
end;

switch type
    case 'Spinsolve'
        % Rearrange the data
        n1 = size(yT, 1); n2 = 1; n3 = 1; n4 = 1;   % Dimensions of the data array
        X = [real(yT) -imag(yT)]';
        X = X(:);
        t = [0:dt:(n1-1)*dt];
        % Write the file
        fileID = fopen(fullfile(dirname, 'data.1d'), 'w');
        fwrite(fileID, [1347571539 1145132097 1446063665 504 n1 n2 n3 n4], 'int');
        fwrite(fileID, t, 'single');
        fwrite(fileID, X, 'single');
        fclose(fileID);
        % Write the parameter file
        fileID = fopen(fullfile(dirname, 'acqu.par'), 'w');
        fprintf(fileID, 'Solvent                   = ""\n');
        fprintf(fileID, ['Sample                    = ""\n']);
        % fprintf(fileID, ['startTime                 = "',
        % datetime('now','TimeZone','local','Format','d-MMM-y_HH:mm:ss Z'),
        % '"\n']);
        fprintf(fileID, 'acqDelay                  = %0.16f\n', tau*1e+06);     % Ringdown delay in ms
        fprintf(fileID, 'b1Freq                    = %0.16f\n', c0);       % B1 frequency in MHz
        fprintf(fileID, 'bandwidth                 = %0.16f\n', (1/dt)/1000);       % Sweep bandwidth in kHz
        fprintf(fileID, 'dwellTime                 = %0.16f\n', 1000*dt);       % Dwell time in ms
        fprintf(fileID, 'experiment                = "1D"\n');
        fprintf(fileID, 'expName                   = "1D"\n');
        fprintf(fileID, 'nrPnts                    = %d\n', n1);
        fprintf(fileID, 'nrScans                   = 1\n');
        fprintf(fileID, 'repTime                   = 0\n');                       % Repetiotion time in ms
        fprintf(fileID, 'rxChannel                 = "1H"\n');
        fprintf(fileID, 'rxGain                    = 0\n');                       % Reciever gain in dB
        fprintf(fileID, 'lowestFrequency           = %0.16f\n', -(1/dt)/2+f0);       % Lowest frequency in Hz
        % fprintf(fileID, 'totalAcquisitionTime      = 53\n');
        % % Total acquisition time in sec
        fprintf(fileID, 'graphTitle                = "1D-1H-"StandardScan""\n');
        fprintf(fileID, 'userData                  = ""\n');
        fprintf(fileID, '90Amplitude               = 0\n');      % Amplitude of the 90-degree pulse in dB
        fprintf(fileID, 'pulseLength               = 0\n');      % Pulse length in ms
        fprintf(fileID, 'Protocol                  = "1D PROTON"\n');
        fprintf(fileID, 'Options                   = "Scan(StandardScan)"\n');
        fprintf(fileID, 'Spectrometer              = "Matlab"\n');
        fprintf(fileID, 'Software                  = "Matlab"');
        fclose(fileID);
    otherwise
        error('Currently only the Spinsolve format is supported.');
end;

end

