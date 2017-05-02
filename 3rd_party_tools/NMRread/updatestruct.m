function struct3 = updatestruct(struct1,struct2)
% Update fields of struct1 with values from struct2.
% Fields present in struct1 that are not present in struct2 are unaffected.
% N.B. Field names are case sensitive.

%% Initialise.
struct3 = struct1;
if (nargin < 2)||isempty(struct2) % Nothing to update
    return
end

%% Update fields.
fields = fieldnames(struct2).';
for cf = fields
    field = cf{:};
    if isfield(struct1,field)&&isstruct(struct2.(field)(1))
        for cs = length(struct2.(field)):-1:1 %1:length(struct2.(field))
            struct3.(field)(cs) = updatestruct(struct1.(field)(cs),struct2.(field)(cs)); % Recursive update
        end
    else
        struct3.(field) = struct2.(field);
    end
end

%% Terminate.
end