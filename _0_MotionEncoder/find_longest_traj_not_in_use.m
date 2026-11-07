function [ListTrajPos_longest, ListTrajPos_longest_ID] = find_longest_traj(ListTrajPos,Traj,EorL)

    for id_pos = 1:numel(ListTrajPos)
        if isempty(ListTrajPos{id_pos})
            ListTrajPos_longest(id_pos,:) = [0, 0];
            ListTrajPos_longest_ID(id_pos) = 0;
        else
            ListTraj = ListTrajPos{id_pos}(:,1);%traj番号
            
            if numel(ListTraj) == 1
                traj_earliest = 1;
                traj_last = 1;
            else
                clear ListStart;%ループで消去されない
                clear ListEnd;%ループで消去されない
                for id_traj = 1:numel(ListTraj)
                    data = Traj{ListTraj(id_traj)};
                    ListStart(id_traj) = data(1,3);
                    ListEnd(id_traj) = data(end,3);
                end
                traj_earliest = min(find(ListStart == min(ListStart)));
                traj_last = max(find(ListEnd == max(ListEnd)));
            end
    
            if EorL == 'e'
                ListTrajPos_longest(id_pos,:) = ListTrajPos{id_pos}(traj_earliest,:);
                ListTrajPos_longest_ID(id_pos) = traj_earliest;
            else
                ListTrajPos_longest(id_pos,:) = ListTrajPos{id_pos}(traj_last,:);
                ListTrajPos_longest_ID(id_pos) = traj_last;
            end
        end
    end

end