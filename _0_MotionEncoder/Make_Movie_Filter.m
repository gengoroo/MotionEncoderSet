clear;close all;
%2026_11_01 エンコーダのサイズを手動指定（大きすぎると精度下がるため）
%-------------------------------------------------------------------------
% 初期フォルダ
clear;close all;
fn_m = mfilename('fullpath');
[pn_m, fn_m] = fileparts(fn_m);
pn_def = [];
if exist([pn_m '\datapath.mat'],'file')
    load([pn_m '\datapath.mat']);
end
pn_def = uigetdir(pn_def,'Select top movie pn that includes avi movies, or sub movie folders\n');
if pn_def~=0
    save([pn_m '\datapath.mat'],'pn_def');
end
%-------------------------------------------------------------------------
fprintf('Type enter only for default setting if "just enter" option is avaiable\n');

yn_py = input('Use python codes y/n, just enter = n','s');
if isempty(yn_py)
    yn_py = 'n';
end
if yn_py == 'y'
    terminate(pyenv);
    if count(py.sys.path, pn_m) == 0
        insert(py.sys.path, int32(0), pn_m);
    end
    py.importlib.import_module('get_movie_feature');
    pyenv(ExecutionMode="OutOfProcess");
    py.importlib.import_module('find_salient');
    py.importlib.import_module('find_conn');
    py.importlib.import_module('seq_connect');
    py.importlib.import_module('find_overlap');
    py.importlib.import_module('find_SIFT_pair');
    mod1 = py.importlib.import_module('find_SIFT_pair');%mod1 = py.importlib.reload(mod1);
    %py.importlib.import_module('make_moviefilter_from_traj');
    mod2 = py.importlib.import_module('make_moviefilter_from_traj');
    mod3 = py.importlib.import_module('format_movie_filter');
    %mod = py.importlib.reload(mod);
end
%-------------------------------------------------------------------------    

% 出力フォルダ
pn_movie_top = pn_def;
pn_save = [pn_movie_top '\MadeEnc'];
mkdir(pn_save);
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
%counter = 0;
clear List_fn_mov_cat;
clear List_pn_mov_cat
select_mode = input('1: Select automatic from single folder 2:manual, just enter = 1 \n');
if isempty(select_mode)
    select_mode = 1;
