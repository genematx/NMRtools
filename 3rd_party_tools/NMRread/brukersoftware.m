function [software,isxw,ispv] = brukersoftware(dirname)

xwparfilename = 'acqum';
pvparfilename = 'acqp';
xwfile = dir(fullfile(dirname,xwparfilename));
pvfile = dir(fullfile(dirname,pvparfilename));
isxw = ~isempty(xwfile);
ispv = ~isempty(pvfile);
if isxw&&ispv
    isxw = (datenum(xwfile.date) > datenum(pvfile.date));
%    ispv = ~isxw;
end
if ispv
    software = 'Paravision';
elseif isxw
    software = 'XWinNMR';
else
    software = '';
end

end