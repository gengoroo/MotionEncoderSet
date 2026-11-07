%--------------------------------------------------------------------------------------------------------
% new voting
clear;
pn_test = 'E:\PTZ\20230710-4\crop_PTZ00uM\crop__int20000_35000_d20000_35000_int0_d_norm0.0011694\select\３Chx3_cop_test';

nCh = 3;
tag = '';
if ~exist('CC_var_hyper_stack','var')||~exist('CC_var_rev_hyper_stack','var')
    [fn_CC_hyper_stack, pn_CC_hyper_stack] = uigetfile([pn_test, '\*CC_hyper_stack.mat'],'load CC_hyper_stack.mat');
    load([pn_CC_hyper_stack,fn_CC_hyper_stack]);
end
if ~exist('ListFnMovie','var')
    pn_movie_dir_list = uigetdir(pn_CC_hyper_stack,'Select dir contarining CC dir to make list');
    DirList_temp = dir(fullfile(pn_movie_dir_list,'*'));
    ynDir = [DirList_temp.isdir];
    DirList = DirList_temp(ynDir);
    for ii = 1:numel(DirList)
        fprintf('%d: %s\n',ii,DirList(ii).name);
    end
    List_select = input('Type # to make list\n');
    MovieList = DirList(List_select);
    counter = 0;
    clear ListFnMovie;
    clear ListCutNumber;
    for id_movie = 1:numel(MovieList)
        clear CC_allcut;
        load([MovieList(id_movie).folder '\' MovieList(id_movie).name,'\CC_allcut.mat']);
        for id_minicut =2:size(CC_allcut,4)
            counter = counter + 1;
            ListFnMovie{counter,1} = MovieList(id_movie).name;
            ListCutNumber{counter,1} = id_minicut;
        end
    end
end

pn_hyper = [pn_CC_hyper_stack,'\CC_var_hyper_3ChStack' tag];
mkdir(pn_hyper);
factor1 = 1/max(max(max(max(CC_var_hyper_stack))));
for id_cut = 1:size(CC_var_hyper_stack,4)
    fn_cut = [ListFnMovie{id_cut},'cut',num2str(ListCutNumber{id_cut})];
    nSlice = size(CC_var_hyper_stack,3)/nCh;
    for id_slice = 1:nSlice
        ListCh = nCh*(id_slice-1)+1:nCh*id_slice;
        im_write = factor1*CC_var_hyper_stack(:,:,ListCh,id_cut);
        if id_slice==1
            imwrite(im_write,[pn_hyper '\' fn_cut '.tif']);   
        else
            imwrite(im_write,[pn_hyper '\' fn_cut '.tif'],'WriteMode','append');   
        end
    end

end

pn_rev_hyper = [pn_CC_hyper_stack,'\CC_var_rev_hyper_3ChStack' tag];
mkdir(pn_rev_hyper);
factor1 = 1/max(max(max(max(CC_var_rev_hyper_stack))));
for id_cut = 1:size(CC_var_rev_hyper_stack,4)
    fn_cut = [ListFnMovie{id_cut},'cut',num2str(ListCutNumber{id_cut})];
    nSlice = size(CC_var_rev_hyper_stack,3)/nCh;
    for id_slice = 1:nSlice
        ListCh = nCh*(id_slice-1)+1:nCh*id_slice;
        im_write = factor1*CC_var_rev_hyper_stack(:,:,ListCh,id_cut);
        if id_slice == 1
            imwrite(im_write,[pn_rev_hyper '\' fn_cut '.tif']);   
        else
            imwrite(im_write,[pn_rev_hyper '\' fn_cut '.tif'],'WriteMode','append');   
        end
    end
end

% save data and images
%--------------------------------------------------------------------------------------------------------