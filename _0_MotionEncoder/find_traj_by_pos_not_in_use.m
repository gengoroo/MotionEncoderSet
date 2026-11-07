function [ListTrajPos, ListTrajPos_ID] = find_traj_by_pos(List_POS,Traj,threshold)

    for id_pos = 1:size(List_POS,1)
        POS = List_POS(id_pos,1:3);
        A = cellfun(@(x) sum((x(:,1:3)-POS).^2,2), Traj, 'UniformOutput', false);
        ListTraj = find(cellfun(@(x) ~isempty(find(x<threshold)) , A));
        ListTrajPos{id_pos} = [];
        ListTrajPos_ID{id_pos} = [];
        for ii = 1:numel(ListTraj)
            traj_number = ListTraj(ii);
            List_id_pos = find(A{traj_number}<threshold);
            nfound = numel(List_id_pos);
            ListTrajPos{id_pos} = [ListTrajPos{id_pos}; repmat(traj_number,nfound,1), List_id_pos];
            ListTrajPos_ID{id_pos} = [ListTrajPos_ID{id_pos}; repmat(ii,nfound,1), List_id_pos];
        end
    end
    
end