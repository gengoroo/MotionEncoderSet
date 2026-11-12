function AttriMap = guided_GradCAM(net,im,label,varargin)

    visible = 'on';
    for ii = 1:nargin-3
        if strcmp('visible',varargin{ii})
            visible = varargin{ii+1};
        end
    end

	classIdx = find(net.Layers(end).Classes=='PTZ00uM');
	scoreMap = gradCAM(net,im,label);
    
	mapGB = guided_backprop(net, im, classIdx );
	map_guided_GradCAM = scoreMap.*mapGB ;
	map_guided_GradCAM = map_guided_GradCAM;
    AttriMap. im = im;
    AttriMap. map_guided_GradCAM = map_guided_GradCAM;
    AttriMap. mapGB = mapGB;
    AttriMap. scoreMap = scoreMap;
	
	cmap = [linspace(1,0,255)' linspace(1,0,255)' linspace(1,0,255)'];
	h=figure('Name',['Attribution Map ' label],'Color','w','Visible',visible);
	subplot(2,2,1);imagesc(im); axis equal;a=gca;a.XLim=[0 size(im,2)]; a=gca;a.YLim=[0 size(im,1)];title('input');colorbar;
	subplot(2,2,2);imagesc(scoreMap); axis equal;a=gca;a.XLim=[0 size(im,2)]; a=gca;a.YLim=[0 size(im,1)];title('gradCAM');colorbar;
	subplot(2,2,3);imagesc(mapGB); axis equal;a=gca;a.XLim=[0 size(im,2)]; a=gca;a.YLim=[0 size(im,1)];title('GuidedBackprop');colorbar;
	subplot(2,2,4);imagesc(map_guided_GradCAM);axis equal;a=gca;a.XLim=[0 size(im,2)]; a=gca;a.YLim=[0 size(im,1)]; title('Guided Grad-CAM');colorbar;
    %tightfig;

end
