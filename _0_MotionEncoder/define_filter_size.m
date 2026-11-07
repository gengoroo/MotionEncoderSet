%scan_RF_size
function [List_sel, max_side , max_frame, Range, List_side, List_dur]= define_filter_size(MOV_onoff)

    List = 1:numel(MOV_onoff);
    List_temp = List;
    yn_stop = 'n';
    Range = [];
    while(yn_stop ~= 'y')
        [idx, max_side, max_frame, Range] = f_define_filter_size(MOV_onoff(List_temp),'Range',Range);
        List_temp = List_temp(idx);
        yn_stop = input('Stop selection y/n, just enter = y?','s');
        if isempty(yn_stop)
            yn_stop = 'y';
        end
        if yn_stop == 'n'
            h=gcf;close(h);
        end
    end
    List_sel = List_temp;
    for id_mov=1:numel(List_sel)
        mov = MOV_onoff{List_sel(id_mov)};
        List_side(id_mov) = size(mov,1);
        List_dur(id_mov) = size(mov,3);
    end

end
function [Idx_sel, max_side, max_frame, Range]= f_define_filter_size(MOV_onoff,varargin)

    for ii = 1:nargin-1
        if strcmp('Range',varargin{ii})
            Range = varargin{ii+1};% import previous setting
        end
    end

    for id_pair = 1:numel(MOV_onoff)
        mov = MOV_onoff{id_pair};
        List_side(id_pair) = size(mov,1);
        List_dur(id_pair) = size(mov,3);

        im_1st = mov(:,:,1);
        im_end = mov(:,:,end);
        [maxVal, idx1] = max(im_1st(:));
        [y1, x1] = ind2sub(size(im_1st), idx1);
        [maxVal, idx2] = max(im_end(:));
        [y2, x2] = ind2sub(size(im_end), idx2);

        List_dist_poles(id_pair) = sqrt((x1-x2)^2 + (y1-y2)^2);
    end
    side_mode = mode(List_side);
    dur_mode = mode(List_dur);
    pole_mode = mode(List_dist_poles(List_dist_poles~=0));

    % Histogram
    figure('Name','SideSize,nFrames,PoleDist');
    movegui(gcf,'northwest')
    
    subplot(3,2,1);hold on;
    histogram(List_side);
    plot(side_mode,0,'*');
    text(side_mode,0,['mode=' num2str(side_mode)]);
    xlabel('Pixels');
    ylabel('Count');
    title('SideSize');
    
    % CDF
    subplot(3,2,2);hold on;
    cdfplot(List_side);
    plot(side_mode,0,'*');
    text(side_mode,0,['mode=' num2str(side_mode)]);
    xlabel('Pixels');
    ylabel('Cumulative N');
    yt = yticks;                    % 現在のtick値取得
    yticklabels(string(round(yt*numel(List_side))));
    title('CDF');
    grid on;

    % Histogram
    %figure('Name','N Frames');
    subplot(3,2,3);hold on;
    histogram(List_dur);
    plot(dur_mode,0,'*');
    text(dur_mode,0,['mode=' num2str(dur_mode)]);
    xlabel('Frames');
    ylabel('Count');
    title('nFrames');
    
    % CDF
    subplot(3,2,4);hold on;
    cdfplot(List_dur);
    plot(dur_mode,0,'*');
    text(dur_mode,0,['mode=' num2str(dur_mode)]);
    xlabel('Frames');
    ylabel('Cumulative Probability');
    yt = yticks;                    % 現在のtick値取得
    yticklabels(string(round(yt*numel(List_side))));
    title('CDF');
    grid on;

     % Histogram
    %('Name','Pole Distance');
    subplot(3,2,5);hold on;
    histogram(List_dist_poles);
    plot(pole_mode,0,'*');
    text(pole_mode,0,['mode=' num2str(pole_mode)]);
    xlabel('Pixels');
    ylabel('Count');
    title('PoleDist');
    
    % CDF
    subplot(3,2,6);hold on;
    cdfplot(List_dist_poles);
    plot(pole_mode,0,'*');
    text(pole_mode,0,['mode=' num2str(pole_mode)]);
    xlabel('Pixels');
    ylabel('Cumulative Probability');
    yt = yticks;                    % 現在のtick値取得
    yticklabels(string(round(yt*numel(List_side))));
    title('CDF');
    grid on;

    

    Side_range = input('Determine [min max] Filter size (1st dim) of encoder []:all range \n');
    Frame_range = input('Determine [min max] Frame number (3rd dim) of encoder []:all range \n');
    Pole_range = input('Determine [min max] Pole distance (3rd dim) of encoder []:all range \n');

    if ~isempty(Side_range)
        Idx_side = find(List_side >= Side_range(1) & List_side <= Side_range(2));
    else
        Idx_side = 1:numel(List_side);
    end
    max_side = max(List_side(Idx_side));

    if ~isempty(Frame_range)
        Idx_frame = find(List_dur >= Frame_range(1) & List_dur <= Frame_range(2));
    else
        Idx_frame = 1:numel(List_dur);
    end
    max_frame = max(List_dur(Idx_frame));

    if ~isempty(Pole_range)
        Idx_pole = find(List_dist_poles >= Pole_range(1) & List_dist_poles <= Pole_range(2));
    else
        Idx_pole = 1:numel(List_dist_poles);
    end

    Idx_sel = intersect(intersect(Idx_side,Idx_frame),Idx_pole);
    fprintf('%d filters are in this range\n',numel(Idx_sel));
    Range.Side_range = Side_range;
    Range.Frame_range = Frame_range;
    Range.Pole_range = Pole_range;

end