function [MOV_onoff_stack, Info_MOV_onoff_stack] = generate_movie_filter(DataBase_filter,sel_mov_clip)

    for id_data = 1:numel(DataBase_filter.pn_filter.top)
        fprintf('%d:black_ref ',id_data);
        if ~isempty(DataBase_filter.b.Points_Traj_pair{id_data})
            N_trajpair.b_ref(id_data) = numel(DataBase_filter.b.Points_Traj_pair{id_data}.ref);
            fprintf('Traj_pair=%d', N_trajpair.b_ref(id_data));
        else
            N_trajpair.b_ref(id_data) = 0;
            fprintf(' Traj_pair=0');
        end
        fprintf(' |white_ref ');
        if ~isempty(DataBase_filter.w.Points_Traj_pair{id_data})
            N_trajpair.w_ref(id_data) = numel(DataBase_filter.w.Points_Traj_pair{id_data}.ref);
            fprintf('Traj_pair=%d', numel(DataBase_filter.w.Points_Traj_pair{id_data}.ref));
        else
            N_trajpair.w_ref(id_data) = 0;
            fprintf('Traj_pair=0');
        end
        fprintf('\n');
    end

    ListData = find(N_trajpair.b_ref);
    for id_dataset = 1:numel(ListData)
        id_data = ListData(id_dataset);
        fprintf('Current file is %s\n',DataBase_filter.pn_filter.top{id_data});
        List_selectWB = {'b','w'};
        for id_wb = 1:numel(List_selectWB)
            selectWB = List_selectWB{id_wb};
    
            Points_Traj_pair = DataBase_filter.(selectWB).Points_Traj_pair{id_data};
            Parameter = DataBase_filter.(selectWB).Parameter{id_data};
    
            try
                switch sel_mov_clip
                    case 1% gaussian
                        [MOV_onoff, Info_MOV_onoff] = make_moviefilter_from_traj(Points_Traj_pair.ref,Points_Traj_pair.found, Parameter.margin_start, Parameter.margin_stop, selectWB);%入力movie filterサンプル作成
                        fprintf('N data for %s of %dth Data is %d\n',selectWB,id_dataset,numel(MOV_onoff));
                    case 2% raw image
                        % New, cut original d_mov instead of 
                        v = VideoReader([pn_save '\MergedVideo.avi']);
                        counter = 0;
                        while hasFrame(v)
                            counter = counter +1;
                            frame_add = readFrame(v);
                            mov(:,:,counter) = frame_add(:,:,1);
                        end
                        d_mov = mov(:,:,2:end) -  mov(:,:,1:end-1);
                
                        [MOV_onoff, Info_MOV_onoff] = make_moviefilter_from_traj_mov(d_mov,Points_Traj_pair.ref,Points_Traj_pair.found, Parameter.margin_start, Parameter.margin_stop);%New 2024.11.16
                end
            catch
                MOV_onoff = [];
                Info_MOV_onoff = [];
            end
    
            if ~isempty(MOV_onoff)
                List_fields = fieldnames(Info_MOV_onoff);
                if id_dataset == 1
                    MOV_onoff_stack.(selectWB) = MOV_onoff;
                    Info_MOV_onoff_stack.(selectWB) = Info_MOV_onoff;
                else
                    MOV_onoff_stack.(selectWB) = [MOV_onoff_stack.(selectWB), MOV_onoff];
                    Info_MOV_onoff_stack.(selectWB).pix_max = [Info_MOV_onoff_stack.(selectWB).pix_max, Info_MOV_onoff.pix_max];
                    Info_MOV_onoff_stack.(selectWB).pix_min = [Info_MOV_onoff_stack.(selectWB).pix_min, Info_MOV_onoff.pix_min];
                    Info_MOV_onoff_stack.(selectWB).size = [Info_MOV_onoff_stack.(selectWB).size; Info_MOV_onoff.size];
                end
        

            end
        end
    end
    for id_wb = 1:numel(List_selectWB)
        selectWB = List_selectWB{id_wb};
        fprintf('Total N for %s is %d\n',selectWB, numel(MOV_onoff_stack.(selectWB)));
    end

end