function [RFMap_filled, ListNaN] = fill_nan_RF(RFMap)

    RFMap_filled = RFMap;
    s= reshape(sum(sum(sum(RFMap,1),2),3),[],1);
    ListNaN = find(isnan(s));
    nMap = size(RFMap,4);
    ListnonNaN = setdiff(1:nMap,ListNaN);
    for ii = 1:numel(ListNaN)
        id_nan = ListNaN(ii);

        id_nonnan_previous = max(ListnonNaN(ListnonNaN<id_nan));
        id_nonnan_next = min(ListnonNaN(ListnonNaN>id_nan));

        im_fill = zeros(size(RFMap,1),size(RFMap,2),size(RFMap,3));
        counter = 0;
        if ~isempty(id_nonnan_previous)
            im_pre = RFMap(:,:,:,id_nonnan_previous);
            im_fill = im_fill + im_pre;
            counter = counter + 1;
        end 
        if ~isempty(id_nonnan_next)
            im_post = RFMap(:,:,:,id_nonnan_next);
            im_fill = im_fill + im_post;
            counter = counter + 1;
        end

        RFMap_filled(:,:,:,id_nan) = im_fill/counter;
    end
    
end