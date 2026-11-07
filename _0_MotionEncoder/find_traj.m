function [Traj_hit, Input_hit] = find_traj(Points_Traj,List_frame_search,List_node_search)

    Traj_hit = [];
    Input_hit =[];
    for id_search = 1:numel(List_frame_search)
        id_frame = List_frame_search(id_search);
        id_node = List_node_search(id_search);

        for id_pos = 1:numel(Points_Traj)
            ListFrame{id_pos} = Points_Traj(id_pos).ListFrame;
            ListNode{id_pos} = Points_Traj(id_pos).node;
        end
        
        FlagFrame = zeros(1,numel(ListFrame));
        FlagFrame(cellfun(@(x) ~isempty(intersect(x,id_frame)), ListFrame)) = 1;
        FlagNode = zeros(1,numel(ListFrame));
        FlagNode(cellfun(@(x) ~isempty(intersect(x,id_node)), ListNode)) = 1;
        
        List_Traj_hit = find(FlagFrame.*FlagNode);
        ListN = cellfun(@numel, ListNode(List_Traj_hit));

        if ~isempty(List_Traj_hit)
            Traj_hit(id_search) = min(List_Traj_hit(find(ListN == max(ListN))));%一番長くて、番号の若いもの
            Input_hit = [Input_hit, id_search];
        else
            Traj_hit(id_search) = 0;
        end
    
    end

end


