%% s_colorContours
%    Compute color discrimination contours
%
%  (HJ) ISETBIO TEAM, 2014

%% Init parameters
s_initISET;
ref     = [0 0 0];
dirList = 0:10:359;  % directions
cropSz  = 24;

%% Compute classification accuracy
%  Set up proclus command
cmd = '[thresh, expData] = ccThreshold(ref, dirList(jobindex), params);';
cmd = [cmd 'save(sprintf(''~/ccContour%d.mat'',jobindex));'];
params.ccParams.cropSz = cropSz;
try % try use proclus
    sgerun2(cmd, 'colorContour', 1, 1:length(dirList));
catch % compute locally
    for ii = 1 : length(dirList)
        [thresh, expData] = ccThreshold(ref, dirList(ii), params);
        save(sprintf('~/ccContour%d.mat', ii));
    end
end

%% Plot color contour
threshPts = zeros(length(dirList), 3);

for ii = 1 : length(dirList)
    fName = sprintf('./ccContour%d.mat', ii);
    data = load(fName);
    curDir = dirList(ii); % current direction
    threshPts(ii, :) = ref + data.thresh*[cosd(curDir) sind(curDir) 0];
end

% fit ellipse and plot
figure; hold on;
plot(threshPts(:,1), threshPts(:,2), 'xr'); % plot points
[zg, ag, bg, alphag] = fitellipse(threshPts(:,1:2));
plotellipse(zg, ag, bg, alphag, 'b--')

axis equal; grid on;
xlabel('L contrast'); ylabel('M contrast');