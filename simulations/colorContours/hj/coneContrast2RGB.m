function stimRGB = coneContrast2RGB(display,stimContrast,bgRGB,sensors)%% function stimRGB = cone2RGB(display,stimLMS,[bgRGB],[sensors])%%   Calculate the RGB values needed to create a stimulus defined by %   stimLMS and the bgRGB values. %   %   The returned values in stimRGB are the RGB values needed to obtain the %   specified LMS value.  The cone contrast is calculated with respect to %   the background, as in%   %     (lmsStimPlusBack - lmsBack) ./ lmsBack%     %  Inputs%%    display:      ISET compatible display structure%    stimContrast: stimulus LMS value to be shown, can be in formats of 3%                  numbers / XW (N-by-3) / RGB (M-by-N-by-3)%    bgRGB  :      (optional) background RGB values, default .5 gray, if%                  background RGB is given in 8 bits, the outputs will also%                  be encoded in 8 bits%    sensors:      (optional) A matrix of sensor wavelength sensitivities%                  shoulde contain two fields .wavelength and .data%                  Default:  Stockman sensors.%%  Outputs%    stimRGB:  RGB value that can be used to get stimContrast on display%            %  See also:%    RGB2ConeContrast%%  Example:%    display = displayCreate('LCD-Apple');%    stimRGB = coneContrast2RGB(display, [0 0.01 0.03]');%%  History: %    ( BW ) Sep, 1998: create first version of this function%    ( RFD) Nov, 2004: made stockman persistent	%    ( RFD) Apr, 2010: allow an rgb2lms matrix as input%    ( HJ ) Aug, 2013: change i/o structure, compute rgb2lms from isetbio%% Check inputs & Initif nargin < 1, error('Display structure required'); endif nargin < 2, error('stimulus LMS values required'); endif nargin < 3, bgRGB = [.5 .5 .5]'; endif ischar(display), display = displayCreate(display); end%  Convert input to XW formatstimContrastFormat = ndims(stimContrast);if stimContrastFormat == 2 && length(stimContrast) == 3    stimContrastFormat = 1;endswitch stimContrastFormat    case 1 % 3 numbers, convert to 3-by-1 column vector        stimContrast = stimContrast(:);    case 2 % XW format, convert to 3-by-N matrix        assert(size(stimContrast,2) == 3, 'Unknown stimContrast format');        stimContrast = stimContrast';    case 3 % M-by-N-by-3, convert to 3-by-M*N matrix        assert(size(stimContrast,3) == 3, 'Unknown stimContrast format');        [row, col, ~] = size(stimContrast);        stimContrast  = RGB2XWFormat(stimContrast)';    otherwise        error('Unknown stimContrast format');end% Convert background RGB to column vectorbgRGB        = bgRGB(:);use8bit      = false; % Init flag indicating if it's an 8 bit inputif max(bgRGB) > 1    bgRGB = bgRGB / 255; % Assume it's 8 bit    use8bit = any(bgRGB > 0); % [0 0 0] is not considered as 8 bit    assert(all(bgRGB >=0) && all(bgRGB <= 1));end%% Compute rgb2lms conversino matrix%  Compute matrix with no unit considerationif nargin < 4 || isempty(sensors) % Sensor not specified, use stockman    [~, rgb2lms] = humanConeIsolating(display);else % Use another sensor model    wave    = sensors.wavelength;    spd     = displayGet(display,'spd',wave);    rgb2lms = sensors.data'*spd;end%  Scaling for unitsif ~exist('wave','var'), wave = displayGet(display, 'wave'); enddWave = wave(2) - wave(1);rgb2lms = rgb2lms * 683 * dWave;%% Compute stimRGB for specified contrast%  Compue LMS for backgroundbgLMS   = rgb2lms * bgRGB;%  Compute output stimulus LMSstimLMS = (stimContrast + 1) .* repmat(bgLMS, [1 size(stimContrast, 2)]);%  Convert to RGBstimRGB = rgb2lms \ stimLMS; % inv(rgb2lms) * stimLMS%  Convert to proper formatswitch stimContrastFormat    case 1 % should by 3-by-1 now, do nothing    case 2 % convert to XW format, namely, N-by-3        stimRGB = stimRGB';    case 3 % convert to M-by-N-by-3        stimRGB = XW2RGBFormat(stimRGB', row, col);    otherwise        error('How could you get here');end%% Check availability and convert to same bitdepth as inputif any(stimRGB(:)) < 0 || any(stimRGB(:)) > 1    warning('Part of desired contrast cannot be obtained on that display');endif use8bit    stimRGB = stimRGB * 255;endend