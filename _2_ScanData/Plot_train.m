function Plot_train(varargin)

%Plot_train
    fn_m = mfilename('fullpath');
    addpath(fileparts(fileparts(fn_m)));
    %------------------------------------------------------------------------------
    for ii = 1:nargin
        if strcmp('pn_parent',varargin{ii})
            pn_parent = varargin{ii+1};
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
        if strcmp('yn_save',varargin{ii})
            yn_save = varargin{ii+1};
        end
    end

    % 以下、引数として入力されなかった場合は、インタラクティブ入力
    if ~exist('pn_parent','var')
        pn_parent = uigetdir('C:\Users\gengoro\Desktop\sel2SandBox\movie_all\DeepLearn[5x7_0x1]','Select pn_parent');
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
    if ~exist('stride','var')
        stride = input('stride\n');
    end
    if ~exist('filtersize','var')
        filtersize = input('filtersize\n');
    end
    if ~exist('rand_use','var')
        rand_use = input('rand_use\n');
    end
    %------------------------------------------------------------------------------
    
    List_pick_ratio = 0.1:0.01:1;
    parfor id_pick_ratio = 1:numel(List_pick_ratio)
    
        [ListScore, ListL, Val, Tr, NetStack, ListEndN] = accu_eachdata(pn_parent,'exc',exc,'pick_ratio',List_pick_ratio(id_pick_ratio),'rand_use',rand_use,'stride',stride,'filtersize',filtersize);
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
    for id_rand = 1:size(AccuVal,1)
        plot(N_total*List_pick_ratio,AccuVal(id_rand,:));
        text(N_total,AccuVal(id_rand,end),num2str(id_rand))
    end
    set(gca,'YLim',[0 1]);
    subplot(2,2,3);hold on;
    for id_rand = 1:size(AccuVal,1)
        ymean = movmean(AccuVal(id_rand,:),10);
        plot(N_total*List_pick_ratio,ymean);
        text(N_total,ymean(end),num2str(id_rand))
    end
    set(gca,'YLim',[0 1]);
    subplot(2,2,2);hold on;
    for id_rand = 1:size(AccuTrain,1)
        plot(N_total*List_pick_ratio,AccuTrain(id_rand,:));
        text(N_total,AccuTrain(id_rand,end),num2str(id_rand))
    end
    set(gca,'YLim',[0 1]);
    subplot(2,2,4);hold on;
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
        pn_save = [pn_parent ,'\train_curve'];
        if ~exist(pn_save,'dir')
            mkdir(pn_save);
        end
        save([pn_save '\train_data.mat'],'AccuVal','AccuTrain','ListScore_stack','ListL_stack','Val_stack','Tr_stack','NetStack_stack','ListEndN_stack');
        saveas(h, [pn_save '\' h.Name '.fig'],'fig');
    end
end