function [Peak_aveX, Peak_Y2, Peak_X_1st, Peak_X_list] = findpeaks(varargin)

    switch nargin
        case 1
            X = 1:numel(varargin{1});
            Y = varargin{1};
        case 2
            X = varargin{1};
            Y = varargin{2};
    end
    X2=X;
    Y2=Y;

    for ii = numel(Y2):-1:2
        if (Y2(ii) == Y2(ii-1))%ひとつ前と同じだったら
            Y2(ii) = [];%後ろから削除
            X2(ii) = [];
        end
    end

    d_data = diff(Y2);
    peaks_id = find(((d_data(1:end-1)>0)&(d_data(2:end)<0)))+1;
    Peak_X_1st = X2(peaks_id);
    Peak_Y2 = Y2(peaks_id);

    for ii = 1:numel(Peak_X_1st)
        Peak_X_list{ii} = Peak_X_1st(ii);
        x = Peak_X_list{ii};
        while isempty(intersect(x+1,X2))&&(x<=max(X))
            Peak_X_list{ii} = [Peak_X_list{ii}, x+1];
            x = x + 1;
        end
        Peak_aveX(ii) = mean(Peak_X_list{ii});
    end
end