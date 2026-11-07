% Vote_simple
function vote_simple_plot(varargin)

    fprintf('\nintegrates train_data.mat under train_curve folders\n');
    for ii = 1:nargin
        if strcmp('pn_top',varargin{ii})
            pn_top = varargin{ii+1};
        end
        if strcmp('id_rand',varargin{ii})
            id_rand = varargin{ii+1};
        end
    end

    if ~exist('pn_top','var')
    %------------------------------------------------------------
        mfn = mfilename('fullpath');
        [pn_main, fn_main] = fileparts(mfn);
        pn_def = '';
        fn_datalocation = [fn_main,'_datalocation.mat'];
        if exist([pn_main '\' fn_datalocation],'file')
            load([pn_main '\' fn_datalocation]);
        end
        if pn_def == 0
            pn_def = '';
        end
        pn_def = uigetdir(pn_def,'select parent of SliceOfCh*');
        save([pn_main '\' fn_datalocation],'pn_def');
         pn_top = pn_def;
        %------------------------------------------------------------
    end

    % Main
    % import data
   if ~exist('id_rand','var')
    id_rand = input('Type id_rand for Val vs Train\n');
   end
    List = dir(fullfile(pn_top,'SliceOf1Ch*','train_curve*','train_data.mat'));
    List_test = dir(fullfile(pn_top,'SliceOf1Ch*'));
    
    if numel(List_test) == numel(List)
        for id_SliceOf = 1:numel(List)
            ListFn{id_SliceOf} = [List(id_SliceOf).folder ,'\' List(id_SliceOf).name];
        end
        
        % integrate data
        h_vote = vote_simple_rand(ListFn,id_rand);
        saveas(h_vote,[pn_top, '\' h_vote.Name 'rand' num2str(id_rand) '.fig'],'fig');
    else
        fprintf('Error, multiple train_data.m are in the same SliceOf1*, check folders\n')
    end
    fprintf('\n');
end
%------------------------------------------------------------

function h_vote = vote_simple_rand(ListFn,id_rand)

    for id_fn = 1:numel(ListFn)
        fprintf('.');
        load(ListFn{id_fn},'Val_stack','Tr_stack','AccuTrain');
        [Val,Tr] = ValTr_stack2ValTr(Val_stack,Tr_stack,AccuTrain,id_rand);%Plot_trainフォーマットデータからDeep_searchデータへ変換

        nPool = size(Val.P,3);
        for id_pool = 1:nPool
            ValStack(id_pool).P(:,:,id_fn) = Val.P{1,1,id_pool};
            TrStack(id_pool).P(:,:,id_fn) = Tr.P{1,1,id_pool};
            TrStack(id_pool).Accuracy_total(id_fn) = Tr.Accuracy_total(1,1,id_pool);
            nSampleTrain(id_pool) = size(Val.P{1,1,id_pool},1);
        end
    end
    imds_max = Tr.imds{1,1,end};
    
    
    clear ValMax;
    clear TrMax;
    clear ValAccuracy;
    clear TrAccuracy;
    ListLabels = unique(imds_max.Labels);
    for id_pool = 1:nPool
        ValMax(id_pool).P = max(ValStack(id_pool).P,[],3);%Pの最大値を採る
        %ValMax(id_pool).P = (ValStack(id_pool).P(:,:,9));%Pの最大値を採る
        ValSum(id_pool).P = sum(ValStack(id_pool).P,3);%Pの最大値を採る

        TrMax(id_pool).P = max(TrStack(id_pool).P,[],3);%Pの最大値を採る
        %TrMax(id_pool).P = (TrStack(id_pool).P(:,:,9));%Pの最大値を採る
        TrSum(id_pool).P = sum(TrStack(id_pool).P,3);%Pの最大値を採る
    
        nData_val = size(ValMax(id_pool).P,1);
        for id_data = 1:nData_val

            ListA = ValMax(id_pool).P(id_data,:);
            ListB = ValSum(id_pool).P(id_data,:);
            ListC = TrStack(id_pool).Accuracy_total;
            ListD = TrStack(end).Accuracy_total;
            finalist = find_finalist(ListA, ListB, ListC, ListD);

            ValMax(id_pool).Classify(id_data,1) = ListLabels(finalist);
        end

        nData_tr = size(TrMax(id_pool).P,1);
        for id_data = 1:nData_tr

            ListA = TrMax(id_pool).P(id_data,:);
            ListB = TrSum(id_pool).P(id_data,:);
            ListC = TrStack(id_pool).Accuracy_total;
            ListD = TrStack(end).Accuracy_total;
            finalist = find_finalist(ListA, ListB, ListC, ListD);

            TrMax(id_pool).Classify(id_data,1) = ListLabels(finalist);
        end
    
        imdsValwork = Val.imds{1,1,id_pool};% rand state 0なので、どのChでもimdsは同じ。
        ValAccuracy(id_pool) = 100*sum(ValMax(id_pool).Classify == imdsValwork.Labels)/numel(imdsValwork.Labels);
        imdsTrwork = Tr.imds{1,1,id_pool};% rand state 0なので、どのChでもimdsは同じ。
        TrAccuracy(id_pool) = 100*sum(TrMax(id_pool).Classify == imdsTrwork.Labels)/numel(imdsTrwork.Labels);
    end
    
    h_vote = figure('Name','Accuracy_vote','Color','w'); hold on;
    plot(nSampleTrain,ValAccuracy);
    plot(nSampleTrain,TrAccuracy);
    a=gca;a.YLim = [0 100];
    legend({'Validation','Train'});
    PlotSmoother;
    
end

function [Val,Tr] = ValTr_stack2ValTr(Val_stack,Tr_stack,AccuTrain,id_rand)
    nPool = numel(Val_stack);
    for id_pool = 1:nPool
        Val.P{1,1,id_pool} = Val_stack{id_pool}.P{id_rand};
        Tr.P{1,1,id_pool} = Tr_stack{id_pool}.P{id_rand};
        Val.imds{1,1,id_pool} = Val_stack{id_pool}.imds{id_rand};
        Tr.imds{1,1,id_pool} = Tr_stack{id_pool}.imds{id_rand};
    end
    Tr.Accuracy_total(1,1,:) = AccuTrain(id_rand,:);
end