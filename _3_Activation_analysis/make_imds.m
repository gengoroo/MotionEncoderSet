function imds = make_imds(rootFolder)

    d = dir(rootFolder);
    d = d([d.isdir]);
    d = d(~ismember({d.name},{'.','..'}));
    
    files = {};
    labels = {};
    
    for i = 1:numel(d)
    
        categoryName = d(i).name;
        categoryPath = fullfile(rootFolder, categoryName);
    
        % このフォルダ直下のみ検索
        tifFiles = dir(fullfile(categoryPath,'*.tif'));
    
        % tifが無いフォルダは除外
        if isempty(tifFiles)
            continue
        end
    
        files = [files;
                 fullfile({tifFiles.folder}',{tifFiles.name}')];
    
        labels = [labels;
                  repmat({categoryName},numel(tifFiles),1)];
    end
    
    imds = imageDatastore(files);
    imds.Labels = categorical(labels);
end