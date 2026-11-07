clear;
pn_def_ref = uigetdir('','select pn_def_ref');
pn_def_source = uigetdir('','select pn_def_source');
pn_def_save = uigetdir('','select pn_def_save');

while(1)
    pn_ref = uigetdir(pn_def_ref,'select reference folder');
    pn_source = uigetdir(pn_def_source,'select copy sorce folder');
    pn_save = uigetdir(pn_def_save,'select pn to save');
    
    ListSource = dir(fullfile(pn_source,'*.tif'));
    ListRef = dir(fullfile(pn_ref,'*.tif'));
    
    for id_ref = 1:numel(ListRef)
        copyfile([ListSource(1).folder '\' ListRef(id_ref).name],[pn_save '\' ListRef(id_ref).name]);
    end
    fprintf('repeating...abort to ctr-C\n');
end

