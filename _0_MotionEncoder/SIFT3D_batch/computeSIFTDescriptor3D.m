function [metric, descriptor] = computeSIFTDescriptor3D(IM, x, y, z, scale, orientation, varargin)

    for ii = 1:nargin - 6
        Gradient3D = varargin{ii};
    end
    
    % ????????
    num_bins = 8; % ??????????????
    window_size = 4; % ??????????????
    descriptor_size = window_size * window_size * window_size * num_bins; % ???????????

    % ???????????
    descriptor = zeros(1, descriptor_size);

    % ????????????????????????
    half_window = window_size / 2;
    [X, Y, Z] = meshgrid(-half_window:half_window, -half_window:half_window, -half_window:half_window);

    % ?????????????
    if exist('Gradient3D','var')
        Gx = Gradient3D{1};
        Gy = Gradient3D{2};
        Gz = Gradient3D{3};
        %fprintf('Gradient3D is pre-calculated\n');
    else
        [Gx, Gy, Gz] = gradient(double(IM));% varargin??????????
    end
    for i = 1:numel(X)
        % ????????
        xi = round(x + X(i) * scale);
        yi = round(y + Y(i) * scale);
        zi = round(z + Z(i) * scale);

        % ?????????
        if xi > 0 && xi <= size(IM, 1) && yi > 0 && yi <= size(IM, 2) && zi > 0 && zi <= size(IM, 3)
            % ?????
            %[gx, gy, gz] = gradient(double(IM(xi, yi, zi)));
            
            gx = Gx(xi, yi, zi);
            gy = Gy(xi, yi, zi);
            gz = Gz(xi, yi, zi);
            gradient_magnitude = sqrt(gx^2 + gy^2 + gz^2); 
            gradient_orientation = atan2(gy, gx);

            % ?????????????????????
            adjusted_orientation = gradient_orientation - orientation;
            adjusted_orientation = mod(adjusted_orientation + pi, 2 * pi) - pi; % -pi??pi??????

            % ???????????????????
            bin = mod(floor((adjusted_orientation + pi) / (2 * pi) * num_bins), num_bins) + 1;
            descriptor(bin) = descriptor(bin) + gradient_magnitude;
        end
    end

    % ???
    descriptor_norm = descriptor / norm(descriptor);

    % ???????????
    descriptor_norm(descriptor_norm > 0.2) = 0.2;
    descriptor_norm = descriptor_norm / norm(descriptor_norm);
    
    metric = sqrt(sum(descriptor.^2, 2));
end