%Plot_merge
close all;
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
pn_def = uigetdir(pn_def,'select pn for copysorce');
save([pn_main '\' fn_datalocation],'pn_def');

%------------------------------------------------------------

[List_fn_fig, pn] = uigetfile(pn_def,'select fig to merge','multiselect','on');
n_ave = input('Type n of movememean');
h_copy = figure('Name','merged lines','Color','w');hold on;
for id_fn = 1:numel(List_fn_fig)
    openfig([pn, '\', List_fn_fig{id_fn}]);
    h=gcf;
    List_copyline = findall(h,'Type','Line','LineStyle','-');

    smoothline(List_copyline,h_copy,n_ave,List_fn_fig{id_fn});
end

function smoothline(List_smooth,h_copy,n_ave,List_fn_fig)
    for ii = 1:numel(List_smooth)
        XData = List_smooth(ii).XData;
        YData = List_smooth(ii).YData;
        YData_new = movmean(YData, n_ave);
        figure(h_copy);
        h = plot(XData,YData_new,'.');
        h.Color = List_smooth(ii).Color*0.75;
        h.LineStyle = '-';
        h.LineWidth = 1.5;%List_smooth(ii).LineWidth;
        h.Marker = List_smooth(ii).Marker;
        h.MarkerSize = List_smooth(ii).MarkerSize;
        h.Marker = List_smooth(ii).Marker;

        text(XData(end),YData_new(end),List_fn_fig);
    end
end
