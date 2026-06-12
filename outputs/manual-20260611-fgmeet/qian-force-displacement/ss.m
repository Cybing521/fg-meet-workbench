function varargout = ss(varargin)
%SS No-op shim for a stray bare "ss" token in the archived predecessor code.
% The raw Qian SubFunMFC function ends a fprintf line with "ss"; putting this
% shim first on the MATLAB path lets the archived function return normally.
varargout = cell(1, nargout);
end
