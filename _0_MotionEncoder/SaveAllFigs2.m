% ショ?[トカットの概要をここに記?q
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fn= mfilename('fullpath');
path_program= fn(1:(max(strfind(fn,'\')-1)));
fn_program = fn((max(strfind(fn,'\')+1)):end);
fn_path = [fn_program '_path.mat'];%プ?グラム毎に違うパス?ﾝ定ファイルが??轤黷?B
data_path=[];
if exist(fn_path,'file')>0
    load([path_program '\' fn_path]);
end

try
    pn_dif = uigetdir(data_path,'select dir to save');
catch
    pn_dif = uigetdir('','select dir to save');
end

data_path = pn_dif;
save([path_program '\' fn_path],'data_path');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ListFig_save = input('Type List fig to save\n');

for ii = 1:numel(ListFig_save)
    id_fig = ListFig_save(ii);
    h=figure(id_fig);
    if ~isempty(h.Name)
        name = h.Name;
    else
        name = num2str(id_fig);
    end
    saveas(h,[pn_dif '\' name '.fig'],'fig');
end
