%LeftFileCopySimple
clear;

%------------------------------------------------------------
mfn = mfilename('fullpath');
[pn_main, fn_main] = fileparts(mfn);
pn_def = '';
fn_datalocation = [fn_main,'_datalocation.mat'];
if exist([pn_main '\' fn_datalocation],'file')
    load([pn_main '\' fn_datalocation]);
end
if pn_def == 0
    pn_def = '';
end
pn_def = uigetdir(pn_def,'select paren folder of any source files');% change this for each code
save([pn_main '\' fn_datalocation],'pn_def');
%------------------------------------------------------------
pn = pn_def;
ext = input('type extensions \n','s');
ListFiles = dir(fullfile(pn, ['*.', ext]));

[fn_exc, pn_exc] = uigetfile(pn_def,'select exc file');
load([pn_exc '\' fn_exc]);

 if exist('ListLeft','var')
    ListCopy = ListLeft;
 else
    fprintf('making ListCopy from exc\n');
    ListCopy = 1:numel(ListFiles);
    for ii = 1:numel(exc)
        ListCopy(exc{ii}) = [];
    end
end

pn_save = [pn 'copy'];
mkdir(pn_save);
for ii = 1:numel(ListCopy)
    id_file = ListCopy(ii);
    copyfile([ListFiles(id_file).folder '\' ListFiles(id_file).name], [pn_save '\' ListFiles(id_file).name]);
end

