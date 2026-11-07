function Pair_mat = pair_py2mat(Pair_py)
    N = int64(py.len(Pair_py));
    
    Pair_mat = cell(1,N);

    fprintf('Converting Pair_mat N=%d\n',N);
    fprintf('current N=');
    for k = 1:N
        if (rem(k,20)==0)||(k==N)
            fprintf('%d ',k);
        end
        Pair_mat{k} = double(Pair_py{k});
    end
    fprintf('\n');
end