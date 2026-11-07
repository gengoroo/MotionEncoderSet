function selectedNode = select_node(varargin)

    for ii = 1:nargin
        if strcmp('N',varargin{ii})
            N = varargin{ii+1};
        end
        if strcmp('netSOM',varargin{ii})
            netSOM = varargin{ii+1};
            N_total = size(netSOM.IW{1},1);

            selectedNode.meshgrid = meshgrid_select(N,N_total);
            selectedNode.kmean = kmean_center(N,netSOM);
            selectedNode.maxdiv = max_diversity(N,netSOM);
        end
        if strcmp('N_total',varargin{ii})
            N_total = varargin{ii+1};
            selectedNode.meshgrid = meshgrid_select(N,N_total);
        end
    end

end
%--------------------------------------------------------------------------
function selected = meshgrid_select(N,N_total)

    idx = round(linspace(1,sqrt(N_total),sqrt(N)));
    % sqrt(N)×sqrt(N)ノード取得
    [r,c] = meshgrid(idx,idx);
    selected = sub2ind([sqrt(N_total) sqrt(N_total)],r(:),c(:));

end

function selected = kmean_center(N,netSOM)
    W = netSOM.IW{1};
    idx = kmeans(W,N);
    for k=1:N
        member = find(idx==k);
        % 重心
        center = mean(W(member,:),1);
        D = pdist2(W(member,:),center);
        [~,ii] = min(D);
        selected(k) = member(ii);
    end
end

function selected = max_diversity(N,netSOM)
%既に選ばれた全ノードから最も遠いノードを順次追加
    W = netSOM.IW{1};
    selected = 1;
    while length(selected)<N
        D = pdist2(W,W(selected,:));
        mindist = min(D,[],2);
        [~,next] = max(mindist);
        selected(end+1)=next;
    end
end