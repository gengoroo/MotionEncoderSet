function MOV_adjust= format_moviefilter_wide(MOV_onoff,Info_MOV_onoff,varargin)

    for ii = 1:nargin-2
        if strcmp('rep_value',varargin{ii})
            rep_value = varargin{ii+1};
        end
        if strcmp('side',varargin{ii})
            side = varargin{ii+1};
        end
    end

    dur_max = max(Info_MOV_onoff.size(:,3));
    dur_unify = dur_max;
    switch rep_value
        case 'mode'
            side_unify = mode(Info_MOV_onoff.size(:,1));
        case 'max'
            side_unify = max(Info_MOV_onoff.size(:,1));
        case 'specify'
            side_unify = side;
    end
    
    clear MOV_adjust;
    for id_pair = 1:numel(MOV_onoff)
        %MOV_max = 0.5*ones(side_max,side_max,dur_max);
        MOV_max = zeros(side_unify,side_unify,dur_max);
        side1 = size(MOV_onoff{id_pair},1);
        side2 = size(MOV_onoff{id_pair},2);
        dur = size(MOV_onoff{id_pair},3);
        xy_start1 = max(floor((side_unify - side1)/2),1);
        xy_stop1 = xy_start1 + side1 -1;
        xy_start2 = max(floor((side_unify - side2)/2),1);
        xy_stop2 = xy_start2 + side2 -1;
        z_start = dur_max - dur + 1;
        
        %MOV_max(xy_start1:xy_stop1,xy_start2:xy_stop2,z_start:end) = MOV_onoff{id_pair};
        MOV_max(xy_start1:xy_stop1,xy_start2:xy_stop2,z_start:dur_max) = MOV_onoff{id_pair};% 2024.11.20 new
    
        xy_start_crop = max(ceil((side_unify - side_unify)/2),1);
        xy_stop_crop = xy_start_crop + side_unify -1;
        z_start_crop = dur_max - dur_unify + 1;
    
        MOV_adjust(:,:,:,id_pair) = MOV_max(xy_start_crop:xy_stop_crop,xy_start_crop:xy_stop_crop,z_start_crop:end);
    end

end