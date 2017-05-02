function dirout = checkdir(dirin,prompt)

if nargin < 2
    prompt = ''; 
end

if isdir(dirin) %(exist(dirin,'dir') == 7)
    if dirin(end) == filesep % Remove last directory separator
        dirout = dirin(1:(end - 1));
    else
        dirout = dirin;
    end
elseif isempty(prompt)
    dirout = uigetdir(pwd);
else
    dirout = uigetdir(pwd,prompt);
end
if isnumeric(dirout)&&(dirout == 0)
    dirout = '';
end

end