function [Points,Pos] = get_movie_feature(fn_full,varargin)

    DIM_select = [3];%[1 2 3]なら全部の軸
    for ii = 1:nargin-1
        if strcmp(varargin{ii},'DIM_select')%bug fix 2026.10.18
            DIM_select = varargin{ii+1};
        end
    end
    
    vid1=VideoReader(fn_full);
    nFrames=vid1.NumberOfFrames;
    for ii=1:nFrames
	    im=rgb2gray(read(vid1,ii));
        IM(:,:,ii) = im;
    end

    if ~isempty(intersect(DIM_select,3))
        Pos.Feature.z = [];
        for id_z = 1:size(IM,3)
            im = IM(:,:,id_z);
            Points.z{id_z} = detectSIFTFeatures(im);
	        %[Features.z{ii},Valid_points.z{ii}] = extractFeatures(im,Points{ii});
            ndata = size(Points.z{id_z}.Location,1);
            %for ii = 1:ndata
                add = [Points.z{id_z}.Location, repmat(id_z,ndata,1)];
                Pos.Feature.z = [Pos.Feature.z; add];
            %end
        end
    end

    if ~isempty(intersect(DIM_select,1))
        Pos.Feature.x = [];
        for id_x = 1:size(IM,1)
            im = reshape(IM(id_x,:,:),size(IM,2),size(IM,3));
            Points.x{id_x} = detectSIFTFeatures(im);
	        %[Features.x{ii},Valid_points.x{ii}] = extractFeatures(im,Points{ii});
            ndata = size(Points.x{id_x}.Location,1);
            %for ii = 1:ndata
                add = [Points.x{id_x}.Location(:,2),repmat(id_x,ndata,1),Points.x{id_x}.Location(:,1)];%経験則
                Pos.Feature.x = [Pos.Feature.x; add];
            %end
        end
    end

    if ~isempty(intersect(DIM_select,2))
        Pos.Feature.y = [];
        for id_y = 1:size(IM,2)
            im = reshape(IM(:,id_y,:),size(IM,1),size(IM,3));
            Points.y{id_y} = detectSIFTFeatures(im);
	        %[Features.y{ii},Valid_points.y{ii}] = extractFeatures(im,Points{ii});
            ndata = size(Points.y{id_y}.Location,1);
            %for ii = 1:ndata
                add = [repmat(id_y,ndata,1),Points.y{id_y}.Location(:,2),  Points.y{id_y}.Location(:,1)];
                Pos.Feature.y = [Pos.Feature.y; add];
            %end
        end
    end

    figure;hold on;
    if ~isempty(intersect(DIM_select,3))
        plot3(Pos.Feature.z(:,1),Pos.Feature.z(:,2),Pos.Feature.z(:,3),'r.');
    end
    if ~isempty(intersect(DIM_select,1))
        plot3(Pos.Feature.x(:,1),Pos.Feature.x(:,2),Pos.Feature.x(:,3),'g.');
    end
    if ~isempty(intersect(DIM_select,2))
        plot3(Pos.Feature.y(:,1),Pos.Feature.y(:,2),Pos.Feature.y(:,3),'b.');
    end
end