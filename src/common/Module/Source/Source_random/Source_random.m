classdef Source_random < matlab.System
    % Public, but non-tunable properties
    properties (Nontunable)
        samples_per_frame = 1,
        rng_seed          = 0,
        rng_type          = 'simdTwister',
        data_type         = 'double',
        interval          = [0 255]
    end

    methods(Access = public)
        function obj = Source_random(varargin)
            setProperties(obj, nargin, varargin{:});
        end
    end

    methods(Access = protected)

        % execute the core functionality
        function y = stepImpl(obj)
            y = randi(obj.interval, obj.samples_per_frame, 1, obj.data_type);
        end

        % initialize the object
        function setupImpl(obj)
            rng(obj.rng_seed, obj.rng_type);
        end

    end
end
