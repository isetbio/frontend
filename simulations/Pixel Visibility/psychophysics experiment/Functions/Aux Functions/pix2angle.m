function angle = pix2angle(display,pix, units)%% function pix2angle(display,angle,[units])%    Transform number of pixels on screen to visual angle%%  Inputs:%    display - ISET compatible display structure%    pix     - Number of pixels on screen%    units   - Units of angle, default in degree%%  Output:%    ang     - Visual angle of the scene%%  Example:%    d   = displayCreate;%    ang = pix2angle(d,100,'degree');%%  See also:%    angle2pix%% (HJ) Aug, 2013%% Check inputsif nargin < 1, error('Display structure required'); endif nargin < 2, error('Number of pixels required'); endif nargin < 3, units = 'deg'; endif isempty(units), units = 'deg'; end%% Compute visual angle in specific units%  Compute visual angle in radiansmpd   = displayGet(display,'meters per dot');                      dist  = displayGet(display,'Viewing Distance');angle = 2 * atan(mpd * pix / dist /2);%  Check and convert unitsswitch lower(units)    case {'rad','radians'}    case {'deg','degree'}        angle = angle * ieUnitScaleFactor('deg');    case {'arcmin','arcsec'}        angle = angle * ieUnitScaleFactor(units);    otherwise        error('Unknown units for visual angle');endend