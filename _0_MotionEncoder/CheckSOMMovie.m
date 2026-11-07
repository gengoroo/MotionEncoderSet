function play_montage(NodeMovie,Model)

    %% SOM layout montage with node numbers%% =====================================================
% Safe SOM Montage Movie
%% =====================================================

    netSOM = Model.SOM;
    
    pos = netSOM.layers{1}.positions;
    
    [h,w,nFrames] = size(NodeMovie{1});
    
    MontageMovie = zeros( ...
        h*8,...
        w*8,...
        nFrames,...
        'single');
    
    for t = 1:nFrames
    
        frameMontage = zeros( ...
            h*8,...
            w*8,...
            'single');
    
        occupied = false(8,8);
    
        for nodeID = 1:min(64,numel(NodeMovie))
    
            movieFrame = mat2gray(NodeMovie{nodeID}(:,:,t));
    
            %=================================================
            % SOM座標 → 格子座標
            %=================================================
    
            col = round(pos(1,nodeID)) + 1;
            row = round(pos(2,nodeID)) + 1;
    
            % 範囲外防止
            col = max(1,min(8,col));
            row = max(1,min(8,row));
    
            % 重複防止
            if occupied(row,col)
    
                placed = false;
    
                for rr = 1:8
                    for cc = 1:8
    
                        if ~occupied(rr,cc)
    
                            row = rr;
                            col = cc;
    
                            placed = true;
                            break
    
                        end
    
                    end
    
                    if placed
                        break
                    end
    
                end
    
            end
    
            occupied(row,col) = true;
    
            %=================================================
            % タイル領域
            %=================================================
    
            r0 = (row-1)*h + 1;
            r1 = min(row*h,size(frameMontage,1));
    
            c0 = (col-1)*w + 1;
            c1 = min(col*w,size(frameMontage,2));
    
            %=================================================
            % サイズ保険
            %=================================================
    
            tileH = r1-r0+1;
            tileW = c1-c0+1;
    
            if size(movieFrame,1)~=tileH || ...
               size(movieFrame,2)~=tileW
    
                movieFrame = ...
                    imresize(movieFrame,...
                    [tileH tileW]);
    
            end
    
            frameMontage(r0:r1,c0:c1) = movieFrame;
    
        end
    
        MontageMovie(:,:,t) = frameMontage;
    
    end
    
    %% =====================================================
    % Preview First Frame
    %% =====================================================
    
    figure
    imshow(MontageMovie(:,:,1),[])
    title('SOM Montage')
    
    %% =====================================================
    % Play
    %% =====================================================
    
    implay(MontageMovie)
end

function check_model(Model)

        [coeff,score,~,~,explained] = pca(Model.Embedding);
        
        figure
        scatter(score(:,1),score(:,2),20,'filled')
        axis equal
        
        figure
        plot(cumsum(explained),'o-')
        ylabel('Variance Explained (%)')
        xlabel('PC')
    
    
        %SOM が意味のある分類をしているか確認
        nodeA = 17;
        nodeB = 30;
        
        idxA = find(Model.Winner==nodeA);
        idxB = find(Model.Winner==nodeB);
        
        meanA = mean(MOV_adjust(:,:,:,idxA),4);
        meanB = mean(MOV_adjust(:,:,:,idxB),4);
        
        implay(mat2gray(meanA))
        implay(mat2gray(meanB))
    
        %% =====================================================
        % Representative movie of each SOM node
        %% =====================================================
        
        NodeMovie = cell(64,1);
        
        for nodeID = 1:64
        
            idx = find(Model.Winner==nodeID);
        
            if isempty(idx)
        
                NodeMovie{nodeID} = ...
                    zeros(size(MOV_adjust(:,:,:,1)));
        
            else
        
                NodeMovie{nodeID} = ...
                    mean(MOV_adjust(:,:,:,idx),4);
        
            end
        
        end
    
        %% =====================================================
        % 8x8 Node Montage
        %% =====================================================
        
        [h,w,nFrames] = size(NodeMovie{1});
        
        MontageMovie = zeros( ...
            h*8,...
            w*8,...
            nFrames,...
            'single');
        
        for t = 1:nFrames
        
            frameMontage = zeros( ...
                h*8,...
                w*8,...
                'single');
        
            for nodeID = 1:64
        
                movieFrame = mat2gray( ...
                    NodeMovie{nodeID}(:,:,t));
        
                row = ceil(nodeID/8);
                col = mod(nodeID-1,8)+1;
        
                r0 = (row-1)*h + 1;
                r1 = row*h;
        
                c0 = (col-1)*w + 1;
                c1 = col*w;
        
                frameMontage(r0:r1,c0:c1) = ...
                    movieFrame;
        
            end
        
            MontageMovie(:,:,t) = frameMontage;
        
        end
        
        implay(MontageMovie)
    
    
        NodeCount = histcounts( ...
        Model.Winner,...
        1:65);
    
        bar(NodeCount)
        
        xlabel('Node')
        ylabel('Movie Count')
        title('SOM Node Occupancy')
    
        figure;
        NodeCount = histcounts(Model.Winner,1:65);
        
        imagesc(MontageMovie(:,:,1))
        hold on
        
        for nodeID = 1:64
        
            row = ceil(nodeID/8);
            col = mod(nodeID-1,8)+1;
        
            text( ...
                (col-1)*129+5,...
                (row-1)*129+15,...
                sprintf('%d\nn=%d',...
                    nodeID,...
                    NodeCount(nodeID)),...
                'Color','w');
    
    end

