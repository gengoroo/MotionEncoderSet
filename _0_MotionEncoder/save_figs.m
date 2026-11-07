function save_figs(ListFig,pn_save)
    for ii = 1:numel(ListFig)
        saveas(ListFig(ii),[pn_save '\' ListFig(ii).Name '.fig'], 'fig');
    end
end