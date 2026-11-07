function FeatureTraj_black = FeatureTraj_py2mat(FeatureTraj_py_black)

    N = int64(py.len(FeatureTraj_py_black));
    
    FeatureTraj_black = struct();
    fprintf('Converting FeatureTraj N=%d\n',N);
    fprintf('current N=');
    for k = 1:N

        if (rem(k,20)==0)||(k==N)
            fprintf('%d ',k);
        end
    
        p = FeatureTraj_py_black{k};
    
        FeatureTraj_black(k).startframe = ...
            double(p.startframe);
    
        FeatureTraj_black(k).ListFrame = ...
            double(p.ListFrame);
    
        FeatureTraj_black(k).node = ...
            double(p.node);
    
        FeatureTraj_black(k).pos = ...
            double(p.pos);
    
        FeatureTraj_black(k).Metric = ...
            double(p.Metric);
    
        FeatureTraj_black(k).Scale = ...
            double(p.Scale);
    
        % Layer
        try
            if ~isempty(p.Layer)
                FeatureTraj_black(k).Layer = ...
                    double(p.Layer);
            end
        catch
        end
    
        % Octave
        try
            if ~isempty(p.Octave)
                FeatureTraj_black(k).Octave = ...
                    double(p.Octave);
            end
        catch
        end
    
    end
    fprintf('\n');
end