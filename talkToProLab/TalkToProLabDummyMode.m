classdef TalkToProLabDummyMode < handle
    
    properties (SetAccess=protected)
        projectID       = '';
        participantID   = '';
        recordingID     = '';
    end
    
    methods
        function obj = TalkToProLabDummyMode()
            % no-op, just check we have the same public interface as non
            % dummy-mode class
            % check we overwrite all public methods (for developer, to make
            % sure we override all accessible baseclass calls with no-ops)
            if 1
                thisInfo = ?TalkToProLabDummyMode;
                realInfo = ?TalkToProLab;
                realMethods = realInfo.MethodList;
                realMethods(~strcmp({realMethods.Access},'public') | (~~[realMethods.Static])) = [];
                thisMethods = thisInfo.MethodList;
                % remove constructor from list TalkToProLabDummyMode
                thisMethods(~strcmp({thisMethods.Access},'public') | (~~[thisMethods.Static]) | ismember({thisMethods.Name},{'TalkToProLabDummyMode'})) = [];
                
                % now check for problems:
                % 1. any methods we define here that are not in superclass?
                notInSuper = ~ismember({thisMethods.Name},{realMethods.Name});
                if any(notInSuper)
                    fprintf('methods that are in %s but not in %s:\n',thisInfo.Name,realInfo.Name);
                    fprintf('  %s\n',thisMethods(notInSuper).Name);
                end
                
                % 2. methods from superclas that are not overridden.
                qNotOverridden = arrayfun(@(x) strcmp(x.DefiningClass.Name,realInfo.Name), thisMethods);
                if any(qNotOverridden)
                    fprintf('methods from %s not overridden in %s:\n',realInfo.Name,thisInfo.Name);
                    fprintf('  %s\n',thisMethods(qNotOverridden).Name);
                end
                
                % 3. right number of input arguments?
                qMatchingInput = false(size(qNotOverridden));
                for p=1:length(thisMethods)
                    superMethod = realMethods(strcmp({realMethods.Name},thisMethods(p).Name));
                    if isscalar(superMethod)
                        qMatchingInput(p) = (length(superMethod.InputNames) == length(thisMethods(p).InputNames)) || (length(superMethod.InputNames) < length(thisMethods(p).InputNames) && strcmp(superMethod.InputNames{end},'varargin'));
                    else
                        qMatchingInput(p) = true;
                    end
                end
                if any(~qMatchingInput)
                    fprintf('methods in %s with wrong number of input arguments (mismatching %s):\n',thisInfo.Name,realInfo.Name);
                    fprintf('  %s\n',thisMethods(~qMatchingInput).Name);
                end
                
                % 4. right number of output arguments?
                qMatchingOutput = false(size(qNotOverridden));
                for p=1:length(thisMethods)
                    superMethod = realMethods(strcmp({realMethods.Name},thisMethods(p).Name));
                    if isscalar(superMethod)
                        qMatchingOutput(p) = length(superMethod.OutputNames) == length(thisMethods(p).OutputNames);
                    else
                        qMatchingOutput(p) = true;
                    end
                end
                if any(~qMatchingOutput)
                    fprintf('methods in %s with wrong number of output arguments (mismatching %s):\n',thisInfo.Name,realInfo.Name);
                    fprintf('  %s\n',thisMethods(~qMatchingOutput).Name);
                end
            end
        end
        
        function delete(~)
        end
        
        function participantID = createParticipant(~,~,~)
            participantID = 'fake_participant_id';
        end
        
        function mediaID = findMedia(~,~)
            mediaID = '';
        end
        
        function [mediaID,wasUploaded] = uploadMedia(~,~,~)
            mediaID = '';
            wasUploaded = false;
        end
        
        function numAOI = attachAOI(~,~)
            numAOI = 0;
        end
        
        function EPState = getExternalPresenterState(~)
            EPState = 'unmet';
        end
        
        function recordingID = startRecording(~,~,~,~,~)
            recordingID     = 'fake_recording_id';
        end
        
        function stopRecording(~)
        end
        
        function finalizeRecording(~)
        end
        
        function discardRecording(~)
        end
        
        function sendStimulusEvent(~,~,~,~,~,~)
        end
        
        function sendCustomEvent(~,~,~,~)
        end
    end
end