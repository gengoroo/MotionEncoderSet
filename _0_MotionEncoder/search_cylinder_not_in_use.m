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