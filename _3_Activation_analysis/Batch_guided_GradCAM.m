%-------------------------------------------------------------------------
% 初期フォルダ
clear;close all;
fn_m = mfilename('fullpath');
[pn_m, fn_m] = fileparts(fn_m);
if exist([pn_m '\datapath.mat'],'file')
    load([pn_m '\datapath.mat']);
end
if exist('datapath','var')
    pn_def = datapath;
else
    pn_def = '';
end
try
    datapath = uigetdir(pn_def,'Select parent folder including SliceOf*\n');
catch
    datapath = uigetdir('','Select parent folder including SliceOf*\n');
end
if datapath~=0
    save([pn_m '\datapath.mat'],'datapath');
end
%-------------------------------------------------------------------------
pn_top = datapath;
if 1==2
pn_class_movie = uigetdir(datapath,'select pn_anyclass of avi');
pn_cc = uigetdir(pn_class_movie,'select pn_CC for analysis');
[void, cc_words_temp] = fileparts(pn_cc);
n_words = input([cc_words_temp ':How many words to specify cc folder\n']);
cc_words = cc_words_temp(1:n_words);
fprintf('%s specified as cc folder search word\n',cc_words);
end
visible = input('Type "on" or "off" to select figure display mode, just enter = on\n','s');
if isempty(visible)
    visible = 'on';
end
%yn_process_attribute = input('Make max attribution map y/n, [just enter = answer later]','s');
yn_process_attribute = input('Make max attribution map y/n, just enter = y','s');
if isempty(yn_process_attribute)
    yn_process_attribute = 'y';
