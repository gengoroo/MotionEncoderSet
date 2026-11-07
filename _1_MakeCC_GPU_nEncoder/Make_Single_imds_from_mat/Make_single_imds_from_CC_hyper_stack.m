% Make_single_imds_from_CC_hyper_stack
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
pn_def = uigetdir(pn_def,'select def folder to start search, grand parent pn of CC');
save([pn_main '\' fn_datalocation],'pn_def');
%------------------------------------------------------------
fn_CC_hyper_stack = 1;
fn_data = 1;
counter = 0;
ListLabels = categorical;
while(fn_data)
    counter = counter + 1;
    [fn_data, pn_data] = uigetfile([pn_def,'\*CC_hyper_stack.mat'],['select CC_hyper_stack.mat from ' num2str(counter) 'th Category']);
    if fn_data~=0
        List_fn_CC_hyper_stack{counter} = fn_data;
        List_pn_CC_hyper_stack{counter} = pn_data;
        ListLabels(counter) = input('Type Label\n','s');

        load([pn_data '\' fn_data],'CC_stack');
        CC_stack{1}(isnan(CC_stack{1})) = 0;%2023.11.20 エラー防止
        SumData = reshape(sum(sum(sum(CC_stack{1},3),2),1),[],1);

        nNeuron = size(CC_stack{1},3);
        for id_neuron = 1:nNeuron
            CC_stack_import{id_neuron} = [];
            for id_file = 1:numel(CC_stack)
                CC_stack{id_file}(isnan(CC_stack{id_file})) = 0;%2023.11.20　エラー防止
                CC_stack_import{id_neuron} = cat(3,CC_stack_import{id_neuron},CC_stack{id_file}(:,:,id_neuron,SumData>0));
            end
            ImData{counter,id_neuron} = CC_stack_import{id_neuron};
        end
    end
end
pn_save_top = uigetdir(pn_def,'select folder to save');

id_neuron = 1;
for id_class = 1:numel(ListLabels)
    nData(id_class) = size(ImData{id_class,id_neuron},3);
end

Labels = categorical;
for id_neuron = 1:nNeuron
    ImData_stack = [];
    for id_class = 1:numel(ListLabels)
        if id_class  == 1
            n_start = 1;
        else
            n_start = sum(nData(1:(id_class-1)))+1;
        end
        n_end = sum(nData(1:id_class));
        Labels(n_start:n_end) = ListLabels(id_class);
        ImData_stack = cat(3,ImData_stack,ImData{id_class,id_neuron});
    end
    pn_save = [pn_save_top '\CC_each_neuron\Neuron' num2str(id_neuron)];
    imds = make_imds_mat_tiff(ImData_stack,Labels,pn_save);
    save([pn_save '\imds.mat'],'imds');
    imds_stack{id_neuron} = imds;
end


