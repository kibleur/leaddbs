function ea_showisovolume(resultfig,elstruct,options)

% __________________________________________________________________________________
% Copyright (C) 2015 Charite University Medicine Berlin, Movement Disorders Unit
% Andreas Horn

ht=uitoolbar(gcf);
set(0,'CurrentFigure',resultfig);



%


jetlist=othercolor('BuOr_12');
       % jetlist=jet;
if size(options.d3.isomatrix{1},2)==4-1 % 3 contact pairs
    shifthalfup=1;
elseif size(options.d3.isomatrix{1},2)==4 % 4 contacts
    shifthalfup=0;
else
    ea_error('Isomatrix has wrong size. Please specify a correct matrix.')
end
for side=options.sides
    cnt=1;
    for sub=1:length(elstruct)
        for cont=1:size(options.d3.isomatrix{1},2)
            if ~isnan(options.d3.isomatrix{side}(sub,cont));
                if ~shifthalfup
                    X{side}(cnt)=elstruct(sub).coords_mm{side}(cont,1);
                    Y{side}(cnt)=elstruct(sub).coords_mm{side}(cont,2);
                    Z{side}(cnt)=elstruct(sub).coords_mm{side}(cont,3);
                else % using pairs of electrode contacts (i.e. 3 pairs if there are 4 contacts)
                    X{side}(cnt)=mean([elstruct(sub).coords_mm{side}(cont,1),elstruct(sub).coords_mm{side}(cont+1,1)]);
                    Y{side}(cnt)=mean([elstruct(sub).coords_mm{side}(cont,2),elstruct(sub).coords_mm{side}(cont+1,2)]);
                    Z{side}(cnt)=mean([elstruct(sub).coords_mm{side}(cont,3),elstruct(sub).coords_mm{side}(cont+1,3)]);
                end
                V{side}(cnt)=options.d3.isomatrix{side}(sub,cont);
                
                cnt=cnt+1;
            end
        end
    end
    
    X{side}=X{side}(:);        Y{side}=Y{side}(:);        Z{side}=Z{side}(:); V{side}=V{side}(:);
    %assignin('base','X',X);
    %assignin('base','Y',Y);
    %assignin('base','Z',Z);
    
    
    bb(1,:)=[min(X{side}),max(X{side})];
    bb(2,:)=[min(Y{side}),max(Y{side})];
    bb(3,:)=[min(Z{side}),max(Z{side})];
    [XI,YI,ZI]=meshgrid(linspace(bb(1,1),bb(1,2),100),linspace(bb(2,1),bb(2,2),100),linspace(bb(3,1),bb(3,2),100));
    
    F = scatteredInterpolant(X{side},Y{side},Z{side},double(V{side}));
    F.ExtrapolationMethod='none';
    VI{side}=F(XI,YI,ZI);
    
    
    
    if options.d3.isovscloud==1 % show interpolated point mesh
        
        
        ipcnt=1;
        for xx=1:10:size(VI{side},1)
            for yy=1:10:size(VI{side},2)
                for zz=1:10:size(VI{side},3)
                    if ~isnan(VI{side}(xx,yy,zz))
                        usefacecolor=VI{side}(xx,yy,zz)*((64+miniso(options.d3.isomatrix))/(maxiso(options.d3.isomatrix)+miniso(options.d3.isomatrix)));
                        usefacecolor=ind2rgb(round(usefacecolor),jetlist);
                        isopatch(side,ipcnt)=plot3(XI(xx,yy,zz),YI(xx,yy,zz),ZI(xx,yy,zz),'o','MarkerFaceColor',usefacecolor,'MarkerEdgeColor',usefacecolor,'Color',usefacecolor);
                        ipcnt=ipcnt+1;
                    end
                end
            end
        end
    elseif options.d3.isovscloud==2 % show isovolume
        VI{side}=smooth3(VI{side},'gaussian',3);
        
        fv{side}=isosurface(XI,YI,ZI,VI{side},max(VI{side}(:))/3);
        fv{side}=reducepatch(fv{side},0.5);
        cdat=repmat(60,(length(fv{side}.vertices)),1);
        isopatch(side,1)=patch(fv{side},'CData',cdat,'FaceColor',[0.8 0.8 1.0],'facealpha',0.7,'EdgeColor','none','facelighting','phong');
        jetlist=jet;
        ea_spec_atlas(isopatch(side,1),'isovolume',jet,1);
        
    end
    
       %ea_exportisovolume(elstruct,options);    
    patchbutton(side)=uitoggletool(ht,'CData',ea_get_icn('isovolume',options),'TooltipString','Isovolume','OnCallback',{@isovisible,isopatch(side,:)},'OffCallback',{@isoinvisible,isopatch(side,:)},'State','on');
    
end


function isovisible(hobj,ev,atls)
set(atls, 'Visible', 'on');
%disp([atls,'visible clicked']);

function isoinvisible(hobj,ev,atls)
set(atls, 'Visible', 'off');
%disp([atls,'invisible clicked']);


function m=maxiso(cellinp) % simply returns the highest entry of matrices in a cell.
m=-inf;
for c=1:length(cellinp)
    nm=max(cellinp{c}(:));
    if nm>m; m=nm; end
end

function m=miniso(cellinp)
m=inf;
for c=1:length(cellinp)
    nm=min(cellinp{c}(:));
    if nm<m; m=nm; end
end