end
switch select_mode
    case 1
        yn_grandparent = input('select y: grandparant folder/category folder/avi files n: parent folder/CategoryName_***.avi, just enter = n \n','s');
        if isempty(yn_grandparent)
            yn_grandparent = 'n';
        end
        n_pick = input('How many movie per category\n');

        if yn_grandparent == 'y'
            d = dir(pn_movie_top);
            d = d([d.isdir]);
            ListDn = {d(~ismember({d.name},{'.','..'})).name};%% '.' と '..' を除外
            counter = 0;
            for id_pn = 1:numel(ListDn)
                List = dir(fullfile([pn_movie_top '\' ListDn{id_pn}],'*.avi'));
                N = numel(List);
                N_pick_exist = min(n_pick, N);
                ListPickRandom = randperm(N, N_pick_exist);
                for id_pick = 1:numel(ListPickRandom)
                    id_random = ListPickRandom(id_pick);
                    if ~strcmp(List(id_random).name,'MergedVideo.avi')
                        counter = counter +1;
                        List_fn_mov_cat{counter} = List(id_random).name;
                        List_pn_mov_cat{counter} = [pn_movie_top '\' ListDn{id_pn}];
                    end
                end
            end
        else
            List = dir(fullfile(pn_movie_top,'*.avi'));
            ListCell = struct2cell(List);
            ListFn = ListCell(1,:);
            ListDelitemp = strfind(ListFn, '_');
            ListDeli = cellfun(@(x) x(1), ListDelitemp);
            Labels = categorical(cellfun(@(x) x(1:ListDeli-1), ListFn, 'UniformOutput', false));
            LabelUni = unique(Labels);
            for id_label = 1:numel(LabelUni)
                ListFnID{id_label} = find(Labels == LabelUni(id_label));
                N = numel(ListFnID{id_label});
                ListSelFnID{id_label} = ListFnID{id_label}(randperm(N, n_pick));
                ListSelFn{id_label} = List(ListSelFnID{id_label});
            end
            data = {cat(1,ListSelFn{:})};
            data2 = struct2cell(data{1});
            List_pn_mov_cat = data2(2,:);
            List_fn_mov_cat = data2(1,:);
        end

    case 2
        yn_make_concat_movie = 'y';
        while(yn_make_concat_movie == 'y')
            if ~exist('List_fn_mov_cat','var')
                [List_fn_mov_cat_temp, pn_temp] = uigetfile([pn_def, '\*.avi'], 'select movie to concatenate, cancel to stop, multi on','MultiSelect','on');
                if iscell(List_fn_mov_cat_temp)
                    List_fn_mov_cat = List_fn_mov_cat_temp;
                else
                    List_fn_mov_cat{1} = List_fn_mov_cat_temp;
                end
                for ii = 1:numel(List_fn_mov_cat)
                    List_pn_mov_cat{ii} = pn_temp;
                end
            else
                [ListFnAdd, pn_temp] = uigetfile([pn_def, '\*.avi'], 'select movie to concatenate, cancel to stop','MultiSelect','on');
                List_fn_mov_cat = [List_fn_mov_cat, ListFnAdd];
                for ii = 1:numel(ListFnAdd)
                    ListPnAdd{ii} = pn_temp;
                end
                List_pn_mov_cat = [List_pn_mov_cat, ListPnAdd];
            end
            
            %counter = counter + 1;
            %[List_fn_mov_cat{counter}, List_pn_mov_cat{counter}] = uigetfile([pn_def, '\*.avi'], 'select movie to concatenate, cancel to stop');
            pn_def = pn_temp;
            if pn_def == 0
                yn_make_concat_movie = 'n';
                List_fn_mov_cat(end) = [];
                List_pn_mov_cat(end) = [];
            else
                %fprintf('%d:%s\n',counter,List_fn_mov_cat{counter});
            end
        end
end

for ii = 1:numel(List_fn_mov_cat)
    fprintf('%d:%s \  %s\n',ii,List_pn_mov_cat{ii}, List_fn_mov_cat{ii});
end

if exist('List_fn_mov_cat','var')
    v = VideoWriter([pn_save '\MergedVideo.avi']);
    open(v);
    for id_movie = 1:numel(List_fn_mov_cat)
        v_add = VideoReader([List_pn_mov_cat{id_movie}, '\',  List_fn_mov_cat{id_movie}]);
        while hasFrame(v_add)
            frame_add = readFrame(v_add);
            writeVideo(v, frame_add);
        end
    end
    close(v);
    save([pn_save '\merged_movies.mat'],'List_fn_mov_cat','List_pn_mov_cat');
end
%-------------------------------------------------------------------------
[fn_mov_cat, pn_mov_cat] = uigetfile([pn_save, '\*.avi'],'select concatenated .avi to make movie filter');

fn_m_full = mfilename('fullpath');
[pn_m, fn_m] = fileparts(fn_m_full);
fn_dataabse = 'DataBase_filter.mat';
if ~exist([pn_save '\DataBase_filter.mat'],'file')
    DataBase_filter=[];
    save([pn_save '\DataBase_filter.mat'],'DataBase_filter');
end

%addpath('C:\Users\gengoro\Dropbox (Scripps Research)\_OriginalSoftwares\MATLAB program CF\_DeepLearning\MovieFilter\_SOM');
%pn_mov = 'C:\Users\gengoro\SynologyDrive\test';
%fn_mov = 'PTZ20230717-1_1_crop1350_crop1.avi';

yn_save_heavy_fig = 'n';%時間がかかる
yn_plot = input('\nyn_plot y/n []=skip \n','s');
%-------------------------------------------------------------------------
%パラメータ
Parameter.min_metric_std=2;
Parameter.Range = [ -1 -25];
Parameter.margin_start = 1;
Parameter.margin_stop = 1;
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
%開いているfig取得
ListFigStart = findall(groot,'Type','figure');
%特徴点と代表特徴点の取得
[fn_black, fn_white, pn_d_movie, pn_filter] = make_d_movie([pn_mov_cat, fn_mov_cat]);%mov_white, mov_black作成。pn_filterは保存するフォルダ
mkdir([pn_filter '\Code']);copyfile(pn_m, [pn_filter '\Code']);

if yn_py == 'y'
    result = py.get_movie_feature.get_movie_feature(fullfile(pn_d_movie,fn_black),py.list({int32(3)}),false);
    Points_black_py = result{1};
    Pos_black_py    = result{2};

    result = py.get_movie_feature.get_movie_feature(fullfile(pn_d_movie,fn_white),py.list({int32(3)}),false);
    Points_white_py = result{1};
    Pos_white_py    = result{2};

    Salient_black_py = py.find_salient.find_salient(Points_black_py.z,Parameter.min_metric_std);
    Salient_white_py = py.find_salient.find_salient(Points_white_py.z,Parameter.min_metric_std);

    AllFeature_black_py = py.find_salient.find_salient(Points_black_py.z,py.None);
    AllFeature_white_py = py.find_salient.find_salient(Points_white_py.z,py.None);

    %特徴点の軌跡の追跡
    Pair_py.black = py.find_conn.find_conn(Points_black_py.z);
    Pair_py.white = py.find_conn.find_conn(Points_white_py.z);
    Points_seq_py.black = py.seq_connect.seq_connect(Pair_py.black,Points_black_py.z);
    Points_seq_py.white = py.seq_connect.seq_connect(Pair_py.white,Points_white_py.z);

    Points_Traj_py.black = py.find_featuretraj.find_featuretraj(Points_seq_py.black, Points_black_py.z);
    Points_Traj_py.white = py.find_featuretraj.find_featuretraj(Points_seq_py.white, Points_white_py.z);

    %--------------------------------------------------------------------------------------------------------
    % MATLABデータ型に変換-
    Points_black.z = sift_py2mat(Points_black_py.z);
    Pos_black.Feature.z = double(Pos_black_py.Feature.z);
    Salient.black = struct_py2mat(Salient_black_py);
    AllFeature.black = struct_py2mat(AllFeature_black_py);

    Points_white.z = sift_py2mat(Points_white_py.z);
    Pos_white.Feature.z = double(Pos_white_py.Feature.z);
    Salient.white = struct_py2mat(Salient_white_py);
    AllFeature.white = struct_py2mat(AllFeature_white_py);
    
    Pair.black = pair_py2mat(Pair_py.black);
    Pair.white = pair_py2mat(Pair_py.white);

    Points_seq.black = Points_seq_py2mat(Points_seq_py.black);
    Points_seq.white = Points_seq_py2mat(Points_seq_py.white);

    Points_Traj.black = FeatureTraj_py2mat(Points_Traj_py.black);
    Points_Traj.white = FeatureTraj_py2mat(Points_Traj_py.white);

else
    [Points_black, Pos_black] = get_movie_feature([pn_d_movie '\' fn_black],'DIM_select', [3]);%で特徴点検出, DIM_select [3]でZ軸のみスキャン
    set(gcf,'Name','FeatureOFF','Color','w');
    [Points_white, Pos_white] = get_movie_feature([pn_d_movie '\' fn_white],'DIM_select', [3]);%で特徴点検出
    set(gcf,'Name','FeatureON','Color','w');

    Salient.black  = find_salient(Points_black.z, Parameter.min_metric_std); %特徴点をMetricで絞る
    Salient.white  = find_salient(Points_white.z, Parameter.min_metric_std); %特徴点をMetricで絞る
    AllFeature.black = find_salient(Points_black.z, []); %特徴点をMetricで絞る, emptyなら全て
    AllFeature.white  = find_salient(Points_white.z, []); %特徴点をMetricで絞る, emptyなら全て
    if yn_plot == 'y'
        plot_salient(Salient.black, Salient.white, AllFeature.black, AllFeature.white);%表示
    end

    %特徴点の軌跡の追跡
    Pair.black = find_conn(Points_black.z);%最短距離でペアを探す
    Pair.white = find_conn(Points_white.z);%最短距離でペアを探す
    Points_seq.black = seq_connect(Pair.black,'Points',Points_black.z);%フレームをスキャンして、連続シークエンスを拾う
    Points_seq.white = seq_connect(Pair.white,'Points',Points_white.z);%フレームをスキャンして、連続シークエンスを拾う

    Points_Traj.black = find_featuretraj(Points_seq.black,Points_black.z,'yn_plot',yn_plot,'min_contig',3,'POS_overlay',Salient.black.Pos);%軌跡データを取得
    set(gcf,'Name','Traj-Salient-OFF');
    Points_Traj.white = find_featuretraj(Points_seq.white,Points_white.z,'yn_plot',yn_plot,'min_contig',3,'POS_overlay',Salient.white.Pos);%軌跡データを取得
    set(gcf,'Name','Traj-Salient-ON');

end

%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
ListFigEnd = findall(groot,'Type','figure');%開いているfig取得
%-------------------------------------------------------------------------
% 保存
if yn_save_heavy_fig == 'y'
    ListFig = setdiff(ListFigEnd,ListFigStart);%保存するfig取得
    pn_save_fig = [pn_filter '\Fig'];
    mkdir(pn_save_fig);
    save_figs(ListFig,pn_save_fig);%Figを保存
    close(ListFig);
end
fn_save = 'FeatureTraj.mat';
save([pn_filter '\' fn_save],'Parameter','Salient','AllFeature','Pair','Points_seq','Points_Traj');
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
List_selectWB = {'b','w'};
yn_save = 'y';
%List_selectWB = {'b'};
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
            if yn_py == 'y'
                All_ref_py = AllFeature_black_py;
                All_search_py = AllFeature_white_py;
		        Points_Traj_ref_py = Points_Traj_py.black;
		        Points_Traj_search_py = Points_Traj_py.white;
                Salient_ref_py = Salient_black_py;
            end

	    case 'w'
            All_ref = AllFeature.white;
            All_search = AllFeature.black;
	        Points_Traj_ref = Points_Traj.white;
	        Points_Traj_search = Points_Traj.black;
            Salient_ref = Salient.white;
            if yn_py == 'y'
                All_ref_py = AllFeature_white_py;
                All_search_py = AllFeature_black_py;
		        Points_Traj_ref_py = Points_Traj_py.white;
		        Points_Traj_search_py = Points_Traj_py.black;
                Salient_ref_py = Salient_white_py;
            end
    end
    %-------------------------------------------------------------------------
    PairOverlap = find_overlap(Salient_ref, All_search, All_ref,'Range',Parameter.Range);%重なるペアを探す
    fprintf('size(PairOverlap.ref.Location,1) is %d\n',size(PairOverlap.ref.Location,1));
    if yn_py == 'y'
        %PairOverlap_py = py.find_overlap.find_overlap(Salient_black_py, All_search_py, All_ref_py, py.list({-5,5}));
        PairOverlap_py = py.find_overlap.find_overlap(Salient_ref_py, All_search_py, All_ref_py, py.list({Parameter.Range(1), Parameter.Range(2)}));
        fprintf('size(double(PairOverlap_py.ref.Location),1) is %d\n',size(double(PairOverlap_py.ref.Location),1));
    end
    %-------------------------------------------------------------------------
    if strcmp(yn_plot, 'y')&&strcmp(yn_py, 'y')
        figure('Name','Ref Search trajectories overaly'); hold on;
        plot3(AllFeature.white.Pos(:,1), AllFeature.white.Pos(:,2),AllFeature.white.Pos(:,3),'k.');
        plot3(AllFeature.black.Pos(:,1), AllFeature.black.Pos(:,2),AllFeature.black.Pos(:,3),'m.');
        plot_traj(Points_Traj_ref,'c');
        plot_traj(Points_Traj_search,'m');
        legend({'ref','search'});
    end
    %-------------------------------------------------------------------------
    % どの軌跡に載っているか座標から探す
    fprintf('Input# of Points_Traj_ref is%d Points_Traj_search is %d\n' ,size(Points_Traj_ref,2) ,size(Points_Traj_search,2));
    Points_Traj_pair = find_SIFT_pair(Points_Traj_ref, Points_Traj_search, PairOverlap);
    fprintf('Output# are ref=%d found=%d\n',size(Points_Traj_pair.ref,2),size(Points_Traj_pair.found,2));
    if yn_py == 'y'
        fprintf('Input# of Points_Traj_ref_py is %d, Points_Traj_search_py are %d\n' ,size(Points_Traj_ref,2) ,size(Points_Traj_search_py,2));
        Points_Traj_pair_py = mod1.find_SIFT_pair(Points_Traj_ref_py, Points_Traj_search_py, PairOverlap_py);
        fprintf('Output# are ref=%d found=%d\n',size(Points_Traj_pair_py.ref,2),size(Points_Traj_pair_py.found,2));
    end
    %-------------------------------------------------------------------------
    %保存
    pn_save_onoff = [pn_filter, '\' selectWB];
    mkdir(pn_save_onoff);
    fn_save_onoff = 'PairTraj.mat';
    save([pn_save_onoff '/' fn_save_onoff],'Points_Traj_pair');
    
    ListFigEnd = findall(groot,'Type','figure');%開いているfig取得
    ListFig = setdiff(ListFigEnd,ListFigStart);%保存するfig取得
    pn_save_onoff_fig = [pn_save_onoff '\Fig'];
    mkdir(pn_save_onoff_fig);
    save_figs(ListFig,pn_save_onoff_fig);%Figを保存
    close (ListFig);

    load([pn_save '\DataBase_filter.mat']);

    yn_overwrite = 'n';
    if ~isempty(DataBase_filter)
        for id_data = 1:numel(DataBase_filter.pn_filter.top)
            fprintf('%d: %s\n',id_data, DataBase_filter.pn_filter.top{id_data});
        end
    end
    if ~isempty(DataBase_filter)
        IDMatch = find(cellfun(@(x) strcmp(pn_filter,x), DataBase_filter.pn_filter.top));
        if ~isempty(IDMatch)&&(selectWB =='b')%topが重なっていて、かつOFFのデータだったら（先に書き込むので）
            fprintf('This has been analyzed in %s\n', num2str(IDMatch));
            fprintf('Overwrite on %s\n' ,num2str(IDMatch));
            yn_overwrite = input('Overwrite y/n','s');
        else
            fprintf('This data is new \n');
        end
    end

    if isempty(DataBase_filter)
        current_number = 1;
    else
        if selectWB == 'b'
            if yn_overwrite == 'y'
                current_number =IDMatch;
            else
                current_number = input('Type number to write []= write on next cell\n');
                if isempty(current_number)
                    current_number = numel(DataBase_filter.pn_filter) + 1;
                end
            end
        end
    end

    %if selectWB == 'b'
    %    yn_save = input('save y/n','s');
    %end
    if yn_save == 'y'
        DataBase_filter.pn_filter.fn_mov_full{current_number} = [pn_mov_cat '\' fn_mov_cat];
        DataBase_filter.pn_filter.top{current_number} = pn_filter;
        DataBase_filter.pn_filter.(selectWB){current_number} = pn_save_onoff;
        DataBase_filter.(selectWB).Points_Traj_pair{current_number} = Points_Traj_pair;
        DataBase_filter.(selectWB).Parameter{current_number} = Parameter;
        save([pn_save '\DataBase_filter.mat'],'DataBase_filter');
    end
    
    %-------------------------------------------------------------------------
end
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
load([pn_save '\DataBase_filter.mat']);
for id_data = 1:numel(DataBase_filter.pn_filter.top)
    fprintf('%d: %s\n',id_data, DataBase_filter.pn_filter.top{id_data});
end

ListData = 1;%input('Type Input List\n');
fprintf('DataBase_filter [ListData= %s] imported \n',num2str(ListData));
for id_dataset = 1:numel(ListData)
    id_data = ListData(id_dataset);
    fprintf('Current file is %s\n',DataBase_filter.pn_filter.top{id_data});
    List_selectWB = {'b','w'};
    for id_wb = 1:numel(List_selectWB)
        selectWB = List_selectWB{id_wb};

        Points_Traj_pair = DataBase_filter.(selectWB).Points_Traj_pair{id_data};
        Parameter = DataBase_filter.(selectWB).Parameter{id_data};
        [MOV_onoff, Info_MOV_onoff] = make_moviefilter_from_traj(Points_Traj_pair.ref,Points_Traj_pair.found, Parameter.margin_start, Parameter.margin_stop, selectWB);%入力movie filterサンプル作成
        if yn_py == 'y'
            result = mod2.make_moviefilter_from_traj(Points_Traj_pair_py.ref, Points_Traj_pair_py.found, int32(Parameter.margin_start), int32(Parameter.margin_stop),py.str(char(selectWB)));
            MOV_onoff_py = result{1};
            Info_MOV_onoff_py = result{2};
        end
        
        
        fprintf('N data for %s of %dth Data is %d\n',selectWB,id_dataset,numel(MOV_onoff));

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
for id_wb = 1:numel(List_selectWB)
    selectWB = List_selectWB{id_wb};
    fprintf('Total N for %s is %d\n',selectWB, numel(MOV_onoff_stack.(selectWB)));
end

%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
if exist([pn_save '\DataBase_SOM.mat'],'file')
    load([pn_save '\DataBase_SOM.mat']);
    for id_data = 1:numel(DataBase_SOM.pn_filter.top)
        fprintf('%d: %s\n',id_data, DataBase_SOM.pn_filter.top{id_data});
    end
end

id_data_som = 1;%input('Type som_data# for saving\n');
fprintf('Saved on DataBase_SOM.MOV_onoff_stack{id_data_som=%d}\n',id_data_som);
DataBase_SOM.pn_filter.top = DataBase_filter.pn_filter.top;
DataBase_SOM.MOV_onoff_stack{id_data_som} = MOV_onoff_stack;
DataBase_SOM.MOV_onoff_stack{id_data_som} = MOV_onoff_stack;
DataBase_SOM.Info_MOV_onoff_stack{id_data_som} = Info_MOV_onoff_stack;
DataBase_SOM.ListData{id_data_som} = ListData;

sel_SOM = input('1:Embedding 3D CNN before SOM [not good] 2:SOM only [good], just enter = 2\n');
if isempty(sel_SOM)
    sel_SOM = 2;
end
switch sel_SOM
    case 1
        mapSize = input('Type mapSize, just enter = 8 [:8x8=64]\n');
        if isempty(mapSize)
            mapSize = 8;
        end
        miniBatchSize = input('Type miniBatchSize, just enter = 192, reduce it if GPU overflows');
        if isempty(miniBatchSize)
            miniBatchSize = 192;
        end
    case 2
        yn_normW = input('Normalize SOM weight yn, n:sometimes better, just enter = y\n','s');
        if isempty(yn_normW)
            yn_normW = 'y';
        end
end

%エンコーダ手動選別　2026_11_01
for id_wb = 1:numel(List_selectWB)
    fprintf('Configuration for %s center encoder\n',List_selectWB{id_wb});
    selectWB = List_selectWB{id_wb};
    [List_sel.(selectWB), Max_side_temp, Max_frame_temp, Range_encoder.(selectWB), List_side, List_dur]= define_filter_size(MOV_onoff_stack.(selectWB));
    mode_side = mode(List_side);

    Max_side.(selectWB) = input(['Type Encoder side crop size, just enter: mode(List_side)=' num2str(mode_side) '\n']);
    if isempty(Max_side.(selectWB))
        Max_side.(selectWB) = mode_side;
    end

    mode_frame = mode(List_dur);
    Max_frame.(selectWB) = input(['Type Encoder Frame crop size, just enter: mode(List_dur)=' num2str(mode_frame) '\n']);
    if isempty(Max_frame.(selectWB))
        Max_frame.(selectWB) = mode_frame;
    end
    List_FilterSize.(selectWB) = [Max_side.(selectWB), Max_side.(selectWB), Max_frame.(selectWB)];%Size = max range
end

ResizeSide = input('Resize RFs?, if yes type pixel number of a suqre side, if not just enter\n');
yn_plot_som_plane = input('Show SOM plane y/n, takes time if RF is too many, just enter = n\n','s');
if isempty(yn_plot_som_plane)
    yn_plot_som_plane = 'n';
end
integmode = 'distance';

h_temp = figure;
h_start = gcf;
for id_wb = 1:numel(List_selectWB)
    selectWB = List_selectWB{id_wb};

    MOV_onoff_all = MOV_onoff_stack.(selectWB);%エンコーダ選別データ取り込み　2026_11_01
    MOV_onoff_sel = MOV_onoff_all(List_sel.(selectWB));%エンコーダ選別データ取り込み　2026_11_01

    Info_MOV_onoff = Info_MOV_onoff_stack.(selectWB);
    Info_MOV_onoff_sel.size = Info_MOV_onoff.size(List_sel.(selectWB),:);%エンコーダ選別データ取り込み　2026_11_01
    Info_MOV_onoff_sel.pix_max = Info_MOV_onoff.pix_max(List_sel.(selectWB));%エンコーダ選別データ取り込み　2026_11_01
    Info_MOV_onoff_sel.pix_min = Info_MOV_onoff.pix_min(List_sel.(selectWB));%エンコーダ選別データ取り込み　2026_11_01

    MOV_adjust= format_moviefilter(MOV_onoff_sel,'Info_MOV_onoff',Info_MOV_onoff_sel,'rep_value','specify','FilterSize',List_FilterSize.(selectWB),'ResizeSide',ResizeSide);%値指定 2026_11_01
    %MOV_adjust= format_moviefilter(MOV_onoff_stack.(selectWB),'Info_MOV_onoff',Info_MOV_onoff_stack.(selectWB),'rep_value','mode');%サイズ調整、最頻値に合わせる 

    if yn_py == 'y'
        MOV_adjust_py = mod3.format_moviefilter(MOV_onoff_py, Info_MOV_onoff_py, rep_value='mode');
        %np = py.importlib.import_module('numpy');
        %Size = double(MOV_adjust_py{1}.shape)
        %A_py = np.ascontiguousarray(MOV_adjust_py{1});
        %A = double(A_py);
    end

    switch sel_SOM
        case 1
            %Model = cortical_som_train(MOV_adjust,pn_save);
            Model = cortical_som_train(MOV_adjust,pn_save,'mapSize',mapSize,'miniBatchSize',miniBatchSize,'tagFig',[selectWB '-Cen']);
            netSOM = Model.SOM;
            [NodeMovie, ListNonNaN] = make_NodeMovie(MOV_adjust,Model,'integmode',integmode);%integmode: weight=synaptic weight, distance=node distance
            MOV_som = cat(4, NodeMovie{:});
        case 2
            [MOV_som, rep_vec, netSOM, ListFig, SideEncoder]= som_movie_filter(MOV_adjust,'yn_normW',yn_normW,'yn_plot',yn_plot);%自己組織化して、入力と結果表示 2024.02.03 SideEncoder
    end
    DataBase_SOM.(selectWB).MOV_som{id_data_som} = MOV_som;
    DataBase_SOM.(selectWB).net{id_data_som} = netSOM;
    DataBase_SOM.(selectWB).rep_vec{id_data_som} = netSOM.IW{1};%rep_vec;
    DataBase_SOM.(selectWB).MOV_adjust{id_data_som} = MOV_adjust;
    DataBase_SOM.(selectWB).SideEncoder = [size(MOV_adjust,1), size(MOV_adjust,2)];%SideEncoder;%2024.02.03 SideEncoder
    if sel_SOM ==1 
        DataBase_SOM.(selectWB).Model{id_data_som} = Model;
    end

    figure;plotsomnd(netSOM);h=gcf;h.Name = [h.Name, selectWB, '-Cen Wdist'];
    figure;plotsomhits(netSOM,Model.Embedding');h=gcf;h.Name = [h.Name, selectWB, '-Cen hits'];
    figure;plotsompos(netSOM, Model.Embedding');h=gcf;h.Name = [h.Name, selectWB, '-Cen Wpos'];
    if yn_plot_som_plane == 'y'
        figure('Name',[selectWB, '-Cen planes']);plotsomplanes(netSOM);
    end

end
h_end = gcf;
save([pn_save '\DataBase_SOM.mat'],'DataBase_SOM');
pn_save_som = [pn_save '\SOM'];
mkdir(pn_save_som);
for ii = h_start.Number+1:h_end.Number
    h = figure(ii);
    saveas(h,[pn_save_som '\' h.Name '.fig'],'fig');
end

%-------------------------------------------------------------------------
id_data_som = 1;%input('Type som_data# to generate DataBase{id_dataset=1}\n');
fprintf('id_data_som=%d is used to generate DataBase{id_dataset=1}\n',id_data_som);
id_dataset = 1;
clear DataBase;
for id_wb = 1:numel(List_selectWB)
    selectWB = List_selectWB{id_wb};
    fprintf('\n%s-Centered Encoders\n',selectWB);
    
    DataBase{id_dataset}.input.RFMap = DataBase_SOM.(selectWB).MOV_som{id_data_som};
    DataBase{id_dataset}.input.SideEncoder = DataBase_SOM.(selectWB).SideEncoder;
    DataBase{id_dataset}.yn_good = ones(size(DataBase{id_dataset}.input.RFMap,4),1);
    DataBase{id_dataset}.Rank = repmat({'A'}, 1,size(DataBase{id_dataset}.input.RFMap,4));
    DataBase{id_dataset}.datasetname = 'SOM';
    DataBase{id_dataset}.List_FilterSize = List_FilterSize;
    DataBase{id_dataset}.List_sel = List_sel;
    DataBase{id_dataset}.Range = Range_encoder;

    save([pn_save '\DataBase_RFMap_' selectWB '.mat'],'DataBase');

    h_start = gcf;
    for id_map = 1:size(DataBase{id_dataset}.input.RFMap,4)
        figure('Name',[selectWB '-Centered RF Map#' num2str(id_map)]);
        nFrame = size(DataBase{id_dataset}.input.RFMap,3);
        for id_frame = 1:nFrame
            range = max(abs(reshape(DataBase{id_dataset}.input.RFMap(:,:,:,id_map),[],1)));
            subplot(1,nFrame,id_frame);
            im = DataBase{id_dataset}.input.RFMap(:,:,id_frame,id_map);
            imagesc(im);
            if ~isnan(min(im(:)))&&~isnan(max(im(:)))
                clim([-range, range]);
            end
        end
    end
    h_end = gcf;
    fig_organizer(h_start.Number:h_end.Number);
end

for id_wb = 1:numel(List_selectWB)
    selectWB = List_selectWB{id_wb};
    fprintf('\nReading %s-Centered Encoders\n',selectWB);

    ListGood = input('Type RF# list [=DataBase{id_dataset=1}.input.RFMap(:,:,:,RF# to use);] to use as encoders, others will be deleted, just enter=use all\n');
    if isempty(ListGood)
        ListGood = 1:size(DataBase{id_dataset}.input.RFMap,4);
    end

    load([pn_save '\DataBase_RFMap_' selectWB '.mat'],'DataBase');
    %上書き
    DataBase{id_dataset}.input.RFMap = DataBase{id_dataset}.input.RFMap(:,:,:,ListGood);
    DataBase{id_dataset}.yn_good = DataBase{id_dataset}.yn_good(ListGood);
    DataBase{id_dataset}.Rank = DataBase{id_dataset}.Rank(ListGood);
    save([pn_save '\DataBase_RFMap_' selectWB '.mat'],'DataBase','ListGood');
end
%-------------------------------------------------------------------------
%-------------------------------------------------------------------------
