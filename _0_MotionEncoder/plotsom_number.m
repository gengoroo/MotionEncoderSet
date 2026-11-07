% SOMのトポロジーをプロットする
plotsom(net.IW{1,1},net.layers{1}.distances);

% 各ユニットの番号をプロットする
for i = 1:size(net.IW{1,1},1)
    for j = 1:size(net.IW{1,1},2)
        text(net.IW{1,1}(i,j,1),net.IW{1,1}(i,j,2),num2str((i-1)*size(net.IW{1,1},2)+j),'HorizontalAlignment','center');
    end
end