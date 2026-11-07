clear;close all;

fprintf('run Main_SIFT3D.m in Matlab2015 before this code.\n')
%-------------------------------------------------------------------------
% 初期フォルダ
clear;close all;
fn_m = mfilename('fullpath');
[pn_m, fn_m] = fileparts(fn_m);
pn_def = [];
if exist([pn_m '\datapath.mat'],'file')
    load([pn_m '\datapath.mat']);
end
pn_def = uigetdir(pn_def,'Select top movie pn\n');
if pn_def~=0
    save([pn_m '\datapath.mat'],'pn_def');
end
%-------------------------------------------------------------------------
% 出力フォルダ
pn_movie_top = pn_def;
pn_save = [pn_movie_top '\MadeEnc'];
mkdir(pn_save);
%-------------------------------------------------------------------------
%counter = 0;
clear List_fn_mov_cat;
clear List_pn_mov_cat;
sel_mov_clip = input('1: gaussian before SOM 2: raw_image\n');
select_mode = input('1: Select automatic from single folder 2:manual \n');
select_black_SIFT3D = input('Filter black_traj by SIFT3D y/n?\n','s');
yn_som = input('Perform Self-Organization y/n\n','s');
size_section_inputimage = input('Specify size of input images that made Encoders, ex tadimage = 80');

if select_black_SIFT3D == 'y'
    addpath('C:\Users\gengoro\Scripps Research Dropbox\Hiramoto Masateru\_OriginalSoftwares\MATLAB program CF\_DeepLearning\MovieFilter\_0_MotionEncoder\SIFT3D_batch');
end

switch select_mode
    case 1
        n_pick = input('How many movie per class\n');
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
    fprintf('%d:%s |  %s\n',ii,List_pn_mov_cat{ii}, List_fn_mov_cat{ii});
end

%%if 1==0 % skip for each mode 2024.11.18
%%if exist('List_fn_mov_cat','var')
%%    v = VideoWriter([pn_save '\MergedVideo.avi']);
%%    open(v);
%%    for id_movie = 1:numel(List_fn_mov_cat)
%%        v_add = VideoReader([List_pn_mov_cat{id_movie}, '\',  List_fn_mov_cat{id_movie}]);
%%        while hasFrame(v_add)
%%            frame_add = readFrame(v_add);
%%            writeVideo(v, frame_add);
%%        end
%%    end
%%    close(v);
%%    save([pn_save '\merged_movies.mat'],'List_fn_mov_cat','List_pn_mov_cat');
%%end
%%clear frame_add;
%%[fn_mov_cat, pn_mov_cat] = uigetfile([pn_save, '\*.avi'],'select concatenated .avi to make movie filter');
%%end
%-------------------------------------------------------------------------

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
Parameter.nSD_metric = 1;% selection by nSD+mean of metric
Parameter.scale_factor = 5;% overlap by 2DSHIFT's metric*scale_factor (radius)
Parameter.maxNfeaturePt = 100;%Max number of trajectories (bk) seleced after overlap with 3D SIFT
%-------------------------------------------------------------------------

%-------------------------------------------------------------------------
pn_SIFT3D = [List_pn_mov_cat{1} '\SIFT3D'];
%nSD_metric = 1; % selection by nSD+mean of metric
%scale_factor = 5; % overlap by 2DSHIFT's metric*scale_factor (radius)
pn_save_feature = extract_feature(List_fn_mov_cat, List_pn_mov_cat, pn_SIFT3D,Parameter,yn_plot,yn_save_heavy_fig);
fprintf('Feature detection complete\n');
%-------------------------------------------------------------------------
DataBase_filter = pair_bw_traj(pn_save_feature,List_pn_mov_cat,List_fn_mov_cat,Parameter,yn_plot);
save([pn_save '\DataBase_filter.mat'],'DataBase_filter');
%-------------------------------------------------------------------------
load([pn_save '\DataBase_filter.mat']);
%-------------------------------------------------------------------------
%ListData = input('Type Input List\n');
[MOV_onoff_stack, Info_MOV_onoff_stack] = generate_movie_filter(DataBase_filter,sel_mov_clip);
%-------------------------------------------------------------------------
List_selectWB = {'b', 'w'};
for id_wb = 1:numel(List_selectWB)
    MOV_adjust{id_wb}= format_moviefilter_wide(MOV_onoff_stack.(List_selectWB{id_wb}),Info_MOV_onoff_stack.(List_selectWB{id_wb}),'rep_value','specify','side',size_section_inputimage);%サイズ調整、XYは動画の1/10, tは一番長いものに統一

    for id_cell = 1:size(MOV_adjust{id_wb},4)
        for id_frame = 1:size(MOV_adjust{id_wb},3)
            MOV_adjust20{id_wb}(:,:,id_frame,id_cell) = imresize(MOV_adjust{id_wb}(:,:,id_frame,id_cell),[20 20]);
        end
    end

    h = figure('Name',['SIFT_MOV_adjust_', List_selectWB{id_wb}]);
    show_RFMap_XYTC(MOV_adjust{id_wb});
    selectWB = List_selectWB{id_wb};
    saveas(h,[pn_save '\DataBase_RFMap_' selectWB '_SIFT3D_adjust.fig'],'fig')
end
%-------------------------------------------------------------------------
List_selectWB = {'b', 'w'};
for id_wb = 1:numel(List_selectWB)
    clear DataBase;
    selectWB = List_selectWB{id_wb};
    DataBase{1}.input.RFMap = MOV_adjust{id_wb};
    DataBase{1}.yn_good = ones(size(DataBase{1}.input.RFMap,4),1);
    DataBase{1}.Rank = repmat({'A'}, 1,size(DataBase{1}.input.RFMap,4));
    DataBase{1}.datasetname = 'SIFT3D_MOV_adjust';
    save([pn_save '\DataBase_RFMap_' selectWB '_SIFT3D_adjust.mat'],'DataBase');

        DataBase{1}.input.RFMap = MOV_adjust20{id_wb};
        save([pn_save '\DataBase_RFMap20_' selectWB '_SIFT3D_adjust.mat'],'DataBase');
end
%-------------------------------------------------------------------------

if yn_som == 'y'
%-------------------------------------------------------------------------
    for id_wb = 1:numel(List_selectWB)
        [MOV_som, rep_vec, net, ListFig, SideEncoder]= som_movie_filter(MOV_adjust,'yn_plot',yn_plot);%自己組織化して、入力と結果表示 2024.02.03 SideEncoder
        figure('Name',['SIFT_SOM', List_selectWB{id_wb}]);
        show_RFMap_XYTC(MOV_som);
        saveas(h,[pn_save '\DataBase_RFMap_' selectWB '_SIFT3D_SOM.fig'],'fig')
    end
    %-------------------------------------------------------------------------
    clear DataBase;
    for id_wb = 1:numel(List_selectWB)
        selectWB = List_selectWB{id_wb};
        DataBase{1}.input.RFMap = MOV_som;
        DataBase{1}.input.SideEncoder = SideEncoder;
        DataBase{1}.yn_good = ones(size(DataBase{id_dataset}.input.RFMap,4),1);
        DataBase{1}.Rank = repmat({'A'}, 1,size(DataBase{id_dataset}.input.RFMap,4));
        DataBase{1}.datasetname = 'SIFT3D_SOM';
        save([pn_save '\DataBase_RFMap_' selectWB '_SIFT3D_SOM.mat'],'DataBase');
    end
    %-------------------------------------------------------------------------
end
%-------------------------------------------------------------------------

