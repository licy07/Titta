classdef TittaDummyMode < Titta
    methods
        function obj = TittaDummyMode(TittaInstance)
            qPassedSuperClass = false;
            if ischar(TittaInstance)
                % direct construction, thats fine
                name = TittaInstance;
            elseif isa(TittaInstance,'Titta')
                qPassedSuperClass = true;
                name = TittaInstance.settings.tracker;
            end
            
            % construct default base class, below we overwrite some
            % settings, if a super class was passed in
            obj = obj@Titta(name);
            
            if qPassedSuperClass
                % passed the superclass. "cast" into subclass by copying
                % over all properties. This is what TMW recommends when you
                % want to downcast...
                C = metaclass(TittaInstance);
                P = C.Properties;
                for k = 1:length(P)
                    if ~P{k}.Dependent && ~strcmp(P{k}.SetAccess,'private')
                        obj.(P{k}.Name) = TittaInstance.(P{k}.Name);
                    end
                end
            end
            
            % check we overwrite all public methods (for developer, to make
            % sure we override all accessible baseclass calls with no-ops)
            if 1
                thisInfo = metaclass(obj);
                superMethods = thisInfo.SuperclassList.MethodList;
                thisMethods = thisInfo.MethodList;
                % for both, remove their constructors from list and limit
                % to only public methods
                superMethods(~strcmp({superMethods.Access},'public') | (~~[superMethods.Static]) | ismember({superMethods.Name},{'Titta'})) = [];
                thisMethods (~strcmp( {thisMethods.Access},'public') | (~~ [thisMethods.Static]) | ismember( {thisMethods.Name},{'TittaDummyMode'})) = [];
                
                % now check for problems:
                % 1. any methods we define here that are not in superclass?
                notInSuper = ~ismember({thisMethods.Name},{superMethods.Name});
                if any(notInSuper)
                    fprintf('methods that are in %s but not in %s:\n',thisInfo.Name,thisInfo.SuperclassList.Name);
                    fprintf('  %s\n',thisMethods(notInSuper).Name);
                end
                
                % 2. methods from superclas that are not overridden.
                qNotOverridden = ~ismember({superMethods.Name},{thisMethods.Name});
                if any(qNotOverridden)
                    fprintf('methods from %s not overridden in %s:\n',thisInfo.SuperclassList.Name,thisInfo.Name);
                    fprintf('  %s\n',superMethods(qNotOverridden).Name);
                end
                
                % 3. right number of input arguments?
                qMatchingInput = false(size(thisMethods));
                for p=1:length(thisMethods)
                    superMethod = superMethods(strcmp({superMethods.Name},thisMethods(p).Name));
                    if isscalar(superMethod)
                        qMatchingInput(p) = (length(superMethod.InputNames) == length(thisMethods(p).InputNames)) || (length(superMethod.InputNames) < length(thisMethods(p).InputNames) && strcmp(superMethod.InputNames{end},'varargin')) || (length(thisMethods(p).InputNames) < length(superMethod.InputNames) && strcmp(thisMethods(p).InputNames{end},'varargin'));
                    else
                        qMatchingInput(p) = true;
                    end
                end
                if any(~qMatchingInput)
                    fprintf('methods in %s with wrong number of input arguments (mismatching %s):\n',thisInfo.Name,thisInfo.SuperclassList.Name);
                    fprintf('  %s\n',thisMethods(~qMatchingInput).Name);
                end
                
                % 4. right number of output arguments?
                qMatchingOutput = false(size(thisMethods));
                for p=1:length(thisMethods)
                    superMethod = superMethods(strcmp({superMethods.Name},thisMethods(p).Name));
                    if isscalar(superMethod)
                        qMatchingOutput(p) = length(superMethod.OutputNames) == length(thisMethods(p).OutputNames);
                    else
                        qMatchingOutput(p) = true;
                    end
                end
                if any(~qMatchingOutput)
                    fprintf('methods in %s with wrong number of output arguments (mismatching %s):\n',thisInfo.Name,thisInfo.SuperclassList.Name);
                    fprintf('  %s\n',thisMethods(~qMatchingOutput).Name);
                end
            end
        end
        
        function out = setDummyMode(obj)
            % we're already in dummy mode, just pass out the same instance
            out = obj;
        end
        
        function out = init(obj)
            out = [];
            % make dummyMode buffer
            obj.buffer = TobiiBufferDummyMode();
            % mark as inited
            obj.isInitialized = true;
        end
        
        function out = calibrate(~,~,~)
            out = [];
        end
        
        function dat = collectSessionData(~)
            dat = [];
        end
        
        function saveData(~,~,~)
        end
        
        function out = deInit(obj)
            out = [];
            % mark as deinited
            obj.isInitialized = false;
        end
    end
end