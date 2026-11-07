function  plot_paird_traj_standalone(Points_Traj_pair)

    figure('Name','Paired trajectories');hold on;

    Pos_ref = Points_Traj_pair.ref.pos(:,1:3);
    Scale_ref = Points_Traj_pair.ref.Metric;
    Pos_found = Points_Traj_pair.found.pos(:,1:3);
    Metric_found = Points_Traj_pair.found.Metric;

    for ii = 1:size(Pos_ref,1)
        plot_circle_xy_3D(Pos_ref(ii,1) , Pos_ref(ii,2), Pos_ref(ii,3), Scale_ref(ii))
    end
    plot3(Pos_ref(:,1),Pos_ref(:,2),Pos_ref(:,3),'k-');
    plot3(Pos_found(:,1),Pos_found(:,2),Pos_found(:,3),'k--');

end

function plot_circle_xy_3D(x_center , y_center, z, r)
    theta = linspace(0, 2*pi, 100);
    x = x_center + r * cos(theta);
    y = y_center + r * sin(theta);
    z = repmat(z, 1, numel(x));
    plot3(x, y, z,'b-', 'LineWidth', 1);
    grid on;
end
