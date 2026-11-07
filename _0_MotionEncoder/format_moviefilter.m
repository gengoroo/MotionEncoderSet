function MOV_adjust= format_moviefilter(MOV_onoff,varargin)%2026_11_01

    ResizeSide = [];%default
    for ii = 1:nargin-2
        if strcmp('rep_value',varargin{ii})
            rep_value = varargin{ii+1};
        end
        if strcmp('FilterSize',varargin{ii})
            FilterSize = varargin{ii+1};
        end
        if strcmp('Info_MOV_onoff',varargin{ii})
            Info_MOV_onoff = varargin{ii+1};
        end
        if strcmp('ResizeSide',varargin{ii})%2026_11_02
            ResizeSide = varargin{ii+1};
        end
    end

    side_max = max(Info_MOV_onoff.size(:,1));
    dur_max = max(Info_MOV_onoff.size(:,3));
    switch rep_value
        case 'mode'
            side_mode = mode(Info_MOV_onoff.size(:,1));
            dur_mode = mode(Info_MOV_onoff.size(:,3));
        case 'specify'%2026_11_02
            side_mode = FilterSize(1);
            dur_mode = FilterSize(3);
    end
    
    if 1==2%2026_11_02
    for id_pair = 1:numel(MOV_onoff)
        %MOV_max = 0.5*ones(side_max,side_max,dur_max);
        MOV_max = zeros(side_max,side_max,dur_max);
        side = size(MOV_onoff{id_pair},1);
        dur = size(MOV_onoff{id_pair},3);
        xy_start = max(floor((side_max - side)/2),1);
        xy_stop = xy_start + side -1;
        z_start = dur_max - dur + 1;
        MOV_max(xy_start:xy_stop,xy_start:xy_stop,z_start:end) = MOV_onoff{id_pair};
    
        xy_start_crop = max(ceil((side_max - side_mode)/2),1);
        xy_stop_crop = min(xy_start_crop + side_mode -1,side_max);
        z_start_crop = dur_max - dur_mode + 1;
    
        if ~isempty(ResizeSide)
            MOV_adjust(:,:,:,id_pair) = imresize(MOV_max(xy_start_crop:xy_stop_crop,xy_start_crop:xy_stop_crop,z_start_crop:end),[ResizeSide,ResizeSide]);
        else
            MOV_adjust(:,:,:,id_pair) = MOV_max(xy_start_crop:xy_stop_crop,xy_start_crop:xy_stop_crop,z_start_crop:end);
        end
    end
    end



%function MOV_adjust= format_moviefilter(MOV_onoff,Info_MOV_onoff,varargin)%2026_11_01

    rep_value = '';% defaultではmodeなどでは選ばない2026_11_01
    for ii = 1:nargin-2
        if strcmp('Info_MOV_onoff',varargin{ii})% オプションにする2026_11_01
            Info_MOV_onoff = varargin{ii+1};
        end
        if strcmp('rep_value',varargin{ii})
            rep_value = varargin{ii+1};
        end
        if strcmp('FilterSize',varargin{ii})
            FilterSize = varargin{ii+1};%変数統一 2026_11_02
        end
    end

    side_max = max(Info_MOV_onoff.size(:,1));
    dur_max = max(Info_MOV_onoff.size(:,3));
    switch rep_value
        case 'mode'%FilterSize値をmode値で上書き
            %side_mode = mode(Info_MOV_onoff.size(:,1));
            %dur_mode = mode(Info_MOV_onoff.size(:,3));
    end
    
    %clear MOV_adjust;
    parfor id_pair = 1:numel(MOV_onoff)
        %MOV_max = 0.5*ones(side_max,side_max,dur_max);
        MOV_max = zeros(side_max,side_max,dur_max);
        side1 = size(MOV_onoff{id_pair},1);
        side2 = size(MOV_onoff{id_pair},2);
        dur = size(MOV_onoff{id_pair},3);
        xy_start1 = max(floor((side_max - side1)/2),1);
        xy_stop1 = xy_start1 + side1 -1;
        xy_start2 = max(floor((side_max - side2)/2),1);
        xy_stop2 = xy_start2 + side2 -1;
        z_start = dur_max - dur + 1;
        
        %MOV_max(xy_start1:xy_stop1,xy_start2:xy_stop2,z_start:end) = MOV_onoff{id_pair};
        MOV_max(xy_start1:xy_stop1,xy_start2:xy_stop2,z_start:dur_max) = MOV_onoff{id_pair};% 2024.11.20 new
    
        xy_start_crop = max(ceil((side_max - FilterSize(1))/2),1);
        xy_stop_crop = min((xy_start_crop + FilterSize(1) -1),side_max);
        z_start_crop = dur_max - FilterSize(3) + 1;
    
        if ~isempty(ResizeSide)
            MOV_adjust(:,:,:,id_pair) = imresize(MOV_max(xy_start_crop:xy_stop_crop,xy_start_crop:xy_stop_crop,z_start_crop:end),[ResizeSide,ResizeSide]);
        else
            MOV_adjust(:,:,:,id_pair) = MOV_max(xy_start_crop:xy_stop_crop,xy_start_crop:xy_stop_crop,z_start_crop:end);
        end
    end

end