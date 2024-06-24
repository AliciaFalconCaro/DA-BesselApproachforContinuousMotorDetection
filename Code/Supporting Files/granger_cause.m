function [GC] = granger_cause(X)
%% Granger Causality performed with adaptation from Multivariate Granger Causality Toolbox:
% Add to path and start toolbox by running 'startup.m' from root folder

% References
% [1] L. Barnett and A. K. Seth,
% <http://www.sciencedirect.com/science/article/pii/S0165027013003701 The MVGC
%     Multivariate Granger Causality Toolbox: A New Approach to Granger-causal
% Inference>, _J. Neurosci. Methods_ 223, 2014
% [ <matlab:open('mvgc_preprint.pdf') preprint> ].
%
% [2] A. K. Seth, "A MATLAB toolbox for Granger causal connectivity analysis",
% _J. Neurosci. Methods_ 186, 2010.
%
% (C) Lionel Barnett and Anil K. Seth, 2012. See file license.txt in
% installation directory for licensing terms.

%% Syntax
%
%     GC = granger_cause(X)
%
%% Arguments
%
% See also <mvgchelp.html#4 Common variable names and data structures>.
%
% _input_
%
%     X          multi-trial time series data
%
% _output_
%
%     GC          Granger causality 
%


% Parameters
regmode   = 'OLS';  % VAR model estimation regression mode ('OLS', 'LWR' or empty for default)
icregmode = 'LWR';  % information criteria regression mode ('OLS', 'LWR' or empty for default)

morder    = 'AIC';  % model order to use ('actual', 'AIC', 'BIC' or supplied numerical value)
momax     = 20;     % maximum model order for model order estimation

% Generate VAR time series data with normally distributed residuals for
% specified coefficients and covariance matrix.
%ptic('\n*** var_to_tsdata... ');
%ptoc;

% Model order estimation
%ptic('\n*** tsdata_to_infocrit\n');
[AIC,BIC] = tsdata_to_infocrit(X,momax,icregmode);
%ptoc('*** tsdata_to_infocrit took ');

[~,bmo_AIC] = min(AIC);
[~,bmo_BIC] = min(BIC);

% Plot information criteria.
% figure(1); clf;
% plot((1:momax)',[AIC BIC]);
% legend('AIC','BIC');

% fprintf('\nbest model order (AIC) = %d\n',bmo_AIC);
% fprintf('best model order (BIC) = %d\n',bmo_BIC);

% Select model order
if strcmpi(morder,'AIC')
    morder = bmo_AIC;
%     fprintf('\nusing AIC best model order = %d\n',morder);
elseif strcmpi(morder,'BIC')
    morder = bmo_BIC;
%     fprintf('\nusing BIC best model order = %d\n',morder);
else
%     fprintf('\nusing specified model order = %d\n',morder);
end

% Granger causality estimation
% Calculate time-domain pairwise-conditional causalities. Return VAR parameters
% so we can check VAR.
% ptic('\n*** GCCA_tsdata_to_pwcgc... ');
[GC,A,SIG] = GCCA_tsdata_to_pwcgc(X,morder,regmode); % use same model order for reduced as for full regressions
% ptoc;

% Check for failed (full) regression
assert(~isbad(A),'VAR estimation failed');

% Check for failed GC calculation
assert(~isbad(GC,false),'GC calculation failed');

end
