classdef Source_file < matlab.System
    % Public, but non-tunable properties
    properties (Nontunable)
        file_name         = '',
        samples_per_frame = 1,
        data_type         ='unit8',
    end
    
    properties (Logical, Nontunable)
        % is_data_complex Data is complex
        % If the data stored in the file is complex, set this property to
        % true. Otherwise, set it to false. The default is false.
        is_data_complex = false;
        
    end
    properties
        play_count = 1
    end
    
    properties (Access = protected)
        % p_is_done True if there are no more samples in the file
        p_is_done
    end
    
    
    
    % Pre-computed constants
    properties(Access = private)
        pFID = -1,
        p_num_EOF_reached = 0
    end
    
    properties(Constant, Hidden)
        pad_value = 0
        
    end
    
    methods(Access = public)
        function obj = Source_file(varargin)
            setProperties(obj, nargin, varargin{:});
            obj.p_is_done = false;
        end
        
        function tf = isDone(obj)
            tf = obj.p_is_done;
        end
    end
    
    methods(Access = protected)
        
        
        % initialize the object
        function setupImpl(obj)
            % Populate obj.pFID
            getWorkingFID(obj)
            
            % Go to start of data
            goToStartOfData(obj)            
        end
        
        % execute the core functionality
        function y = stepImpl(obj)
            bs = obj.samples_per_frame;
            y = readBuffer(obj, bs);
        end
        
        function resetImpl(obj)
            goToStartOfData(obj);
            obj.p_num_EOF_reached = 0;
            obj.p_is_done = false;
        end
        
        % release the object and its resources
        function releaseImpl(obj)
            fclose(obj.pFID);
            obj.pFID = -1;
            obj.p_is_done = false;
        end
        
        % indicate if we have reached the end of the file
        
        function loadObjectImpl(obj,s,wasLocked)
            % Call base class method
            loadObjectImpl@matlab.System(obj,s,wasLocked);
            
            % Re-load state if saved version was locked
            if wasLocked
                % All the following were set at setup
                
                % Set obj.pFID - needs obj.file_name (restored above)
                obj.pFID = -1; % Superfluous - already set to -1 by default
                getWorkingFID(obj);
                % Go to saved position
                fseek(obj.pFID, s.SavedPosition, 'bof');
                
                obj.p_num_EOF_reached = s.p_num_EOF_reached;
            end
            
        end
        
        function s = saveObjectImpl(obj)
            % Default implementation saves all public properties
            s = saveObjectImpl@matlab.System(obj);
            
            if isLocked(obj)
                % All the fields in s are properties set at setup
                s.SavedPosition = ftell(obj.pFID);
                s.p_num_EOF_reached = obj.p_num_EOF_reached;
            end
        end
    end
    
    methods(Access = private)
        
        function getWorkingFID(obj)
            if(obj.pFID < 0)
                [obj.pFID, err] = fopen(obj.file_name, 'r');
                if ~isempty(err)
                    error(['FileReader: ', err]);
                end
            end
            
        end
        
        function goToStartOfData(obj)
            fid = obj.pFID;
            frewind(fid);
        end
        
        
        function rawData = readBuffer(obj, numValues)
            bufferSize = obj.samples_per_frame;
            if obj.is_data_complex
                rbs = 2*bufferSize;
                nv = numValues*2;
            else
                rbs = bufferSize;
                nv = numValues;
            end
            
            dt = obj.data_type;
            tmp = fread(obj.pFID, rbs, dt); % Lire une trame
            
            numValuesRead = numel(tmp);
            
            if(numValuesRead == rbs)&&(~feof(obj.pFID))
                rD = tmp;
            else
                % End of file - may also need to complete frame
                obj.p_num_EOF_reached = obj.p_num_EOF_reached + 1;
                if(obj.p_num_EOF_reached < obj.play_count)
                    % Keep reading from start of file
                    goToStartOfData(obj)
                    moreData = readBuffer(obj, nv-numValuesRead);
                    rD = [tmp; moreData];
                else
                    % First pad with pad value, then reshape
                    padVector = repmat(obj.pad_value, ...
                        nv - numValuesRead, 1);
                    rD = [tmp; padVector];
                end
                
            end
            
            obj.p_is_done = logical(feof(obj.pFID));
            rD = cast(rD,dt);
            if obj.is_data_complex
                rawData = complex(rD(1:2:end),rD(2:2:end));
            else
                rawData = rD;
            end
            
        end
        
    end
end
