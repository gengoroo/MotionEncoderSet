%AdjustRFs
clear;
fprintf('This adjust animal RFs time length to artficial RF\n');
pn_main = fileparts(mfilename('fullpath'));
fn_datalocation = [mfilename(), '_datalocation.mat'];
%----------------------------------------------------------------------------------------
if exist([pn_main '\' fn_datalocation],'file')
    load([pn_main '\' fn_datalocation]);
end
if ~exist('pn_RFmap_SOM_def','var')
    pn_RFmap_SOM_def = 'C:\Users\gengoro\SynologyDrive\Behavior\CultureCells\2023-11-16 HEK LatA\8div2sec\MadeEnc_0_500_5000nM';
end
[fn_RFMap_SOM, pn_RFmap_SOM] = uigetfile(pn_RFmap_SOM_def,'select DataBase of synthetic RFMap');
pn_RFmap_SOM_def = pn_RFmap_SOM;
load([pn_RFmap_SOM, fn_RFMap_SOM]);
DataBase_SOM = DataBase;

if ~exist('pn_RFmap_natural_def','var')
    pn_RFmap_natural_def = pn_main;
elseif (pn_RFmap_natural_def == 0)
    pn_RFmap_natural_def = pn_main;
end
[fn_RFMap_natural, pn_RFmap_natural] = uigetfile(pn_RFmap_natural_def,'select DataBase of natural RFMap');
pn_RFmap_natural_def = pn_RFmap_natural;
load([pn_RFmap_natural, fn_RFMap_natural]);
DataBase_natural = DataBase;

%-----------
save([pn_main '\' fn_datalocation],'pn_RFmap_SOM_def','pn_RFmap_natural_def');% save default 
%----------------------------------------------------------------------------------------
MF_natural = DataBase2MF(DataBase_natural,'keyword','600ms','Range_frame',1:24);
nFrame_SOM = size(DataBase_SOM{1}.input.RFMap,3);
MF_SOM = DataBase2MF(DataBase_SOM,'keyword','SOM','Range_frame',1:nFrame_SOM);

ON_OFF_int_SOM = find_mean_interval(MF_SOM);
ON_OFF_int_natural = find_mean_interval(MF_natural);
rescale_ratio = ON_OFF_int_SOM/ON_OFF_int_natural;

nCell = size(MF_natural.RFMap,4);
for id_cell = 1:nCell
    V = MF_natural.RFMap(:,:,:,id_cell);
    V_resize = imresize3(V,[size(V,1),size(V,2),round(size(V,3)*rescale_ratio)]);
    MF_natural_resize.RFMap(:,:,:,id_cell) = V_resize;
    V = MF_natural.RF_black(:,:,:,id_cell);
    V_resize = imresize3(V,[size(V,1),size(V,2),round(size(V,3)*rescale_ratio)]);
    MF_natural_resize.RF_black(:,:,:,id_cell) = V_resize;
    V = MF_natural.RF_white(:,:,:,id_cell);
    V_resize = imresize3(V,[size(V,1),size(V,2),round(size(V,3)*rescale_ratio)]);
    MF_natural_resize.RF_white(:,:,:,id_cell) = V_resize;
end

%DataBaseに格納
DataBase_natural_rescaled{1}.input.RFMap = MF_natural_resize.RFMap;
DataBase_natural_rescaled{1}.input.RF_black = MF_natural_resize.RF_black;
DataBase_natural_rescaled{1}.input.RF_white = MF_natural_resize.RF_white;
for id_cell = 1:nCell
    DataBase_natural_rescaled{1}.Rank{id_cell} = 'S';
end
DataBase_natural_rescaled{1}.yn_good(1:nCell,1) = 1;
DataBase_natural_rescaled{1}.datasetname = '600ms';

figure('Name','rescaled RF_natural')
nFrame_rescale = size(DataBase_natural_rescaled{1}.input.RFMap,3);
for id_cell = 1:nCell
    for id_frame = 1:nFrame_rescale
        subplot(nCell,nFrame_rescale,nFrame_rescale*(id_cell-1)+id_frame);hold on;
        imagesc(MF_natural_resize.RFMap(:,:,id_frame,id_cell),[-10 10]);
    end
end
tightfig;

yn_save = input('Save RF_natural_rescaled y/n','s');
if yn_save == 'y'
    MF = MF_natural_resize;
    DataBase = DataBase_natural_rescaled;
    save([pn_RFmap_SOM 'DataBase_natural_rescaled.mat'],'MF','DataBase');
    h=gcf;
    saveas(h,[pn_RFmap_SOM 'DataBase_natural_rescaled.fig'],'fig')
end

function MF = DataBase2MF(DataBase,varargin)
    yn_flip_T = 'n';
    yn_invert_IM = 'n';
    keyword = '';
    for ii = 1:nargin - 1
        if strcmp('keyword',varargin{ii})
            keyword = varargin{ii+1};
        end
        if strcmp('Range_frame',varargin{ii})
            Range_frame = varargin{ii+1};
        end
    end
    SelRank = {'A','S'};

    counter = 0;
    for id_data = 1:numel(DataBase)
            
        nCell = size(DataBase{id_data}.input.RFMap,4);
        ListSel{id_data} =[];
        
        for id_cell = 1:nCell
            if ~isempty(strfind(DataBase{id_data}.datasetname,keyword))&& isfield(DataBase{id_data},'Rank')
                if numel(DataBase{id_data}.Rank) >= id_cell
                    if~isempty(intersect(SelRank,DataBase{id_data}.Rank{id_cell}))
                        ListSel{id_data} = [ListSel{id_data}, id_cell];
                        counter = counter +1;
                        if yn_flip_T == 'y'
                            MF.RFMap(:,:,:,counter) = DataBase{id_data}.input.RFMap(:,:,Range_frame,id_cell);
                            if isfield(DataBase{id_data}.input,'RF_black')
                                MF.RF_black(:,:,:,counter) = DataBase{id_data}.input.RF_black(:,:,Range_frame,id_cell);
                            end
                            if isfield(DataBase{id_data}.input,'RF_white')
                                MF.RF_white(:,:,:,counter) = DataBase{id_data}.input.RF_white(:,:,Range_frame,id_cell);
                            end
                        else
                            MF.RFMap(:,:,:,counter) = flip(DataBase{id_data}.input.RFMap(:,:,Range_frame,id_cell),3);
                            if isfield(DataBase{id_data}.input,'RF_black')
                                MF.RF_black(:,:,:,counter) = flip(DataBase{id_data}.input.RF_black(:,:,Range_frame,id_cell),3);
                            end
                            if isfield(DataBase{id_data}.input,'RF_white')
                                MF.RF_white(:,:,:,counter) = flip(DataBase{id_data}.input.RF_white(:,:,Range_frame,id_cell),3);
                            end
                        end
                        if yn_invert_IM == 'y'% invert OFFRF=> ON RF, ONRF=>OFF RF
                            MF.RFMap(:,:,:,counter) = -MF.RFMap(:,:,:,counter);
                            if isfield(DataBase{id_data}.input,'RF_black')
                                MF.RF_black(:,:,:,counter) = MF.RF_white(:,:,:,counter);
                            end
                            if isfield(DataBase{id_data}.input,'RF_white')
                                MF.RF_white(:,:,:,counter) = MF.RF_black(:,:,:,counter);
                            end
                        end
                    end
                end
            end  
        end
    end

end

function ON_OFF_int = find_mean_interval(MF)

    if ~isfield(MF,'RF_black')
        MF.RF_black = (abs(MF.RFMap) - MF.RFMap)/2;
    end
    if ~isfield(MF,'RF_white')
        MF.RF_white = (abs(MF.RFMap) + MF.RFMap)/2;
    end

    nFilter = size(MF.RFMap,4);
    %fprintf('N filteres of RFmap_SOM are %d\n',nFilter);

    
    ListSumOFf = reshape(sum(sum(MF.RF_black,2),1),size(MF.RF_black,3),size(MF.RF_black,4));
    ListSumON = reshape(sum(sum(MF.RF_white,2),1),size(MF.RF_white,3),size(MF.RF_white,4));
    
    for id_filter = 1:nFilter
        ListOFFPeakFrame(id_filter) = max(find(ListSumOFf(:,id_filter)==max(ListSumOFf(:,id_filter))));
        ListONPeakFrame(id_filter) = min(find(ListSumON(:,id_filter)==max(ListSumON(:,id_filter))));
        interval(id_filter) = abs(ListOFFPeakFrame(id_filter) - ListONPeakFrame(id_filter));
    end
    ON_OFF_int = mean(interval);
end


