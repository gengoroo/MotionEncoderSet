% Merge_cat_folders
% Add category folder name to the head of file names
% and copy all files into a single "top" folder.

function pn_merged = merge_cat_folders(pn_parent)

    % Parent folder containing category folders
    %pn_parent = uigetdir([], 'Select parent folder');
    
    % Destination folder
    pn_merged = fullfile(fileparts(pn_parent), 'merged');
    
    if ~exist(pn_merged, 'dir')
        mkdir(pn_merged);
    end
    
    % Get all subfolders
    D = dir(pn_parent);
    D = D([D.isdir]);
    
    for iFolder = 1:length(D)
    
        folderName = D(iFolder).name;
    
        % Skip "." ".." and destination folder
        if any(strcmp(folderName,{'.','..','merged'}))
            continue;
        end
    
        pn_cat = fullfile(pn_parent, folderName);
    
        % Get files in category folder
        F = dir(fullfile(pn_cat, '*'));
    
        % Remove folders
        F = F(~[F.isdir]);
    
        for iFile = 1:length(F)
    
            oldName = F(iFile).name;
            pn_source = fullfile(pn_cat, oldName);
    
            % Add category name to the front
            newName = sprintf('%s_%s', folderName, oldName);
    
            pn_dest = fullfile(pn_merged, newName);
    
            copyfile(pn_source, pn_dest);
    
            fprintf('Copied: %s --> %s\n', oldName, newName);
    
        end
    end
    
    fprintf('\nFinished.\n');
end