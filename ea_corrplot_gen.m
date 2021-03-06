function fig=ea_corrplot(varargin)
% this simple function is a small wrapper for a corrplot figure.


X=varargin{1};
description=varargin{2};
labels=varargin{3};
if nargin>3
    handles=varargin{4};
end
if nargin>4
    groups=varargin{5};
else
    groups=ones(length(X),1);
end

dim=size(X,2);

disp(description);




[R,p]=corrcoef(X,'rows','pairwise');
R_upd=R(2:end,1);
p_upd=p(2:end,1);

%labels=M.stats(1).ea_stats.atlases.names(lidx);


jetlist=lines;
jetlist(groups,:);
for area=1:length(R_upd)
    %% plot areas:
    f=figure('color','w','name',description);
    
    scatter(X(:,1),X(:,area+1),[],jetlist(groups,:),'filled');
    h=lsline;
    set(h,'color','k');
    axis square
    [~,fn]=fileparts(labels{area+1});
    if strcmp(fn(end-3:end),'.nii')
        [~,fn]=fileparts(fn);
    end
    title([description,' (R=',sprintf('%.3f',R_upd(area)),', p=',sprintf('%.3f',p_upd(area)),').'],'FontSize',16,'FontName','Helvetica');
    xlabel(sub2space(labels{1}),'FontSize',16,'FontName','Helvetica');
    ylabel(labels{2},'FontSize',16,'FontName','Helvetica');
    if nargin==4
        if ~isempty(varargin{4})
        odir=get(handles.groupdir_choosebox,'String');
        ofname=[odir,description,'_',fn,'_',labels{1},'.png'];
        ea_screenshot(ofname);
        end
    end
end



function str=sub2space(str) % replaces subscores with spaces
str(str=='_')=' ';