function ListSliceSel = select_SliceOf(dOFFvsON)
    for id_y = 1:size(dOFFvsON,1)
        for id_x = 1:size(dOFFvsON,2)
            for id_cut = 1:size(dOFFvsON,5)
                data = dOFFvsON(id_y,id_x,:,:,id_cut);%id_filter, id_shift
                nCell = size(data,3);
                nShift = size(data,4);
                data = reshape(data,nCell,nShift);
                [~, order] = sort(data,1,'descend');%それぞれのグリッドのフィルターが何番目に大きいか。
                list_order_sum = sum(order,1);%すべてのフィルターについての順位を合計する
                ListSliceSel(id_y,id_x,id_cut) = min(find(list_order_sum == min(list_order_sum)));%
            end
        end
    end
end