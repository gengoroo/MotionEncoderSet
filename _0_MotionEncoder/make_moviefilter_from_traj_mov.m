%function [MOV_Feature, MOV_onoff, Info] = make_moviefilter_from_traj_mov(mov,Points_Traj_ref_pair, Points_Traj_found_pair, margin_start, margin_stop,ref_wb)
function [MOV_Feature, Info] = make_moviefilter_from_traj_mov(mov,Points_Traj_ref_pair, Points_Traj_found_pair, margin_start, margin_stop)


    margin_start = margin_start;
    margin_stop = margin_stop;


    for id_pair = 1:numel(Points_Traj_ref_pair)

        List_z_found = Points_Traj_found_pair(id_pair).pos(:,3);
        List_z_ref = Points_Traj_ref_pair(id_pair).pos(:,3);
        z_peak_1st = Points_Traj_found_pair(id_pair).peak;
        z_peak_2nd = Points_Traj_ref_pair(id_pair).peak;

            z_start = z_peak_1st - margin_start;
            z_stop = z_peak_2nd + margin_stop;
    
            ListFrames_abs = z_start:z_stop;
            Cen = Points_Traj_ref_pair(id_pair).pos(find(List_z_ref==z_peak_2nd),1:3);
            sigma_ori = Points_Traj_ref_pair(id_pair).Scale(find(List_z_ref==z_peak_2nd))*1.5;
            halfside = round(sigma_ori*4);%ONOFFの、全フレームの最大の４σ

            % new --------------------------------------------
            Center = Points_Traj_ref_pair(id_pair).pos(1,1:2);
            LeftTop = Center - [halfside, halfside];
            RightBottom = Center + [halfside, halfside];
            MOV_Feature{id_pair} = mov(LeftTop(1):RightBottom(1), LeftTop(2):RightBottom(2), z_start:z_stop);
            % new --------------------------------------------
    
            if 0
            clear IM_found;
            clear IM_ref;
            for ii = 1:numel(ListFrames_abs)
                frame_abs = ListFrames_abs(ii);
    
                [~,frameid,~] = intersect(List_z_found,frame_abs);
                if ~isempty(frameid)
                    GC = Points_Traj_found_pair(id_pair).pos(frameid,1:2);
                    sigma = Points_Traj_found_pair(id_pair).Scale(frameid)*1.5;
                    IM_found(:,:,ii) = make_gaussian_image(GC-Cen(1:2), sigma, halfside);
                else
                    IM_found(:,:,ii) = zeros(2*halfside+1);
                end
    
                [~,frameid,~] = intersect(List_z_ref,frame_abs);
                if ~isempty(frameid)
                    GC = Points_Traj_ref_pair(id_pair).pos(frameid,1:2);
                    sigma = Points_Traj_ref_pair(id_pair).Scale(frameid)*1.5;
                    IM_ref(:,:,ii) = make_gaussian_image(GC-Cen(1:2), sigma, halfside);
                else
                    IM_ref(:,:,ii) = zeros(2*halfside+1);
                end
    
                switch ref_wb
                    case 'b'
                    %MOV_onoff{id_pair}(:,:,ii) = 0.5+ 0.5*(IM_found(:,:,ii) - IM_ref(:,:,ii));
                    MOV_onoff{id_pair}(:,:,ii) = IM_found(:,:,ii) - IM_ref(:,:,ii);
                    case 'w'
                    %MOV_onoff{id_pair}(:,:,ii) = 0.5+ 0.5*(IM_ref(:,:,ii) - IM_found(:,:,ii));
                    MOV_onoff{id_pair}(:,:,ii) = IM_ref(:,:,ii) - IM_found(:,:,ii);
                end
    
            end
            Info.pix_max(id_pair) = max(max(max(MOV_onoff{id_pair})));
            Info.pix_min(id_pair) = min(min(min(MOV_onoff{id_pair})));
            Info.size(id_pair,:) = size(MOV_onoff{id_pair});
            end

            Info.pix_max(id_pair) = max(max(max(MOV_Feature{id_pair})));
            Info.pix_min(id_pair) = min(min(min(MOV_Feature{id_pair})));
            Info.size(id_pair,:) = size(MOV_Feature{id_pair});

    end

end


