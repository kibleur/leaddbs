function atlases=ea_showatlas(varargin)
% This function shows atlas data in the 3D-Scene viewer. It
% reads in all atlases found in the eAuto_root/atlases folder, calculates a
% convex hull around the nonzero area and renders this area as 3D surfaces.
% For a small part of contact statistics, the function uses
% inhull.m which is covered by the BSD-license (see below).
% __________________________________________________________________________________
% Copyright (C) 2014 Charite University Medicine Berlin, Movement Disorders Unit
% Andreas Horn

maxcolor=64; % change to 45 to avoid red / 64 to use all colors


resultfig=varargin{1};
if nargin==2
    options=varargin{2};
end
if nargin>2
    elstruct=varargin{2};
    options=varargin{3};
end


nm=[0:1]; % native and mni
try
nmind=[options.atl.pt,options.atl.can]; % which shall be performed?
catch
    nmind=[0 1];
end
nm=nm(logical(nmind)); % select which shall be performed.



for nativemni=nm % switch between native and mni space atlases.
    
    switch nativemni
        case 0
            root=[options.root,options.patientname,filesep];
        case 1
            root=options.earoot;
    end

atlascnt=1;
set(0,'CurrentFigure',resultfig)

if ~exist([root,'atlases',filesep,options.atlasset,filesep,'atlas_index.mat'],'file')
    atlases=ea_genatlastable(root,options);
else
    load([root,'atlases',filesep,options.atlasset,filesep,'atlas_index.mat']);
end


if options.writeoutstats
    try
    load([options.root,options.patientname,filesep,'ea_stats']);
    prioratlasnames=ea_stats.atlases.names;
    end
end


try
    jetlist=options.colormap;
    atlases.colormap=jetlist;
    colormap(jetlist)
catch
    
    if isfield(atlases,'colormap');
        
        try
            jetlist=eval(atlases.colormap);
            
        catch
            jetlist=atlases.colormap;
            
        end
        colormap(atlases.colormap);
        
        
        
    else
        atlases.colormap='jet';
        jetlist=jet;
    end
end



setinterpol=1;

ht=uitoolbar(resultfig);

% prepare stats fields
if options.writeoutstats
    
    for el=1:length(elstruct)
        for side=1:length(elstruct(el).coords_mm)
            ea_stats.conmat{el,side}=nan(size(elstruct(el).coords_mm{side},1),length(atlases.names));
            ea_stats.conmat_inside_vox{el,side}=nan(size(elstruct(el).coords_mm{side},1),length(atlases.names));
            ea_stats.conmat_inside_hull{el,side}=nan(size(elstruct(el).coords_mm{side},1),length(atlases.names));
            ea_stats.patname{el,side}=elstruct(el).name;
        end
    end
    ea_stats.atlases=atlases;
    ea_stats.electrodes=elstruct;
end

