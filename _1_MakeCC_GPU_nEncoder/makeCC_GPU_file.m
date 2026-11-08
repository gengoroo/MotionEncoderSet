function makeCC_GPU_file(fn_movie, pn_movie, pn_CC, InfoEncoder, InfoMovie, varargin)

        %-------------------------------------------------------------------
        % load parematers
        sec_filter_frame = InfoMovie.sec_filter_frame;
        cut_duration = InfoMovie.cut_duration;
        sel_movie = InfoMovie.sel_movie;
        offset_mode = InfoMovie.offset_mode;
        x_margin = InfoMovie.x_margin;
        y_margin = InfoMovie.y_margin;
        ListShift_norm = InfoMovie.ListShift_norm;

        MF = InfoEncoder.MF;
        nSection = InfoEncoder.nSection;
        SideEncoder =  InfoEncoder.SideEncoder;
        ListUsedEncoderID = MF.ListUsedEncoderID;
        %-------------------------------------------------------------------
        % import varargins
        tag = '';
        yn_flip_T = 'n';
        cc_mode = 'sum';
        yn_skip_fig = 'y';
        MovieXYresize = [];
        for ii = 1:nargin - 5
            if strcmp('tag',varargin{ii})
                tag = varargin{ii+1};
            end
            if strcmp('tag',varargin{ii})
                yn_flip_T = varargin{ii+1};
            end
            if strcmp('MovieXYresize',varargin{ii})%2026_11_08
                MovieXYresize = varargin{ii+1};%2026_11_08
            end
        end
        %-------------------------------------------------------------------
        nFilter = size(MF.RFMap,4);

        [Movie_Mat, ListFrame_startstop,nCut] = movie2mat(pn_movie, fn_movie, sec_filter_frame,cut_duration);% skip ramdisk New 2023.1.5

        if ~isempty(Movie_Mat)
            
            fn_save = [fn_movie(1:end-4) '_25-' num2str(cut_duration) 'sec_x' num2str(nCut)];
            %%%%%%%%%
            %%%%%%%%%
            %%%%%%%%%
            Movie_deriv_Mat = Movie_Mat(:,:,2:end) -  Movie_Mat(:,:,1:end-1);

            % changed to be able to tune nSection
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if ~isempty(SideEncoder)% synthetic RFの場合、はみ出しを切り取る。
                crop_size = SideEncoder.*nSection;
                Movie_Mat = Movie_Mat(1:crop_size(1), 1:crop_size(2), :);
            end
            if exist('SideEncoder','var')%2026_10_31
                side_rf = SideEncoder(1);%scalar, square
            else
                side_rf = input('SideEncoder is missing type number, such as 20\n');
            end
            fprintf('side_rf is %d, encoder is square\n',side_rf);
            XYsize = nSection * side_rf;%2023.12.18
            %XYsize= [200 200];%2023.12.18
            %nSection = XYsize/side_rf;%2023.12.18
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            if ~isempty(MovieXYresize)
                XYsize = MovieXYresize;
                fprintf('Resizing to %s\n',num2str(XYsize));
            end
    
            clear Movie_intact_resize;
            clear Movie_deriv_resize;
            for id_frame = 1:size(Movie_Mat,3)-1
                Movie_intact_resize(:,:,id_frame) = imresize(Movie_Mat(:,:,id_frame),XYsize);
                Movie_deriv_resize(:,:,id_frame) = imresize(Movie_deriv_Mat(:,:,id_frame),XYsize);
            end
    
            switch sel_movie
                case 'i'
                    add_fn = [tag '_i'];
                    Movie_all_resize = Movie_intact_resize;
                    %Movie_all_resize = gpuArray(Movie_intact_resize);
                    note = 'intact';
                case 'd'
                    add_fn = [tag '_d'];
                    Movie_all_resize = Movie_deriv_resize;
                    note = 'deriv';
            end
            fn_save = [fn_save, add_fn];
            pn_save_final =strcat(pn_CC, '\', fn_save);
            mkdir(pn_save_final);
    
            CC_allcut = zeros(nSection(2),nSection(1),nFilter,nCut-1);
    
            nCut_current = nCut-1;
            for id_cut = 2:nCut_current% to prevent stick out
                fprintf('Current cut is %d out of %d\n',id_cut,nCut);
                ListFrame = round(ListFrame_startstop(1,id_cut):ListFrame_startstop(2,id_cut)); 
                %ListFrame = gpuArray(round(ListFrame_startstop(1,id_cut):ListFrame_startstop(2,id_cut))); 
     
                Movie_resize = Movie_all_resize(:,:,ListFrame);
    
                %clear CC;
                nFrame_filter = size(MF.RFMap,3);
                fprintf('View is divided into %d x %d\n',nSection(1),nSection(2));
                %-------------------------------------------------
                switch offset_mode
                    case 'e'% default
                        for id_xsec = 1:nSection(1) - x_margin% var version
                            for id_ysec = 1:nSection(2) - y_margin% var version
                                
                                %x_range = gpuArray(side_rf*(id_xsec-1) + 1:side_rf*id_xsec);
                                %y_range = gpuArray(side_rf*(id_ysec-1) + 1:side_rf*id_ysec);
                                x_range = side_rf*(id_xsec-1) + 1:side_rf*id_xsec;
                                y_range = side_rf*(id_ysec-1) + 1:side_rf*id_ysec;
                                Movie_sec = Movie_resize(y_range,x_range,:);
    
                                % OFF??????OFF??????????????
                                ListIntensity = reshape(sum(sum(Movie_sec,2),1),[],1);
                                ListIntensity_cut = ListIntensity;% ????????
                                if yn_flip_T == 'y'
                                    OnFrameIn = min(find(ListIntensity_cut == min(ListIntensity_cut)));
                                    offset_t = OnFrameIn - MF.OnFrame;
                                else
                                    OffFrameIn = min(find(ListIntensity_cut == min(ListIntensity_cut)));
                                    offset_t = OffFrameIn - MF.OffFrame;
                                end
                                if ListUsedEncoderID == 0%2024.02.07 for nEncoder = 0
                                    offset_t = 0;%時刻合わせ行わない
                                end
    
                                %start_total = gpuArray(ListFrame_startstop(1,id_cut) + offset_t);% frames can be next cut
                                %stop_total = gpuArray(start_total + nFrame_filter - 1);% frames can be next cut
                                start_total = ListFrame_startstop(1,id_cut) + offset_t;% frames can be next cut
                                stop_total = start_total + nFrame_filter - 1;% frames can be next cut
    
                                InputMovie = Movie_all_resize(x_range,y_range,start_total:stop_total);
                                Range = {'','',0};
                                B = double(InputMovie)/256;
    
                                clear B_shift;%2023.12.21 
                                %ListShift = gpuArray(round(ListShift_norm*side_rf));%Seq
                                ListShift = round(ListShift_norm*side_rf);%Seq
                                %for id_shift = gpuArray(1:size(ListShift,1))
                                for id_shift = 1:size(ListShift,1)
                                    y_shift = ListShift(id_shift, 1);
                                    x_shift = ListShift(id_shift, 2);
                                    InputMovie_shift = Movie_all_resize(x_range(1) + x_shift:x_range(end) + x_shift, y_range(1) + y_shift:y_range(end) + y_shift,start_total:stop_total);% 
                                    B_shift(:,:,:,id_shift) = double(InputMovie_shift)/256;
                                end
    
                                %for id_filter = gpuArray(1:nFilter)
                                for id_filter = 1:nFilter
                                    A = MF.RFMap(:,:,:,id_filter);
                                    
                                    switch cc_mode
                                        case 'max'
                                            norm_CCM = A.*B./sqrt(sum(sum(sum(A.^2)))*sum(sum(sum(B.^2))));% simplified
                                            CC_allcut(id_ysec,id_xsec,id_filter,id_cut) = max(max(max(norm_CCM)));
                                        case 'sum'
                                            norm_CCM = A.*B./sqrt(sum(sum(sum(A.^2)))*sum(sum(sum(B.^2))));% simplified
                                            CC_allcut(id_ysec,id_xsec,id_filter,id_cut) = sum(sum(sum(norm_CCM)));
                                        case '3Dcc'
                                            [ CCM, norm_CCM, T] = cc_3D_range( A,B, Range);
                                            CC_allcut(id_ysec,id_xsec,id_filter,id_cut) = max(max(max(norm_CCM)));
                                    end
                                    
                                end

                                %------------------------------------------
                                % use GPU 
                                A_resize = imresize(MF.RFMap,[size(B_shift,1),size(B_shift,2)]);
                                A_resize_rempat = repmat(A_resize,1,1,1,1,size(ListShift,1));%x,y,t,filter,shift_repmat

                                Aoff_resize = imresize(-MF.RF_black,[size(B_shift,1),size(B_shift,2)]);%負の値にしておく
                                Aoff_resize_rempat = repmat(Aoff_resize,1,1,1,1,size(ListShift,1));%x,y,t,filter,shift_repmat

                                for id_shift = 1:size(ListShift,1)
                                    B_shift_repmat(:,:,:,:,id_shift) = repmat(B_shift(:,:,:,id_shift),1,1,1,nFilter,1);%x,y,t,filter_repmat,shiftt
                                end
                                if canUseGPU()
                                    Encoder = gpuArray(A_resize_rempat);
                                    Encoder_off = gpuArray(Aoff_resize_rempat);
                                    InputData = gpuArray(B_shift_repmat);
                                else
                                    Encoder = A_resize_rempat;
                                    Encoder_off = Aoff_resize_rempat;
                                    InputData = B_shift_repmat;
                                end
                                CCM_shift_repmat = Encoder.*InputData;
                                CCMoff_shift_repmat = Encoder_off.*InputData;%この値が小さい（負の）方がoff match度が高い
                                if nFilter == 1%次元が下の方から詰められるので、:,:を使うと３次元目（neuron#)に4次元目(id_shift)が入ってしまう。2024.02.04　エラー回避
                                    CC_allcut_var(id_ysec,id_xsec,1,:,id_cut) = sum(sum(sum(CCM_shift_repmat,3),2),1)./sqrt(sum(sum(sum(Encoder.^2,3),2),1).*sum(sum(sum(InputData.^2,3),2),1));% x, y id_filter, id_shift, id_cut
                                    CCoff_allcut_var(id_ysec,id_xsec,1,:,id_cut) = sum(sum(sum(CCMoff_shift_repmat,3),2),1)./sqrt(sum(sum(sum(Encoder.^2,3),2),1).*sum(sum(sum(InputData.^2,3),2),1));% x, y id_filter, id_shift, id_cut
                                else
                                    CC_allcut_var(id_ysec,id_xsec,:,:,id_cut) = sum(sum(sum(CCM_shift_repmat,3),2),1)./sqrt(sum(sum(sum(Encoder.^2,3),2),1).*sum(sum(sum(InputData.^2,3),2),1));% x, y id_filter, id_shift, id_cut
                                    CCoff_allcut_var(id_ysec,id_xsec,:,:,id_cut) = sum(sum(sum(CCMoff_shift_repmat,3),2),1)./sqrt(sum(sum(sum(Encoder.^2,3),2),1).*sum(sum(sum(InputData.^2,3),2),1));% x, y id_filter, id_shift, id_cut
                                end
                                for id_shift = 1:size(ListShift,1)
                                    for id_filter = 1:nFilter
                                        dOFFvsON(id_ysec,id_xsec,id_filter,id_shift,id_cut) = calc_OFFvsON_d_index(A_resize(:,:,:,id_filter),B_shift(:,:,:,id_shift));%2024.02.02 add
                                    end
                                end
                                %------------------------------------------

                            end
                            fprintf('.');
                        end
                        %dOFFvsON_sum = reshape(sum(sum(sum(dOFFvsON(:,:,:,:,id_cut),3),2),1),[],1);
                        %dOFFvsON_max_shift(id_cut) = find(dOFFvsON_sum == max(dOFFvsON_sum));
    
                    case 'c'
                        %-------------------------------------------------
                        % OFFset value is common for all 10x10
                        % calculating offset, this mode is also slow
                        ListIntensity = reshape(sum(sum(Movie_resize,2),1),[],1);
                        ListIntensity_cut = ListIntensity;% ????????
                        if yn_flip_T == 'y'
                            OnFrameIn = min(find(ListIntensity_cut == min(ListIntensity_cut)));
                            offset_t = OnFrameIn - MF.OnFrame;
                        else
                            OffFrameIn = min(find(ListIntensity_cut == min(ListIntensity_cut)));
                            offset_t = OffFrameIn - MF.OffFrame;
                        end
                        start_total = ListFrame_startstop(1,id_cut) + offset_t;% frames can be next cut
                        stop_total = start_total + nFrame_filter - 1;% frames can be next cut
                        %-calculating offset
                        InputMovie = Movie_all_resize(:,:,start_total:stop_total);
                        B = double(InputMovie)/256;
    
                        Range = {'','',0};
                        for id_filter = 1:nFilter
                            A = repmat(MF.RFMap(:,:,:,id_filter),nSection(1),nSection(2),1);
                            %[ CCM, norm_CCM, T] = cc_3D_range( A,B, Range);
                            norm_CCM = A.*B./sqrt(sum(sum(sum(A.^2)))*sum(sum(sum(B.^2))));% simplified
                            for id_xsec = 1:nSection(1)
                                for id_ysec = 1:nSection(2)
                                    x_range = side_rf*(id_xsec-1) + 1:side_rf*id_xsec;
                                    y_range = side_rf*(id_ysec-1) + 1:side_rf*id_ysec;  
                                    CC_allcut(id_ysec,id_xsec,id_filter,id_cut) = max(max(max(norm_CCM(y_range,x_range,:))));
                                    %if  max(max(max(norm_CCM(y_range,x_range,:)))) == 0
                                    %    fprintf('0');
                                    %else
                                    %    fprintf('.');
                                    %end              
                                end
                                fprintf('.');
                            end
                            fprintf('\n');
                        end
    
                end
                %-------------------------------------------------
                %-------------------------------------------------
                %CC_allcut(:,:,:,id_cut) = CC;
                fprintf('\n');
            end
            SumCC = reshape(sum(sum(CC_allcut,2),1),size(CC_allcut,3),size(CC_allcut,4));
            AveSumCC = mean(SumCC,2);
            [B,I] = sort(AveSumCC);
            OrderCC = I;
    
    
            
            if yn_skip_fig ~= 'y'
                % fastモードの場合Skipする
                %----------------------------------------------------------------------------------    
                % show CC 
                for id_cut = 2:nCut-1% to prevent stick out
                    CC = CC_allcut(:,:,:,id_cut);
                    h(id_cut) = figure('Name',['movie spectrum ' note ' cut#' num2str(id_cut)],'Color','w');hold on;
                    maxvalue = abs(prctile(reshape(CC,1,[]),100));
                    for id_filter =1:nFilter
                        subplot(5,5,id_filter);
                        imagesc(floor(255*(CC(:,:,id_filter)/maxvalue)),[0 255]);
                    end
                    tightfig;
                    saveas(h(id_cut), [pn_save_final '\' h(id_cut).Name '.fig'],'fig');
                    close(h(id_cut));
                end
        
                % show 1st frames
                h_1stimage = figure('Name','First frame of each cut','color','w');
                nColumn = 5;nRow = ceil(nCut/5);
                maxscale = max(max(max(Movie_Mat)));
                for id_cut = 1:nCut
                    subplot(nRow,nColumn,id_cut);hold on;    
                    imagesc(Movie_Mat(:,:,ListFrame_startstop(1,id_cut)),[min(min(min(Movie_Mat))),max(max(max(Movie_Mat)))]);
                    %imshow(ceil(3000/maxscale*Movie_Mat(:,:,ListFrame_startstop(1,id_cut))));
                    title(['Cut#' num2str(id_cut)]);
                     a=gca;a.XLim(2) = size(Movie_Mat,2);a.YLim(2) = size(Movie_Mat,1);
                end
                tightfig;
                saveas(h_1stimage, [pn_save_final '\' h_1stimage.Name '.fig'],'fig');
                close(h_1stimage);
                %----------------------------------------------------------------------------------  
            end
    
            % save images
            save(strcat(pn_save_final, '\CC_allcut.mat'),'CC_allcut','AveSumCC','OrderCC','CC_allcut_var','CCoff_allcut_var','dOFFvsON');
    
            pn_im_stack = strcat(pn_save_final, '\CC_');
            mkdir(pn_im_stack);
            for id_cut = 2:size(CC_allcut,4)+1% to prevent stick out
                CC = CC_allcut(:,:,:,id_cut-1);
                for id_neuron = 1:size(CC,3)

                    CC_single = CC(:,:,id_neuron);%2023_08_07 mat gives larger dynamic range
                    save(strcat(pn_im_stack, '\', fn_movie(1:end-4), '_Neuron_', num2str(id_neuron), 'Cut_', num2str(id_cut), '.mat'),'CC_single');%2023_08_07

                    
                    if yn_skip_fig ~= 'y' 
                        %------------------- skip -----------------------------
                        % prevoius style, scale is not enough
                        imwrite(CC(:,:,id_neuron),[pn_im_stack '\' fn_movie(1:end-4) '_Neuron_' num2str(id_neuron) 'Cut_' num2str(id_cut) '.tif']);  
                        
                        % Tiff Stack below piles up for all neurons, not channnel, scale is not enough
                        if id_neuron == 1
                            imwrite(CC(:,:,id_neuron),[pn_im_stack '\Cut_' num2str(id_cut) '.tif']);   
                        else
                            imwrite(CC(:,:,id_neuron),[pn_im_stack '\Cut_' num2str(id_cut) '.tif'],'WriteMode','append');  
                        end
                        %------------------- skip -----------------------------
                    end
                    
                end
            end
            %------------------------------------------------------------------------------------------------
            
        end% if not Movie_mat empty
end
%2024.02.02 add
function dOFFvsON = calc_OFFvsON_d_index(Encoder,InputIm)
    Enc_posi = Encoder(Encoder>0);
    data = reshape(sum(sum(Enc_posi,2),1),[],1);
    ONpeak_Enc = min(find(data == max(data)));

    InputIm_posi = InputIm(InputIm>0);
    data = reshape(sum(sum(InputIm_posi,2),1),[],1);
    %ONpeak_input = min(find(data == max(data)));

    GC_dist_ON = calc_GCdist(Enc_posi(:,:,ONpeak_Enc),InputIm_posi(:,:,ONpeak_Enc));

    %----------------------------------------------------------------------
    Enc_nega = abs(Encoder(Encoder<0));
    data = reshape(sum(sum(Enc_nega,2),1),[],1);
    OFFpeak_Enc = max(find(data == max(data)));

    InputIm_nega = abs(InputIm(InputIm>0));
    data = reshape(sum(sum(InputIm_nega,2),1),[],1);
    %OFFpeak_input = max(find(data == max(data)));
    GC_dist_OFF = calc_GCdist(Enc_nega(:,:,OFFpeak_Enc),InputIm_nega(:,:,OFFpeak_Enc));

    dOFFvsON = (GC_dist_ON - GC_dist_OFF)/(GC_dist_ON + GC_dist_OFF);
end
function GC_dist = calc_GCdist(im1,im2)
    GC1 = calc_GC(im1);
    GC2 = calc_GC(im2);
    dGC = GC2 - GC1;
    GC_dist = sqrt(sum(dGC.^2));
end
function GC = calc_GC(im)
    tot_mass = sum(im(:));
    [ii,jj] = ndgrid(1:size(im,1),1:size(im,2));
    R = sum(ii(:).*im(:))/tot_mass;
    C = sum(jj(:).*im(:))/tot_mass;
    GC = [R,C];
end