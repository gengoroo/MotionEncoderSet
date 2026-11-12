clear;close all;

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
datapath = uigetdir(pn_def,'Select def pn including any Deep.mat\n');
if datapath~=0
    save([pn_m '\datapath.mat'],'datapath');
end
%-------------------------------------------------------------------------

%pn_def = 'C:\Users\gengoro\SynologyDrive\Behavior\PTZ\PTZ20230717-1\CC_var_hyper_9Ch_Slice_0_5_15_30uM\SliceOf1Ch1\combine_All\results_all_no_shuffle_v2_2023-0815-1036';
[fn, pn] = uigetfile(datapath,'Select mat containing net suc as Deep.mat [] example network\n');
fn_data_net = [pn '\' fn ];
if isempty(fn_data_net)
    fn_data_net = 'C:\Users\gengoro\SynologyDrive\Behavior\PTZ\PTZ20230717-1\CC_var_hyper_9Ch_Slice_0_5_15_30uM\SliceOf1Ch1\combine_All\results_all_no_shuffle_v2_2023-0815-1036\Deep.mat';
end
load(fn_data_net);

%pn_def = 'C:\Users\gengoro\SynologyDrive\Behavior\PTZ\PTZ20230717-1\CC_var_hyper_9Ch_Slice_0_5_15_30uM\SliceOf1Ch1\combine_All';
pn_def = fileparts(fileparts(fileparts(pn)));
pn_grandparent =uigetdir(pn_def,'select grandparent folder contarininng .tif = parent of class folder');


% 各クラスの最初のtifを取り込む
ListPnClass = dir(fullfile(pn_grandparent, '*'));
id_class = 0;
clear im;
for ii = 1:numel(ListPnClass)
    if (numel(ListPnClass(ii).name) > 3)&& isempty(strfind(ListPnClass(ii).name,'combine'))%クラスフォルダ選択
        id_class = id_class + 1;
        ListTif = dir(fullfile([ListPnClass(ii).folder ,'\' ListPnClass(ii).name]));
        counter = 1;
        while ListTif(counter).isdir%フォルダをスキップして最初の画像を読み込む
            counter = counter + 1;
        end
        im_temp = imread([ListTif(counter).folder,'\',ListTif(counter).name]);
        im(:,:,id_class) = double(im_temp)/255;
    end
end
nChannels = id_class;%クラス数

FileList = dir(fullfile(pn_grandparent,'*.tif'));

% Analysis using Activation function
reset(imds);
T=read(imds);
nLayers = numel(net.Layers);
figure('Name','activation_analysis');hold on;
for id_Layer = 1:nLayers
    act{id_Layer} = activations(net, T{1},id_Layer);
    fprintf('Size of %s is %s \n', net.Layers(id_Layer).Name, num2str(size(act{id_Layer})));
    subplot(nLayers,1,id_Layer);

    ListDim = size(act{id_Layer});
    ListDim_multi = find(ListDim>=2);
    if numel(ListDim_multi) == 1
        DimReshape = [ListDim(ListDim_multi), 1];
    else
        DimReshape = ListDim(ListDim_multi);
    end
    outputdata = reshape(act{id_Layer},DimReshape);

    if numel(size(outputdata)) <= 2
        imagesc(outputdata);
    else
        lastlayerim = outputdata(:,:,1);
        imagesc
    end
end
%--------------------------------------------------------------------------
analyzeNetwork(net);
%--------------------------------------------------------------------------
nFile = size(im,3);
figure('Name','RF of each layer ROW input im Class');
counter = 0;
List_file_number = 0:nChannels;
maxrange = max(max(max(im(:,:,List_file_number(2:end)))));
nColumn = 6;
nRow = size(im,3)+1;
for ii = 1:numel(List_file_number)
    id_file = List_file_number(ii);

    if id_file>= 1
        id_row = ii;
        id_column = 1;
        subplot(nRow,nColumn,nColumn*(id_row-1)+id_column);hold on;
        imagesc(im(:,:,id_file),[0 maxrange]);colorbar;hold on;
    end

    for layer = 2:6
        id_row = ii;
        id_column = layer;

        subplot(nRow,nColumn,nColumn*(id_row-1)+id_column);hold on;
        name = net.Layers(layer).Name;
        fprintf('Layer name is %s\n',name);
        switch layer
            case {2,3,4}
                channels = 1:64;
            case {5,6}
                channels = 1:nChannels;
        end
        if id_file < 1 % without setting Initial images
            I = deepDreamImage(net,name,channels, 'PyramidLevels',1);
            I_stack{layer} = I;
        else % initial images are input image
            I = deepDreamImage(net,name,channels, 'PyramidLevels',1,'InitialImage',im(:,:,id_file));
        end
        title(name);
        I_tile = imtile(I,'ThumbnailSize',[64 64]);
        imshow(I_tile);
        if id_row == 1
            name = net.Layers(layer).Name;
            title(['Layer ',name,' Features'],'Interpreter','none');
        elseif id_column == 1
            title(['Filename ' FileList(id_file).name],'Interpreter','none');
        end
    end
end
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
layer = 5;%fc
I = I_stack{layer};
F_fc = reshape(I,size(I,1),size(I,2),size(I,numel(size(I))));%無駄な次元を詰める
nClass = size(F_fc,3);
nNeuron=25;
n_side = sqrt(nNeuron);
n_div = size(F_fc,1)/n_side;
for id_class = 1:nClass
    F_single = F_fc(:,:,id_class);
    for id_dim1 = 1:n_div
        for id_dim2 = 1:n_div
            range_1 = n_side*(id_dim1-1)+1:n_side*id_dim1;
            range_2 = n_side*(id_dim2-1)+1:n_side*id_dim2;
            F_mini(:,:,id_dim1,id_dim2,id_class) = F_single(range_1,range_2);
            F_linear(:,id_dim1,id_dim2,id_class) = reshape(F_single(range_1,range_2),[],1);
        end
    end
end

nClass = size(F_fc,3);
maxrange = max(max(max(max(F_linear))));
for id_class = 1:nClass
    classname = string(net.Layers(end).Classes(id_class));
    figure('Name',['Movie channel Spectrum in FC layer of Class# ',num2str(id_class), classname{1}]);
    for id_dim1 = 1:n_div
        for id_dim2 = 1:n_div
            id_plot = n_div*(id_dim2-1) + id_dim1;
            subplot(n_div,n_div,id_plot);hold on;
            plot(F_linear(:,id_dim1,id_dim2,id_class));
        end
    end
end
%--------------------------------------------------------------------------
% softmaxをPCA解析
layer = 6;
Data = reshape(I_stack{layer},[],nClass)';
[coeff,score,latent,tsquared,explained,mu] = pca(Data);
figure('Name','Softmax Category PCA');hold on;
plot3(score(:,1),score(:,2),score(:,3),'o');
for id_category = 1:nClass
    text(score(id_category,1),score(id_category,2),score(id_category,3),num2str(id_category));
end
%--------------------------------------------------------------------------
ListClass = net.Layers(7,1).Classes;
pn_data_net = fileparts(fn_data_net);
[a, pn_data_label] = fileparts(pn_grandparent);
pn_save = [pn_data_net '\ ActAna_' pn_data_label];
mkdir(pn_save);
%--------------------------------------------------------------------------
save([pn_save, '\activation_data.mat'],'I_stack','F_fc','F_mini','F_linear','ListClass','coeff','score','latent','tsquared','explained','mu');
h=findall(groot,'Type','figure');
for id_h = 1:numel(h)
    saveas( h(id_h), [pn_save, '\' h(id_h).Name, '.fig'],'fig');
end
%--------------------------------------------------------------------------
