function gamma = gmr(nuclei,bar)
% Gyromagnetic ratio /[rad/Ts] (bar = false) or [Hz/T] (bar = true)

%% Initialise.
if nargin < 2
    bar = false;
end

%% Parse nucleus.
element = regexp(nuclei,'[a-zA-Z]+','Match');
rmm = regexp(nuclei,'\d+','Match');
if iscell(nuclei)
%     element = vertcat(element{:});
%     rmm = vertcat(rmm{:});
    gamma = nan(size(nuclei));
    for cg = 1:length(gamma)
        if isempty(rmm{cg})
            gamma(cg) = lookupgmr(element{cg}{1},'');
        else
            gamma(cg) = lookupgmr(element{cg}{1},rmm{cg}{1});
        end
    end
else
    if isempty(rmm)
            gamma = lookupgmr(element{1},'');
        else
            gamma = lookupgmr(element{1},rmm{1});
    end
    
end
if bar
    gamma = gamma./(2.*pi);
end

%% Terminate, nested functions
    function gmratio = lookupgmr(symbol,mass)
        nucleus = [lower(symbol),mass];
        switch nucleus
            case {'h1','h'}
                gmratio = 2.675e8;
            case {'h2','d'}
                gmratio = 4.106e7;
            case {'li7','li'}
                gmratio = 1.040e8;
            case {'c13','c'}
                gmratio = 6.726e7;
            case {'f19','f'}
                gmratio = 2.517e8;
            case {'na23','na'}
                gmratio = 7.076e7;
            case {'p31','p'}
                gmratio = 1.083e8;
            otherwise
                gmratio = nan;
        end
    end
end