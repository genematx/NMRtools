function Npoints = brukergroupdelay(decimation,dspversion)

if nargin < 2
    dspversion = 11;
end

groupdelays = load('brukerdelays.mat');
dsp = ['dspfvs',strtrim(num2str(dspversion))];
if isfield(groupdelays,dsp)
    listsize = length(groupdelays.(dsp));
    Npoints = lookupdelay(groupdelays.decim(1:listsize),groupdelays.(dsp));
else
    Npoints = 0;
end

    function N = lookupdelay(decimlist,delaylist)
        N = interp1(decimlist,delaylist,decimation,'nearest','extrap');
        N = N./decimation;
    end
end