% iterate through atlases, visualize them and write out stats.
for atlas=1:length(atlases.names)
    
    if ~isfield(atlases,'fv') % rebuild from nii files
        switch atlases.types(atlas)
            case 1 % left hemispheric atlas.
                [nii,V]=load_nii_proxy([root,'atlases',filesep,options.atlasset,filesep,'lh',filesep,atlases.names{atlas}],options);
                nii.img=round(nii.img);
                
            case 2 % right hemispheric atlas.
                [nii,V]=load_nii_proxy([root,'atlases',filesep,options.atlasset,filesep,'rh',filesep,atlases.names{atlas}],options);
                nii.img=round(nii.img);
            case 3 % both-sides atlas composed of 2 files.
                [lnii,lV]=load_nii_proxy([root,'atlases',filesep,options.atlasset,filesep,'lh',filesep,atlases.names{atlas}],options);
                [rnii,rV]=load_nii_proxy([root,'atlases',filesep,options.atlasset,filesep,'rh',filesep,atlases.names{atlas}],options);
                lnii.img=round(lnii.img);
                rnii.img=round(rnii.img);
            case 4 % mixed atlas (one file with both sides information.
                [nii,V]=load_nii_proxy([root,'atlases',filesep,options.atlasset,filesep,'mixed',filesep,atlases.names{atlas}],options);
                nii.img=round(nii.img);
            case 5 % midline atlas (one file with both sides information.
                [nii,V]=load_nii_proxy([root,'atlases',filesep,options.atlasset,filesep,'midline',filesep,atlases.names{atlas}],options);
                nii.img=round(nii.img);
        end
    end
    
    for side=detsides(atlases.types(atlas));
        if ~isfield(atlases,'fv') % rebuild from nii files
            
            if atlases.types(atlas)==3 % both-sides atlas composed of 2 files.
                if side==1
                    nii=lnii;
                    V=lV;
                elseif side==2
                    nii=rnii;
                    V=rV;
                end
            end
        
        
        
        
        colornames='bgcmywkbgcmywkbgcmywkbgcmywkbgcmywkbgcmywkbgcmywkbgcmywkbgcmywk'; % red is reserved for the VAT.
        
        colorc=colornames(1);
        colorc=rgb(colorc);
            
            [xx,yy,zz]=ind2sub(size(nii.img),find(nii.img>0)); % find 3D-points that have correct value.
            
            
            if ~isempty(xx)
                
                XYZ=[xx,yy,zz]; % concatenate points to one matrix.
                
                XYZ=map_coords_proxy(XYZ,V); % map to mm-space
                
                
                if atlases.types(atlas)==4 % mixed atlas, divide
                    if side==1
                        XYZ=XYZ(XYZ(:,1)>0,:,:);
                    elseif side==2
                        XYZ=XYZ(XYZ(:,1)<0,:,:);
                    end
                end
                
            end
            
            %surface(xx(1:10)',yy(1:10)',zz(1:10)',ones(10,1)');
            hold on
            
            
            
            
            
            
            
            
            
            
            bb=[0,0,0;size(nii.img)];
            
            bb=map_coords_proxy(bb,V);
            gv=cell(3,1);
            for dim=1:3
                gv{dim}=linspace(bb(1,dim),bb(2,dim),size(nii.img,dim));
            end
            [X,Y,Z]=meshgrid(gv{1},gv{2},gv{3});
            if options.prefs.hullsmooth
                nii.img = smooth3(nii.img,'gaussian',options.prefs.hullsmooth);
            end
            fv=isosurface(X,Y,Z,permute(nii.img,[2,1,3]),max(nii.img(:))/3);
            
            if ischar(options.prefs.hullsimplify)
                
                % get to 700 faces
                simplify=700/length(fv.faces);
                fv=reducepatch(fv,simplify);
                
            else
                if options.prefs.hullsimplify<1 && options.prefs.hullsimplify>0
                    
                    fv=reducepatch(fv,options.prefs.hullsimplify);
                elseif options.prefs.hullsimplify>1
                    simplify=options.prefs.hullsimplify/length(fv.faces);
                    fv=reducepatch(fv,simplify);
                end
            end
            
            
            
            
            % set cdata
            
            try % check if explicit color info for this atlas is available.
                
                cdat=abs(repmat(atlases.colors(atlas),length(fv.vertices),1) ... % C-Data for surface
                    +randn(length(fv.vertices),1)*2)';
            catch
                cdat=abs(repmat(atlas*(maxcolor/length(atlases.names)),length(fv.vertices),1)... % C-Data for surface
                    +randn(length(fv.vertices),1)*2)';
                atlases.colors(atlas)=atlas*(maxcolor/length(atlases.names));
            end
            
            ifv{atlas,side}=fv; % later stored
            icdat{atlas,side}=cdat; % later stored
            iXYZ{atlas,side}=XYZ; % later stored
            ipixdim{atlas,side}=nii.hdr.dime.pixdim(2:4); % later stored
            icolorc{atlas,side}=colorc; % later stored

            pixdim=ipixdim{atlas,side};
        else

            fv=atlases.fv{atlas,side};
            cdat=abs(repmat(atlases.colors(atlas),length(fv.vertices),1) ... % C-Data for surface
                +randn(length(fv.vertices),1)*2)';
            XYZ=atlases.XYZ{atlas,side};
            pixdim=atlases.pixdim{atlas,side};
            colorc=nan;
        end
        set(0,'CurrentFigure',resultfig); 
        atlassurfs(atlascnt)=patch(fv,'CData',cdat,'FaceColor',[0.8 0.8 1.0],'facealpha',0.7,'EdgeColor','none','facelighting','phong');
        
        
        % make fv compatible for stats
        
        
        
        caxis([1 64]);
        
        % prepare colorbutton icon
        
        atlasc=squeeze(jetlist(round(atlases.colors(atlas)),:));  % color for toggle button icon 
        colorbuttons(atlascnt)=uitoggletool(ht,'CData',ea_get_icn('atlas',atlasc),'TooltipString',atlases.names{atlas},'OnCallback',{@atlasvisible,atlassurfs(atlascnt)},'OffCallback',{@atlasinvisible,atlassurfs(atlascnt)},'State','on');
     
        % gather contact statistics
        if options.writeoutstats
            atsearch=KDTreeSearcher(XYZ);
            for el=1:length(elstruct)
                
                [~,D]=knnsearch(atsearch,ea_stats.electrodes(el).coords_mm{side});
                %s_ix=sideix(side,size(elstruct(el).coords_mm{side},1));
                
                ea_stats.conmat{el,side}(:,atlas)=D;
                Dh=D;
                
                try
                    in=inhull(ea_stats.electrodes(el).coords_mm{side},fv.vertices,fv.faces,1.e-13*mean(abs(fv.vertices(:))));
                    Dh(in)=0;
                    
                catch
                    disp('No tesselation info found for this atlas. Maybe atlas is too small. Use different hullmethod if needed.');
                end
                ea_stats.conmat_inside_hull{el,side}(:,atlas)=Dh;
                
                D(D<mean(pixdim))=0; % using mean here but assuming isotropic atlases in general..
                ea_stats.conmat_inside_vox{el,side}(:,atlas)=D;
                
                
                
            end
        end
        
        normals{atlas,side}=get(atlassurfs(atlascnt),'VertexNormals');

        
        ea_spec_atlas(atlassurfs(atlascnt),atlases.names{atlas},atlases.colormap,setinterpol);
        
        atlascnt=atlascnt+1;
        
        set(gcf,'Renderer','OpenGL')
        axis off
        set(gcf,'color','w');
        axis equal

        drawnow
        
        
    end
end




% save table information that has been generated from nii files (on first run with this atlas set).
try
atlases.fv=ifv;
atlases.cdat=icdat;
atlases.XYZ=iXYZ;
atlases.pixdim=ipixdim;
atlases.colorc=icolorc;
end

atlases.normals=normals;

try
setappdata(gcf,'iXYZ',atlases.XYZ);
setappdata(gcf,'ipixdim',atlases.pixdim);
end
try
save([root,'atlases',filesep,options.atlasset,filesep,'atlas_index.mat'],'atlases');
end

if options.writeoutstats
if exist('prioratlasnames','var')
    if ~isequal(ea_stats.atlases.names,prioratlasnames)
        warning('Other atlasset used as before. Deleting VAT and Fiberinfo. Saving backup copy.');
        save([options.root,options.patientname,filesep,'ea_stats_new'],'ea_stats');
        load([options.root,options.patientname,filesep,'ea_stats']);
        save([options.root,options.patientname,filesep,'ea_stats_backup'],'ea_stats');
        movefile([options.root,options.patientname,filesep,'ea_stats_new.mat'],[options.root,options.patientname,filesep,'ea_stats.mat']);
    else
        save([options.root,options.patientname,filesep,'ea_stats'],'ea_stats');
    end
else
            save([options.root,options.patientname,filesep,'ea_stats'],'ea_stats');

end
end

end










function C=rgb(C) % returns rgb values for the colors.

C = rem(floor((strfind('kbgcrmyw', C) - 1) * [0.25 0.5 1]), 2);


function atlasvisible(hobj,ev,atls)
set(atls, 'Visible', 'on');
%disp([atls,'visible clicked']);

function atlasinvisible(hobj,ev,atls)
set(atls, 'Visible', 'off');
%disp([atls,'invisible clicked']);

function sides=detsides(opt)

switch opt
    case 1 % left hemispheric atlas
        sides=1;
    case 2 % right hemispheric atlas
        sides=2;
    case 3
        sides=1:2;
    case 4
        sides=1:2;
    case 5
        sides=1; % midline
        
end



function coords=map_coords_proxy(XYZ,V)

XYZ=[XYZ';ones(1,size(XYZ,1))];

coords=V.mat*XYZ;
coords=coords(1:3,:)';



function [nii,V]=load_nii_proxy(fname,options)

nii=load_untouch_nii(fname);
if ~all(nii.hdr.dime.pixdim(2:4)<=1)
    reslice_nii(fname,fname,[0.5,0.5,0.5]);
    nii=load_untouch_nii(fname);
end
V.mat=[nii.hdr.hist.srow_x;nii.hdr.hist.srow_y;nii.hdr.hist.srow_z;0,0,0,1];



%
% function six=sideix(side,howmany)
% howmany=howmany/2;
% six=side*howmany-(howmany-1):side*howmany;


function in = inhull(testpts,xyz,tess,tol)

% Copyright (c) 2009, John D'Errico
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

% inhull: tests if a set of points are inside a convex hull
% usage: in = inhull(testpts,xyz)
% usage: in = inhull(testpts,xyz,tess)
% usage: in = inhull(testpts,xyz,tess,tol)
%
% arguments: (input)
%  testpts - nxp array to test, n data points, in p dimensions
%       If you have many points to test, it is most efficient to
%       call this function once with the entire set.
%
%  xyz - mxp array of vertices of the convex hull, as used by
%       convhulln.
%
%  tess - tessellation (or triangulation) generated by convhulln
%       If tess is left empty or not supplied, then it will be
%       generated.
%
%  tol - (OPTIONAL) tolerance on the tests for inclusion in the
%       convex hull. You can think of tol as the distance a point
%       may possibly lie outside the hull, and still be perceived
%       as on the surface of the hull. Because of numerical slop
%       nothing can ever be done exactly here. I might guess a
%       semi-intelligent value of tol to be
%
%         tol = 1.e-13*mean(abs(xyz(:)))
%
%       In higher dimensions, the numerical issues of floating
%       point arithmetic will probably suggest a larger value
%       of tol.
%
%       DEFAULT: tol = 0
%
% arguments: (output)
%  in  - nx1 logical vector
%        in(i) == 1 --> the i'th point was inside the convex hull.
%
% Example usage: The first point should be inside, the second out
%
%  xy = randn(20,2);
%  tess = convhulln(xy);
%  testpoints = [ 0 0; 10 10];
%  in = inhull(testpoints,xy,tess)
%
% in =
%      1
%      0
%
% A non-zero count of the number of degenerate simplexes in the hull
% will generate a warning (in 4 or more dimensions.) This warning
% may be disabled off with the command:
%
%   warning('off','inhull:degeneracy')
%
% See also: convhull, convhulln, delaunay, delaunayn, tsearch, tsearchn
%
% Author: John D'Errico
% e-mail: woodchips@rochester.rr.com
% Release: 3.0
% Release date: 10/26/06

% get array sizes
% m points, p dimensions
p = size(xyz,2);
[n,c] = size(testpts);
if p ~= c
    error 'testpts and xyz must have the same number of columns'
end
if p < 2
    error 'Points must lie in at least a 2-d space.'
end

% was the convex hull supplied?
if (nargin<3) || isempty(tess)
    tess = convhulln(xyz);
end
[nt,c] = size(tess);
if c ~= p
    error 'tess array is incompatible with a dimension p space'
end

% was tol supplied?
if (nargin<4) || isempty(tol)
    tol = 0;
end

% build normal vectors
switch p
    case 2
        % really simple for 2-d
        nrmls = (xyz(tess(:,1),:) - xyz(tess(:,2),:)) * [0 1;-1 0];
        
        % Any degenerate edges?
        del = sqrt(sum(nrmls.^2,2));
        degenflag = (del<(max(del)*10*eps));
        if sum(degenflag)>0
            warning('inhull:degeneracy',[num2str(sum(degenflag)), ...
                ' degenerate edges identified in the convex hull'])
            
            % we need to delete those degenerate normal vectors
            nrmls(degenflag,:) = [];
            nt = size(nrmls,1);
        end
    case 3
        % use vectorized cross product for 3-d
        ab = xyz(tess(:,1),:) - xyz(tess(:,2),:);
        ac = xyz(tess(:,1),:) - xyz(tess(:,3),:);
        nrmls = cross(ab,ac,2);
        degenflag = false(nt,1);
    otherwise
        % slightly more work in higher dimensions,
        nrmls = zeros(nt,p);
        degenflag = false(nt,1);
        for i = 1:nt
            % just in case of a degeneracy
            % Note that bsxfun COULD be used in this line, but I have chosen to
            % not do so to maintain compatibility. This code is still used by
            % users of older releases.
            %  nullsp = null(bsxfun(@minus,xyz(tess(i,2:end),:),xyz(tess(i,1),:)))';
            nullsp = null(xyz(tess(i,2:end),:) - repmat(xyz(tess(i,1),:),p-1,1))';
            if size(nullsp,1)>1
                degenflag(i) = true;
                nrmls(i,:) = NaN;
            else
                nrmls(i,:) = nullsp;
            end
        end
        if sum(degenflag)>0
            warning('inhull:degeneracy',[num2str(sum(degenflag)), ...
                ' degenerate simplexes identified in the convex hull'])
            
            % we need to delete those degenerate normal vectors
            nrmls(degenflag,:) = [];
            nt = size(nrmls,1);
        end
end

% scale normal vectors to unit length
nrmllen = sqrt(sum(nrmls.^2,2));
% again, bsxfun COULD be employed here...
%  nrmls = bsxfun(@times,nrmls,1./nrmllen);
nrmls = nrmls.*repmat(1./nrmllen,1,p);

% center point in the hull
center = mean(xyz,1);

% any point in the plane of each simplex in the convex hull
a = xyz(tess(~degenflag,1),:);

% ensure the normals are pointing inwards
% this line too could employ bsxfun...
%  dp = sum(bsxfun(@minus,center,a).*nrmls,2);
dp = sum((repmat(center,nt,1) - a).*nrmls,2);
k = dp<0;
nrmls(k,:) = -nrmls(k,:);

% We want to test if:  dot((x - a),N) >= 0
% If so for all faces of the hull, then x is inside
% the hull. Change this to dot(x,N) >= dot(a,N)
aN = sum(nrmls.*a,2);

% test, be careful in case there are many points
in = false(n,1);

% if n is too large, we need to worry about the
% dot product grabbing huge chunks of memory.
memblock = 1e6;
blocks = max(1,floor(n/(memblock/nt)));
aNr = repmat(aN,1,length(1:blocks:n));
for i = 1:blocks
    j = i:blocks:n;
    if size(aNr,2) ~= length(j),
        aNr = repmat(aN,1,length(j));
    end
    in(j) = all((nrmls*testpts(j,:)' - aNr) >= -tol,1)';
end