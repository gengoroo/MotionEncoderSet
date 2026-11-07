%--------------------------------------------------------------------------------------------------------
% new voting

function f_Write_hyper_CC_var3x3x3Ch(fn_full_CC_hyper_stack)

    nCh = 3;
    tag = '';

    %load(fn_full_CC_hyper_stack,'CC_var_hyper_stack','CC_var_rev_hyper_stack','pn_im_stack'); % 2024.01.31　'pn_im_stack'追加。
    load(fn_full_CC_hyper_stack); % 2024.02.04 offmatch追加のため全部ロード
    pn_movie_dir_list = fileparts(fn_full_CC_hyper_stack);

    if ~exist('ListFnMovie','var')
        %pn_movie_dir_list = uigetdir(pn_CC_hyper_stack,'Select dir contarining CC dir to make list');
        DirList_temp = dir(fullfile(pn_movie_dir_list,'*crop*crop*'));
        ynDir = [DirList_temp.isdir];
        DirList = DirList_temp(ynDir);
        for ii = 1:numel(DirList)
            fprintf('%d: %s\n',ii,DirList(ii).name);
        end
        %List_select = input('Type # to make list\n');
        List_select = 1:numel(DirList);% select all
        MovieList = DirList(List_select);
        counter = 0;
        clear ListFnMovie;
        clear ListCutNumber;
        for id_movie = 1:numel(MovieList)
            clear CC_allcut;
            load([MovieList(id_movie).folder '\' MovieList(id_movie).name,'\CC_allcut.mat'],'CC_allcut');
            for id_minicut =2:size(CC_allcut,4)
                counter = counter + 1;
                ListFnMovie{counter,1} = MovieList(id_movie).name;
                ListCutNumber{counter,1} = id_minicut;
            end
        end
    end
    %------------------------------------------------------------------------------------------
    % 2024.01.31　'*crop*crop*'がない時にファイル名がoverflowになるのを防ぐ
    if exist('pn_im_stack','var')
        for id_movie = 1:numel(pn_im_stack)
            clear CC_allcut;
            data = pn_im_stack{id_movie};
            load([data{1},'\CC_allcut.mat'],'CC_allcut');
            for id_minicut =2:size(CC_allcut,4)
                [~, data] = fileparts(pn_im_stack{id_movie});
                ListFnMovie{id_movie,1} = data{1};
                ListCutNumber{id_movie,1} = id_minicut;
            end
        end
    end
    %------------------------------------------------------------------------------------------
    
    pn_hyper = strcat(pn_movie_dir_list,'\CC_var_hyper_3ChStack', tag);
    mkdir(pn_hyper);
    factor1 = 1/max(max(max(max(CC_var_hyper_stack))));
    for id_cut = 1:size(CC_var_hyper_stack,4)
        try
            fn_cut = [ListFnMovie{id_cut},'cut',num2str(ListCutNumber{id_cut})];
        catch
            %------------------------------------------------------
            % overflow エラーメッセージ
            if ~exist('ListFnMovie','var')
                fprintf('ListFnMovie is missing\n');
            elseif numel(ListFnMovie) < id_cut
                fprintf('id_cuts exceeds ListFnMovie{}\n');
            end
            %-----------------------------------------------------
            fn_cut = ['fn_overflow' num2str(id_cut) 'cut_overflow' num2str(id_cut)];
        end
        nSlice = size(CC_var_hyper_stack,3)/nCh;
        for id_slice = 1:nSlice
            ListCh = nCh*(id_slice-1)+1:nCh*id_slice;
            im_write = factor1*CC_var_hyper_stack(:,:,ListCh,id_cut);
            if id_slice==1
                imwrite(im_write,strcat(pn_hyper, '\', fn_cut, '.tif'));   
            else
                imwrite(im_write,strcat(pn_hyper, '\', fn_cut, '.tif'),'WriteMode','append');   
            end
        end
    
    end
    
    pn_rev_hyper = strcat(pn_movie_dir_list,'\CC_var_rev_hyper_3ChStack', tag);
    mkdir(pn_rev_hyper);
    factor1 = 1/max(max(max(max(CC_var_rev_hyper_stack))));
    for id_cut = 1:size(CC_var_rev_hyper_stack,4)
        try
            fn_cut = strcat(ListFnMovie{id_cut},'cut',num2str(ListCutNumber{id_cut}));
        catch
            fn_cut = strcat('fn_overflow', num2str(id_cut), 'cut_overflow', num2str(id_cut));
        end
        nSlice = size(CC_var_rev_hyper_stack,3)/nCh;
        for id_slice = 1:nSlice
            ListCh = nCh*(id_slice-1)+1:nCh*id_slice;
            im_write = factor1*CC_var_rev_hyper_stack(:,:,ListCh,id_cut);
            if id_slice == 1
                imwrite(im_write,strcat(pn_rev_hyper, '\', fn_cut, '.tif'));   
            else
                imwrite(im_write,strcat(pn_rev_hyper, '\', fn_cut, '.tif'),'WriteMode','append');   
            end
        end
    end

    % 2025.02.04 add for offmatch
    pn = strcat(pn_movie_dir_list,'\CC_var_hyper_offmatch_3ChStack', tag);
    var_hyper_offmatch_3ChStack_writer(pn,CC_var_hyper_offmatch_stack,ListFnMovie,ListCutNumber,id_cut,nCh);

    pn = strcat(pn_movie_dir_list,'\CC_var_rev_hyper_offmatch_3ChStack', tag);
    var_hyper_offmatch_3ChStack_writer(pn,CC_var_rev_hyper_offmatch_stack,ListFnMovie,ListCutNumber,id_cut,nCh);

    % 2025.02.07 add for maxoffcc
    pn = strcat(pn_movie_dir_list,'\CC_var_hyper_maxoffcc_3ChStack', tag);
    var_hyper_offmatch_3ChStack_writer(pn,CC_var_hyper_maxoffcc_stack,ListFnMovie,ListCutNumber,id_cut,nCh);

    pn = strcat(pn_movie_dir_list,'\CC_var_rev_hyper_maxoffcc_3ChStack', tag);
    var_hyper_offmatch_3ChStack_writer(pn,CC_var_rev_hyper_maxoffcc_stack,ListFnMovie,ListCutNumber,id_cut,nCh);
end

% save data and images
%--------------------------------------------------------------------------------------------------------

function var_hyper_offmatch_3ChStack_writer(pn_hyper,CC_var_hyper_stack,ListFnMovie,ListCutNumber,id_cut,nCh)

   %pn_hyper = strcat(pn_movie_dir_list,'\CC_var_hyper_3ChStack', tag);
    mkdir(pn_hyper);
    factor1 = 1/max(max(max(max(CC_var_hyper_stack))));
    for id_cut = 1:size(CC_var_hyper_stack,3)
        try
            fn_cut = [ListFnMovie{id_cut},'cut',num2str(ListCutNumber{id_cut})];
        catch
            %------------------------------------------------------
            % overflow エラーメッセージ
            if ~exist('ListFnMovie','var')
                fprintf('ListFnMovie is missing\n');
            elseif numel(ListFnMovie) < id_cut
                fprintf('id_cuts exceeds ListFnMovie{}\n');
            end
            %-----------------------------------------------------
            fn_cut = ['fn_overflow' num2str(id_cut) 'cut_overflow' num2str(id_cut)];
        end

        im_write = factor1*CC_var_hyper_stack(:,:,id_cut);
        imwrite(im_write,strcat(pn_hyper, '\', fn_cut, '.tif'));   

    end
end