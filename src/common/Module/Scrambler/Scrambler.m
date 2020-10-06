classdef Scrambler < matlab.System
    % Public, but non-tunable properties
    properties (Nontunable)
        sequence = []
    end

    methods(Access = public)
        function obj = Scrambler(varargin)
            setProperties(obj, nargin, varargin{:});
        end
    end

    methods(Access = protected)
        % execute the core functionality
        function y = stepImpl(obj, x)
            y = bitxor(x, obj.sequence);   % scrambler
        end
    end

end
