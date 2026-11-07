function [ListScore, ListL, Val, Tr, NetStack, ListEndN] = accu_eachdata(pn_parent,varargin)

    addpath(fileparts(fileparts(mfilename('fullpath'))));

    [imds, Labels, NameList, FolderList, LabelList] = make_imds_simple(pn_parent);

    yn_plot = 'n';
    yn_figure = 'y';
    use_ratio = 0.7;

    for ii =1:nargin-1
        if strcmp(varargin{ii},'stride')
            stride = varargin{ii+1};
        end
        if strcmp(varargin{ii},'filtersize')
            filtersize = varargin{ii+1};
        end
        if strcmp(varargin{ii},'nFilter')
            nFilter = varargin{ii+1};
        end
        if strcmp(varargin{ii},'use_ratio')
            use_ratio = varargin{ii+1};
        end
        if strcmp(varargin{ii},'learn_rate')
            learn_rate = varargin{ii+1};
        end
        if strcmp(varargin{ii},'exc')
            exc = varargin{ii+1};
        end
        if strcmp(varargin{ii},'pick_ratio')
            pick_ratio = varargin{ii+1};
        end
        if strcmp(varargin{ii},'yn_figure')
            yn_figure = varargin{ii+1};
        end
        if strcmp(varargin{ii},'List_rand')
            List_rand = varargin{ii+1};
        end
        if strcmp(varargin{ii},'List_rand')
            List_rand = varargin{ii+1};
        end
        if strcmp(varargin{ii},'List_rand')
            List_rand = varargin{ii+1};
        end
        if strcmp(varargin{ii},'List_rand')
            List_rand = varargin{ii+1};
        end

    end
    N_rand = numel(List_rand);


    if exist('exc','var')
        if ~isempty(exc)
            for ii = 1:numel(exc)
                imds.Files(exc{ii}) = [];
            end
        end
    end
    if exist('pick_ratio','var')
        if pick_ratio~=1
            rand('state',10);
            imds = splitEachLabel(imds,pick_ratio,'randomized');
        end
    end

    ListLabels = unique(imds.Labels);
    for ii = 1:numel(ListLabels)
        list = find(imds.Labels == ListLabels(ii));
        ListEndN(ii) = list(end);
    end



    for ii = 1:numel(List_rand)

        id_rand = List_rand(ii);
                
        rand ('state', id_rand);%Ch間で同じでないといけない
        [imdsTrainwork,imdsValwork] = splitEachLabel(imds,use_ratio,'randomized');
        [layers, options] = config_Layer(imdsTrainwork, learn_rate, filtersize,nFilter,yn_plot,'stride',stride);
        
        [net, tr] = trainNetwork(imdsTrainwork,layers,options);
        NetStack{id_rand} = net;
    
        [Tr.Res{id_rand},Tr.P{id_rand}] = classify(net, imdsTrainwork);
        Tr.imds{id_rand} = imdsTrainwork;
        [ListScore.train.Idx{id_rand}, ListScore.train.P{id_rand}] = score_eachdata(imdsTrainwork,Tr.P{id_rand},imds);
    
        [Val.Res{id_rand},Val.P{id_rand}]  = classify(net, imdsValwork);
        Val.imds{id_rand} = imdsValwork;
        [ListScore.val.Idx{id_rand}, ListScore.val.P{id_rand}] = score_eachdata(imdsValwork,Val.P{id_rand},imds);
    
        [Tr.Accuracy_total(id_rand), Tr.N_total(id_rand), Tr.Accuracy_each(:,id_rand), Tr.N_each(:,id_rand)] = calc_score(imdsTrainwork,Tr.Res{id_rand});
        [Val.Accuracy_total(id_rand), Val.N_total(id_rand), Val.Accuracy_each(:,id_rand), Val.N_each(:,id_rand)] = calc_score(imdsValwork,Val.Res{id_rand});
    
        IM_score_train(ListScore.train.Idx{id_rand},id_rand) = ListScore.train.P{id_rand};
        IM_score_val(ListScore.val.Idx{id_rand},id_rand) = ListScore.val.P{id_rand};

    end

    for id_idx = 1:size(IM_score_train,1)
        data = IM_score_train(id_idx,1:N_rand);
        IM_score_train_ave(id_idx,1) = mean(data(data>0));  
    end
    IM_score_train(:,N_rand+2) = IM_score_train_ave;
    ListL.train = find(IM_score_train_ave < 0.5);

    for id_idx = 1:size(IM_score_val,1)
        data = IM_score_val(id_idx,1:N_rand);
        IM_score_val_ave(id_idx,1) = mean(data(data>0));
    end
    IM_score_val(:,N_rand+2) = IM_score_val_ave;
    listLv = find(IM_score_val_ave < 0.5);
    for id_cat = 1:numel(ListLabels)
        if id_cat == 1
            ListL.val{id_cat} = intersect(1:ListEndN(id_cat),listLv);
        else
            ListL.val{id_cat} = intersect(ListEndN(id_cat-1):ListEndN(id_cat),listLv);
        end
    end

    IM_score_train(ListEndN,N_rand+1) = 1;
    IM_score_val(ListEndN,N_rand+1) = 1;

    if yn_figure == 'y'
        figure('Name','P_chart');
        subplot(1,2,1);hold on;title('Val');
        imagesc(IM_score_val);
        clim([0 1]);colorbar;
        subplot(1,2,2);hold on;title('Train');
        imagesc(IM_score_train);
        clim([0 1]);colorbar;
    
        figure('Name','P_plot');hold on;
        subplot(1,2,1);hold on;title('Val');
        plot(IM_score_val(:,N_rand+2),'.')
        plot(ListEndN,[0 0 0 0],'r*');
    
        subplot(1,2,2);hold on;title('Train');
        plot(IM_score_train(:,N_rand+2),'.')
        plot(ListEndN,[0 0 0 0],'r*');
    
        figure('Name','accu');
        subplot(1,5,1);hold on;title('total');
        plot(Val.Accuracy_total,'.');
        plot(Tr.Accuracy_total,'.');a=gca;a.YLim(1) = 0;
    
        subplot(1,5,2);hold on;title(string(ListLabels(1)));
        plot(Val.Accuracy_each(1,:),'.');
        plot(Tr.Accuracy_each(1,:),'.');a=gca;a.YLim(1) = 0;
    
        subplot(1,5,3);hold on;title(string(ListLabels(2)));
        plot(Val.Accuracy_each(2,:),'.');
        plot(Tr.Accuracy_each(2,:),'.');a=gca;a.YLim(1) = 0;
    
        subplot(1,5,4);hold on;title(string(ListLabels(3)));
        plot(Val.Accuracy_each(3,:),'.');
        plot(Tr.Accuracy_each(3,:),'.');a=gca;a.YLim(1) = 0;
    
        subplot(1,5,5);hold on;title(string(ListLabels(4)));
        plot(Val.Accuracy_each(4,:),'.');
        plot(Tr.Accuracy_each(4,:),'.');a=gca;a.YLim(1) = 0;
    end

end
function [ListIdx, ListScore] = score_eachdata(imds_sub,P,imds_master)

    ListIdx = find_imds_overlap(imds_master,imds_sub);
    AnserID = grp2idx(imds_sub.Labels);

    for ii = 1:numel(AnserID)
        ListScore(ii,1) = P(ii,AnserID(ii));
    end
    
end

