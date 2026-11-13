pn = uigetdir('','Select pn of movies');
pn_save = [pn '_2'];
if ~exist(pn_save,'dir')
    mkdir(pn_save);
end

oldStr = input('Type str before\n','s');
newStr = input('Type str after\n','s');

L = dir(fullfile(pn,'*'));

for i = 1:length(L)

    if L(i).isdir
        continue
    end

    fn_old = L(i).name;

    if contains(fn_old, oldStr)

        fn_new = strrep(fn_old, oldStr, newStr);

        copyfile( ...
            fullfile(pn, fn_old), ...
            fullfile(pn_save, fn_new) );

        fprintf('%s -> %s\n', fn_old, fn_new);
    else
        copyfile( ...
            fullfile(pn, fn_old), ...
            fullfile(pn_save, fn_old) );

    end
end