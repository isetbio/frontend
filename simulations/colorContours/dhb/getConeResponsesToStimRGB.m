function [coneResponses,ranIndex] = getConeResponsesToStimRGB(cSensor,stimulus,theParams,staticParams,runtimeParams,staticComputedValues,ranIndex)
% [coneResponses,ranIndex] = getConeResponsesToStimRGB(cSensor,stimulus,theParams,staticParams,runtimeParams,staticComputedValues,ranIndex)
%
% Get sensor values for use in classification.  Returns a structure that contains the resonses
% as well as auxilliary values.
%
% Input is a struct that contains a type field.  The type field is passed back in the coneResponses struct.
% Although there is only one type at present, this design should allow us to implement more complicated
% stimuli and response formats in the future.
%
% Noise is added (or not) depending on the value of theParams.noiseType
%
% If ranIndex is not passed, any randomization associated with which cones to sample is done,
% and the result is returned in this variable.  If it is passed, the passed values are used.
% This allows the same cones to be sampled on multiple calls to this routine.  This can matter,
% because svm's can potentially use differences in noise across cones to do classificaiton, and
% we don't want that.
%
% Implemented types
%   'rgb_uniform' - Responses to a uniform field, specified as linear rgb values for a particular monitor.
%
%   Input:
%     stimulus.type                                  - 'rgb_uniform'
%     stimulus.rgbVector                             - Column vector containing rgb values.
%     stimulus.monitorName                           - Name of monitor that iset knows about (e.g. 'LCD-Apple');
%     stimulus.isetGammaValue                        - The gamma value used by iset when it converts from a read in file (almost surely 2.2).
%
%   Output: 
%     coneResponses.type                             - Specifies type of stimulus used
%     coneResponses.theVectors                       - This backVectors has one vector for each draw, where the vectors
%                                                      are in the columns.  Each row corresponds to one individual cone
%                                                      in the array.
%     coneResponses.oneConeEachClassStartIndices     - The cones in each column are ordered by nominal L, M, and S class.
%                                                      This vector (3 entries) indexes the row of the first cone of each type.
%     coneResponses.iseLMSIsomerizations             - Vector of maximum LMS isomerizations (max taken over space).  Useful
%                                                      for debugging (compare with PTB computed values, etc.)
%     coneResponess.iseLMSQuantalEfficiencies        - The LMS spectral quantal efficiencies that the iset routines are using.
%                                                    - These live in the rows of the 3 by nWavelengths matrix (PTB style).
%     coneResponses.isetLMSQuantalEfficiencyWavelengths - The wavelenghs (nm) at which the iset LMS spectral quantal efficiencies are sampled. 
%
% 8/26/13  dhb  Pulled this out of main code, wrote so it will work for blank and test stimuli.

%% Set return type
%
% Then process according to type
coneResponses.type = stimulus.type;
coneResponses.coneNumbersToUse = stimulus.coneNumbersToUse;

%% Generate the random index, or use passed value
if (nargin < 7 || isempty(ranIndex))
    generateRanIndex = true;
else
    generateRanIndex = false;
end

