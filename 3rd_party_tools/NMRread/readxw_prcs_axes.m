function lists = readxw_prcs_axes(dirname,prcspars)

%% Initialise
dirname = checkdir(dirname,'Open Bruker process number');
if (nargin < 2)||isempty(prcspars)
    prcspars = readxw_prcs_pars(dirname);
end

%% Generate frequency axes
if isfield(prcspars,'procs')
    for cdim = 1:numel(prcspars.procs)
        dimname1 = ['freq',strtrim(num2str(cdim))];
        nlim = (prcspars.procs(cdim).si)/2; % Nyquist index
        if prcspars.procs(cdim).stsi > 0
            freqinc = (prcspars.procs(cdim).sw_p)./(prcspars.procs(cdim).stsi); % Hz per point
        else
            freqinc = (prcspars.procs(cdim).sw_p)./(prcspars.procs(cdim).si); % Hz per point
        end
        naxis = -nlim:(nlim - 1); % Frequency axis indices; N.B. XWinNMR considers the upper limit as the first point
        iaxis = prcspars.procs(cdim).si - prcspars.procs(cdim).stsr - (0:(prcspars.procs(cdim).stsi - 1)); % Strip axis indices
        freqaxis = naxis.*freqinc; % Hz Frequency axis (full)
        freqlim = freqaxis(1); % Hz Nyquist frequency (negative position)
        lists.(dimname1) = freqaxis(iaxis); % Hz Frequency axis (strip)
        dimname2 = ['shift',strtrim(num2str(cdim))];
        lists.(dimname2) = prcspars.procs(cdim).offset + (lists.(dimname1) + freqlim)./(prcspars.procs(cdim).sf); % Chemical shift axis (strip)
    end
else
    lists = [];
end

%% Terminate
end