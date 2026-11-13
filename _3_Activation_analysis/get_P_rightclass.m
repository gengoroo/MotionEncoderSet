function [BestCh, P, P_allCh, Accu, AccuClass, Y] = get_P_rightclass(pn_ChTop)

    %------------------------------------------------------------
    % calc_score
    %ListDeep = dir(fullfile(pn_ChTop,'SliceOf1Ch*','combine_All','results_all*','Deep.mat'));
    ListDeep = dir(fullfile(pn_ChTop,'SliceOf1Ch*','train_curve*','train_data.mat'));
    load([ListDeep(1).folder '\' ListDeep(1).name]);% to get Labels
    net = NetStack_stack{end}{end};
    

    fprintf('Calculating accuracies\n');
    Labels = net.Layers(end).Classes;
    for id_deep = 1:numel(ListDeep)
        fn_net = [ListDeep(id_deep).folder '\' ListDeep(id_deep).name];
        load(fn_net);
        net = NetStack_stack{end}{end};
        pn_cat_top = fileparts(fileparts(fn_net));
        imds = make_imds(pn_cat_top);
        
        [Y,Scores(:,:,id_deep)] = classify(net,imds);
        Accu(id_deep) = sum(Y == imds.Labels)/numel(Y);%各ネットワークの精度（全体）

       for id_class = 1:numel(Labels)
           list_class = find(imds.Labels == Labels(id_class));
           AccuClass(id_deep,id_class) = sum(Y(list_class) == Labels(id_class))/numel(list_class);   %各ネットワークの各クラスの精度（クラス毎）
       end
    end

    Weight(1,1,:) = Accu;
    Weight = repmat(Weight,size(Scores,1),size(Scores,2));
    ScoresVotePre = Scores.*Weight;
    ScoresVote = mean(ScoresVotePre,3);
    
    [void, ResponseVote] = find(max(ScoresVote,[],2) == ScoresVote);
    Correct = grp2idx(imds.Labels);% 最後(#9)のシフトグループのimdsを使っている。フォルダ名以外は同じ

    for ii = 1:numel(Correct)
        P(ii,1) = ScoresVote(ii,Correct(ii));%votingで正しいクラスを選ぶ確率。
        P_allCh(ii,:) = reshape(Scores(ii,Correct(ii),:),1,[]);%それぞれのネットワークが正しいクラスを選ぶ確率。
        ListCandi = find( P_allCh(ii,:) == max( P_allCh(ii,:)) );% その動画を正しく選ぶ確率が一番高いネットワーク（複数ありうる）
        ListCandi2 = ListCandi(find( AccuClass(ListCandi,Correct(ii)) == max(AccuClass(ListCandi,Correct(ii)))));%複数あった場合、そのクラスに関する選択精度がより高いもの
        ListCandi3 = ListCandi2(find(Accu(ListCandi2) == max(Accu(ListCandi2))));%その中で、全体の選択制度がより高いもの。
        if numel(ListCandi) == 1
            BestCh(ii) = ListCandi;
        elseif numel(ListCandi2) == 1
            BestCh(ii) = ListCandi2;
        else
            BestCh(ii) = min(ListCandi3);%それでも複数あった場合エラー防止のため最初のものを取る
        end
    end
    %------------------------------------------------------------

end