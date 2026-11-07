function Points_seq_black = Points_seq_py2mat(Points_seq_py_black)

    N = int64(py.len(Points_seq_py_black));
    
    Points_seq_black = struct( ...
        'seq',{}, ...
        'startframe',{}, ...
        'pos',{});
    
    fprintf('Converting Points_seq N=%d\n',N);
    fprintf('current N=');
    for k = 1:N

        if (rem(k,20)==0)||(k==N)
            fprintf('%d ',k);
        end
    
        pyObj = Points_seq_py_black{k};
    
        Points_seq_black(k).seq = ...
            double(py.numpy.array(pyObj.seq));
    
        Points_seq_black(k).startframe = ...
            double(pyObj.startframe);
    
        Points_seq_black(k).pos = ...
            double(pyObj.pos);
    
    end
    fprintf('\n');
end