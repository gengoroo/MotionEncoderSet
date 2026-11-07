function show_STRF(RF)
    nFrames = size(RF,3);
    maxvalue = max(abs([min(min(RF(:))), max(max(RF(:)))]));
    range = [-maxvalue, maxvalue];
    for id_frame = 1:nFrames
        subplot(1,nFrames,id_frame);
        imagesc(RF(:,:,id_frame),range);
    end
end