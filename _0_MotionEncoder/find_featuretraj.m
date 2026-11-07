function FeatureTraj = find_featuretraj(FeatureSeq,Points,varargin)

    yn_plot = 'n';
    min_conting = 10;
    for ii = 1:nargin-2
        if strcmp('yn_plot',varargin{ii})
            yn_plot = varargin{ii+1};
        end
        if strcmp('min_conting',varargin{ii})
            min_conting = varargin{ii+1};
        end
        if strcmp('POS_overlay',varargin{ii})
            POS_overlay = varargin{ii+1};
        end
    end

    if yn_plot == 'y'
        figure('Name','FeatureTrajectory');hold on;
    end

    for id_seq = 1:numel(FeatureSeq)
	    startframe= FeatureSeq(id_seq).startframe;
	    
	    for id_frame = 1:numel(FeatureSeq(id_seq).seq)
		    frame = startframe + id_frame -1;
		    id_node = FeatureSeq(id_seq).seq(id_frame);
            FeatureTraj(id_seq).startframe = startframe;
            FeatureTraj(id_seq).ListFrame = startframe:startframe + id_frame -1;
            FeatureTraj(id_seq).node(id_frame) = id_node;
		    FeatureTraj(id_seq).pos(id_frame,:) = [Points{frame}.Location(id_node,:),startframe + id_frame -1];
            FeatureTraj(id_seq).Metric(id_frame) = Points{frame}.Metric(id_node);
            FeatureTraj(id_seq).Scale(id_frame) = Points{frame}.Scale(id_node);
            if isfield(Points{frame},'Layer')
                FeatureTraj(id_seq).Layer(id_frame) = Points{frame}.Layer(id_node);
            else
                fprintf('Omit FeatureTraj(id_seq).Layer since Layer is absent from Points{frame}\n');
            end
            if isfield(Points{frame},'Octave')
                FeatureTraj(id_seq).Octave(id_frame) = Points{frame}.Octave(id_node);
            else
                fprintf('Omit FeatureTraj(id_seq).Octave since Octave is absent from Points{frame}\n');
            end
        end

        if yn_plot == 'y'

            for id_frame = 1:numel(Points)
                z = repmat(id_frame,size(Points{id_frame}.Location,1));
                plot3(Points{id_frame}.Location(:,1),Points{id_frame}.Location(:,2),z,'k.');
            end

            Colormap = cool(100);
	        if size(FeatureTraj(id_seq).pos,1)>=min_conting
		        plot(FeatureTraj(id_seq).pos(:,1),FeatureTraj(id_seq).pos(:,2));
                for id_frame = 1:size(FeatureTraj(id_seq).pos,1)
                    all_value =  FeatureTraj(id_seq).Metric;
                    value =  FeatureTraj(id_seq).Metric(id_frame);
                    id_color = max(min(100,round(100*   (value - min(all_value))  /   (max(all_value) - min(all_value))            )),1);
                    viscircles(FeatureTraj(id_seq).pos(id_frame,1:2),FeatureTraj(id_seq).Scale(id_frame),'Color',Colormap(id_color,:),'LineWidth',0.5);
                end
            end
        end

    end

    if exist('POS_overlay','var')
        plot3(POS_overlay(:,1),POS_overlay(:,2),POS_overlay(:,3),'r*');
    end

end