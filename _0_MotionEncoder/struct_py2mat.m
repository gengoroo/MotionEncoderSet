function MatSruct = struct_py2mat(Py_Obj)

    ListFields = fieldnames(Py_Obj);
    fprintf('Converting py2structmat N=%d\n',numel(ListFields));
    fprintf('current N=');
    for id_field = 1:numel(ListFields)

        if (rem(id_field,20)==0)||(id_field==numel(ListFields))
            fprintf('%d ',id_field);
        end
    
        data = Py_Obj.(ListFields{id_field});
        MatSruct.(ListFields{id_field}) = double(data);
    
    end
    fprintf('\n');
end