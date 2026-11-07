%-------------------------------------------------------------------------
function pn_save_feature = extract_feature(List_fn_mov_cat, List_pn_mov_cat, pn_SIFT3D,Parameter,yn_plot,yn_save_heavy_fig)
    nMovie = numel(List_fn_mov_cat);
    for id_movie = 1:nMovie
        %-------------------------------------------------------------------------
        %開いているfig取得
        ListFigStart = findall(groot,'Type','figure');
        %特徴点と代表特徴点の取得
        %[fn_black, fn_white, pn_d_movie, pn_filter] = make_d_movie([pn_mov_cat, fn_mov_cat]);%mov_white, mov_black作成。pn_filterは保存するフォルダ
        [fn_black, fn_white, pn_d_movie, pn_filter] = make_d_movie([List_pn_mov_cat{id_movie}, '\' List_fn_mov_cat{id_movie}]);%each version 2024.11.18
        %fn_m = mfilename('fullpath');
        %[pn_m, fn_m] = fileparts(fn_m);
        %mkdir([pn_filter '\Code']);copyfile(pn_m, [pn_filter '\Code']);
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
        %-------------------------------------------------------------------------
        %特徴点の軌跡の追跡
        Pair.black = find_conn(Points_black.z);%最短距離でペアを探す
        Pair.white = find_conn(Points_white.z);%最短距離でペアを探す
        Points_seq.black = seq_connect(Pair.black,'Points',Points_black.z);%フレームをスキャンして、連続シークエンスを拾う
        Points_seq.white = seq_connect(Pair.white,'Points',Points_white.z);%フレームをスキャンして、連続シークエンスを拾う
        
        Points_Traj.black = find_featuretraj(Points_seq.black,Points_black.z,'yn_plot',yn_plot,'min_contig',3,'POS_overlay',Salient.black.Pos);%軌跡データを取得
        set(gcf,'Name','Traj-Salient-OFF');
        Points_Traj.white = find_featuretraj(Points_seq.white,Points_white.z,'yn_plot',yn_plot,'min_contig',3,'POS_overlay',Salient.white.Pos);%軌跡データを取得
        set(gcf,'Name','Traj-Salient-ON');
        
        % New SIFT3D Points_Traj.blackのうち、SIFT3Dで検出される特徴点を含むものを選ぶ。2024.11.08
        load([pn_SIFT3D, '\' List_fn_mov_cat{id_movie}(1:end-4) '_SIFT3D.mat']);% SIFT3Dロード
        %scale_facotor = 10;
        %ListKeyPoints = List_octlevelmatch(1,1).coords;
        Metric = [keys.metric];
        ListKeyPoints = find(Metric >= mean(Metric)+Parameter.nSD_metric*std(Metric));% mean+SD以上を選択。

        %Parameter.maxNfeaturePt = 100;%
        [Points_Traj.black, ListHit] = traj_select(Points_Traj.black,ListKeyPoints,Parameter);

        %-------------------------------------------------------------------------
        ListFigEnd = findall(groot,'Type','figure');%開いているfig取得
        %-------------------------------------------------------------------------
        % 保存
        pn_save_feature{id_movie} = pn_filter;
        if ~exist(pn_save_feature{id_movie},'dir')
            mkdir(pn_save_feature{id_movie});
        end
        if yn_save_heavy_fig == 'y'
            ListFig = setdiff(ListFigEnd,ListFigStart);%保存するfig取得
            pn_save_fig = [pn_save_feature{id_movie} '\Fig'];
            mkdir(pn_save_fig);
            save_figs(ListFig,pn_save_fig);%Figを保存
            close(ListFig);
        end
        fn_save = 'FeatureTraj.mat';
        save([pn_save_feature{id_movie} '\' fn_save],'Parameter','Salient','AllFeature','Pair','Points_seq','Points_Traj','List_fn_mov_cat','List_pn_mov_cat','pn_SIFT3D');
        %-------------------------------------------------------------------------
        %-------------------------------------------------------------------------
        fprintf('.');
        if rem(id_movie,50)==0
            fprintf('\n');
        end
    end
end