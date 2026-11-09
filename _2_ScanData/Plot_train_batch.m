function Plot_train_batch()
    %------------------------------------------------------------
    mfn = mfilename('fullpath');
    [pn_main, fn_main] = fileparts(mfn);
    
    addpath([pn_main,'\OffMatchAnalysis']);%2026_10_30; for 'make_imds_simple' is not accessible error 
    %2026_10_30; for 'config_Layer' and 'calc_score' included 

    pn_def = '';
    fn_datalocation = [fn_main,'_datalocation.mat'];
    if exist([pn_main '\' fn_datalocation],'file')
        load([pn_main '\' fn_datalocation]);
    end
    try
        pn_def = uigetdir(pn_def,'CC_var_hyper_3ChStack or CC_var_rev_hyper_3ChStack folder');
    catch
        pn_def = uigetdir('','CC_var_hyper_3ChStack or CC_var_rev_hyper_3ChStack folder');
    end
    save([pn_main '\' fn_datalocation],'pn_def');
    %------------------------------------------------------------
    fprintf('Select all "SliceOf1Ch*" folders\n');

    pn_top = pn_def;
    ListPn = uigetdir2(pn_top, 'muliselect');

    fprintf('Type enter only for default setting if "just enter" option is avaiable\n');
    filtersize  = input('filtersize, [must be =sq(nEncoders) for hyper, size(Image,1)/sq(nEncoders) for rev-hyper (3),5,(7)...]\n');
    stride  = input('stride, [must be = filtersize], just enter = same as filtersize\n');
    if isempty(stride)
        stride = filtersize;
    end
    fn_exc_fullpath = 0;
    rand_use = 0;% randstate for selecting stepwise increment data
    List_rand = input('Type List_rand init# to divide train vs validation, just enter = 10\n');% randstate for dividing train vs test, mutivalues OK
    if isempty(List_rand)
        List_rand = 10;
    end
    yn_save = 'y';

    delete(gcp('nocreate'));%2026_10_29 二重に作るとエラー
    parpool(2*gpuDeviceCount("available"));%2026_10_29
    WaitMessage = parfor_wait(numel(ListPn), 'Waitbar', true);
    parfor id_pn = 1:numel(ListPn)
        Plot_train('pn',ListPn{id_pn},'fn_exc_fullpath',fn_exc_fullpath,'stride',stride,'filtersize',filtersize,'rand_use',rand_use,'List_rand',List_rand,'yn_save',yn_save);
        WaitMessage.Send;
    end
    WaitMessage.Destroy

    % integrate SliceOfCH*
    for ii = 1:numel(List_rand)
        id_rand = List_rand(ii);
        vote_simple_plot('pn_top',pn_top,'id_rand',id_rand);
    end

    % save codes 
    [void, pn_code_last] = fileparts(pn_main);
    zip([pn_top, '\' pn_code_last '.zip'],pn_main);
end


function Plot_train(varargin)
%Plot_train
    fn_m = mfilename('fullpath');
    addpath(fileparts(fileparts(fn_m)));

    %------------------------------------------------------------------------------
    for ii = 1:nargin
        if strcmp('pn',varargin{ii})
            pn = varargin{ii+1};
        end
        if strcmp('fn_exc_fullpath',varargin{ii})
            fn_exc_fullpath = varargin{ii+1};
        end
        if strcmp('stride',varargin{ii})
            stride = varargin{ii+1};
        end
        if strcmp('filtersize',varargin{ii})
            filtersize = varargin{ii+1};
        end
        if strcmp('rand_use',varargin{ii})
            rand_use = varargin{ii+1};
        end
        if strcmp('List_rand',varargin{ii})
            List_rand = varargin{ii+1};
        end
        if strcmp('yn_save',varargin{ii})
            yn_save = varargin{ii+1};
        end
    end

    % 以下、引数として入力されなかった場合は、インタラクティブ入力
    if ~exist('pn','var')
        pn = uigetdir('C:\Users\gengoro\Desktop\sel2SandBox\movie_all\DeepLearn[5x7_0x1]','Select parent pn of classes');
    end
    exc = [];%default
    if exist('fn_exc_fullpath','var')
        if fn_exc_fullpath~= 0%ゼロならexc = [];
            pn_def_exc = 'C:\Users\gengoro\Desktop\sel2SandBox\movie_all\DeepLearn\CC_var_hyper_3ChStack\Scan\SliceOf1Ch1';
            [fn_exc, pn_exc] = uigetfile(pn_def_exc,'select exc file, cancel to skip');
            if fn_exc ~= 0%ゼロでなければロード
                load([pn_exc '\' fn_exc]);
            end
        end
    end    

    nFilter = 512;
    learn_rate = 0.0005;
    if ~exist('stride','var')
        stride = input('stride\n');
    end
    if ~exist('filtersize','var')
        filtersize = input('filtersize\n');
    end
    if ~exist('rand_use','var')
        rand_use = input('rand_use []=0\n');
        if isempty(rand_use)
            rand_use = 0;
        end
    end
    %------------------------------------------------------------------------------
    
    List_pick_ratio = 0.1:0.01:1;
    parfor id_pick_ratio = 1:numel(List_pick_ratio)
        [ListScore, ListL, Val, Tr, NetStack, ListEndN] = ...
            accu_eachdata(pn,'exc',exc,'pick_ratio',List_pick_ratio(id_pick_ratio),'rand_use',rand_use,'stride',stride,'filtersize',filtersize,...
            'List_rand',List_rand,'learn_rate',learn_rate,'nFilter',nFilter);
        
        AccuVal(:,id_pick_ratio) = Val.Accuracy_total';
        AccuTrain(:,id_pick_ratio) = Tr.Accuracy_total';
    
        ListEndN_stack(id_pick_ratio,:) = ListEndN;
        NetStack_stack{id_pick_ratio} = NetStack;
        ListScore_stack{id_pick_ratio} = ListScore;
        ListL_stack{id_pick_ratio} = ListL;
        Val_stack{id_pick_ratio} = Val;
        Tr_stack{id_pick_ratio} = Tr;
        fprintf('.');
    end
    N_total =  numel(Tr_stack{end}.imds{end}.Labels);
    
    h = figure('Name','Train curve');
    subplot(2,2,1);hold on;
    title('Validation raw');
    for id_rand = 1:size(AccuVal,1)
        plot(N_total*List_pick_ratio,AccuVal(id_rand,:));
        text(N_total,AccuVal(id_rand,end),num2str(id_rand))
    end
    set(gca,'YLim',[0 1]);
    subplot(2,2,3);hold on;
    title('Validation slide mean [10]');
    for id_rand = 1:size(AccuVal,1)
        ymean = movmean(AccuVal(id_rand,:),10);
        plot(N_total*List_pick_ratio,ymean);
        text(N_total,ymean(end),num2str(id_rand))
    end
    set(gca,'YLim',[0 1]);
    subplot(2,2,2);hold on;
    title('Training raw');
    for id_rand = 1:size(AccuTrain,1)
        plot(N_total*List_pick_ratio,AccuTrain(id_rand,:));
        text(N_total,AccuTrain(id_rand,end),num2str(id_rand))
    end
    set(gca,'YLim',[0 1]);
    subplot(2,2,4);hold on;
    title('Training slide mean [10]');
    for id_rand = 1:size(AccuTrain,1)
        ymean = movmean(AccuTrain(id_rand,:),10);
        plot(N_total*List_pick_ratio,ymean);
        text(N_total,ymean(end),num2str(id_rand))
    end
    set(gca,'YLim',[0 1]);
    
    if ~exist('yn_save','var')
        yn_save = input('n_save y\n','s');
    end
    if yn_save == 'y'
        %pn_save_parent = uigetdir(pn_parent,'select folder to save');
        pn_save = [pn ,'\train_curve_rand_incri_' num2str(rand_use)];
        if ~exist(pn_save,'dir')
            mkdir(pn_save);
        end
        save([pn_save '\train_data.mat'],'AccuVal','AccuTrain','ListScore_stack','ListL_stack','Val_stack','Tr_stack','NetStack_stack','ListEndN_stack',...
            'List_rand','rand_use','List_pick_ratio','nFilter','learn_rate');
        saveas(h, [pn_save '\' h.Name '.fig'],'fig');
    end
end