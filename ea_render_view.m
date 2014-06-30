function resultfig=ea_render_view(varargin)
% This function is the main 3D-visualization function of lead DBS. It
% reads all atlases found in the lead_root/atlases folder, calculates a
% convex hull around the nonzero area and renders it as 3D surfaces.
% Resulting figures are interactive and objects can be hidden. This
% functionality is preserved as long as the files are saved as .fig Matlab
% figures and the functions remain on the path when figures are reopened
% lateron. Basically, this function only needs a valid options struct as input.
% __________________________________________________________________________________
% Copyright (C) 2014 Charite University Medicine Berlin, Movement Disorders Unit
%
% Andreas Horn


% Initialize inputs
options=varargin{1};
if nargin>2
    stimparams=varargin{3};
else
    stimparams=nan;
end
if nargin==4
    fiberthresh=varargin{4};
else
    
    fiberthresh=options.fiberthresh;
end
if nargin>1
    multiplemode=1;
    elstruct=varargin{2};
    
else
    multiplemode=0;
    
    try
        load([options.root,options.patientname,filesep,'ea_reconstruction']);
    catch
        coords_mm=ea_read_fiducials([options.root,options.patientname,filesep,'ea_coords.fcsv'],options);
    end
    
    try
        load([options.root,options.patientname,filesep,'ea_reconstruction.mat']);
    catch % generate trajectory from coordinates.
        trajectory{1}=ea_fit_line(coords_mm(1:4,:));
        trajectory{2}=ea_fit_line(coords_mm(options.elspec.numel+1:options.elspec.numel+4,:));
    end
    
    elstruct(1).coords_mm=coords_mm;
    elstruct(1).trajectory=trajectory;
    elstruct(1).name=options.patientname;
    clear coords_mm trajectory
end

% Initialize figure

resultfig=figure('name',[options.patientname,': Electrode-Scene'],'numbertitle','off','CloseRequestFcn',@closesattelites,'visible',options.d3.verbose);
set(resultfig, 'Position', get(0,'Screensize')); % Maximize figure.


% Get paramters (Coordinates and fitted line).

figtitle=get(gcf,'Name');
set(gcf,'Name',[figtitle,'...building...']);
axis equal




ht=uitoolbar(resultfig);

% Set some visualization parameters

set(gcf,'Renderer','OpenGL')
axis off
set(gcf,'color','w');

% show electrode(s).


