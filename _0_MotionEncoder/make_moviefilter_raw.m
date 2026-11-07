function MOV_ONOFF = make_moviefilter_raw(PairOverlap, Traj_hit_ref, Traj_hit_found, Points_Traj_ref, Points_Traj_found, margin_start, margin_stop)

    Traj_ref = Points_Traj_ref(Traj_hit_ref);
    Traj_found = Points_Traj_found(Traj_hit_found);
    Peak_Location_ref = PairOverlap.ref.Location;
    Peak_Location_found = PairOverlap.found.Location;
    Interval_frames = abs(Peak_Location_ref(:,3) - Peak_Location_found(:,3));
    total_frames = max(Interval_frames)*2;%最長インターバルの２倍

    figure;hold on;
    for ii = 1:numel(Traj_ref)
        plot3(Traj_ref(ii).pos(:,1),Traj_ref(ii).pos(:,2),Traj_ref(ii).pos(:,3),'k-');
        plot3(Traj_found(ii).pos(:,1),Traj_found(ii).pos(:,2),Traj_found(ii).pos(:,3),'r-');
    end
    plot3(Peak_Location_ref(:,1),Peak_Location_ref(:,2),Peak_Location_ref(:,3),'k*')
    plot3(Peak_Location_found(:,1),Peak_Location_found(:,2),Peak_Location_found(:,3),'r*')

    if PairOverlap.found.id_slice(1) < PairOverlap.ref.id_slice(1)
        pivot = 'k';
    end
    if PairOverlap.ref.id_slice(1) < PairOverlap.found.id_slice(1)
        pivot = 'w'; 
    end

    for ii = 1:numel(Traj_ref)
        
        switch pivot
            case 'k'
                Pos_ref = Peak_Location_ref(ii,:);
                frame_start = min(Peak_Location_found(ii,3)) - margin_start;
            case 'w'
                Pos_ref = Peak_Location_found(ii,:);
                frame_start = min(Peak_Location_ref(ii,3)) - margin_start;
        end

        halfside_ONOFF = ceil(1.5*max( max(Traj_ref(ii).Scale), max(Traj_found(ii).Scale)));     

        ListLocation = Traj_ref(ii).pos;
        ListFrame = Traj_ref(ii).ListFrame;
        ListSigma = Traj_ref(ii).Scale*1.5;
        MOV_OFF = make_gaussian_movie(ListLocation, ListFrame,ListSigma, frame_start, Pos_ref, halfside_ONOFF, margin_stop);

        ListLocation = Traj_found(ii).pos;
        ListFrame = Traj_found(ii).ListFrame;
        ListSigma = Traj_found(ii).Scale*1.5;
        MOV_ON = make_gaussian_movie(ListLocation, ListFrame,ListSigma, frame_start, Pos_ref, halfside_ONOFF, margin_stop);

        MOV_ON_temp = 0.5+0.5*MOV_ON;
        MOV_OFF_temp = 0.5 - 0.5*MOV_OFF;
        if ~isempty(MOV_ON_temp)&&~isempty(MOV_OFF_temp)
            if size(MOV_ON_temp) == size(MOV_OFF_temp)
            
            MOV_ONOFF{ii} = MOV_ON_temp + MOV_OFF_temp;
    
            figure; hold on;
            plot3(Pos_ref(1),Pos_ref(2),Pos_ref(3),'*');
            plot3(Traj_ref(ii).pos(:,1), Traj_ref(ii).pos(:,2), Traj_ref(ii).pos(:,3),'k-');
            plot3(Traj_found(ii).pos(:,1), Traj_found(ii).pos(:,2), Traj_found(ii).pos(:,3),'r-');
            void = input('');
            end
        end
    end

end

function MOV = make_gaussian_movie(ListLocation, ListFrame, ListSigma, frame_start, Pos_ref, halfside_ONOFF, margin_stop)%XYT and cells
    MOV = [];

    w = halfside_ONOFF*2+1;
    frame_end = Pos_ref(3)+margin_stop;

    if frame_start < ListFrame(1)
            MOV_pre = zeros(w,w, ListFrame(1) - frame_start);
    end
    if  ListFrame(end) < frame_end
            MOV_post = zeros(w,w, frame_end - ListFrame(end));
    end

    [ListFramePick, ia, ib] = intersect(frame_start:frame_end,ListFrame);

    for ii = 1:numel(ListFramePick)
        GCx = ListLocation(ib(ii));
        GCy = ListLocation(ib(ii));
        sigma = ListSigma(ib(ii));
        [X, Y] = meshgrid(-halfside_ONOFF:1:halfside_ONOFF);
        MOV(:,:,ii) = 1/(sqrt(2*pi)*sigma) * exp((-(X-GCx+Pos_ref(1)).^2-(Y-GCy+Pos_ref(2)).^2)/(2*sigma^2));
    end
    
    if exist('MOV','var')
        if exist('MOV_pre','var')
            MOV = cat(3,MOV_pre,MOV);
        end
        if exist('MOV_post','var')
            MOV = cat(3, MOV, MOV_post);
        end
    end

end