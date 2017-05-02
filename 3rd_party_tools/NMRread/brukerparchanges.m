function [changedpars,fixedpars] = brukerparchanges(parfile,dirlist,dirroot)
%% Initialise
if nargin < 3
    dirroot = pwd;
end
Nexp = length(dirlist);

%% Read parameter files
[acqspars,fields] = readbatchbrukerpars(parfile,dirlist,dirroot);
fields = sort(fields);
%% Determine changed fields
Nfields = length(fields);
if length(acqspars) > 1
    for cf = Nfields:-1:1
        isfixed(cf) = isequal(acqspars.(fields{cf}));
    end
else
    isfixed  = true(1,Nfields);
end
ischanged = ~isfixed;
%% Build fixed and changed parameter structs
fixedpars = rmfield(acqspars(1),fields(ischanged));
for cf = find(ischanged)
   %%
   field = fields{cf};
   fieldsizes = arrayfun(@(s) size(s.(field)),acqspars,'UniformOutput',false);
   if isequal(fieldsizes{:})
       fieldsize = fieldsizes{1};
       N = prod(fieldsize);
       Ns = N;
   else
       Ns = cellfun(@prod,fieldsizes);
       [N,maxpos] = max(Ns);
       fieldsize = fieldsizes{maxpos};
   end
   Ndims = length(fieldsize);
   if isnumeric(acqspars(1).(field))&&isscalar(Ns)&&(N > 1)
       vals = cat(Ndims + 1,acqspars.(field));
       vals = squeeze(permute(vals,[Ndims + 1,1:Ndims]));
       N2 = 2^max(nextpow2(N),3);
       for ca = 1:N
           vn = genvarname([field,num2str(mod(ca,N2))]);
           if sum(abs(diff(vals(:,ca)))) == 0
               fixedpars.(vn) = vals(1,ca);
           else
               temp = num2cell(vals(:,ca));
               [changedpars(1:Nexp).(vn)] = deal(temp{:});
           end
       end
   else
       [changedpars(1:Nexp).(field)] = deal(acqspars.(field));
   end
end

%% Terminate
end