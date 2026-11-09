%MakeCC_main
% 2023.12.21 f_Make_hyper_CC_var3X3_rev2_f1
clear;
fprintf('variants cleared\n');
%------------------------------------------------------------
mfn = mfilename('fullpath');
[pn_main, fn_main] = fileparts(mfn);
fn_datalocation = [fn_main,'_datalocation.mat'];
if exist([pn_main '\' fn_datalocation],'file')
    load([pn_main '\' fn_datalocation]);
end

folder_style = input('Is folder style 1: grandparant folder/category folder/avi files 2: parent folder/CategoryName_***.avi, just enter = 2 \n','s');
try
    pn_crop2 = uigetdir(pn_def,'select the grandparent or parent folder that includes avi files to encode\n');
catch
    pn_crop2 = uigetdir('','select the grandparent or parent that includes avi files to encode');
end
pn_def = pn_crop2;
save([pn_main '\' fn_datalocation],'pn_def');

switch folder_style
    case 1
        fprintf('Merging the subfolders to make "merged" folder\n');
        pn_merged = merge_cat_folders(pn_crop2);
        pn_crop2 = pn_merged;
    case 2
end
%------------------------------------------------------------
fprintf('Type enter only for default setting if "just enter" option is avaiable\n');

sel_start = input('start= 1 or []:f_MakeMovieFilterSeq3x3_cube_GPU_nEncoder 2:f_Make_hyper_CC_var3X3_rev2_f1 3:f_Write_hyper_CC_var3x3x3Ch 4:TiffStackChanger 5:Single_neuron_CC 6:Single_neuron_shift \n');
if isempty(sel_start)
    sel_start = 1;
end
if sel_start <=4
    [void, pn_label] = fileparts(pn_crop2);
    fprintf('pn_label for 3Ch folder is %s\n',pn_label);
    %pn_export_3Ch_temp = uigetdir(pn_crop2,'Select Folder to copy 3Ch folders for deep learning\n');
    
    %tag_3ch = input('Type folername to copy 3Ch folders','s');

    List = dir(fullfile(pn_crop2,'*avi'));
    vidObj = VideoReader([pn_crop2 '\' List(1).name]);
    Size_movie = [vidObj.Height, vidObj.Width, vidObj.BitsPerPixel];
    %fprintf('Movie size is %s\n',num2str(Size_movie));
end

if sel_start <=1

        MovieXYresize = [];%default
        tag_RFMap = [];
        
        yn_flip_T = input('flip ON-OFF sequence in filter? y/n []=n','s');
        if isempty('yn_flip_T')
            yn_flip_T = 'n';
        end
        yn_invert_IM = input('invert image pixel intensity in filter? y/n []=n','s');
        if isempty('yn_invert_IM')
            yn_invert_IM = 'n';
        end
        yn_RFMap = input('Select RFMap y/n  y: load a RFMap file generated from movies n: use RFMap from animals, just enter =n \n','s');
        if yn_RFMap == 'y'
            if ~exist('pn_RFmap_def','var')
                pn_RFmap_def = pn_def;
            end
            try
                [fn_RFMap_SOM, pn_RFmap_SOM] = uigetfile(pn_RFmap_def,'select "DataBase_RFMap_b.mat" ');
            catch
                [fn_RFMap_SOM, pn_RFmap_SOM] = uigetfile('','select "DataBase_RFMap_b.mat" ');
            end
            fn_full_RFMap = [pn_RFmap_SOM, fn_RFMap_SOM];
            pn_RFmap_def = pn_RFmap_SOM;
            save([pn_main '\' fn_datalocation],'pn_def','pn_RFmap_def');

            select_tag = input('tag 1:SIFT 2:RFadj (natural RF rescaled by SIFT) 3: type manual\n');
            switch select_tag
                case 1
                    tag_RFMap = 'SIFT';
                case 2
                    tag_RFMap = 'RFadj';
                case 3
                    tag_RFMap = input('Any tag words\n','s');
            end
            load(fn_full_RFMap);
            
            [RFMap_filled, ListNaN] = fill_nan_RF(DataBase{1}.input.RFMap);% fill NaN RF with neibour's RFs 2026_11_05 to avoid error
            if ~isempty(ListNaN)
                DataBase{1}.input.RFMap = RFMap_filled;
                fn_full_RFMap = [fn_full_RFMap(1:end-4), '_nanfill.mat'];% fill NaN RF with neibour's RFs 2026_11_05 to avoid error, fn_full_RFMap update
                save(fn_full_RFMap,'DataBase');% fill NaN RF with neibour's RFs 2026_11_05 to avoid error fn_full_RFMap update
            end

            yn_TrimRF = input('y:Trim Encoder to fit movie size n:Trim movies to fit Encoder, just enter = n\n','s');%2026_10_31
            if isempty(yn_TrimRF)
                yn_TrimRF = 'n';
            end

            %fprintf('RFMap size is %s\n',num2str(Size_RFMap));
        else
            fn_full_RFMap = [pn_main,'\DataBase_Dipole_Rank.mat'];
            if ~exist(fn_full_RFMap,'file')
                fprintf('DataBase_Dipole_Rank.mat is not present in the code folder, load manually\n');
                [fn_RFMap_nat, pn_RFmap_nat] = uigetfile(pn_RFmap_def,'select "DataBase_RFMap_b.mat" ');
                fn_full_RFMap = [pn_RFmap_nat, fn_RFMap_nat];
            end
        end

        SideEncoder_input = [];
        Range_frame = [];%default, needed to avoid error %2026_11_08
        if yn_RFMap == 'y'
            % 2024.02.02
            fprintf('Movie size [obtained from 1st avi file] is %s\n',num2str(Size_movie));

            if 1==2%2026_10_31 major update, SideEncoderは使わず
            if isfield(DataBase{1}.input,'SideEncoder')
                SideEncoder = DataBase{1}.input.SideEncoder;
            else
                SideEncoder10 = Size_movie(1:2)/10;
                fprintf('To make 10x10 grids SideEncoder is %s\n',num2str(SideEncoder10));
                SideEncoder = input('Type SideEncoder [  ,  ] [] for take above\n');
                if isempty(SideEncoder)
                    SideEncoder = SideEncoder10;
                end
            end
            end

            RF_size = size(DataBase{1}.input.RFMap,1,2);
            fprintf('RFMap size is [%d, %d]\n', RF_size(1), RF_size(2)); 
            if yn_TrimRF == 'y'% Trim Encoder to fit Movie
                %2026_10_31 major update

                d1 = find(rem(Size_movie(1),1:Size_movie(1))==0); %縦pixの約数
                idx1 = d1 <= RF_size(1);% Size_movie(1)以下の約数  
                SideEncoder_trim(1) = max(d1(idx1));  %;%エンコーダのtrim後縦pix
                d2 = find(rem(Size_movie(2),1:Size_movie(2))==0); %縦pixの約数
                idx2 = d2 <= RF_size(2);% Size_movie(1)以下の約数  
                SideEncoder_trim(2) = max(d2(idx2));  %;%エンコーダのtrim後縦pix
    
                fprintf('RFMap size needs to be trimmed to [%d, %d]\n',SideEncoder_trim(1),SideEncoder_trim(2)); 
                if SideEncoder_trim(1) ~= SideEncoder_trim(2)
                    error('Encoder must be square, Remake square encoder and trim movies instead!');
                end
                nSection_best = [Size_movie(1)/SideEncoder_trim(1), Size_movie(2)/SideEncoder_trim(2)];
                fprintf('nSection of movies for resized artRF are size movie/RF = [%d, %d]\n', nSection_best(1), nSection_best(2));

                fprintf('Trim RFs and remake DataBase_RFMap**.mat as DataBase_RFMap**_trim.mat\n');
                void = input('Type enter to proceed\n');
                DataBase{1,1}.input.RFMap = DataBase{1,1}.input.RFMap(1:SideEncoder_trim(1),1:SideEncoder_trim(2),:,:);
                fn_full_RFMap = [fn_full_RFMap(1:end-4), '_trim.mat']; %fn_full_RFMap update
                save(fn_full_RFMap,'DataBase');

                SideEncoder_input = SideEncoder_trim;
                nSection = nSection_best;

            else% Trim movie to fit Encoder
                %2026_10_31 major update SideEncoderは使わず、RFを調べる
                %fprintf('RFMap size is %s\n',num2str(SideEncoder)); 
                %nSection_best = floor(Size_movie(1:2)./SideEncoder);
                nSection_best = floor([Size_movie(1)/RF_size(1), Size_movie(2)/RF_size(2)]);
                %SideEncoder_input = input(['Type RFMap size pix [ ,  ]  []= ' num2str(SideEncoder(1:2)) '\n']);
                SideEncoder_input = input(['Type RFMap size pix [ ,  ]  []= ' num2str(RF_size(1:2)) '\n']);
                if isempty(SideEncoder_input)
                    SideEncoder_input = RF_size;
                end
                nSection = floor(Size_movie(1:2)./SideEncoder_input);
            end

        else
            SideEncoder = 20;
            fprintf('This mode use RFmaps from animals [%d, %d] pix, Range_frame 1:24\n',SideEncoder,SideEncoder);
            
            MovieXYresize = input('Type MovieXYresize [ ,  ] to resize movies (adjust obj size to encoder size), just enter = [200, 200] \n');%2026.11.08 added
            if isempty(MovieXYresize)    
                MovieXYresize = [200, 200];%2026.11.08 added
            end

            nSection = [MovieXYresize(1)/SideEncoder, MovieXYresize(2)/SideEncoder];%2026.11.08
            fprintf('Then, nSection is [%d, %d]\n',nSection(1), nSection(2));
            %nSection = input('Type nSection [ ,  ] to cut movies, as [N x N] Grids of encoders, just enter = [10, 10] grids\n');
            %if isempty(nSection)    
                %nSection = [10, 10];%2023.12.18 added
                %SideEncoder_input = Size_movie(1:2)./nSection;%2026.11.08 deleted
            %end
            %SideEncoder_input = MovieXYresize(1:2)./nSection;%2026.11.08added_Then deleted

            Range_frame = input('Type Range_frame to specify used frames to make encoders, just enter = 1:24\n');%2026.11.08 added
            if isempty(Range_frame)    
                Range_frame = 1:24;%2026.11.08 added
            end

        end

        %id_cc_mode = input('1: sum of CC 2: max of CC 3:3Dcc[]=2\n');
        id_cc_mode = input('1: sum of CC 2: max of CC 3:3Dcc[]=1\n');%2023.12.21
        if isempty(id_cc_mode)
            id_cc_mode = 1;
        end
        switch id_cc_mode
            case 1
                cc_mode = 'sum';
            case 2
                cc_mode = 'max';
            case 3
                cc_mode = '3Dcc';
        end
        %tag_CC = input('Type Tag for CC such as 8x8\n','s');
        tag = [tag_RFMap, '_' cc_mode];
        %pn_CC = f_MakeMovieFilterSeq3x3_cube(pn_crop2,'yn_flip_T',yn_flip_T,'yn_invert_IM',yn_invert_IM,'fn_full_RFMap',fn_full_RFMap,'tag',[tag_RFMap, '_' tag_CC],'cc_mode',cc_mode,'nSection',nSection);
        %pn_CC = f_MakeMovieFilterSeq3x3_cube_GPU_parfor(pn_crop2,'yn_flip_T',yn_flip_T,'yn_invert_IM',yn_invert_IM,'fn_full_RFMap',fn_full_RFMap,'tag',[tag_RFMap, '_' tag_CC],'cc_mode',cc_mode,'nSection',nSection,'SideEncoder',SideEncoder_input);
        %[pn_CC, tag] = f_MakeMovieFilterSeq3x3_cube_GPU_nEncoder(pn_crop2,'yn_flip_T',yn_flip_T,'yn_invert_IM',yn_invert_IM,'fn_full_RFMap',fn_full_RFMap,'tag',tag,'cc_mode',cc_mode,'nSection',nSection,'SideEncoder',SideEncoder_input,'MovieXYresize',MovieXYresize,'Range_frame',Range_frame);
        [pn_CC, tag] = f_MakeMovieFilterSeq3x3_cube_GPU_nEncoder(pn_crop2,'yn_flip_T',yn_flip_T,'yn_invert_IM',yn_invert_IM,'fn_full_RFMap',fn_full_RFMap,'tag',tag,'cc_mode',cc_mode,'nSection',nSection,'MovieXYresize',MovieXYresize,'Range_frame',Range_frame);

end
if sel_start <=2
        fn_full_CC_hyper_stack = f_Make_hyper_CC_var3X3_rev2_f1(pn_CC,'yn_skip_fig','y');
end
if sel_start <=3
    if ~exist('fn_full_CC_hyper_stack','var')
        [fn_temp, pn_temp] = uigetfile(pn_CC,'Select CC_hyper_stack.mat');
        fn_full_CC_hyper_stack = [pn_temp,'\',fn_temp];
    end
    f_Write_hyper_CC_var3x3x3Ch(fn_full_CC_hyper_stack);
end
if sel_start <=4
    pn_export_3Ch = [fileparts(pn_crop2) ,'\DeepLearn', tag];
    mkdir(pn_export_3Ch);

    List3Ch = dir(fullfile(pn_CC,'*_3ChStack'));
    for id_3Ch = 1:numel(List3Ch)
        pn_3ch = [List3Ch(id_3Ch).folder '\' List3Ch(id_3Ch).name];
        fprintf('Reorganizing %s\n',List3Ch(id_3Ch).name);
        pn_output = f_TiffStackChanger(pn_3ch,'pn_label',pn_label,'pn_export_3Ch',pn_export_3Ch);

        list_pn_all = dir(fullfile(pn_output,'SliceOf1Ch1','*'));
        if numel(list_pn_all) == 3 % if only 1 subfolder
            copyfilewithtag_CC(pn_output);
        end
    end
end

if sel_start ==5
    addpath([pn_main,'\Make_Single_imds_from_mat']);
    Make_single_imds_from_CC_hyper_stack;
end

if sel_start ==6
    addpath([pn_main,'\Make_Single_imds_from_mat']);
    Make_single_var_imds_from_CC_hyper_stack;
end

[void, pn_main_last] = fileparts(pn_main);
mkdir([pn_export_3Ch, '\', pn_main_last]);copyfile(pn_main, [pn_export_3Ch, '\', pn_main_last]);