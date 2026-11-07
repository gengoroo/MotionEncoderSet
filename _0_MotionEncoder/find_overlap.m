function PairOverlap = find_overlap(Salient_ref,Salient_search,Salient_ref_all, varargin)

    figure('Name','overlap');hold on;
    plot3(Salient_search.Pos(:,1),Salient_search.Pos(:,2),Salient_search.Pos(:,3),'m.');
    plot3(Salient_ref_all.Pos(:,1),Salient_ref_all.Pos(:,2),Salient_ref_all.Pos(:,3),'k.');
    title('XYT plot of keypoits pair');
    %a=gca;a.XLim = [1 800];a.YLim = [1 800];

    PairOverlap=[];    
    for ii =1:nargin -3
        if strcmp('Range',varargin{ii})
            Range = varargin{ii+1};
        end
    end

    XYZ = Salient_search.Pos;
    nPos = size(Salient_ref.Pos,1);
    counter = 0;
    for id = 1:nPos
	    PosXYZ= Salient_ref.Pos(id,:);
	    id_slice=Salient_ref.Pos(id,3);
        r = Salient_ref.Scale(id)*1.5*1.5;%σの１．５倍
	    id_feature = Salient_ref.id_feature(id);

        List_feature_search = Salient_search.id_feature;
	    Found = search_cylinder(PosXYZ, XYZ, r, Range, List_feature_search);
	    if ~isempty(Found.id_slice)
            %fprintf('Found!\n');
		    counter = counter + 1;
		    PairOverlap.ref.id_slice(counter) = id_slice;
		    PairOverlap.ref.id_feature(counter)= id_feature;
		    PairOverlap.ref.Location(counter,:) =PosXYZ;
		    PairOverlap.ref.Scale(counter) = r;
		    PairOverlap.found.id_slice(counter) = Found.id_slice;
            PairOverlap.found.id_feature(counter) = Found.id_feature;
            PairOverlap.found.Location(counter,:) = Found.Pos;
		    PairOverlap.found.Scale(counter) = Salient_search.Scale(Found.id_feature);

            POS_ref = PairOverlap.ref.Location(counter,:);
            POS_found = PairOverlap.found.Location(counter,:);
            POS_ref_found = [POS_ref; POS_found];
            plot3(POS_ref(1), POS_ref(2), POS_ref(3), 'k*');
            plot3(POS_found(1), POS_found(2), POS_found(3),'m*');
            plot3(POS_ref_found(:,1),POS_ref_found(:,2),POS_ref_found(:,3));
            
	    end
    end
    
    %------------------------------------------------------------------------------------
    legend({'search' 'ref' });
end
function Found = search_cylinder(PosXYZ, XYZ, r, Range, List_feature_search)

    Found.id_slice = [];
    Found.id_feature = [];
    Found.Pos = [];

    if Range(1) < Range(2)% z rangeが増えている
        dir = 'u';
    else
        dir = 'd';
    end

    
    Range_limit = Range + PosXYZ(3);

    DataRadius = ((XYZ(:,1) - PosXYZ(1)).^2 + (XYZ(:,2) - PosXYZ(2)).^2  );
    ListRadius = find(   DataRadius   <   r^2);
    ListDepth = find((XYZ(:,3) - Range_limit(1)).*(Range_limit(2) - XYZ(:,3)) > 0);%逆だった
    [ListCylinder, iR, iD] = intersect(ListRadius, ListDepth);
    DataRadius_select = DataRadius(iR);%その中でXY平面での距離が最小のものを探す。
    List_min_radius = ListCylinder(find(DataRadius_select == min(DataRadius_select)));

    LiztZ = XYZ(List_min_radius,3);
    if ~isempty(LiztZ)
        switch dir
            case 'u'
                id_pick = min(List_min_radius(find(LiztZ == min(LiztZ))));%一番下の一番番号が若い
            case 'd'
                id_pick = min(List_min_radius(find(LiztZ == max(LiztZ))));%一番上の一番番号が大きい
        end
        Found.id_feature = List_feature_search(id_pick);
        Found.Pos = XYZ(id_pick,:);
        Found.id_slice = Found.Pos(:,3);
    end
end