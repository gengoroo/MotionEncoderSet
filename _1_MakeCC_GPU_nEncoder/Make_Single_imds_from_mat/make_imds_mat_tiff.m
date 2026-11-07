function imds = make_imds_mat_tiff(matdata,Labels,pn)
    %https://www.mathworks.com/matlabcentral/answers/376927-question-about-imagedatastore-input
    pn_imds = make_mat_folder(matdata,Labels,pn);
    imds = imageDatastore(pn_imds,'IncludeSubfolders',true,'FileExtensions','.mat','LabelSource','foldernames','ReadFcn',@loadmydata);
end

function data = loadmydata(filename)
     data = load(filename);
end

function pn_imds = make_mat_folder(matdata,Labels,pn)
    ListLabels = unique(Labels);
    matdata_norm = uint8(round(255*matdata/max(max(max(matdata)))));
    for id_label = 1:numel(ListLabels)
        pn_imds = pn;
        note = string(ListLabels(id_label));
        pn_class = [pn_imds '\' note{1}];
        mkdir(pn_class);
        ListWrite = find((Labels == ListLabels(id_label)));
        for ii = 1:numel(ListWrite)
            id_data = ListWrite(ii);
            data = matdata(:,:,id_data);
            save([pn_class '\data' num2str(id_label) '-' num2str(id_data) '.mat'],'data');
            imwrite(uint8(round(matdata_norm(:,:,id_data))),[pn_class '\data' num2str(id_label) '-' num2str(id_data) '.tif']);
        end
    end
end