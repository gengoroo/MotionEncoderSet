%reshape[20 20]しない2026_11_03
function [MOV_som, rep_vec, netSOM, ListFig, SideEncoder]= som_movie_filter(MOV_adjust,varargin)

    SideEncoder = [size(MOV_adjust,1), size(MOV_adjust,2)];%2024.02.23

    ListFig1 = findall(groot, 'type', 'figure');

    yn_plot = 'n';
    yn_normW = 'y';
    for ii = 1:nargin-1
        if strcmp(varargin{ii},'yn_plot')
            yn_plot = varargin{ii+1};
        end
        if strcmp(varargin{ii},'yn_normW')
            yn_normW = varargin{ii+1};
        end
    end

    if yn_plot == 'y'
        nMovie = size(MOV_adjust,4);
        for id_pair = 1:nMovie
            figure('Name',['SOMInputMov', num2str(id_pair)])

            MIN = min(min(min(min(MOV_adjust))));
            MAX = max(max(max(max(MOV_adjust))));
            range = max(abs(MIN),abs(MAX));

            for id_panel = 1:size(MOV_adjust,3)
                subplot(1,size(MOV_adjust,3),id_panel);    hold on;
                imagesc(MOV_adjust(:,:,id_panel,id_pair));
                clim([-range, +range]);
                a=gca;a.XLim(2) = size(MOV_adjust,2);a.YLim(2) = size(MOV_adjust,1);
            end
        end
        h=gcf;fig_last = h.Number;fig_first = fig_last - nMovie+1;
        fig_organizer(fig_first:fig_last);
        ListFig = fig_first:fig_last;
    end

    for id_pair = 1:size(MOV_adjust,4)
        %MOV_resize(:,:,:,id_pair) = imresize3(MOV_adjust(:,:,:,id_pair),[20,20,size(MOV_adjust,3)]);%
        MOV_resize(:,:,:,id_pair) = MOV_adjust(:,:,:,id_pair);%reshape[20 20]しない2026_11_03
        DataSOM(id_pair,:) = reshape(MOV_resize(:,:,:,id_pair),1,[]);
    end
    netSOM = selforgmap([8 8]);
    netSOM = train(netSOM, DataSOM);
    
    rep_vec = netSOM.IW{1};

    if yn_normW == 'y'
    % normalize 2026_11_05
        s = sum(abs(rep_vec),2);
        s(s==0) = 1;
        rep_vec = rep_vec ./ s;
    % normalize 2026_11_05
    % Normalization decreased accuracy 2026_11_05
    end

    DataSOMout = rep_vec*DataSOM;

    for id_out = 1:size(DataSOMout,1)
        MOV_som(:,:,:,id_out) = reshape(DataSOMout(id_out,:),[size(MOV_resize,1),size(MOV_resize,2),size(MOV_resize,3)]);
    end
    
    if yn_plot == 'y'
        ListPlot_all = 1:size(MOV_som,4);
        n_step = 5;
        ListPlot_show = 1:n_step:ListPlot_all(end);

        
        for ii = 1:numel(ListPlot_show)
            id_pair = ListPlot_show(ii);
            figure('Name',['SOMOutputMov' num2str(id_pair)])

            MIN = min(min(min(MOV_som(:,:,:,id_pair))));
            MAX = max(max(max(MOV_som(:,:,:,id_pair))));
            range = max(abs(MIN),abs(MAX));

            for id_panel = 1:size(MOV_som,3)
                subplot(1,size(MOV_som,3),id_panel);    hold on;
                imagesc(MOV_som(:,:,id_panel,id_pair));
                clim([-range,+range]);
                a=gca;a.XLim(2) = size(MOV_som,2);a.YLim(2) = size(MOV_som,1);
            end
            colorbar;
        end

        h=gcf;fig_last = h.Number;fig_first = fig_last - numel(ListPlot_show) + 1;
        fig_organizer(fig_first:fig_last);
    end

    ListFig2 = findall(groot, 'type', 'figure');
    ListFig = setdiff(ListFig2, ListFig1);
end