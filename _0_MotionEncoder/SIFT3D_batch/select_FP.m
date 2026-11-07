%select_FP

%pn_def = 'C:\Users\gengoro\SynologyDrive\AI\Tad\Select\crop2_sel\Rot0.48\movie_package\SIFT3D';
%pn_input = uigetdir(pn_def,'select folder');

function select_FP(pn_input)
    pn_save = [pn_input '\FP_select'];
    mkdir(pn_save);
    
    Info = dir(pn_input);
    for ii = 1:numel(Info)
        fn_full = [pn_input ,'\' Info(ii).name];
        fn_save = [pn_save ,'\' Info(ii).name(1:end-4) '_sel.mat'];
        if ~isdir(fn_full)&&strcmp(fn_full(end-2:end),'mat')
    
            load(fn_full);
            Metric = [keys.metric];
            
            
            data = struct2cell(keys);
            Value_OctLevel = cell2mat(data(4:5,:));
            ListOct = unique(Value_OctLevel(1,:));
            ListLevel = unique(Value_OctLevel(2,:));
            ListCoords=cell2mat(data(1,:)');
    
            for id_oct = 1:numel(ListOct)
                for id_level = 1:numel(ListLevel)
                    List_octlevelmatch(id_oct,id_level).id = intersect(find(Value_OctLevel(1,:)==ListOct(id_oct)), find(Value_OctLevel(2,:)==ListLevel(id_level)));
                    List_octlevelmatch(id_oct,id_level).coords = ListCoords(List_octlevelmatch(id_oct,id_level).id,:);
                end
            end
            save(fn_save,'List_octlevelmatch','ListOct','ListLevel');
        
        end
    end
end