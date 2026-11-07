function Points_Traj_pair = find_SIFT_pair(Points_Traj_ref, Points_Traj_search, PairOverlap)

    for ii = 1:numel(Points_Traj_ref)
        Traj_ref{ii} = Points_Traj_ref(ii).pos;%cellfunが使えるようにまとめる。
    end
    for ii = 1:numel(Points_Traj_search)
        Traj_found{ii} = Points_Traj_search(ii).pos;%cellfunが使えるようにまとめる。
    end
    
    List_POS = PairOverlap.ref.Location;
    Traj = Traj_ref;
    match_threshold = 1.5;%1.5ピクセル以内なら合っていると判断
    [ListTrajPos_ref_all]  = find_traj_by_pos(List_POS,Traj,match_threshold);%[その点を通る軌跡＃データと、点は軌跡内の何番目にあるか]複数の軌跡がヒットする
    [ListTrajPos_ref_temp]= find_longest_traj(ListTrajPos_ref_all,Traj,'e');% より早いフレームからつながっているもの選択。
    
    List_POS = PairOverlap.found.Location;
    Traj = Traj_found;
    match_threshold = 1.5;%1.5ピクセル以内なら合っていると判断
    [ListTrajPos_found_all]= find_traj_by_pos(List_POS,Traj,match_threshold);%[その点を通る軌跡＃データと、点は軌跡内の何番目にあるか]複数の軌跡がヒットする
    [ListTrajPos_found_temp] = find_longest_traj(ListTrajPos_found_all,Traj,'l');%より後のフレームまでつながっているものを選択
    
    ListExist = find(ListTrajPos_ref_temp(:,1).*ListTrajPos_ref_temp(:,2).*ListTrajPos_found_temp(:,1).*ListTrajPos_found_temp(:,2));%乗っている軌跡があったもの
    ListTrajPos_ref = ListTrajPos_ref_temp(ListExist,:);
    ListTrajPos_found = ListTrajPos_found_temp(ListExist,:);
    plot_paird_traj(Traj_ref,ListTrajPos_ref,Traj_found,ListTrajPos_found);%ペアの軌跡の確認プロット
    
    Points_Traj_pair.ref = Points_Traj_ref(ListTrajPos_ref(:,1));%使うTrajectoryデータのみセレクト
    Points_Traj_pair.found = Points_Traj_search(ListTrajPos_found(:,1));
    for id_pair = 1:numel(Points_Traj_pair.ref)
        Points_Traj_pair.ref(id_pair).peak = Points_Traj_pair.ref(id_pair).pos(ListTrajPos_ref(id_pair,2),3);%peakが軌跡の何番目かのデータも入れてまとめる
        Points_Traj_pair.found(id_pair).peak = Points_Traj_pair.found(id_pair).pos(ListTrajPos_found(id_pair,2),3);
    end

end

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

function plot_paird_traj(Traj_ref,ListTrajPos_ref,Traj_found,ListTrajPos_found)
    figure('Name','Paired trajectories');hold on;
    for ii = 1:size(ListTrajPos_ref,1)
        id_traj = ListTrajPos_ref(ii,1);
        id_pos = ListTrajPos_ref(ii,2);
        plot3(Traj_ref{id_traj}(:,1),Traj_ref{id_traj}(:,2),Traj_ref{id_traj}(:,3),'k');
        text(Traj_ref{id_traj}(1,1),Traj_ref{id_traj}(1,2),Traj_ref{id_traj}(1,3),['#' num2str(id_traj)]);
        plot3(Traj_ref{id_traj}(id_pos,1),Traj_ref{id_traj}(id_pos,2),Traj_ref{id_traj}(id_pos,3),'k*');
    
        id_traj_ref = id_traj;
        id_pos_ref = id_pos;
    
        id_traj = ListTrajPos_found(ii,1);
        id_pos = ListTrajPos_found(ii,2);
        plot3(Traj_found{id_traj}(:,1),Traj_found{id_traj}(:,2),Traj_found{id_traj}(:,3),'r');
        text(Traj_found{id_traj}(1,1),Traj_found{id_traj}(1,2),Traj_found{id_traj}(1,3),['#' num2str(id_traj)], 'Color','r');
        plot3(Traj_found{id_traj}(id_pos,1),Traj_found{id_traj}(id_pos,2),Traj_found{id_traj}(id_pos,3),'r*');
        id_traj_found = id_traj;
        id_pos_found = id_pos;
    
        plot3([Traj_ref{id_traj_ref}(id_pos_ref,1),Traj_found{id_traj_found}(id_pos_found,1)],...
            [Traj_ref{id_traj_ref}(id_pos_ref,2),Traj_found{id_traj_found}(id_pos_found,2)],...
            [Traj_ref{id_traj_ref}(id_pos_ref,3),Traj_found{id_traj_found}(id_pos_found,3)], 'g');
    end
    legend({'ref','','found',''});
end