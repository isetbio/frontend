function [acc, err, staticValues] = ccAccuracy(simParams, staticValues)
%% function ccAccuracy(simParams)
%    find classification accuracy for color discrimination experiment
%    defined in simParams
%
%  Inputs:
%    simParams    - structure, contains all information about experiment,
%                   for more information about the structure, please refer 
%                   to setParameters (Name might be changed afterwards) and
%                   constructSimulationParameters
%    staticValues - contains precomputed values
%                   Required fields include
%                     .refRGB,  reference color RGB value in 0~1
%                     .display, ISET compatible dispaly structure
%                     .sensor,  human eye sensor structure
%                   Optional fields include
%                     .cbType, colorblind type
%                     .scenePixels, size of patches in pixels
%                     .refScene, ISET scene structure for reference color
%                     .refOI,    optical image for reference color
%                     .isRefVoltsImgComputed, bool, indicating whether
%                                volts image for reference color exists in
%                                sensor structure
%
%
%  Outputs:
%    acc          - classification accuracy
%    err          - standard deviation of accuracies in cross validation
%    staticValues - static value structure with optional fields computed,
%                   this is useful only when program is not run in
%                   parellel, otherwise, do not use this output
%
%  Example:
%
%
%  See also:
%    setParameters, 
%
%  DHB/BW/HJ ISETBIO Team, 2013

%% Check inputs
if nargin < 1, error('simulation parameter structure required'); end
if nargin < 2, error('static values structure required'); end

%% Compute photon images for reference image
%  if scene for reference color is not set, create it
if ~isfield(staticValues, 'refScene')
    refImg   = ones([staticValues.scenePixels 3]);
    for i = 1 : 3
        refImg(:,:,i) = simParams.matchRGB(i);
    end
    refImgName = fullfile(isetbioRootPath,'tmp',['refImg_' ...
                        num2str(randi(1e6)) '.png']);
    staticValues.refScene = sceneFromFile(refImgName, 'rgb', ...
                                          [], staticValues.display);
    delete(refImgName);
end
% vcAddAndSelectObject(staticValues.refScene); sceneWindow;

%  if refOI is not computed, create and compute it
if ~isfield(staticValues, 'refOI')
    wave   = 380 : 4 : 780;
    wvf    = wvfCreate('wave',wave);
    pupilDiameterMm = 3;
    sample_mean = wvfLoadThibosVirtualEyes(pupilDiameterMm);
    wvf    = wvfSet(wvf,'zcoeffs',sample_mean);
    wvf    = wvfComputePSF(wvf);
    staticValues.refOI = wvf2oi(wvf,'shift invariant');
end

%  if photon images is not computed, compute and store it
if ~isfield(staticValues, 'isRefVoltsImgComputed') || ...
        ~staticValues.isRefVoltsImgComputed
    nFrames = 100;
    staticValues.sensor = coneSamples(staticValues.refScene, nFrames, ...
        staticValues.sensor, staticValues.refOI);
end

% get photon absorptions from each cone in the sensor array
refPhotons = sensorGet(staticValues.sensor,'photons');

%% Compute photon images for match image
%  Compute match image color
if ~isfield(simParams, 'matchRGB')
    % Comment will appear
    disp('No matchRGB')
end
%  Create image for match color
if ~isfield(staticValues, 'scenePixels')
    staticValues.scenePixels = [64 64]; 
end
if isscalar(staticValues.scenePixels)
    val = staticValues.scenePixels;
    staticValues.scenePixels = [val val];
end

% This creates the data that will be written out into the scene file
matchImg   = ones([staticValues.scenePixels 3]);
for i = 1 : 3
    matchImg(:,:,i) = simParams.matchRGB(i);
end

% Create scene for match patch
% should change the random number to some simulation
matchImgName = fullfile(isetbioRootPath,'tmp',['matchImg_' ...
    num2str(randi(1e6)) '.png']);
imwrite(matchImg, matchImgName);

% Re-write sceneFromFile so instead of a file name, we can send in RGB
% data. Also, allow the display to be either a name of a file or a display
% structure. 
matchScene = sceneFromFile(matchImgName, 'rgb', [], staticValues.display.name);
matchScene = sceneSet(matchScene,'h fov',sceneGet(staticValues.refScene,'h fov'));
% vcAddAndSelectObject(matchScene); sceneWindow;

% clean up
delete(matchImgName);

%  Compute cone samples
sensor = coneSamples(matchScene, nFrames, staticValues.sensor, ...
    staticValues.refOI);
matchPhotons = sensorGet(sensor, 'photons');
%% Classification

svmOpts = '-s 0 -t 0';
predictOpts = ' -q';
% if (runtimeParams.SIM_QUIET)
%     svmOpts =  [svmOpts ' -q'];
%     % predictOpts = [predictOpts ' -q'];
% end

% We have matchPhotons - these are the test stimuli
% We have refPhotons - these are the absorptions to the background
% We take half of them and train 
trainLabels = [ones(50,1); -1*ones(50,1)];
trainRefPhotons   = RGB2XWFormat(refPhotons(:,:,1:50))';
trainMatchPhotons = RGB2XWFormat(matchPhotons(:,:,1:50))';
% trainingD = cat(,matchPhotons(:,:,1:50),3)

% Each row is a photon image
svmModel = svmtrain(trainLabels, double(cat(1,trainRefPhotons,trainMatchPhotons)), svmOpts);

testLabels = [ones(50,1); -1*ones(50,1)];
testRefPhotons   = RGB2XWFormat(refPhotons(:,:,51:end))';
testMatchPhotons = RGB2XWFormat(matchPhotons(:,:,51:end))';

[predictLabels, accuracy, foo] = svmpredict(testLabels, double(cat(1,testRefPhotons,testMatchPhotons)), svmModel, predictOpts);
acc = accuracy(1);  % This is the probability correct

%% Tell the calling routine that we computed the refPhotons
staticValues.isRefVoltsImgComputed = true;

end