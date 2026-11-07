%make_rot_RF (0, 90, 270, 180 degrees)
function newData4D = make_rot_RF(Data4D, ListRot)
    nCell = size(Data4D,4);
    List_Nrot_90 = ListRot/90;
    for id_cell = 1:nCell
        for id_rot = 1:numel(List_Nrot_90)
            id_filter = numel(List_Nrot_90)*(id_cell - 1) + id_rot;
            data_temp = Data4D(:,:,:,id_cell);
            for ii = 1:List_Nrot_90(id_rot)
                data_temp = rot90(data_temp);
            end
            newData4D(:,:,:,id_filter) = data_temp;
        end
    end
end