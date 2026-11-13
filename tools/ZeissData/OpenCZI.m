clear;
close all;

fn_m = mfilename('fullpath');
[pn_m, fn_m] = fileparts(fn_m);
pn_def = [];
if exist([pn_m '\datapath.mat'],'file')
    load([pn_m '\datapath.mat']);
end

try
    [file,path] = uigetfile([pn_def, '\*.czi']);
catch
    [file,path] = uigetfile('*.czi');
end

pn_def = path;
save([pn_m '\datapath.mat'],'pn_def');

%-------------------------------------------------------------------------------------
reader = BioformatsImage(fullfile(path,file));

img0 = reader.getPlane(1,1,1);
[ny,nx] = size(img0);
MOV = zeros(ny,nx,3,reader.sizeT,'like',img0);
for t = 1:102
    for c = 1:2
        MOV(:,:,c,t) = reader.getPlane(1,c,t);
    end
end

ch_analyze = input('Which Ch# to analyze?\n');
implay(mat2gray(MOV(:,:,ch_analyze,:)));

%-------------------------------------------------------------------------------------
dMOV = MOV(:,:,:,2:end) - MOV(:,:,:,1:end-1);
AvedMOV = mean(abs(dMOV),4);
h_ave_d=figure('Name','AvedMOV');imagesc(AvedMOV(:,:,1));colorbar;
AveMOV = mean((MOV),4);
h_ave=figure('Name','AveMOV');imagesc(AveMOV(:,:,1));colorbar;

nPixBlock = input('nPix of one block\n');

img = double(AvedMOV(:,:,ch_analyze));
AvedMap = blockproc(img,[nPixBlock nPixBlock], ...
    @(block) mean(block.data(:)));
figure('Name','mean(diff Pix)');imagesc(AvedMap);colorbar;

img = double(AveMOV(:,:,ch_analyze));
AveMap = blockproc(img,[nPixBlock nPixBlock], ...
    @(block) mean(block.data(:)));
figure('Name','mean(Pix)');imagesc(AveMap);colorbar;

if 1==2
I = AvedMap;
Inorm = mat2gray(I);   % 最小→0, 最大→1
th = graythresh(Inorm);
th_original = min(I(:)) + th*(max(I(:))-min(I(:)));
AvedMap_thre = AvedMap*1.5;
AvedMap_thre(AvedMap_thre<th_original) = 0;
figure;imagesc(AvedMap_thre);colorbar;
end

AvedMap_thre = AvedMap;
Values_diffave =AvedMap(:);
thre_diff = mean(Values_diffave) + 0.5*std(Values_diffave);
figure;hist(Values_diffave);hold on;plot(thre_diff,0,'r*');title('AvePixDiff');
AvedMap_thre(AvedMap_thre<thre_diff) = 0;
figure('Name','mean(diff Pix over ther)');imagesc(AvedMap_thre);colorbar;
idx_diff = find(AvedMap >= thre_diff);

AveMap_thre = AveMap;
Values_ave =AveMap(:);
thre_int = mean(Values_ave) + 0.3*std(Values_ave);
figure;hist(Values_ave);hold on;plot(thre_int,0,'r*');title('AvePix');
AveMap_thre(AveMap_thre<thre_int) = 0;
figure('Name','mean(Pix) over thre');imagesc(AveMap_thre);colorbar;
idx_int = find(AveMap >= thre_int);

idx_integ = intersect(idx_diff, idx_int);
[row, col] = ind2sub(size(AvedMap), idx_integ);
Pos = [row(:), col(:)];
Pos(:,1) = size(AvedMap,1) -  Pos(:,1) +1;%1次元目反転

%-------------------------------------------------------------------------------------
nFrame = size(MOV,3);
blockH = nPixBlock;
blockW = nPixBlock;
nRow = floor(size(MOV,1)/blockH);
nCol = floor(size(MOV,2)/blockW);

figure(h_ave); hold on;
for id_pos = 1:size(Pos,1)
    r = Pos(id_pos,1);
    c = Pos(id_pos,2); 

    if (r*blockH <= size(MOV,1))&&(c*blockH <= size(MOV,2))
        MOV_split(:,:,:,id_pos) = ...
        MOV((r-1)*blockH+1:r*blockH,...
            (c-1)*blockW+1:c*blockW,ch_analyze,:);
    end
    text((c-1)*blockW+1,size(MOV,1)-(r-1)*blockH+1,[num2str(id_pos) ':' num2str(Pos(id_pos,:))],'Color','w');
    text(c*blockW,size(MOV,1)-r*blockH,[num2str(id_pos)],'Color','w');%左右反転上下逆転
end

%-------------------------------------------------------------------------------------
% 保存先フォルダ
outDir = [path '\AVI_export'];
if ~exist(outDir,'dir')
    mkdir(outDir);
end

fps = 30; % フレームレート(適宜変更)
for id_pos = 1:size(MOV_split,4)

    % 動画データ取得
    movieData = double(MOV_split(:,:,:,id_pos));
    % 動画全体で輝度範囲を決定
    vmin = min(movieData(:));
    vmax = max(movieData(:));

    % AVIファイル作成
    outFile = fullfile(outDir, sprintf('MOV_%03d.avi', id_pos));

    v = VideoWriter(outFile,'Motion JPEG AVI');
    v.FrameRate = fps;
    open(v);

    % 各フレームを書き込み
    for f = 1:size(movieData,3)

        frame = movieData(:,:,f);
        % 0-1へ正規化
        if vmax > vmin
            frame = (frame - vmin) / (vmax - vmin);
        else
            frame = zeros(size(frame));
        end
        frame = max(0,min(1,frame));

        frame = uint8(frame * 255);
        writeVideo(v, frame);

    end
    close(v);
    fprintf('Saved: %s\n', outFile);

end
disp('All movies exported.');