function FeatureSeq = seq_connect(Pair,varargin)

    for ii = 1:nargin-1
        if strcmp('Points',varargin{ii})
            Points = varargin{ii+1};
        end
    end

    yn_plot = 'n';
    FeatureSeq=[];
    List_active_seq = [];
    Colormap = jet(200);
    if yn_plot == 'y'
        figure;hold on;
    end
    

    for id_frame= 1:numel(Pair)%フレームスキャン
    
	    previous_ends = [];%active エンドを取得
	    for id_active = 1:numel(List_active_seq)
		    previous_ends = [previous_ends, FeatureSeq(List_active_seq(id_active)).seq(end)];
	    end
	    
        if isempty(Pair{id_frame})%Pairがなかったら切る
            List_active_seq = [];
        else%あったら続ける
	        start_ends = Pair{id_frame}(:,1);
	        stop_ends = Pair{id_frame}(:,2);
	        % 延長するノードを見つけて終点を追加
	        [List_common, ia, ib] = intersect(previous_ends,start_ends);
	        for kk=1:numel(ia)
		        FeatureSeq(List_active_seq(ia(kk))).seq = [FeatureSeq(List_active_seq(ia(kk))).seq, stop_ends(ib(kk))];
                if exist('Points','var')
                    FeatureSeq(List_active_seq(ia(kk))).pos = [FeatureSeq(List_active_seq(ia(kk))).pos; Points{id_frame+1}.Location(stop_ends(ib(kk)),:)];
                    if yn_plot == 'y'
                        plot(Points{id_frame+1}.Location(stop_ends(ib(kk)),1),Points{id_frame+1}.Location(stop_ends(ib(kk)),2),'.','Color',Colormap(List_active_seq(ia(kk)),:))
                    end
                end
	        end
	        List_active_seq = List_active_seq(ia);%active_seqを更新
        
	        %新しいノードを見つける. 始点・終点を追加
	        [List_new, ia] = setdiff(start_ends,previous_ends);
	        nFeatureSeq_previous = numel(FeatureSeq);
	        for jj = 1:numel(List_new)
		        id_seq = nFeatureSeq_previous + jj;
		        FeatureSeq(id_seq).seq = [start_ends(ia(jj)), stop_ends(ia(jj))];
		        FeatureSeq(id_seq).startframe = id_frame;
		        List_active_seq = [List_active_seq, id_seq];%active_seqを追加
                if exist('Points','var')
                    FeatureSeq(id_seq).pos = [Points{id_frame}.Location(List_new(jj),:);Points{id_frame+1}.Location(stop_ends(ia(jj)),:)];
                    if yn_plot == 'y'
                        plot(Points{id_frame}.Location(List_new(jj),1),Points{id_frame}.Location(List_new(jj),2),'.','Color',Colormap(id_seq,:))
                    end
                end
            end
        end
    end
    
    if exist('Points','var')
        if yn_plot == 'y'
            figure;hold on;
            for id_seq =  1:numel(FeatureSeq)
                plot(FeatureSeq(id_seq).pos(:,1),FeatureSeq(id_seq).pos(:,2),'Color',Colormap(id_seq,:));
            end
        end
    end

end
