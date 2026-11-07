%SelectMovieFileFrames
clear;close all;

fprintf('Put all cropped movie files in a signle folder\n');

nAve = 100;

pn_def = 'C:\Users\gengoro\_Data';
pn = uigetdir(pn_def, '');
Info = dir(pn);
counter = 0;
for ii = 1:numel(Info)
    
    fn = Info(ii).name;
    if ~isempty(strfind(fn,'intensity.mat'))
        counter = counter + 1;
        ListMat{counter} = fn;
    end
end

Intensity_stack = [];
d_Intensity_stack = [];
d_Intensity_norm_stack = [];
for ii = 1:numel(ListMat)
    load([pn '\' ListMat{ii}]);

    d_Intensity = abs(d_Intensity);%Changed for abs version そのまま平均化したらキャンセルしてしまう。

    length = nAve*floor((numel(Intensity) - 1)/nAve);% cut rem
    Intensity_stack(:,ii) = mean(reshape(Intensity(1:length),nAve,[]),1); %average ~3sec
    d_Intensity_stack(:,ii) = mean(reshape(d_Intensity(1:length),nAve,[]),1); %average ~3sec 
    d_Intensity_norm_stack(:,ii) = mean(reshape(d_Intensity(1:length)./Intensity(1:length),nAve,[]),1); %average ~3sec
end
Intensity_all = reshape(Intensity_stack,[],1);
d_Intensity_all = reshape(d_Intensity_stack,[],1);
d_Intensity_norm_all = reshape(d_Intensity_norm_stack,[],1);

data_raw = Intensity_all-min(Intensity_all);
MIN = prctile(data_raw,1);% 1-99 prctile??
MAX = prctile(data_raw,99);% 1-99 prctile??
List1 = intersect(find(data_raw>=MIN),find(data_raw<=MAX));
data_int = data_raw(List1);

data_raw = d_Intensity_all-min(d_Intensity_all);
data_d = data_raw(List1);

data_raw = d_Intensity_norm_all-min(d_Intensity_norm_all);
data_d_norm = data_raw(List1);

figure('Name','int, d, norm_d');
subplot(1,3,1);
hist(data_int);
subplot(1,3,2);
hist(data_d);
subplot(1,3,3);
hist(data_d_norm);

select_range = input('1:xSTD 2:value 3:x absSTD');
switch select_range
    case 1
        RangeSTD = input('Type RangeSTD in 1x2 vector\n'); 
        RangeData = ['SD_' num2str(RangeSTD(1)) '_' num2str(RangeSTD(2))];
    case 2
        %RangeValue = input('Type Range value in 1x2 vector\n'); 
        %RangeData = [num2str(RangeValue(1)) '_' num2str(RangeValue(2))];
    case 3
        RangeAbsSTD = input('Type RangeAbsSTD in 1x2 vector\n'); 
        RangeData = ['SDabs_' num2str(RangeAbsSTD(1)) '_' num2str(RangeAbsSTD(2))];
end

switch select_range
    case 1
        data_d_process = data_d;
        data_d_process_norm = data_d_norm;
        
        Range_int = [mean(data_int) + RangeSTD(1) * std(data_int), mean(data_int) + RangeSTD(2) * std(data_int)];
        Range_d = [mean(data_d_process) + RangeSTD(1) * std(data_d_process), mean(data_d_process) + RangeSTD(2) * std(data_d_process)];
        Range_d_norm = [mean(data_d_process_norm) + RangeSTD(1) * std(data_d_process_norm), mean(data_d_process_norm) + RangeSTD(2) * std(data_d_process_norm)];
        
        List_int = intersect(find(data_int>=Range_int(1)), find(data_int<=Range_int(2)));
        List_d = intersect(find(data_d_process>=Range_d(1)), find(data_d_process<=Range_d(2)));
        List_d_norm = intersect(find(data_d_process_norm>=Range_d_norm(1)), find(data_d_process_norm<=Range_d_norm(2)));
    case 2 
        Range_int = input('Type RangeValue in 1x2 vector for intensity [] for all\n');
        Range_d = input('Type RangeValue in 1x2 vector for Range_d [] for all\n');
        Range_d_norm = input('Type RangeValue in 1x2 vector for Range_d_norm [] for all\n');
        
        
        data_d_process = data_d;
        data_d_process_norm = data_d_norm;
        
        if isempty(Range_int)
            Range_int = [0, max(data_int)];
        end
        if isempty(Range_d)
            Range_d = [0, max(data_d_process)];
        end
        if isempty(Range_d_norm)
            Range_d_norm = [0, max(data_d_process_norm)];
        end
        RangeData = ['_int' num2str(Range_d(1)) '_' num2str(Range_d(2)) '_d' num2str(Range_d(1)) '_' num2str(Range_d(2)) '_int' num2str(Range_d_norm(1)) '_d_norm' num2str(Range_d_norm(2))];

        List_int = intersect(find(data_int>=Range_int(1)), find(data_int<=Range_int(2)));
        List_d = intersect(find(data_d_process>=Range_d(1)), find(data_d_process<=Range_d(2)));
        List_d_norm = intersect(find(data_d_process_norm>=Range_d_norm(1)), find(data_d_process_norm<=Range_d_norm(2)));
    
    case 3
        data_d_process = abs(data_d);
        data_d_process_norm = abs(data_d_norm);
        
        Range_int = [mean(data_int) + RangeAbsSTD(1) * std(data_int), mean(data_int) + RangeAbsSTD(2) * std(data_int)];
        Range_d = [mean(data_d_process) + RangeAbsSTD(1) * std(data_d_process), mean(data_d_process) + RangeAbsSTD(2) * std(data_d_process)];
        Range_d_norm = [mean(data_d_process_norm) + RangeAbsSTD(1) * std(data_d_process_norm), mean(data_d_process_norm) + RangeAbsSTD(2) * std(data_d_process_norm)];
                
        List_int = intersect(find(data_int>=Range_int(1)), find(data_int<=Range_int(2)));
        List_d = intersect(find(data_d_process>=Range_d(1)), find(data_d_process<=Range_d(2)));
        List_d_norm = intersect(find(data_d_process_norm>=Range_d_norm(1)), find(data_d_process_norm<=Range_d_norm(2)));
end



select_parameter = input('1: dIM only 2:dIM & IM 3: dIM & IM & dIM norm\n');
switch select_parameter
    case 1
        List_total = List_d;
    case 2
        intersect(List_int,List_d);
    case 3
        List_total = intersect(intersect(List_int,List_d),List_d_norm);
end

List_total_stack(:,1) = ceil(List_total/size(Intensity_stack,1));
List_total_stack(:,2) = rem(List_total,size(Intensity_stack,1));
%------------------------------------------------------------------------------------------------------
h=figure('Name',['hist_intensity' RangeData]);
subplot(2,3,1);hold on;
title('Intensity all');

hist(data_int,[min(data_int):(max(data_int)-min(data_int))/100:max(data_int)]);
plot(mean(data_int),0,'*');
plot(Range_int(1),0,'+');
plot(Range_int(2),0,'+');

subplot(2,3,2);
hold on; title('dIntensity all');
hist(data_d_process,[min(data_d_process):(max(data_d_process)-min(data_d_process))/100:max(data_d_process)]);
plot(mean(data_d_process),0,'*');
plot(Range_d(1),0,'+');
plot(Range_d(2),0,'+');

subplot(2,3,3);
hold on; title('dIntensity norm all');
hist(data_d_process_norm,[min(data_d_process_norm):(max(data_d_process_norm)-min(data_d_process_norm))/100:max(data_d_process_norm)]);
plot(mean(data_d_process_norm),0,'*');
plot(Range_d_norm(1),0,'+');
plot(Range_d_norm(2),0,'+');

subplot(2,3,4);
hist(data_int(List_total),[min(data_int):(max(data_int)-min(data_int))/100:max(data_int)]);

subplot(2,3,5);
hist(data_d_process(List_total),[min(data_d_process):(max(data_d_process)-min(data_d_process))/100:max(data_d_process)]);

subplot(2,3,6);
hist(data_d_process_norm(List_total),[min(data_d_process_norm):(max(data_d_process_norm)-min(data_d_process_norm))/100:max(data_d_process_norm)]);
%------------------------------------------------------------------------------------------------------
save([pn,'\SelectCut_' RangeData '.mat'],'ListMat','nAve','Intensity_stack','d_Intensity_stack','d_Intensity_norm_stack','Range_int','Range_d','Range_d_norm',...
    'List_int','List_d','List_d_norm','List_total','List_total_stack','RangeData');
saveas(h,[pn,'\' h.Name '.fig'],'fig');