end

function [Dnode, MeanNode] =dist_Nodes(Model)
    %Node間距離
    nodes = unique(Model.Winner);
    
    for k = 1:length(nodes)
    
        idx = find(Model.Winner==nodes(k));
    
        MeanNode(:,:,:,k) = ...
            mean(MOV_adjust(:,:,:,idx),4);
    
    end
    
    X = reshape(MeanNode,[],size(MeanNode,4));
    
    Dnode = pdist2(X',X');
    
    figure
    imagesc(Dnode)
    axis image
    colorbar
    title('Distance between node movies')
    
    %------------------------------------
    %最も孤立したNode
    avgDist = mean(Dnode,2);
    
    [~,idx] = sort(avgDist,'descend');
    
    idx(1:10)
    %そのNodeに属する動画群
    node = idx(1);
    
    members = find(Model.Winner==node);
    
    members
end

function R = corr_SOM_MOV(Model)
    %SOMが機能しているか？
    [r,c] = ind2sub([8 8],1:64);
    
    pos = [r(:) c(:)];
    
    r = corrcoef( ...
        squareform(pdist(pos)), ...
        squareform(pdist(Dnode)) );
    %もっと簡単には
    figure
    plot(Dnode(52,:))
    hold on
    plot(Dnode(54,:))
    
    %SOMがちゃんと位相保存しているか
    [r,c] = ind2sub([8 8],1:64);
    pos = [r(:) c(:)];
    
    Dsom = pdist(pos);
    
    X = reshape(MeanNode,[],64);
    
    DnodeVec = pdist(X');
    
    R = corrcoef(Dsom,DnodeVec);
    
    R(1,2)
end

function R = corr_SOM_3DCNN(Model)
    %　R > 0　なら良い　0.3～0.7ならかなり成功　近くに配置されたノードほど似た動画
    %ただしEmbedding(64dim)でSOMは学習しているのに、比較は違う空間の距離で行っているのでこの指標は？
    %以下が良い
    [r,c] = ind2sub([8 8],1:64);
    
    pos = [r(:) c(:)];
    nodes = 1:64;
    
    for k = 1:64
    
        idx = find(Model.Winner==k);
    
        if ~isempty(idx)
    
            NodeEmbed(k,:) = ...
                mean(Model.Embedding(idx,:),1);
    
        else
    
            NodeEmbed(k,:) = NaN;
    
        end
    end
    %空ノード除外
    valid = ~any(isnan(NodeEmbed),2);
    
    NodeEmbed = NodeEmbed(valid,:);
    
    posValid = pos(valid,:);
    %距離
    Dsom = pdist(posValid);
    
    Demb = pdist(NodeEmbed);
    
    R = corrcoef(Dsom,Demb);
    
    R(1,2)%0.413だった good
end

%外れ値動画を抽出(他の全動画から平均的に最も遠い動画)
D = pdist2(Model.Embedding,Model.Embedding);

meanD = mean(D,2);

[~,idx] = sort(meanD,'descend');

idx(1:20)

%35 36 37 がトップ３だった
%この3つが同じSOMノードに入るか
specialIdx = idx(1:3); Model.Winner(specialIdx);%ans = 16    16    48 NodeはSOMが見つけた特殊イベント群


%外れ値動画モンタージュ Encoder が最も区別しているイベント群
idxShow = [35 36 37 26 69 98 140 21 ...
           86 117 58 56 152 73 30 44];

figure

for k = 1:length(idxShow)

    subplot(4,4,k)

    movie = MOV_adjust(:,:,:,idxShow(k));

    imagesc(mean(movie,3))

    axis image off
    title(num2str(idxShow(k)))

end

colormap gray

%外れ値動画同士の距離
specialIdx = idx(1:20);

Dspecial = pdist2( ...
    Model.Embedding(specialIdx,:), ...
    Model.Embedding(specialIdx,:));

figure
imagesc(Dspecial)
axis image
colorbar %小さな青ブロックを作れば、外れ値クラスタ 全部バラバラなら別種類の特徴

%これらの外れ値動画が同じノードに集約されているのか複数の特殊ノードに分かれているのか
%Model.Winner([35 36 37 26 69 98 140])

specialIdx = [35 36 37 26 69 98 140 21 86 117 58 56 152 73 30 44 54 27 60 123];
[ specialIdx(:) , Model.Winner(specialIdx(:))' ]
%あるいは見やすく
table(specialIdx(:), ...
      Model.Winner(specialIdx(:)), ...
      'VariableNames',{'Movie','Node'})%上位外れ値動画 20 個は、少数の特殊ノードに集中していない

%ノードごとの外れ値数
%Node48 : 3個
%Node16 : 2個
%Node52 : 2個
%その他は１個ずつ

%Encoderは1つの軸で分離しているのではなく複数種類の特徴軸を作っている

%特に調べる価値があるノード
%各ノードの平均動画
nodes = [16 48 52];

figure

for n = 1:length(nodes)

    idx = find(Model.Winner==nodes(n));

    MeanMovie = mean(MOV_adjust(:,:,:,idx),4);

    subplot(1,3,n)

    imagesc(mean(MeanMovie,3))

    axis image off

    title(sprintf('Node %d (N=%d)', ...
        nodes(n), numel(idx)))

end

colormap gray

%特に興味深い点
%R = 0.413 SOM上で近いノード=>Embeddingも似ている

%Node16・48・52 の違いを比較
nodes = [16 48 52];

for n = 1:numel(nodes)

    idx = find(Model.Winner==nodes(n));

    MeanNode(:,:,:,n) = ...
        mean(MOV_adjust(:,:,:,idx),4);

end

clim = max(abs(MeanNode(:)));

figure

for n = 1:3

    for f = 1:size(MeanNode,3)

        subplot(3,size(MeanNode,3),...
            (n-1)*size(MeanNode,3)+f)

        imagesc(MeanNode(:,:,f,n),[-clim clim])

        axis image off

        title(sprintf('N%d F%d', ...
            nodes(n),f))

    end

end

colormap gray

%Encoderが分離している特徴
%出現タイミング 双極子の強さ 空間的広がり 前駆活動の有無らしい

%何が違うか」を直接見るなら差分
Diff16_48 = MeanNode(:,:,:,1)-MeanNode(:,:,:,2);
Diff16_52 = MeanNode(:,:,:,1)-MeanNode(:,:,:,3);
Diff48_52 = MeanNode(:,:,:,2)-MeanNode(:,:,:,3);

figure

for f = 1:5

    subplot(3,5,f)
    imagesc(Diff16_48(:,:,f))
    axis image off
    title(sprintf('16-48 F%d',f))

    subplot(3,5,5+f)
    imagesc(Diff16_52(:,:,f))
    axis image off
    title(sprintf('16-52 F%d',f))

    subplot(3,5,10+f)
    imagesc(Diff48_52(:,:,f))
    axis image off
    title(sprintf('48-52 F%d',f))

end

colormap gray
colorbar
%定量的には
for i = 1:3
    for j = i+1:3

        d(i,j) = norm( ...
            MeanNode(:,:,:,i)-MeanNode(:,:,:,j), ...
            'fro');

    end
end

d
%特に興味深いのは、
find(Model.Winner==16)
find(Model.Winner==48)
find(Model.Winner==52)

%すでに
%35,36 → Node16
%37,69,140 → Node48
%26,98 → Node52
%だったので
%Node16 = 35・36型イベント
%Node48 = 37・69・140型イベント
%Node52 = 26・98型イベント
%を代表している可能性が高いです。

%各ノードの時間プロファイルを比較
nodes = [16 48 52];

for n = 1:numel(nodes)

    idx = find(Model.Winner==nodes(n));

    MeanMovie = mean(MOV_adjust(:,:,:,idx),4);

    T(:,n) = squeeze(mean(abs(MeanMovie),[1 2]));

end

figure
plot(T,'LineWidth',2)

legend("Node16","Node48","Node52")
xlabel('Frame')
ylabel('Mean Abs Activity')

%全体評価
%Embedding Diversity ≈ 0.057
%SOM位相保存相関 ≈ 0.413
%Node52 ≠ Node54
%Node16・48・52で明瞭な時間構造差
%なので動画中の異なるイベントタイプを表現空間上で整理できている状態