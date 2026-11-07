 function plot_salient(Salient_black, Salient_white, All_black, All_white)
        
        figure('Name','Salient Scale black white','Color','w');
        subplot(1,2,1);
        title('All Scale ONOFF');hold on;
        normal = [0 0 1];%法線ベクトル
        MetStack = [All_black.Metric;All_white.Metric];
        for ii = 1:size(All_black.Pos,1)
            factor = 0.5+0.5*(All_black.Metric(ii)- min(MetStack))/(max(MetStack) - min(MetStack));
            plotCircle3D(All_black.Pos(ii,:),normal,3*1.5*All_black.Scale(ii),[0 1 0]*factor);%3σで裾まで表示
        end
        for ii = 1:size(All_white.Pos,1)
            factor = 0.5+0.5*(All_white.Metric(ii)- min(MetStack))/(max(MetStack) - min(MetStack));
            plotCircle3D(All_white.Pos(ii,:),normal,3*1.5*All_white.Scale(ii),[1 0 0]*factor);%3σで裾まで表示
        end

        subplot(1,2,2);
        title('Salient Scale ONOFF'); hold on;
        plot3(All_black.Pos(:,1),All_black.Pos(:,2),All_black.Pos(:,3),'g.');
        plot3(All_white.Pos(:,1),All_white.Pos(:,2),All_white.Pos(:,3),'r.');  
        
        normal = [0 0 1];%法線ベクトル
        MetStack = Salient_black.Metric;
        for ii = 1:size(Salient_black.Pos,1)
            factor = (Salient_black.Metric(ii)- min(MetStack))/(max(MetStack) - min(MetStack));
            plotCircle3D(Salient_black.Pos(ii,:),normal,3*1.5*Salient_black.Scale(ii),[0 0.7 0]*factor + [0 0.3 0]);%3σで裾まで表示
        end

        MetStack = Salient_white.Metric;
        for ii = 1:size(Salient_white.Pos,1)
            factor = (Salient_white.Metric(ii)- min(MetStack))/(max(MetStack) - min(MetStack));
            plotCircle3D(Salient_white.Pos(ii,:),normal,3*1.5*Salient_white.Scale(ii),[0.7 0 0]*factor + [0.3 0 0]);%3σで裾まで表示
        end
        legend({'OFF','ON'});

    end