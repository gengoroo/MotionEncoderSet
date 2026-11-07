%traj_select
%for id_frame = 1:numel(FeatureSeq(id_seq).seq)
%        frame = startframe + id_frame -1;
%	    id_node = FeatureSeq(id_seq).seq(id_frame);
%        FeatureTraj(id_seq).startframe = startframe;
%        FeatureTraj(id_seq).ListFrame = startframe:startframe + id_frame -1;
%        FeatureTraj(id_seq).node(id_frame) = id_node;
%	    FeatureTraj(id_seq).pos(id_frame,:) = [Points{frame}.Location(id_node,:),startframe + id_frame -1];
%        FeatureTraj(id_seq).Metric(id_frame) = Points{frame}.Metric(id_node);
%        FeatureTraj(id_seq).Scale(id_frame) = Points{frame}.Scale(id_node);
%        FeatureTraj(id_seq).Layer(id_frame) = Points{frame}.Layer(id_node);
%        FeatureTraj(id_seq).Octave(id_frame) = Points{frame}.Octave(id_node);
%end

function [FeatureTraj_selected, ListHit_select] = traj_select(FeatureTraj,ListPosKey,Parameter)

    ListHit.idseq = [];
    ListHit.metric = [];
    for id_seq = 1:numel(FeatureTraj)
        
        for id_frame = 1:numel(FeatureTraj(id_seq))
            r = FeatureTraj(id_seq).Scale(id_frame)*Parameter.scale_factor;%σのsigma_facotor倍
            POS = FeatureTraj(id_seq).pos(id_frame,:);
            metric = FeatureTraj(id_seq).Metric(id_frame);
    
            frame = FeatureTraj(id_seq).startframe + id_frame -1;
            ListPosID = find(ListPosKey(:,3)==frame);% 2D特徴点と同じframeにある、Metricが基準以上の3D特徴点をリストアップして、それが一定距離にあるかしらべ、選択。
    
            List_d = sqrt((ListPosKey(ListPosID,1) - POS(1)).^2 + (ListPosKey(ListPosID,2) - POS(2)).^2);
            if ~isempty(find(List_d < r))
                ListHit.idseq = [ListHit.idseq, id_seq];
                ListHit.metric = [ListHit.metric, metric];
            end

        end
    end

    ListIdseq = unique(ListHit.idseq);%重複を削除して、その軌跡内の特徴点の最大Metricを得る。
    if ~isempty(ListIdseq)
        for ii = 1:numel(ListIdseq)
            id_seq = ListIdseq(ii);
            ListHit_select.idseq(ii) = id_seq;
    
            List_number = find(ListHit.idseq == id_seq);
            ListMetric_serch = ListHit.metric(List_number);
            ListHit_select.metric(ii) = max(ListMetric_serch);
        end
        
        [ListMaxMetric, IDX] = sort(ListHit_select.metric,'descend');
    
        if isfield(Parameter,'maxNfeaturePt')
            maxN = min(Parameter.maxNfeaturePt,numel(IDX));
            FeatureTraj_selected = FeatureTraj(ListHit_select.idseq(IDX(1:maxN)));%上から決めら数を取得する。
            FeatureTraj_selected.MaxMetric = ListMaxMetric(1:maxN);
        end
    else
        FeatureTraj_selected = [];
        ListHit_select = [];
    end

end