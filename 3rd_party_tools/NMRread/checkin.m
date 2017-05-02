function parout = checkin(parin,names,defaults)

namesin = fieldnames(parin);
isrequired = cellfun(@ischar,defaults);
isrequired(isrequired) = strcmpi('required',defaults(isrequired));
isabsent = ~isfield(parin,names);
ismissed = isabsent & isrequired;
if any(ismissed)
    errstr = 'Required input fields missing: ';
    errstr = [errstr,repmat('%s; ',1,sum(ismissed) - 1),'%s.'];
    error(errstr,names{ismissed});
%     disp(sprintf(errstr,names{ismissed}));
end
isdefault = isabsent & (~isrequired);
defaulted = vertcat(names(isdefault),defaults(isdefault));
if ~isempty(parin)
    parout = parin;
end
for cd = defaulted
    parout.(cd{1}) = cd{2};
end

end