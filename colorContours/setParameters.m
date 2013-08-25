function theParams = setParameters(parameterPreset)
%  theParams = setParameters([parameterPreset])
%
% Manage simulation parameters, return as one big struct.
%
% Sets of parameters may be defined and invoked by the
% passed name.  Preset options are:
%   'BasicNoSurround'
%   'BasicRDrawSurround'
%   'BasicDetermSurround'
%   'BasicDetermSurroundWithNoise'
%   'MacularPigmentVary'
%   'QuickTest' [Default]
%
% 9/24/13  dhb  Pulled this out from main routine.
                            
%% Parameter section

% Visual system related
theParams.integrationTimeSecs = 0.050;                    % Temporal integration time for detecting mechanisms.
theParams.fieldOfViewDegrees = 2;                         % Field of view specified for the scenes.
theParams.scenePixels = 64;                               % Size of scenes in pixels
theParams.pupilDiameterMm = 3;                            % Pupil diameter.  Used explicitly in the PSF calc.
                                                          % [** Need to check that this is carried through to 
                                                          % the absorption calculations.  We might be using an isetbio
                                                          % default rather than the value set here.]
theParams.coneProportions = [0.1 .6 .2 .1];               % Proportions of cone types in the mosaic, order: empty, L,M,S
theParams.isetSensorConeSlots = [2 3 4];                  % Indices for LMS cones in iset sensor returns.   These run 2-4 because
                                                          % of the empty pixels
theParams.coneApertureMeters = [sqrt(4.1) sqrt(4.1)]*1e-6;% Size of (rectangular) cone apertures, in meters.
                                                          % The choice of 4.1 matches the area of a 2.3 micron diameter IS diameter,
                                                          % and that is PTB's default.
                                                
% Stimulus related
theParams.monitorName = 'LCD-Apple';                      % Monitor spectrum comes from this file
theParams.backRGBValue = 0.5;                             % Define background for experment in monitor RGB
theParams.gammaValue = 2.2;

theParams.nColorDirections = 16;                          % Number of color directions for contour.
theParams.dirAngleMax = 2*pi;                             % Use pi for sampling directions from hemicircle, 2*pi for whole circle
theParams.nTestLevels = 8;                                % Number of test levels to simulate for each test direction psychometric function.
theParams.nDrawsPerTestStimulus = 400;                    % Number of noise draws used in the simulations, per test stimulus
theParams.criterionCorrect = 0.82;                        % Fraction correct for definition of threshold in TAFC simulations.
theParams.testContrastLengthMax = 0.5;                    % Default maximum contrast lenght of test color vectors used in each color direction.
                                                          % Setting this helps make the sampling of the psychometric functions more efficient.
                                                          % This value can be overridden in a switch statement on OBSERVER_STATE in a loop below.

% Data management parameters
theParams.theContourPlotLim = 0.5;                        % Axis limit for contour plots.
theParams.outputRoot = 'out';                             % Plots get dumped a directory with this root name, but with additional
                                                          % characters to identify parameters of the run tacked on below.

% Preset parameters, vary with preset name.
if (nargin < 1 || isempty(parameterPreset))
    parameterPreset = 'QuickTest';
