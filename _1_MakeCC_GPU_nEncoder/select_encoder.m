function [MF, addtag] = select_encoder(MF,varargin)

    fn_full_RFMap = 'C:a.txt';
    for ii = 1:nargin-1
        if strcmp('fn_full_RFMap', varargin{ii})
            fn_full_RFMap = varargin{ii+1};
        end
    end

    nFilter_all = size(MF.RFMap,4);
    fprintf('N of encoders are %d\n',nFilter_all);
    selector = input('1:all encoders 2:Automatic selection by specifying N# of encoders 3:manual select []=1\n');
    if isempty(selector)
        selector = 1;
    end
    
    switch selector
        case 1
            ListUsedEncoderID = 1:nFilter_all;
            addtag = ['_AllEn' num2str(nFilter_all)];
            
        case 2
            nEncoder = input('How many encoder to use 1,2,4,9,16,25,36...:2orSquare(int)\n');
            nFilter = nEncoder;

            sel_som_data = input('1: meshgrid selection(good) 2: k mean centers [requires netSOM](OK) 3: max diversity [requires netSOM](bad) 4:random(OK), just enter=1\n');
            if isempty(sel_som_data)
                sel_som_data = 1;
            end
            switch sel_som_data %2026_11_04
                case 1 %2026_11_04
                    selectedNode = select_node('N',nEncoder,'N_total',nFilter_all);
                    ListUsedEncoderID = selectedNode.meshgrid;
                    addtag = ['_En' num2str(nEncoder) '_mesh'];
                case 2 %2026_11_04
                    [fn_som,pn_som] = uigetfile(fileparts(fn_full_RFMap),'select DataBase_SOM.mat');
                    load([pn_som, fn_som],'DataBase_SOM');
                    tag_selectWB = fn_full_RFMap(end-5:end-4);
                    if strcmp(tag_selectWB,'_b')
                        selectWB = 'b';
                    elseif strcmp(tag_selectWB,'_w')
                        selectWB = 'w';
                    else
                        selectWB = input('Type b: OFF center RF w: ON center RF\n','s');
                    end
                    fprintf('%s- center RF is selected\n',selectWB);

                    netSOM = DataBase_SOM.(selectWB).net{1};
                    selectedNode = select_node('N',nEncoder,'netSOM',netSOM);
                    ListUsedEncoderID = selectedNode.kmean;
                    addtag = ['_En' num2str(nEncoder) '_kmean'];
                case 3 %2026_11_04
                     [fn_som,pn_som] = uigetfile(fileparts(fn_full_RFMap),'select DataBase_SOM.mat');
                    load([pn_som, fn_som],'DataBase_SOM');
                    tag_selectWB = fn_full_RFMap(end-5:end-4);
                    if strcmp(tag_selectWB,'_b')
                        selectWB = 'b';
                    elseif strcmp(tag_selectWB,'_w')
                        selectWB = 'w';
                    else
                        selectWB = input('Type b: OFF center RF w: ON center RF\n','s');
                    end
                    fprintf('%s- center RF is selected\n',selectWB);

                    netSOM = DataBase_SOM.(selectWB).net{1};
                    selectedNode = select_node('N',nEncoder,'netSOM',netSOM);
                    ListUsedEncoderID = selectedNode.maxdiv;
                    addtag = ['_En' num2str(nEncoder) '_maxdiv'];
                case 4
                    nState = input('Type random state number []=0\n');
                    if isempty(nState)
                        nState = 0;
                    end
                    addtag = ['_En' num2str(nEncoder) '_rnd' num2str(nState)];
                    
                    rand('state',nState);
                    ListEncoderRandom =  randperm(nFilter_all,nFilter_all);
                    ListUsedEncoderID = ListEncoderRandom(1:nEncoder);
            end
            ListUsedEncoderID = unique(sort(ListUsedEncoderID,'ascend'));%2026_11_04 類似するもの近く
            fprintf('Selected Encoders are ');
            fprintf('%d,',ListUsedEncoderID);
            fprintf('\n');

            if nEncoder == 0
                ListUsedEncoderID = 0;
                nFilter = 1;
                MF.RFMap = ones(size(MF.RFMap,1), size(MF.RFMap,2),size(MF.RFMap,3),1);
                MF.RF_black = ones(size(MF.RFMap,1), size(MF.RFMap,2),size(MF.RFMap,3),1);
                MF.RF_white = ones(size(MF.RFMap,1), size(MF.RFMap,2),size(MF.RFMap,3),1);
            end

            if nEncoder == 2
                ListUsedEncoderID = [ListUsedEncoderID(1), ListUsedEncoderID(2), ListUsedEncoderID(1), ListUsedEncoderID(2)];
                nFilter = 4;
            end
 
            if nEncoder >= 1
                MF.RFMap = MF.RFMap(:,:,:,ListUsedEncoderID);
                MF.RF_black = MF.RF_black(:,:,:,ListUsedEncoderID);
                MF.RF_white = MF.RF_white(:,:,:,ListUsedEncoderID);
            end
            
        case 3
            ListUsedEncoderID = input('Type encoder# list\n');
            nFilter = numel(ListUsedEncoderID);
            addtag = ['_En_manusel' num2str(nFilter)];
            
            MF.RFMap = MF.RFMap(:,:,:,ListUsedEncoderID);
            MF.RF_black = MF.RF_black(:,:,:,ListUsedEncoderID);
            MF.RF_white = MF.RF_white(:,:,:,ListUsedEncoderID);
            
    end
    
    MF.ListUsedEncoderID = ListUsedEncoderID;

end