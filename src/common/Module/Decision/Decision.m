classdef Decision < matlab.System
    methods(Access = public)
        function obj = Decision(varargin)
        end
    end

    methods(Access = protected)
        % execute the core functionality
        function y = stepImpl(obj, x)
            y = x < 0;   % décide x
        end
    end

end
