function plot_traj(Points_Traj,color)
    for ii = 1:numel(Points_Traj)
        plot3(Points_Traj(ii).pos(:,1),Points_Traj(ii).pos(:,2),Points_Traj(ii).pos(:,3),'Color',color);
    end
end