end
switch (parameterPreset)
                            
    case 'BasicNoSurround'
        theParams.OBSERVER_STATES = {'LMandS' 'MSonly' 'LSonly'}; % Simulate various tri and dichromats
        theParams.DO_TAFC_CLASSIFIER_STATES = [true];             % Can be true, false, or [true false]
        theParams.macularPigmentDensityAdjustments = [0];         % Amount to adjust macular pigment density for cone fundamentals of simulated observer.
                                                                  % Note that stimuli are computed for a nominal (no adjustment) observer.
                                                        
        theParams.noiseType = 1;                                  % Type of photoreceptor noise.  1 -> Poisson.  0 -> none.
        theParams.surroundType = 'none';                          % Define type of surround calc to implement
        theParams.surroundSize = 0;                               % Parameter defining surround size.
        theParams.surroundWeight = 0;                             % Parameter defining surround weight.  NOT YET IMPLEMENTED.
        theParams.integrationArea = 0;                            % Stimulus integration area.  NOT YET IMPLEMENTED.
        theParams.opponentLevelNoiseSd = 0;                       % Noise added after opponent recombination, if any added.
                                                                  % Expressed as a fraction Poisson sd to use.
 
    case 'BasicNoSurroundWithNoise'
        theParams.OBSERVER_STATES = {'LMandS' 'MSonly' 'LSonly'}; 
        theParams.DO_TAFC_CLASSIFIER_STATES = [true];             
        theParams.macularPigmentDensityAdjustments = [0];         
        
        theParams.noiseType = 0;  
        theParams.surroundType = 'determ';                          
        theParams.surroundSize = 0;                               
        theParams.surroundWeight = 0;                             
        theParams.integrationArea = 0;                            
        theParams.opponentLevelNoiseSd = 1;                                                                        
        theParams.testContrastLengthMax = 1;
                                                       
    case 'BasicRDrawSurround'
        theParams.OBSERVER_STATES = {'LMandS' 'MSonly' 'LSonly'}; 
        theParams.DO_TAFC_CLASSIFIER_STATES = [true];             
        theParams.macularPigmentDensityAdjustments = [0];
        
        theParams.noiseType = 1;
        theParams.surroundType = 'rdraw';                         
        theParams.surroundSize = 10;                             
        theParams.surroundWeight = 0.7;                        
        theParams.integrationArea = 0;                            
        theParams.opponentLevelNoiseSd = 0;
        
    case 'BasicDetermSurround'
        theParams.OBSERVER_STATES = {'LMandS' 'MSonly' 'LSonly'}; 
        theParams.DO_TAFC_CLASSIFIER_STATES = [true];             
        theParams.macularPigmentDensityAdjustments = [0]; 
        
        theParams.noiseType = 1;
        theParams.surroundType = 'determ';                         
        theParams.surroundSize = 10;                             
        theParams.surroundWeight = 0.7;                        
        theParams.integrationArea = 0;                            
        theParams.opponentLevelNoiseSd = 0;
        
    case 'BasicDetermSurroundWithNoise'
        theParams.OBSERVER_STATES = {'LMandS' 'MSonly' 'LSonly'}; 
        theParams.DO_TAFC_CLASSIFIER_STATES = [true];             
        theParams.macularPigmentDensityAdjustments = [0]; 
        
        theParams.noiseType = 0;
        theParams.surroundType = 'determ';                         
        theParams.surroundSize = 10;                             
        theParams.surroundWeight = 0.7;                        
        theParams.integrationArea = 0;                            
        theParams.opponentLevelNoiseSd = 1;
        theParams.testContrastLengthMax = 1;

    case 'MacularPigmentVary'
        theParams.OBSERVER_STATES = {'MSonly' 'LSonly'}; 
        theParams.DO_TAFC_CLASSIFIER_STATES = [true];             
        theParams.macularPigmentDensityAdjustments = [-0.3 0 0.3];
        
        theParams.noiseType = 1;
        theParams.surroundType = 'none';                          
        theParams.surroundSize = 0;                              
        theParams.surroundWeight = 0;                             
        theParams.integrationArea = 0;                           
        theParams.opponentLevelNoiseSd = 0;
    
    case 'QuickTest'
        theParams.nColorDirections = 4;
        theParams.dirAngleMax = pi;
        theParams.nTestLevels = 4;
        theParams.nDrawsPerTestStimulus = 100;
        
        theParams.OBSERVER_STATES = {'LMandS'};
        theParams.DO_TAFC_CLASSIFIER_STATES = [false];
        theParams.macularPigmentDensityAdjustments = [0];
        
        theParams.noiseType = 1;
        theParams.surroundType = 'none';                        
        theParams.surroundSize = 0;                              
        theParams.surroundWeight = 0;                            
        theParams.integrationArea = 0;                         
        theParams.opponentLevelNoiseSd = 0;                      
                                                       
    otherwise
        error('Unknown parameter presets');
end

% Convenience parameters
theParams.nSensorClasses = length(theParams.isetSensorConeSlots);
theParams.parameterPreset = parameterPreset;
