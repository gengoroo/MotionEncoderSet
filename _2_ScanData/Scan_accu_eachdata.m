clear;
pn_parent = uigetdir('C:\Users\gengoro\Desktop\sel2SandBox\movie_all\DeepLearn\CC_var_hyper_3ChStack');
pn_save_top = uigetdir('C:\Users\gengoro\Desktop\sel2SandBox\movie_all\DeepLearn\Scan','select parent folder of label folder');
[~, savename] = fileparts(pn_parent);
pn_save = [pn_save_top '\' savename];
if ~exist(pn_save,'dir')
    mkdir(pn_save);
end

nRepeat = input('How many time to repeat trim\n');
for kk = 1:nRepeat
    
    if kk == 1
        [ListScore, ListL, Val, Tr, NetStack, ListEndN] = accu_eachdata(pn_parent);
        nTotal = ListEndN(end);
    else
        [ListScore, ListL, Val, Tr, NetStack, ListEndN] = accu_eachdata(pn_parent,'exc',exc,'yn_figure','y');
    end
    exc{kk} = ListL.val{2};
    ListLeft{kk} = find_Left(exc, nTotal);
    
    h=gcf;
    for ii = h.Number-2:h.Number
        h2 = figure(ii);
        saveas(h2,[pn_save, '\cycle' num2str(kk) '_' h2.Name '.fig'],'fig');
        save([pn_save ,'\Cycle' num2str(kk) '.mat'],'exc','ListLeft','ListL');
    end
end

function ListLeft = find_Left(exc, nTotal)
    ListLeft = 1:nTotal;
    for ii = 1:numel(exc)
        ListLeft(exc{ii}) = [];
    end
end