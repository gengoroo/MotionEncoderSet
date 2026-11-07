function Points_z = sift_py2mat(PointsPy_z)

    N = size(PointsPy_z,2);
    Points_z = cell(1,N);

    for id_z = 1:N
    
        pyFeature = PointsPy_z{id_z};
        feature = struct();
    
        feature.Location = double(pyFeature.Location);
        feature.Metric   = double(pyFeature.Metric)';
        feature.Scale    = double(pyFeature.Scale)';
    
        Points_z{id_z} = feature;
    
    end
end