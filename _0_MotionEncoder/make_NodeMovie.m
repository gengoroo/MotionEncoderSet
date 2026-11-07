function [NodeMovie, ListNonNaN, ListNaN] = make_NodeMovie(MOV_input,Model,varargin)

    integmode = 'distance';%default
    for ii = 1:nargin-2
        if strcmp('integmode',varargin{ii})
            integmode = varargin{ii+1};
        end
    end

    switch integmode
        case 'nope'
        weights = Model.SOM.IW{1};
        
        D = pdist2( ...
            Model.Embedding, ...
            weights);
    
        %所属確率変換
        tau = median(D(:))/5;%単なる加重平均だとどのノードもおなじになってしまう
        P = exp(-D/tau);%exp(-D);%単なる加重平均だとどのノードもおなじになってしまう
        P = P ./ sum(P,2);%P(i,j):動画iがノードjに属する強さ
        
        nNodes = size(D,2);
        for id_node = 1:nNodes
            w = P(:,id_node);
            w = w / sum(w);
            
            meanMovie = zeros(size(MOV_input,1), ...
                              size(MOV_input,2), ...
                              size(MOV_input,3));
            
            for k = 1:size(MOV_input,4)
            
                meanMovie = meanMovie + ...
                    w(k)*MOV_input(:,:,:,k);
            
            end
            NodeMovie{id_node} = meanMovie;
        end
        %implay(mat2gray(NodeMovie{1}));
    

        case 'decoder'
        fprintf('decoder mode is under construction\n');

        case 'distance'
            weights = Model.SOM.IW{1};
            nNode = size(weights,1);
            winner = Model.Winner;

            ListNaN = [];
            ListNonNaN = [];
            for iNode = 1:nNode

                idx = find(winner==iNode);
                ListIdx(iNode) = iNode;
            
                if isempty(idx)
                    ListNaN = [ListNaN, iNode];
                    continue
                else
                    ListNonNaN = [ListNonNaN, iNode];
                end

                D = pdist2(weights(iNode,:), Model.Embedding(idx,:));
                D = D(:);
                sigma = median(D);%ガウス重み
            
                w = exp(-(D.^2)/(2*sigma^2));
                w = w/sum(w);

                %%slower version (explanation)
                %M = zeros(size(MOV_input),'single');
                %for k = 1:numel(idx)
                %    M = M + w(k)*MOV_input(:,:,:,idx(k));
                %end
                M = sum(MOV_input(:,:,:,idx) .* reshape(w,1,1,1,[]),4);%faster version

                NodeMovie{iNode} = M;
                
            end

            for ii = 1:numel(ListNaN)
                idx_nan = ListNaN(ii);

                id_nonnan_previous = max(ListNonNaN(ListNonNaN < idx_nan));
                id_nonnan_next = min(ListNonNaN(ListNonNaN > idx_nan));

                if ~isempty(id_nonnan_previous)
                    NodeMovie{idx_nan} = NodeMovie{id_nonnan_previous};
                else
                    NodeMovie{idx_nan} = NodeMovie{id_nonnan_next};
                end

            end
    end

end