switch (stimulus.type)
    case 'rgb_uniform'
        %% Filename unique to calling condition and time now, to prevent stepping on ourselves from parfor loop
        imageFileName = sprintf('tmp_%s_%d_%d_%d_%d.png',theParams.OBSERVER_STATE,theParams.DO_TAFC_CLASSIFIER,round(100*theParams.macularPigmentDensityAdjust),...
            round(1000*theParams.cdAngle),now);
        
        %% Create a scene with the background spectrum
        %
        % To patch into scene creation routines, we create an image
        % on disk with spatially uniform RGB values.  These are then treated
        % as frame buffer values, and will be raised to the specified
        % gamma value(gamma uncorrected) by the scene creation routine.
        %
        % [**] Find a way to do this (and the corresponding version
        % for the test) that does not involve writing an image to disk and
        % that skips the gamma correction stuff.
        ungammedRgbVector = stimulus.rgbVector.^(1/staticParams.stimulus.isetGammaValue);
        tmp = ones(staticParams.scenePixels,staticParams.scenePixels,3);
        [tmp,row,col] = RGB2XWFormat(tmp);
        tmp = tmp*diag(ungammedRgbVector(:));
        theImg = XW2RGBFormat(tmp,row,col);
        clear tmp
        imwrite(theImg,imageFileName,'png');
        theScene = sceneFromFile(imageFileName,'rgb',[],[staticParams.stimulus.monitorName '.mat'],staticComputedValues.wavelengthsNm);
        theScene = sceneSet(theScene,'name','temp');
        theScene = sceneSet(theScene,'fov',staticParams.fieldOfViewDegrees);
        delete(imageFileName);
        %vcAddAndSelectObject(sceneB);
        %sceneWindow;
        
        %% Pass the background through the optics
        theOiD = oiCompute(staticComputedValues.oiD, theScene);
        vcAddAndSelectObject(theOiD);
        %oiWindow;
        
        %% Compute noise free sensor image
        theCSensorNF = sensorComputeNoiseFree(cSensor,theOiD);
        %vcAddAndSelectObject(theCSensorNF);
        %sensorWindow;
        
        %% Get noise free cone isomerizations for background
        %
        % Store the max for each sensor class to pass back.
        % We pick the max to avoid the edge effects in the sensor image.
        for ii = 1:staticParams.nSensorClasses
            theSensorValsNF{ii} = sensorGet(theCSensorNF,'electrons',staticParams.isetSensorConeSlots(ii));
            coneResponses.isetLMSIsomerizations(ii) = round(max(theSensorValsNF{ii}));
        end
        
        % Get iset LMS quantal efficiences and wavelengths
        temp = sensorGet(theCSensorNF,'spectralqe')';
        coneResponses.isetLMSQuantalEfficiencies = temp(staticParams.isetSensorConeSlots,:);
        coneResponses.isetLMSQuantalEfficiencyWavelengths = sensorGet(theCSensorNF,'wave');
        clear temp
        
        %% Get multivariate sample distribution of LMS
        % responses out of the sensor objects.
        %
        % Have option of doing this noise free here, so we can add all
        % our noise at an opponent site.  That isn't realistic, but
        % I'm charging ahead just to try to get some intuitions about
        % what opponency does.
        if (theParams.noiseType ~= 0)
            theVoltImage = sensorComputeSamples(theCSensorNF,staticParams.nDrawsPerTestStimulus,theParams.noiseType);
        else
            theVoltImageNF = sensorGet(theCSensorNF,'volts');
            theVoltImage = theVoltImageNF(:,:,ones(1,staticParams.nDrawsPerTestStimulus));
        end
        
        %% I'm sure there is a reason why we put volts back in and then
        % take electrons out.  Brian probably explained it to me.  But
        % now I forget.
        % [** Brian, can you write a comment here?]
        for k = 1:staticParams.nDrawsPerTestStimulus
            for ii = 1:staticParams.nSensorClasses
                theCSensorTemp = sensorSet(theCSensorNF,'volts',theVoltImage(:,:,k));
                theSensorVals{k,ii} = sensorGet(theCSensorTemp,'electrons',staticParams.isetSensorConeSlots(ii));
            end
        end
        clear theVoltImage
        
        %% We want to control the integration area.
        %
        % Here we'll do this by specifying the number of cones
        % of each type to use.
        %
        % First figure out length of sample vector
        if (staticParams.nSensorClasses ~= length(staticParams.stimulus.coneNumbersToUse))
            error('Mismatch in number of sensor classes as specified in different ways in the parameters');
        end
        for ii = 1:staticParams.nSensorClasses
            nUse(ii) = staticParams.stimulus.coneNumbersToUse(ii);
        end
        nUseAll = sum(nUse);
        
        %% Now draw samples
        coneResponses.theVectors = zeros(nUseAll,staticParams.nDrawsPerTestStimulus);
        typeVec = zeros(nUseAll,1);
        coneResponses.oneConeEachClassStartIndices = zeros(staticParams.nSensorClasses,1);
        
        startIndex = 1;
        for ii = 1:staticParams.nSensorClasses
            % Pull out a set of randomly chosen responses for this sensor class
            % and tuck it into the response vector, for both background and test.
            % Also store the sensor class index for each stored response.
            endIndex = startIndex + nUse(ii) - 1;
            
            % Currently, this shufles the responses of each class before
            % pulling out the requisite number of responses, to try in general
            % to avoid any weird edge effects.  The shuffling is constant across
            % draws, so we use the same set of cones for each draw.  
            %
            % Different cones will be used for different calls into this routine,
            % for different simulations, but that should not matter much.
            %
            % [** Better will be to fix this up to be more spatially realistic.]
            if (generateRanIndex)
                ranIndex{ii} = Shuffle(1:length(theSensorVals{1,ii}));
            end
            
            for k = 1:staticParams.nDrawsPerTestStimulus
                if (rem(k,10) == 0)
                    if (~runtimeParams.SIM_QUIET)
                        fprintf('\tGetting cone catches for draw %d of %d\n',k,staticParams.nDrawsPerTestStimulus);
                    end
                end
                
                coneResponses.theVectors(startIndex:endIndex,k) = theSensorVals{k,ii}(ranIndex{ii}(1:nUse(ii)));
                if (k == 1)
                    typeVec(startIndex:endIndex) = ii;
                    coneResponses.oneConeEachClassStartIndices(ii) = startIndex;
                end
            end
            
            startIndex = endIndex+1;
        end
        
    otherwise
        error('Unknown stimulus type specified');
        
end

