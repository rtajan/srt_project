classdef Converter_bit_oct < matlab.System
    % Pre-computed constants
    properties(Access = private)
        padding_value = 0;
    end
    
    properties(Access = private, Hidden)
        padding_nbr = 0;
        padding_vector = [];
    end
    
    methods(Access = public)
        function obj = Converter_bit_oct(varargin)
            setProperties(obj, nargin, varargin{:});
        end
    end
    
    methods(Access = protected)
        % initialize the object
        function setupImpl(obj,u)
            obj.padding_nbr = ceil(length(u)/8)*8 - length(u);
            obj.padding_vector = obj.padding_value * ones(obj.padding_nbr,1);
        end
        
        % execute the core functionality
        function y = stepImpl(obj,b)
            padded_b = [b(:); obj.padding_vector];
            y = uint8(bi2de(reshape(padded_b,8,[]).','left-msb'));
        end 
    end
end