for pt=1:length(elstruct)
    [el_render(pt).el_render]=ea_showelectrode(resultfig,elstruct(pt),pt,options);
    try
        if multiplemode
            caption{1}=[elstruct(pt).name,'_Left'];         caption{2}=[elstruct(pt).name,'_Right'];
        else
            caption{1}='Electrode_Left'; caption{2}='Electrode_Right';
        end
        uitoggletool(ht,'CData',ea_get_icn('electrode',options),'TooltipString',caption{1},'OnCallback',{@objvisible,el_render(pt).el_render{2}},'OffCallback',{@objinvisible,el_render(pt).el_render{2}},'State','on');
        uitoggletool(ht,'CData',ea_get_icn('electrode',options),'TooltipString',caption{2},'OnCallback',{@objvisible,el_render(pt).el_render{1}},'OffCallback',{@objinvisible,el_render(pt).el_render{1}},'State','on');
    end
    
    if options.d3.elrendering==1 % export vizstruct for lateron export to JSON file / Brainbrowser.
        
        
        vizstruct=struct('faces',[],'vertices',[],'colors',[]);
        
        
        extract=[1,4,7,10,13,16,19,22,25]; % surfaces without endplates.
        labels={'rel_traj','lel_traj','rel_btwc1','lel_btwc1','rel_btwc2','lel_btwc2','rel_btwc3','lel_btwc3'...
            'rel_cnt1','lel_cnt1','rel_cnt2','lel_cnt2','rel_cnt3','lel_cnt3','rel_cnt4','lel_cnt4','rel_tip','lel_tip',};
        cnt=1;
        for ex=extract
            for side=1:2
                
                ps = surf2patch(get(el_render(pt).el_render{side}(ex),'XData'),get(el_render(pt).el_render{side}(ex),'YData'),get(el_render(pt).el_render{side}(ex),'ZData'),'triangles');
                % temporally plot electrode to get vertex normals..
                tmp=figure('visible','off');
                tp=patch(ps);
                
                vizstruct(cnt).normals=get(tp,'VertexNormals');
                delete(tmp);
                vizstruct(cnt).faces=ps.faces;
                vizstruct(cnt).vertices=ps.vertices;
                scolor=get(el_render(pt).el_render{side}(ex),'CData');
                vizstruct(cnt).colors=repmat([squeeze(scolor(1,1,:))',0.7],length(vizstruct(cnt).faces),1);
                vizstruct(cnt).name=labels{cnt};
                cnt=cnt+1;
                
            end
        end
    end
    
end




% Initialize a draggable lightbulb

[resultfig,lightbulb]=ea_show_light(resultfig);
set(lightbulb, 'Visible', 'off');
lightbulbbutton=uitoggletool(ht,'CData',ea_get_icn('lightbulb',options),'TooltipString','Lightbulb','OnCallback',{@objvisible,lightbulb},'OffCallback',{@objinvisible,lightbulb});


clightbulbbutton=uitoggletool(ht,'CData',ea_get_icn('clightbulb',options),'TooltipString','Lightbulb','OnCallback',{@objvisible,getappdata(gcf,'ceiling_lamp')},'OffCallback',{@objinvisible,getappdata(gcf,'ceiling_lamp')},'State','on');
llightbulbbutton=uitoggletool(ht,'CData',ea_get_icn('llightbulb',options),'TooltipString','Lightbulb','OnCallback',{@objvisible,getappdata(gcf,'right_lamp')},'OffCallback',{@objinvisible,getappdata(gcf,'right_lamp')},'State','on');
rlightbulbbutton=uitoggletool(ht,'CData',ea_get_icn('rlightbulb',options),'TooltipString','Lightbulb','OnCallback',{@objvisible,getappdata(gcf,'left_lamp')},'OffCallback',{@objinvisible,getappdata(gcf,'left_lamp')},'State','on');


% Initialize HD-Export button

hdsavebutton=uipushtool(ht,'CData',ea_get_icn('save',options),'TooltipString','Save Scene','ClickedCallback',@export_hd);

% Initialize Export to Lead-Server button

lsbutton=uipushtool(ht,'CData',ea_get_icn('server',options),'TooltipString','Export to Server','ClickedCallback',{@ea_export_server,options});

% Initialize Sliceview-Button

slicebutton=uipushtool(ht,'CData',ea_get_icn('slices',options),'TooltipString','Slice Control Figure','ClickedCallback',{@opensliceviewer,resultfig,options});


% Initialize Stimulation-Button

stimbutton=uipushtool(ht,'CData',ea_get_icn('stimulation',options),'TooltipString','Stimulation Control Figure','ClickedCallback',{@openstimviewer,elstruct,resultfig,options});




% Show atlas data
if options.d3.writeatlases
    atlases=ea_showatlas(resultfig,elstruct,options);
    if options.d3.elrendering==1 % export vizstruct for lateron export to JSON file / Brainbrowser.
        cnt=length(vizstruct);
        
        % export vizstruct
        for side=1:2
            for atl=1:length(atlases.fv)
                
                if isfield(atlases.fv{atl,side},'faces')
                    vizstruct(cnt+1).faces=atlases.fv{atl,side}.faces;
                    vizstruct(cnt+1).vertices=atlases.fv{atl,side}.vertices;
                    vizstruct(cnt+1).normals=atlases.normals{atl,side};
                    vizstruct(cnt+1).colors=[squeeze(ind2rgb(round(atlases.cdat{atl,side}),atlases.colormap)),repmat(0.7,size(atlases.normals{atl,side},1),1)];
                    cnt=cnt+1;
                end
            end
        end
        
        
    end
end

% Show isomatrix data

if options.d3.showisovolume && options.d3.isovscloud>1
    
    ea_showisovolume(resultfig,elstruct,options);
    
end
set(0,'CurrentFigure',resultfig);

set(gcf,'Renderer','OpenGL')
axis off
set(gcf,'color','w');
axis vis3d
axis equal
set(gcf,'Name',figtitle);



if options.d3.elrendering==1 % export vizstruct for lateron export to JSON file / Brainbrowser.
    
    % store json in figure file
    
    bbstruct=ea_viz2brainbrowser(vizstruct);
    setappdata(resultfig,'bbstruct',bbstruct);
    
    if options.prefs.ls.autosave
        ea_export_server([],[],options);
    end
end













function opensliceviewer(hobj,ev,resultfig,options)
awin=ea_anatomycontrol(gcf,options);
setappdata(resultfig,'awin',awin);
WinOnTop(awin,true);


function openstimviewer(hobj,ev,elstruct,resultfig,options)
stimwin=ea_stimparams(elstruct,gcf,options);
setappdata(resultfig,'stimwin',stimwin);
WinOnTop(stimwin,true);



function closesattelites(src,evnt)
stimwin=getappdata(gcf,'stimwin');
try
    close(stimwin)
end
awin=getappdata(gcf,'awin');
try
    close(awin)
end
delete(gcf)

function export_hd(hobj,ev)

[FileName,PathName] = uiputfile('LEAD_Scene.png','Save file name');

set(gcf, 'Color', [1,1,1]);
[~, cdata] = ea_myaa([4, 2]);

imwrite(cdata, [PathName,FileName], 'png');

function objvisible(hobj,ev,atls)
set(atls, 'Visible', 'on');

function objinvisible(hobj,ev,atls)
set(atls, 'Visible', 'off');

function [varargout] = ea_myaa(varargin)
% This function has been slightly modified for export use in eAuto-DBS.
% Copyright (c) 2009, Anders Brun
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.

%   See also PUBLISH, PRINT
%
%   Version 1.1, 2008-08-21
%   Version 1.0, 2008-08-05
%
%   Author: Anders Brun
%           anders@cb.uu.se
%

%% Force drawing of graphics
drawnow;

%% Find out about the current DPI...
screen_DPI = get(0,'ScreenPixelsPerInch');

%% Determine the best choice of convolver.
% If IPPL is available, imfilter is much faster. Otherwise it does not
% matter too much.
try
    if ippl()
        myconv = @imfilter;
    else
        myconv = @conv2;
    end
catch
    myconv = @conv2;
end

%% Set default options and interpret arguments
if isempty(varargin)
    self.K = [4 4];
    try
        imfilter(zeros(2,2),zeros(2,2));
        self.aamethod = 'imresize';
    catch
        self.aamethod = 'standard';
    end
    self.figmode = 'figure';
elseif strcmp(varargin{1},'publish')
    self.K = [4 4];
    self.aamethod = 'noshrink';
    self.figmode = 'publish';
elseif strcmp(varargin{1},'update')
    self = get(gcf,'UserData');
    figure(self.source_fig);
    drawnow;
    self.figmode = 'update';
elseif strcmp(varargin{1},'lazyupdate')
    self = get(gcf,'UserData');
    self.figmode = 'lazyupdate';
elseif length(varargin) == 1
    self.K = varargin{1};
    if length(self.K) == 1
        self.K = [self.K self.K];
    end
    if self.K(1) > 16
        error('To avoid excessive use of memory, K has been limited to max 16. Change the code to fix this on your own risk.');
    end
    try
        imfilter(zeros(2,2),zeros(2,2));
        self.aamethod = 'imresize';
    catch
        self.aamethod = 'standard';
    end
    self.figmode = 'figure';
elseif length(varargin) == 2
    self.K = varargin{1};
    self.aamethod = varargin{2};
    self.figmode = 'figure';
elseif length(varargin) == 3
    self.K = varargin{1};
    self.aamethod = varargin{2};
    self.figmode = varargin{3};
    if strcmp(self.figmode,'publish') && ~strcmp(varargin{2},'noshrink')
        printf('\nThe AAMETHOD was not set to ''noshrink'': Fixed.\n\n');
        self.aamethod = 'noshrink';
    end
else
    error('Wrong syntax, run: help myaa');
end

if length(self.K) == 1
    self.K = [self.K self.K];
end

%% Capture current figure in high resolution
if ~strcmp(self.figmode,'lazyupdate');
    tempfile = 'lead_temp_screendump.png';
    self.source_fig = gcf;
    current_paperpositionmode = get(self.source_fig,'PaperPositionMode');
    current_inverthardcopy = get(self.source_fig,'InvertHardcopy');
    set(self.source_fig,'PaperPositionMode','auto');
    set(self.source_fig,'InvertHardcopy','off');
    print(self.source_fig,['-r',num2str(1.5*screen_DPI*self.K(1))], '-dpng', tempfile); % change 1.5 to e.g. 2 to get even higher resolution image out.
    set(self.source_fig,'InvertHardcopy',current_inverthardcopy);
    set(self.source_fig,'PaperPositionMode',current_paperpositionmode);
    self.raw_hires = imread(tempfile);
    delete(tempfile);
end
%% Start filtering to remove aliasing
w = warning;
warning off;
if strcmp(self.aamethod,'standard') || strcmp(self.aamethod,'noshrink')
    % Subsample hires figure image with standard anti-aliasing using a
    % butterworth filter
    kk = lpfilter(self.K(2)*3,self.K(2)*0.9,2);
    mm = myconv(ones(size(self.raw_hires(:,:,1))),kk,'same');
    a1 = max(min(myconv(single(self.raw_hires(:,:,1))/(256),kk,'same'),1),0)./mm;
    a2 = max(min(myconv(single(self.raw_hires(:,:,2))/(256),kk,'same'),1),0)./mm;
    a3 = max(min(myconv(single(self.raw_hires(:,:,3))/(256),kk,'same'),1),0)./mm;
    if strcmp(self.aamethod,'standard')
        if abs(1-self.K(2)) > 0.001
            raw_lowres = double(cat(3,a1(2:self.K(2):end,2:self.K(2):end),a2(2:self.K(2):end,2:self.K(2):end),a3(2:self.K(2):end,2:self.K(2):end)));
        else
            raw_lowres = self.raw_hires;
        end
    else
        raw_lowres = double(cat(3,a1,a2,a3));
    end
elseif strcmp(self.aamethod,'imresize')
    % This is probably the fastest method available at this moment...
    raw_lowres = single(imresize(self.raw_hires,1/self.K(2),'bilinear'))/256;
end
warning(w);

%% Place the anti-aliased image in some image on the screen ...
if strcmp(self.figmode,'figure');
    % Create a new figure at the same place as the previous
    % The content of this new image is just a bitmap...
    oldpos = get(gcf,'Position');
    self.myaa_figure = figure('Name','Export','Visible','off');
    fig = self.myaa_figure;
    set(fig,'Menubar','none');
    set(fig,'Resize','off');
    sz = size(raw_lowres);
    set(fig,'Units','pixels');
    pos = [oldpos(1:2) sz(2:-1:1)];
    set(fig,'Position',pos);
    ax = axes;
    hi = image(raw_lowres);
    set(ax,'Units','pixels');
    set(ax,'Position',[1 1 sz(2) sz(1)]);
    axis off;
elseif strcmp(self.figmode,'publish');
    % Create a new figure at the same place as the previous
    % The content of this new image is just a bitmap...
    self.myaa_figure = figure('Name','Export','Visible','off');
    fig = self.myaa_figure;
    current_units = get(self.source_fig,'Units');
    set(self.source_fig,'Units','pixels');
    pos = get(self.source_fig,'Position');
    set(self.source_fig,'Units',current_units);
    set(fig,'Position',[pos(1) pos(2) pos(3) pos(4)]);
    ax = axes;
    hi=image(raw_lowres);
    set(ax,'Units','normalized');
    set(ax,'Position',[0 0 1 1]);
    axis off;
    close(self.source_fig);
elseif strcmp(self.figmode,'update');
    fig = self.myaa_figure;
    figure(fig);
    clf;
    set(fig,'Menubar','none');
    set(fig,'Resize','off');
    sz = size(raw_lowres);
    set(fig,'Units','pixels');
    pos = get(fig,'Position');
    pos(3:4) = sz(2:-1:1);
    set(fig,'Position',pos);
    ax = axes;
    hi=image(raw_lowres);
    set(ax,'Units','pixels');
    set(ax,'Position',[1 1 sz(2) sz(1)]);
    axis off;
elseif strcmp(self.figmode,'lazyupdate');
    clf;
    fig = self.myaa_figure;
    sz = size(raw_lowres);
    pos = get(fig,'Position');
    pos(3:4) = sz(2:-1:1);
    set(fig,'Position',pos);
    ax = axes;
    hi=image(raw_lowres);
    set(ax,'Units','pixels');
    set(ax,'Position',[1 1 sz(2) sz(1)]);
    axis off;
end

%% Store current state

set(gcf,'userdata',self);
set(gcf,'KeyPressFcn',@keypress);
set(gcf,'Interruptible','off');

%% Avoid unnecessary console output
if nargout == 1
    varargout(1) = {fig};
elseif nargout == 2
    varargout(1) = {fig};
    varargout(2) = {get(hi, 'CData')};
    close(self.myaa_figure);
end

%% A simple lowpass filter kernel (Butterworth).
% sz is the size of the filter
% subsmp is the downsampling factor to be used later
% n is the degree of the butterworth filter
function kk = lpfilter(sz, subsmp, n)
sz = 2*floor(sz/2)+1; % make sure the size of the filter is odd
cut_frequency = 0.5 / subsmp;
range = (-(sz-1)/2:(sz-1)/2)/(sz-1);
[ii,jj] = ndgrid(range,range);
rr = sqrt(ii.^2+jj.^2);
kk = ifftshift(1./(1+(rr./cut_frequency).^(2*n)));
kk = fftshift(real(ifft2(kk)));
kk = kk./sum(kk(:));

function keypress(src,evnt)
if isempty(evnt.Character)
    return
end
recognized = 0;
self = get(gcf,'userdata');

if evnt.Character == '+'
    self.K(2) = max(self.K(2).*0.5^(1/2),1);
    recognized = 1;
    set(gcf,'userdata',self);
    myaa('lazyupdate');
elseif evnt.Character == '-'
    self.K(2) = min(self.K(2).*2^(1/2),16);
    recognized = 1;
    set(gcf,'userdata',self);
    myaa('lazyupdate');
elseif evnt.Character == ' ' || evnt.Character == 'r' || evnt.Character == 'R'
    set(gcf,'userdata',self);
    myaa('update');
elseif evnt.Character == 'q'
    close(gcf);
elseif find('123456789' == evnt.Character)
    self.K = [str2double(evnt.Character) str2double(evnt.Character)];
    set(gcf,'userdata',self);
    myaa('update');
end






function WasOnTop = WinOnTop( FigureHandle, IsOnTop )
%WINONTOP allows to trigger figure's "Always On Top" state
% INPUT ARGUMENTS:
% * FigureHandle - Matlab's figure handle, scalar
% * IsOnTop      - logical scalar or empty array
%
% USAGE:
% * WinOnTop( hfigure, bool );
% * WinOnTop( hfigure );            - equal to WinOnTop( hfigure,true);
% * WinOnTop();                     - equal to WinOnTop( gcf, true);
% * WasOnTop = WinOnTop(...);       - returns boolean value "if figure WAS on top"
% * IsOnTop  = WinOnTop(hfigure,[]) - gets "if figure is on top" property
%
% LIMITATIONS:
% * java enabled
% * figure must be visible
% * figure's "WindowStyle" should be "normal"
%
%
% Written by Igor
% i3v@mail.ru
%
% 16 June 2013 - Initial version
% 27 June 2013 - removed custom "ishandle_scalar" function call
%

%% Parse Inputs

if ~exist('FigureHandle','var');FigureHandle = gcf; end
assert(...
    isscalar( FigureHandle ) && ishandle( FigureHandle ) &&  strcmp(get(FigureHandle,'Type'),'figure'),...
    'WinOnTop:Bad_FigureHandle_input',...
    '%s','Provided FigureHandle input is not a figure handle'...
    );

assert(...
    strcmp('on',get(FigureHandle,'Visible')),...
    'WinOnTop:FigInisible',...
    '%s','Figure Must be Visible'...
    );

assert(...
    strcmp('normal',get(FigureHandle,'WindowStyle')),...
    'WinOnTop:FigWrongWindowStyle',...
    '%s','WindowStyle Must be Normal'...
    );

if ~exist('IsOnTop','var');IsOnTop=true;end
assert(...
    islogical( IsOnTop ) &&  isscalar( IsOnTop) || isempty( IsOnTop ), ...
    'WinOnTop:Bad_IsOnTop_input',...
    '%s','Provided IsOnTop input is neither boolean, nor empty'...
    );
%% Pre-checks

error(javachk('swing',mfilename)) % Swing components must be available.


%% Action

% Flush the Event Queue of Graphic Objects and Update the Figure Window.
drawnow expose

jFrame = get(handle(FigureHandle),'JavaFrame');

drawnow

WasOnTop = jFrame.fHG1Client.getWindow.isAlwaysOnTop;

if ~isempty(IsOnTop)
    jFrame.fHG1Client.getWindow.setAlwaysOnTop(IsOnTop);
end



