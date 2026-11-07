function DataBase_filter = pair_bw_traj(pn_save_feature,List_pn_mov_cat,List_fn_mov_cat,Parameter,yn_plot)
    for id_mov = 1:numel(pn_save_feature)
        load([pn_save_feature{id_mov} '\FeatureTraj.mat'],'AllFeature','Points_Traj','Salient');%AllFeature, Pair, Parameter, Points_seq, Points_Traj, Salient
    
        %-------------------------------------------------------------------------
        List_selectWB = {'b','w'};
        for id_wb = 1:numel(List_selectWB)
            selectWB = List_selectWB{id_wb};
            ListFigStart = findall(groot,'Type','figure');%開いているfig取得
            switch selectWB 
	            case 'b'
                    All_ref = AllFeature.black;
                    All_search = AllFeature.white;
		            Points_Traj_ref = Points_Traj.black;
		            Points_Traj_search = Points_Traj.white;
                    Salient_ref = Salient.black;
	            case 'w'
                    All_ref = AllFeature.white;
                    All_search = AllFeature.black;
		            Points_Traj_ref = Points_Traj.white;
		            Points_Traj_search = Points_Traj.black;
                    Salient_ref = Salient.white;
            end
            %-------------------------------------------------------------------------
            PairOverlap = find_overlap(Salient_ref, All_search, All_ref,'Range',Parameter.Range);%重なるペアを探す
            %-------------------------------------------------------------------------
            if yn_plot == 'y'
                figure('Name','Ref Search trajectories overaly'); hold on;
                plot3(AllFeature.white.Pos(:,1), AllFeature.white.Pos(:,2),AllFeature.white.Pos(:,3),'k.');
                plot3(AllFeature.black.Pos(:,1), AllFeature.black.Pos(:,2),AllFeature.black.Pos(:,3),'m.');
                plot_traj(Points_Traj_ref,'c');
                plot_traj(Points_Traj_search,'m');
                legend({'ref','search'});
            end
            %-------------------------------------------------------------------------
            % どの軌跡に載っているか座標から探す
            clear Traj_ref;%変数クリア　重要
            for ii = 1:numel(Points_Traj_ref)
                Traj_ref{ii} = Points_Traj_ref(ii).pos;%cellfunが使えるようにまとめる。
            end
            clear Traj_found;%変数クリア　重要
            for ii = 1:numel(Points_Traj_search)
                Traj_found{ii} = Points_Traj_search(ii).pos;%cellfunが使えるようにまとめる。
            end
            
    
            if exist('Traj_ref','var')&&exist('Traj_found','var')
                if isfield(PairOverlap,'ref')&&isfield(PairOverlap,'found')
                    List_POS = PairOverlap.ref.Location;
                    Traj = Traj_ref;
                    match_threshold = 1.5;%1.5ピクセル以内なら合っていると判断
                    [ListTrajPos_ref_all]  = find_traj_by_pos(List_POS,Traj,match_threshold);%[その点を通る軌跡＃データと、点は軌跡内の何番目にあるか]複数の軌跡がヒットする
                    [ListTrajPos_ref_temp]= find_longest_traj(ListTrajPos_ref_all,Traj,'e');% より早いフレームからつながっているもの選択。
                    
                    List_POS = PairOverlap.found.Location;
                    Traj = Traj_found;
                    match_threshold = 1.5;%1.5ピクセル以内なら合っていると判断
                    [ListTrajPos_found_all]= find_traj_by_pos(List_POS,Traj,match_threshold);%[その点を通る軌跡＃データと、点は軌跡内の何番目にあるか]複数の軌跡がヒットする
                    [ListTrajPos_found_temp] = find_longest_traj(ListTrajPos_found_all,Traj,'l');%より後のフレームまでつながっているものを選択
                    
                    ListExist = find(ListTrajPos_ref_temp(:,1).*ListTrajPos_ref_temp(:,2).*ListTrajPos_found_temp(:,1).*ListTrajPos_found_temp(:,2));%乗っている軌跡があったもの
                    ListTrajPos_ref = ListTrajPos_ref_temp(ListExist,:);
                    ListTrajPos_found = ListTrajPos_found_temp(ListExist,:);
                    plot_paird_traj(Traj_ref,ListTrajPos_ref,Traj_found,ListTrajPos_found);%ペアの軌跡の確認プロット
                    
                    Points_Traj_pair.ref = Points_Traj_ref(ListTrajPos_ref(:,1));%使うTrajectoryデータのみセレクト
                    Points_Traj_pair.found = Points_Traj_search(ListTrajPos_found(:,1));
                    for id_pair = 1:numel(Points_Traj_pair.ref)
                        Points_Traj_pair.ref(id_pair).peak = Points_Traj_pair.ref(id_pair).pos(ListTrajPos_ref(id_pair,2),3);%peakが軌跡の何番目かのデータも入れてまとめる
                        Points_Traj_pair.found(id_pair).peak = Points_Traj_pair.found(id_pair).pos(ListTrajPos_found(id_pair,2),3);
                    end
                    
                    %-------------------------------------------------------------------------
                    %保存
                    %pn_save_onoff = [pn_filter, '\' selectWB]; %2024.11.19
                    pn_save_onoff = pn_save_feature{id_mov};
                    mkdir(pn_save_onoff);
                    fn_save_onoff = 'PairTraj.mat';
                    save([pn_save_onoff '/' fn_save_onoff],'Points_Traj_pair');
                    
                    ListFigEnd = findall(groot,'Type','figure');%開いているfig取得
                    ListFig = setdiff(ListFigEnd,ListFigStart);%保存するfig取得
                    pn_save_onoff_fig = [pn_save_onoff '\Fig'];
                    mkdir(pn_save_onoff_fig);
                    save_figs(ListFig,pn_save_onoff_fig);%Figを保存
                    close (ListFig);
                
                    if 1==2
                    %load([pn_save '\DataBase_filter.mat']);
                    %
                    %yn_overwrite = 'n';
                    %if ~isempty(DataBase_filter)
                    %    for id_data = 1:numel(DataBase_filter.pn_filter.top)
                    %        fprintf('%d: %s\n',id_data, DataBase_filter.pn_filter.top{id_data});
                    %    end
                    %end
                    %if ~isempty(DataBase_filter)
                    %    IDMatch = find(cellfun(@(x) strcmp(pn_filter,x), DataBase_filter.pn_filter.top));
                    %    if ~isempty(IDMatch)&&(selectWB =='b')%topが重なっていて、かつOFFのデータだったら（先に書き込むので）
                    %        fprintf('This has been analyzed in %s\n', num2str(IDMatch));
                    %        fprintf('Overwrite on %s\n' ,num2str(IDMatch));
                    %        yn_overwrite = input('Overwrite y/n','s');
                    %    else
                    %        fprintf('This data is new \n');
                    %    end
                    %end
                
                    
                    %if isempty(DataBase_filter)
                    %    current_number = 1;
                    %else
                    %    if selectWB == 'b'
                    %        if yn_overwrite == 'y'
                    %            current_number =IDMatch;
                    %        else
                    %            current_number = input('Type number to write []= write on next cell\n');
                    %            if isempty(current_number)
                    %                current_number = numel(DataBase_filter.pn_filter) + 1;
                    %            end
                    %        end
                    %    end
                    %end
                    end
                
                    DataBase_filter.pn_filter.fn_mov_full{id_mov} = [List_pn_mov_cat{id_mov} '\' List_fn_mov_cat{id_mov}];
                    DataBase_filter.pn_filter.top{id_mov} = [List_pn_mov_cat{1} '\filter'];
                    DataBase_filter.pn_filter.(selectWB){id_mov} = pn_save_onoff;
                    DataBase_filter.(selectWB).Points_Traj_pair{id_mov} = Points_Traj_pair;
                    DataBase_filter.(selectWB).Parameter{id_mov} = Parameter;
                  end
                
                %-------------------------------------------------------------------------
            else
                DataBase_filter.pn_filter.fn_mov_full{id_mov} = [List_pn_mov_cat{id_mov} '\' List_fn_mov_cat{id_mov}];
                DataBase_filter.pn_filter.top{id_mov} = [List_pn_mov_cat{1} '\filter'];
                DataBase_filter.pn_filter.(selectWB){id_mov} = [];
                DataBase_filter.(selectWB).Points_Traj_pair{id_mov} = [];
                DataBase_filter.(selectWB).Parameter{id_mov} = Parameter;
            end
        end
        %-------------------------------------------------------------------------
        %-------------------------------------------------------------------------
    end
end
