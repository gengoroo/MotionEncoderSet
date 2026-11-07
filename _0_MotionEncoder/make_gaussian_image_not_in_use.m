function im = make_gaussian_image(GC, sigma, halfside)%XYT and cells
    w = halfside*2+1;
    [X, Y] = meshgrid(-halfside:1:halfside);
    im = 1/(sqrt(2*pi)*sigma) * exp((-(X-GC(1)).^2-(Y-GC(2)).^2)/(2*sigma^2));
end