end
%-------------------------------------------------------------------------
% AttriMap作成
ListSliceOf = dir(fullfile(datapath,'SliceOf1*'));
for id_slice = 1:numel(ListSliceOf)

    fprintf('Current folder is %s\n',ListSliceOf(id_slice).name);
    InfoDeep = dir(fullfile(pn_top, ListSliceOf(id_slice).name,'train_curve*', 'train_data.mat'));
    load([InfoDeep.folder '\train_data.mat']);
    ListIM =  dir(fullfile(pn_top, ListSliceOf(id_slice).name,'*', '*.tif'));

    parfor id_fn = 1:numel(ListIM)
        close all;
    
        fn_full = [ListIM(id_fn).folder ,'\' ListIM(id_fn).name];
        pn_save = [ListIM(id_fn).folder '\GradCAM'];
        if ~exist(pn_save,'dir')
            mkdir(pn_save);
        end
        im = imread(fn_full);
        [void, label] = fileparts(ListIM(id_fn).folder);
        net = NetStack_stack{end}{end};
        AttriMap = guided_GradCAM(net,im,label,'visible',visible);
        h=gcf;
        h.Name = strcat(h.Name, [' ', ListSliceOf(id_slice).name]);
        saveas(h,[pn_save,'\' ListIM(id_fn).name(1:end-4),'.tif'],'tif');
        parsave_AttriMap([pn_save,'\' ListIM(id_fn).name(1:end-4),'_GradCAM.mat'],AttriMap);
        %fprintf('.');
    end
    fprintf('\n');
end
%-------------------------------------------------------------------------
%if isempty(yn_process_attribute)% 返事を保留した場合
%    yn_process_attribute = input('Make max attribution map y/n','s');
%end
%-------------------------------------------------------------------------
% Get Pixel Info to merge data from shift group
%if pn_class_movie == 0 % 返事を保留した場合
%    pn_class_movie = uigetdir(datapath,'select pn_anyclass of avi');
%end

%ListPnSingle = dir(fullfile(pn_class_movie,[cc_words '*'],'CC_single','Neuron*'));
%nNeuron = numel(ListPnSingle);
nNeuron = input('Type number of Encoders\n');
nSideNeuron = sqrt(nNeuron);
%ListFnMovie = dir(fullfile(pn_class_movie,'*.avi'));
%vidObj = VideoReader([ListFnMovie(1).folder '\' ListFnMovie(1).name]);
%SizeMovie = [vidObj.Height, vidObj.Width];
SizeMovie = input('Type YX movie size in [ , ]\n');

ListIM = dir(fullfile(datapath,'SliceOf1*','*','*.tif'));
im_encode = imread([ListIM(1).folder,'\' ListIM(1).name]);
SizeEncode = size(im_encode);

yn_resized_movie = input('Are movies resized during training network? y/n, [artificial encoder = usually n, natural encoder = usually y]\n ','s');
if yn_resized_movie == 'y'
    nPixPerGrid = SizeMovie./ (SizeEncode + [nSideNeuron, nSideNeuron]);% 1エンコーダは画像何ピクセルか 45+5
else
    nPixEncoder = input('Type side lengh [pix] of an encoder');
    nPixPerGrid = nPixEncoder/nSideNeuron;
end

ListPnShift = dir(fullfile(datapath,'SliceOf1*'));
nShift = numel(ListPnShift);
nSideShift = sqrt(nShift);

ListShift_norm = [0 0; 0 1/3; 0 2/3; 1/3 0; 1/3 1/3; 1/3 2/3; 2/3 0; 2/3 1/3; 2/3 2/3];
ListShift_lefttop = round((ListShift_norm + 1/2).* nPixPerGrid.*[nSideNeuron, nSideNeuron]);%2023.11.22修正 gradCAMデータの座標はエンコーダの中心に位置する。
ListShift_rightbottom = SizeMovie + round(([-3/2, -3/2] + ListShift_norm).* nPixPerGrid.*[nSideNeuron, nSideNeuron]); %2023.11.22修正
%-------------------------------------------------------------------------

[BestCh, P, P_allCh, Accu, AccuClass, Response] = get_P_rightclass(datapath);%どのセッションはどのnetを読むべきか。max peak => そのlabelに強いもの=>全体に強いもの

%-------------------------------------------------------------------------
% Attribution map作成
pn_movie = uigetdir('','select avi movie folder\n');
ListMovie = dir(fullfile(pn_movie, '*.avi'));

fprintf('Minimal GradCAM data is saved in "_SliceOfAllCh\Results.mat", see Results(mov_id).guided_GradCAM_bestCh\n');
yn_make_figures = input('\nMake& save figures in each category folder? [takes time] y/n, just enter = y\n','s');
if isempty(yn_make_figures)
    yn_make_figures = 'y';
end
if yn_make_figures == 'y'
    yn_save_original_fig = input('Save original fig files or tif only? y/n, just enter = n','s');
    if isempty(yn_save_original_fig)
        yn_save_original_fig = 'n';
    end
end

%fn_movie_cuttag = '_25-';
clear AttriMap;
clear AttriMapStack;
clear Results;
if yn_process_attribute == 'y'
    pn_save_top = [datapath, '\_SliceOfAllCh'];
    if ~exist(pn_save_top,'dir')
        mkdir(pn_save_top);
    end

    ListGradCh1 = dir(fullfile(datapath, 'SliceOf1Ch1','*','GradCAM','*mat'));% scan GradCAM files in the first "SliceOf1Ch1" folder

    fig = figure('Name', 'Press Space to Pause / Resume', 'NumberTitle', 'off', 'Position', [1, 950, 300, 80]);
    isPaused = false;%中断用2026.11.13
    set(fig, 'KeyPressFcn', @(src, event) assignin('base', 'isPaused', ~evalin('base', 'isPaused')));%中断用2026.11.13

    for id_grad = 1:numel(ListGradCh1)
        while isPaused && ishandle(fig)
            title('[PAUSED] Press any key to resume');
            pause(0.1);
        end
        if ishandle(fig)
            title('[RUNNING] Press any key to pause');
        end

        fprintf('.');
        if rem(id_grad,100) == 0
            fprintf('\n');
        end
        [void, label] = fileparts(fileparts(ListGradCh1(id_grad).folder));

        fn_gradCAM = ListGradCh1(id_grad).name;
        

        %該当する動画を検索。(ファイル名が包含される動画ファイルを検索）
        idx = find(arrayfun(@(x) contains(fn_gradCAM, erase(x.name,'.avi')), ListMovie));

        fprintf('Search for *.avi file matching %s\n',fn_gradCAM);
        if numel(idx)==1%2026.11.13
            ListMovie_found = ListMovie(idx);%
        else
            fprintf('\nMultiple *.avi files found, narrowing down\n');
            for ii = numel(idx):-1:1
                % grab character in fn_gradCAM after matching words
                id_char_check = strfind(fn_gradCAM,ListMovie(idx(ii)).name(1:end-4)) + numel(ListMovie(idx(ii)).name)-4;
                if ~strcmp(fn_gradCAM(id_char_check),'_')
                    idx(ii) = [];
                end
            end
            if numel(idx)==1 
                ListMovie_found = ListMovie(idx);%
            else
                fprintf('\nSelect *.avi file for %s\n',fn_gradCAM);
                for ii = 1:numel(idx)
                    fprintf('%d:%s\n',ii,ListMovie(idx(ii)).name);
                end
                kk = input('Select correct number\n');
                ListMovie_found = ListMovie(idx(kk));%
            end
        end
        fprintf('%s selected\n',ListMovie_found.name);

        fn_avi = [ListMovie_found.folder, '\' ListMovie_found.name];
        Results(id_grad).fn_avi = fn_avi;% Output

        %------------------------------------------------------------------
        % reading movie
        %fn_avi_temp = [fileparts(pn_class_movie), '\' label '\' ListGradCh1(id_grad).name(1:end-12)];%
        %cutlletterid = strfind(fn_avi_temp, fn_movie_cuttag);
        %fn_avi = [fn_avi_temp(1:cutlletterid-1), '.avi'];
        vidObj = VideoReader(fn_avi);
        dproj = 0;
        proj = 0;
        for id_frame = 2:vidObj.NumFrames
            dproj = dproj + sum(abs(double(read(vidObj,id_frame)) - double(read(vidObj,id_frame-1))),3);
            proj = proj + double(read(vidObj,id_frame));
        end
        %AttriMapStack.vidproj = vidproj; % making video projection
        AttriMapStack.trackproj = uint8(255 * mat2gray(dproj)); % making video projection
        AttriMapStack.dproj = uint8(255 * mat2gray(dproj)); % making video projection
        AttriMapStack.proj = uint8(255 * mat2gray(proj)); % making video projection
        %------------------------------------------------------------------
        % reading projected image
        if 1==2
        fn_avi_temp = [fileparts(pn_class_movie), '\' label '\track_proj\' ListGradCh1(id_grad).name(1:end-12)];%
        cutlletterid = strfind(fn_avi_temp, fn_movie_cuttag);

        fn_trackproj = [fn_avi_temp(1:cutlletterid-1), '_trackproj.fig'];
        uiopen(fn_trackproj,1);h=gcf;imdata=findall(h,'Type','image');
        AttriMapStack.trackproj = imdata.CData; % making track projection
        AttriMapStack.traj = findall(h,'Type','Line');
        close (h);

        fn_dproj = [fn_avi_temp(1:cutlletterid-1), '_dproj.fig'];
        uiopen(fn_dproj,1);h=gcf;imdata=findall(h,'Type','image');
        AttriMapStack.dproj = imdata.CData; % making track projection
        close (h);

        fn_proj = [fn_avi_temp(1:cutlletterid-1), '_proj.fig'];
        uiopen(fn_proj,1);h=gcf;imdata=findall(h,'Type','image');
        AttriMapStack.proj = imdata.CData; % making track projection
        close (h);
        end
        %------------------------------------------------------------------
        % Attribution map作成
        ListMem = dir(fullfile(datapath, 'SliceOf1Ch*',label,'GradCAM',fn_gradCAM));%scan GradCAM files in ALL "SliceOf1Ch*" folders,１つの動画カットに対して9Ch分ある
        for id_Ch = 1:numel(ListMem)
            load([ListMem(id_Ch).folder, '\' ListMem(id_Ch).name],'AttriMap');%ここでAttriMapロードされる

            AttriMapStack.im(1:SizeMovie(1),1:SizeMovie(2),id_Ch) = 0;%2023.11.22追加
            AttriMapStack.mapGB(1:SizeMovie(1),1:SizeMovie(2),id_Ch) = 0;%2023.11.22追加
            AttriMapStack.scoreMap(1:SizeMovie(1),1:SizeMovie(2),id_Ch) = 0;%2023.11.22追加
            AttriMapStack.map_guided_GradCAM(1:SizeMovie(1),1:SizeMovie(2),id_Ch) = 0;%2023.11.22追加       

            rangeDim1 = ListShift_lefttop(id_Ch,1):ListShift_rightbottom(id_Ch,1);%書き込む範囲
            rangeDim2 = ListShift_lefttop(id_Ch,2):ListShift_rightbottom(id_Ch,2);%書き込む範囲
            size_dim1 = numel(rangeDim1);
            size_dim2 = numel(rangeDim2);

            %AttriMapStack.im(rangeDim1,rangeDim2,id_Ch) = imresize(AttriMap.im, nPixPerGrid(1));
            AttriMapStack.im(rangeDim1,rangeDim2,id_Ch) = imresize(AttriMap.im, [size_dim1, size_dim2]);%2023.11.22修正
            %AttriMapStack.mapGB(rangeDim1,rangeDim2,id_Ch) = imresize(AttriMap.mapGB, nPixPerGrid(1));
            AttriMapStack.mapGB(rangeDim1,rangeDim2,id_Ch) = imresize(AttriMap.mapGB, [size_dim1, size_dim2]);%2023.11.22修正
            %AttriMapStack.scoreMap(rangeDim1,rangeDim2,id_Ch) = imresize(AttriMap.scoreMap,nPixPerGrid(1));
            AttriMapStack.scoreMap(rangeDim1,rangeDim2,id_Ch) = imresize(AttriMap.scoreMap, [size_dim1, size_dim2]);%2023.11.22修正
            %AttriMapStack.map_guided_GradCAM(rangeDim1,rangeDim2,id_Ch) = imresize(AttriMap.map_guided_GradCAM, nPixPerGrid(1));
            AttriMapStack.map_guided_GradCAM(rangeDim1,rangeDim2,id_Ch) = imresize(AttriMap.map_guided_GradCAM, [size_dim1, size_dim2]);%2023.11.22修正
        end
        %------------------------------------------------------------------
        % Track projにAttribution mapを重ねる
        AttriMapStack.trackproj_mapGB = repmat(rescale(AttriMapStack.trackproj)/2,1,1,3);
        %im = rescale(max(AttriMapStack.mapGB,[],3))/2;
        im = rescale(AttriMapStack.mapGB(:,:,BestCh(id_grad)))/2;
        AttriMapStack.trackproj_mapGB(1:size(im,1),1:size(im,2),2) = AttriMapStack.trackproj_mapGB(1:size(im,1),1:size(im,2),2) + im;
        
        AttriMapStack.trackproj_scoreMap = repmat(rescale(AttriMapStack.trackproj)/2,1,1,3);
        %im = rescale(max(AttriMapStack.scoreMap,[],3))/2;
        im = rescale(AttriMapStack.scoreMap(:,:,BestCh(id_grad)))/2;
        AttriMapStack.trackproj_scoreMap(1:size(im,1),1:size(im,2),2) = AttriMapStack.trackproj_scoreMap(1:size(im,1),1:size(im,2),2) + im;

        AttriMapStack.trackproj_guided_GradCAM = repmat(rescale(AttriMapStack.trackproj)/2,1,1,3);
        %im = rescale(max(AttriMapStack.map_guided_GradCAM,[],3))/2;
        im = rescale(AttriMapStack.map_guided_GradCAM(:,:,BestCh(id_grad)))/2;
        AttriMapStack.trackproj_guided_GradCAM(1:size(im,1),1:size(im,2),2) = AttriMapStack.trackproj_guided_GradCAM(1:size(im,1),1:size(im,2),2) + im;

        Results(id_grad).guided_GradCAM_bestCh = single(AttriMapStack.map_guided_GradCAM(:,:,BestCh(id_grad)));
        %Results(id_grad).guided_GradCAM_AllCh = single(AttriMapStack.map_guided_GradCAM);
        Results(id_grad).scoreMap_bestCh = single(AttriMapStack.scoreMap(:,:,BestCh(id_grad)));
        %Results(id_grad).scoreMap_AllCh = single(AttriMapStack.scoreMap);
        Results(id_grad).GuidedBackProp_bestCh = single(AttriMapStack.mapGB(:,:,BestCh(id_grad)));
        %Results(id_grad).GuidedBackProp_AllCh = single(AttriMapStack.mapGB);
        Results(id_grad).BestCh = BestCh(id_grad);
        Results(id_grad).P = P(id_grad);
        Results(id_grad).P_allCh = P_allCh(id_grad,:);
        Results(id_grad).Response = Response(id_grad);
        Results(id_grad).projectedMOV = single(AttriMapStack.proj);
        Results(id_grad).projectedMOVdiff = single(AttriMapStack.dproj);
        %------------------------------------------------------------------
        pn_save_class = [pn_save_top, '\GradCAM\' label];
        if ~exist(pn_save_class,'dir')
            mkdir(pn_save_class);
        end
        
        if yn_make_figures == 'y'

            videoproj = AttriMapStack.trackproj;
            try
                close(h);
            catch
            end
            h=figure('Name',['Attribution Map max ' label],'Color','w','Visible',visible);
            h.Position = [1,1,750,850];

            subplot(5,4,1);imagesc(mean(AttriMapStack.im,3)); axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)];title('mean(EncoderOutputs)');colorbar;
	        subplot(5,4,2);imagesc(mean(AttriMapStack.scoreMap,3)); axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)];title('gradCAM mean');colorbar;
	        subplot(5,4,3);imagesc(mean(AttriMapStack.mapGB,3)); axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)];title('GuidedBackprop mean');colorbar;
	        subplot(5,4,4);imagesc(mean(AttriMapStack.map_guided_GradCAM,3));axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)]; title('Guided Grad-CAM mean');colorbar;
    
            subplot(5,4,5);imagesc(AttriMapStack.im(:,:,BestCh(id_grad))); axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)];
            title({'EncoderOut best(P)' strcat("Ch=", num2str(BestCh(id_grad)),"P=", sprintf('%.2f', P(id_grad))), strcat('response:',string(Response(id_grad)))});colorbar;
	        subplot(5,4,6);imagesc(AttriMapStack.scoreMap(:,:,BestCh(id_grad))); axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)];title({'gradCAM', 'bestCh'});colorbar;
	        subplot(5,4,7);imagesc(AttriMapStack.mapGB(:,:,BestCh(id_grad))); axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)];title({'GuidedBackprop', 'bestCh'});colorbar;
	        subplot(5,4,8);imagesc(AttriMapStack.map_guided_GradCAM(:,:,BestCh(id_grad)));axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)]; title({'Guided Grad-CAM', 'bestCh'});colorbar;
    
	        subplot(5,4,9);imagesc(max(AttriMapStack.im,[],3)); axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)];title('max(EncoderOutputs)');colorbar;
	        subplot(5,4,10);imagesc(max(AttriMapStack.scoreMap,[],3)); axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)];title('gradCAM max');colorbar;
	        subplot(5,4,11);imagesc(max(AttriMapStack.mapGB,[],3)); axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)];title('GuidedBackprop max');colorbar;
	        subplot(5,4,12);imagesc(max(AttriMapStack.map_guided_GradCAM,[],3));axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)]; title('Guided grad-CAM max');colorbar;
            
            subplot(5,4,13);imagesc(AttriMapStack.trackproj);axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)]; title('track Projection');
            %%subplot(5,4,14);imshow(flipud(AttriMapStack.dproj));axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)]; title('d Projection');
            %subplot(5,4,14);imshow((AttriMapStack.dproj));axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)]; title('d Projection');
            subplot(5,4,15);imshow(AttriMapStack.proj);axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)]; title('Projection');
    
            subplot(5,4,17);imshow(AttriMapStack.trackproj_scoreMap);axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)]; title({'trackProjection', 'ScoreMap bestCh'});
            subplot(5,4,18);imshow(AttriMapStack.trackproj_mapGB);axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)]; title({'trackProjection', 'BackProp bestCh'});
            subplot(5,4,19);imshow(AttriMapStack.trackproj_guided_GradCAM);axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)]; title({'trackProjection', 'guidedGradCAM bestCh'});
            
            %subplot(4,3,5);imagesc(sum(AttriMapStack.vidproj,3));axis equal;a=gca;a.XLim=[0 size(videoproj,2)]; a=gca;a.YLim=[0 size(videoproj,1)]; title('Video Projection');colorbar;
    
            try
                %save ([pn_save_class '\' ListGradCh1(id_grad).name], 'AttriMapStack');
                saveas(h,[pn_save_class,'\' ListGradCh1(id_grad).name(1:end-4),'_maxproj_' , '.tif'],'tif');
                if yn_save_original_fig == 'y'
                    saveas(h,[pn_save_class,'\' ListGradCh1(id_grad).name(1:end-4),'_maxproj_' , '.fig'],'fig');
                end
            catch
                fprintf('Error in saving %s\n',[pn_save_class,'\' ListGradCh1(id_grad).name(1:end-4),'_maxproj_']);
            end

        end
    end

    save([pn_save_top, '\Results.mat'], 'Results','BestCh','P', 'P_allCh', 'Accu', 'AccuClass','Response','-v7.3');
end
%-------------------------------------------------------------------------