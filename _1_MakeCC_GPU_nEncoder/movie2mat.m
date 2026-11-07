function [Movie_Mat,ListFrame_startstop,nCut,duration,sec_per_frame] = movie2mat(pn_movie, fn_movie, sec_filter_frame,cut_duration)

        vidObj = VideoReader([pn_movie '\' fn_movie]);
        duration = vidObj.Duration;
        nCut = floor((duration - sec_filter_frame)/cut_duration);%2???????
        nFramePerCut = round(cut_duration/sec_filter_frame);
        for id_cut = 1:nCut
            ListFrame_startstop(:,id_cut) = [nFramePerCut*(id_cut-1) + 1, nFramePerCut*id_cut];
        end
        fprintf('%d frames in one cut x %d\n',nFramePerCut,nCut);
        Movie_Mat = [];
        for id_cut = 1:nCut
            for id_frame = 1:nFramePerCut
                vidObj.CurrentTime = cut_duration*(id_cut-1) + sec_filter_frame * id_frame;
                frame = readFrame(vidObj);
                if size(frame,1) >=size(frame,2)
                    frame = imresize(frame,round(800*[1, size(frame,2)/size(frame,1)]));
                else
                    frame = imresize(frame,round(800*[size(frame,1)/size(frame,2),1]));
                end

                Movie_Mat(:,:,round(nFramePerCut*(id_cut-1) + id_frame)) = mean(frame,3);
                fprintf('.');
            end
            fprintf('\n');
        end
        fprintf('\n');
        sec_per_frame = sec_filter_frame;

        if max(max(max(Movie_Mat)))==0
            fprintf('Error! max of Movie_Mat =0\n');
        end
end
