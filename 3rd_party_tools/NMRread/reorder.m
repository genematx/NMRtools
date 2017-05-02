function [dataout,orderout] = reorder(datain,orderin,dim)

%% Initialise
numdims = ndims(datain);

%% Sort
[orderout,sortorder] = sort(orderin(:)); % Reverse the order (temp is the target order)
if numdims > 1
    dims = setdiff(1:numdims,dim);
    dataout = num2cell(datain,dims); % Split across object dimension into cells
    dataout = dataout(sortorder); % Sort the cell array
    dataout = cat(dim,dataout{:}); % Recombine cells to form reordered array
else % numdims == 1
    dataout = datain(sortorder); % Sort the array
end

%% Terminate
end