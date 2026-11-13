function MOV_som_align = align_RF_t(MOV_som,selectWB)

    MOV_som_align = MOV_som;
    for id_cell = 1:size(MOV_som,4)
        RF = MOV_som(:,:,:,id_cell);
        
        RF_posi = (RF + abs(RF))/2;
        RF_nega = (RF - abs(RF))/2;
        
        RF_posi_linear = reshape(sum(sum(RF_posi,1),2),1,{});
        RF_nega_linear = abs(reshape(sum(sum(RF_nega,1),2),1,{}));
        
        %gc_w = sum(RF_posi_linear.*[1:numel(RF_posi_linear)],2)/sum(RF_posi_linear,2);
        %gc_b = sum(RF_nega_linear.*[1:numel(RF_nega_linear)],2)/sum(RF_nega_linear,2);

        peak_w = max(find(RF_posi_linear == max(RF_posi_linear)));
        peak_b = max(find(RF_nega_linear == max(RF_nega_linear)));
        
        switch selectWB
            case 'b'
                if peak_w > peak_b
                    MOV_som_align(:,:,:,id_cell) = (-1)*MOV_som(:,:,:,id_cell);
                end
            case 'w'
                if peak_b > peak_w
                    MOV_som_align(:,:,:,id_cell) = (-1)*MOV_som(:,:,:,id_cell);
                end
        end
        
    end

end