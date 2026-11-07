
%pn_def = 'C:\Users\gengoro\SynologyDrive\AI\Tad\Select\crop2_sel\Rot0.48\movie_package';
%pn_input = uigetdir(pn_def,'select folder');

function [keys, dIM, keys_raw] = sift3d_batch(pn_input)
    
    pn_save = [pn_input '\SIFT3D'];
    mkdir(pn_save);
    Info = dir(pn_input);
    for ii = 1:numel(Info)
        fn_full = [pn_input ,'\' Info(ii).name];
        if ~isdir(fn_full)
            if strcmp(Info(ii).name(end-2:end),'avi')
        
                % VideoReader?????????
                vidObj = VideoReader(fn_full);

                % ?????????1??????????
                counter = 0;
                while hasFrame(vidObj)
                    counter  =counter +1;
                    frame = readFrame(vidObj);
                    %imshow(frame);
                    %pause(1/vidObj.FrameRate); % ????????????????
                    IM(:,:,counter) = frame(:,:,1);
                end

                dIM = IM(:,:,2:end) - IM(:,:,1:end-1);
                keys_raw = detectSift3D(dIM,'numKpLevels',3,'sigmaN',1.15,'sigma0',1.6);
                
                [Gx, Gy, Gz] = gradient(double(dIM));% varargin?????????
                Gradient3D{1} = Gx;
                Gradient3D{2} = Gy;
                Gradient3D{3} = Gz;
                
                for id_key = 1:numel(keys_raw)
                    POS= keys_raw(id_key).coords;
                    scale = keys_raw(id_key).scale;
                    orientation= keys_raw(id_key).ori;

                    [metric, descriptor] = computeSIFTDescriptor3D(dIM, POS(1), POS(2), POS(3), scale, orientation,Gradient3D);
                    keys_raw(id_key).metric = metric;
                    keys_raw(id_key).descriptor = descriptor;
                end
                metrics = [keys_raw.metric];
                [~, sortedIdx] = sort(metrics, 'descend');
                keys = keys_raw(sortedIdx);
                
                fn_save = [Info(ii).name(1:end-4) '_SIFT3D.mat'];
                save([pn_save '\' fn_save],'keys');
            
            end
        
        end
    end
    
end