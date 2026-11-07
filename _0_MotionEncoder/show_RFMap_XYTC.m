function show_RFMap_XYTC(RF4D,varargin)

    for ii = 1:nargin-1
        if strcmp('maxNCell',varargin{ii})
            maxNCell = varargin{ii+1};
        end
    end

    if exist('maxNCell','var')
        nCell = min(size(RF4D,4),maxNCell);
    else
        nCell = size(RF4D,4);
    end
    fprintf('showing %d cell RFs\n',nCell);

    nFrame = size(RF4D,3);
    
    hold on;
    for id_cell = 1:nCell
        maxvalue = max(reshape(abs([RF4D(:,:,:,id_cell)]),1,[]));
        for id_frame = 1:nFrame
            subplot(nCell,nFrame,nFrame*(id_cell-1) + id_frame);
            imagesc(RF4D(:,:,id_frame,id_cell),[-maxvalue maxvalue]);
        end
    end
    
end