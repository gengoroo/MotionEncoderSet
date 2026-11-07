function [imds, List_imds, pn_combine] = make_imds(tag,varargin)

    yn_shuffle = 'n';
    yn_interlace = 'n';
    n_interlace = 1;
    pn_def = 'E:\PTZ\20230710-4\DeepLearn\3Chx3_3D_test\Var_Hyper\CC_var_hyper_20000_50000_3Chx3\1Chx9Sclices';
    for ii = 1:nargin-2
        if strcmp(varargin{ii},'List_subset')
            List_subset = varargin{ii+1};
            for kk = 1:numel(List_subset)
                fprintf('Class%d: N data is %d\n',kk,numel(List_subset{kk}));
            end
        end
        if strcmp(varargin{ii},'shuffle')
            yn_shuffle = 'y';
            fprintf('image order is shuffled\n')
        end
        if strcmp(varargin{ii},'interlace')
            yn_interlace = 'y';
            n_interlace = varargin{ii+1};
            fprintf('image order is interlaced\n')
        end
        if strcmp(varargin{ii},'pn_def')
            pn_def = varargin{ii+1};
        end
        if strcmp(varargin{ii},'pn_parent')
            pn_parent = varargin{ii+1};
        end
    end

    if exist('pn_parent','var') % select all child files automatic
        FileList = dir(fullfile(pn_parent, '*'));
        counter = 0;
        for ii = numel(FileList):-1:1
            if isempty(strfind(FileList(ii).name,'combine'))&&(numel(FileList(ii).name)>=3)
                counter = counter + 1;
                List_pn{counter} = [FileList(ii).folder '\' FileList(ii).name];
            end
        end
    else % select child files manually
        yn_continue = 'y';
        counter = 0;
        pn_parent = uigetdir(pn_def,'select parent folder to start');
        while(yn_continue == 'y')
            counter = counter + 1;
            pn_select = uigetdir(pn_parent, 'Select folder for categorize, select cancel to stop');
            if pn_select~=0
                List_pn{counter} = pn_select;
            else
                yn_continue = 'n';
            end
        end
    end

    for counter = 1:numel(List_pn)
        List_imds{counter} = imageDatastore(List_pn{counter},"FileExtensions",[".jpg",".tif"],"IncludeSubfolders", true,"LabelSource","foldernames");
        
        if yn_shuffle == 'y'
            List_imds{counter} = shuffle_imds(List_imds{counter});
        end
        if yn_interlace == 'y'
            List_imds{counter} = interlace_imds(List_imds{counter},n_interlace);
        end

        deli = strfind(List_pn{counter},'\');
        pn_last = List_pn{counter}(deli(end)+1:end);
        List_label{counter} = pn_last;
        for id_data = 1:numel(List_imds{counter}.Files)
            List_imds{counter}.Labels(id_data) = pn_last;
        end
    end
    
    %pn_make_combine = uigetdir(pn_parent,'where do you make a combined folder');
    pn_make_combine = pn_parent;

    pn_combine = [pn_make_combine '\combine_' tag];
    mkdir(pn_combine);
    nClass = numel(List_imds);
    for id_class = 1:nClass
        pn_combi{id_class} = [pn_combine ,'\', List_label{id_class}];
        mkdir(pn_combi{id_class});
        delete([pn_combi{id_class} '\*.tif']);

        if exist('List_subset','var')
            ListImport = List_subset{id_class};
        else
            ListImport = 1:numel(List_imds{id_class}.Files);
        end

        for ii = 1:numel(ListImport)
            id_file = ListImport(ii);
            fn = List_imds{id_class}.Files{id_file};
            copyfile (fn, pn_combi{id_class});
        end
    end
    
    imds = imageDatastore(pn_combine,"FileExtensions",[".jpg",".tif"],"IncludeSubfolders", true,"LabelSource","foldernames");

end
function imds_shuffle = shuffle_imds(imds)
    nFiles = numel(imds.Files);
    rand('state',0);
    ListRand = randperm(nFiles);
    Folders = imds.Folders;
    Labels = imds.Labels;
    imds_shuffle = imds;
    imds_shuffle.Files = imds.Files(ListRand);
    imds_shuffle.Labels = Labels(ListRand);
    %imds_shuffle.Folders = Folders;
end
function imds_interlace = interlace_imds(imds,n_interlace)
    nFiles = numel(imds.Files);
    counter = 0;
    for ii = 1:n_interlace
        List_seq{ii} = ii:n_interlace:nFiles;
        List(ii,1) = counter + 1;
        List(ii,2) = counter + numel(List_seq{ii});
        counter = List(ii,2);
        ListReorder(List_seq{ii}) = List(ii,1):List(ii,2);
    end
    Folders = imds.Folders;
    Labels = imds.Labels;
    imds_interlace = imds;
    imds_interlace.Files = imds.Files(ListReorder);
    imds_interlace.Labels = Labels(ListReorder);
    %imds_shuffle.Folders = Folders;
end