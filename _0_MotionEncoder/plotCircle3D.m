function plotCircle3D(center,normal,radius,Color)
    if isempty(Color)
        Color = 'r';
    end
    theta=0:0.01:2*pi;
    v=null(normal);
    points=repmat(center',1,size(theta,2))+radius*(v(:,1)*cos(theta)+v(:,2)*sin(theta));
    try
        plot3(points(1,:),points(2,:),points(3,:),'Color',Color);
    catch
        void=input('type enter to skip drawing error\n');
    end
end