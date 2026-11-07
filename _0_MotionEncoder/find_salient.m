function Salient  = find_salient(Points, min_metric_std)
	Salient.Pos =[];
	Salient.id_feature = [];
    Salient.Scale = [];
    Salient.Metric = [];
    
    Met = [];
    for id_slice = 1:numel(Points)
        Met = [Met; Points{id_slice}.Metric];
    end
    Metric_data.mean = mean(Met);
    Metric_data.std = std(Met);
    Metric_data.n = numel(Met);
    if ~isempty(min_metric_std)
        min_metric = mean(Met) + min_metric_std*std(Met);
    end

	for id_slice = 1:numel(Points)
        if ~isempty(min_metric_std)% emptyなら全て
		    ListSalient = find(Points{id_slice}.Metric>=min_metric);
        else
            ListSalient = [1:numel(Points{id_slice}.Metric)]';
        end
		ListPos = Points{id_slice}.Location(ListSalient ,:);
		ListPos3 = [ListPos, repmat(id_slice,size(ListPos,1),1)];
		Salient.Pos = [Salient.Pos; ListPos3];
		Salient.id_feature = [Salient.id_feature; ListSalient];
        Salient.Scale = [Salient.Scale; Points{id_slice}.Scale(ListSalient)];
        Salient.Metric = [Salient.Metric; Points{id_slice}.Metric(ListSalient)];
	end
	Salient .Slice = Salient.Pos(:,3);

end
