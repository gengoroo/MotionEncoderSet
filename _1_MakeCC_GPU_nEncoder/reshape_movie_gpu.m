%reshape_movie_gpu

% f_MakeMovieFilterSeq3x3_cube_RAMskip.mのL293のMovie_resizeをもっと大きなスタックにする。
% movieセットは２sec x 136 fileで390MB
clear;

nGrid = 10;
side_rf = 20;
cut_duration = 0.6;
sec_filter_frame = 0.025;

side_filter = nGrid*side_rf;

pn ='C:\Users\gengoro\SynologyDrive\Behavior\CultureCells\2023-11-16 HEK LatA\8div2sec\LatA0000uM';
List_fn_movie = dir(fullfile(pn,'\*.avi'));
pn_movie = List_fn_movie(1).folder;

Movie_deriv_cat = [];
counter = 0;
nMovie = numel(List_fn_movie);
for id_movie = 1:nMovie
    fprintf('%d percent of %d movies\n',round(100*id_movie/nMovie),nMovie);

    fn_movie = List_fn_movie(id_movie).name;

    [Movie_Mat, ListFrame_startstop{id_movie},nCut(id_movie)] = movie2mat(pn_movie, fn_movie, sec_filter_frame,cut_duration);% skip ramdisk New 2023.1.5
    Movie_deriv_Mat = Movie_Mat(:,:,2:end) -  Movie_Mat(:,:,1:end-1);
    Movie_deriv_resize = resize(Movie_deriv_Mat,[side_filter,side_filter]);

    ListFrame_cat = [];
    for id_cut = 2:nCut(id_movie)-1% to prevent stick out, dMovie's frame is 1frame smaller than Movie, which generated nCut(ii)
        add_frame = round(ListFrame_startstop{id_movie}(1,id_cut):ListFrame_startstop{id_movie}(2,id_cut));
        ListFrame_cat = [ListFrame_cat, add_frame];

        counter = counter + 1;
        ListFn{counter} = fn_movie;
        ListCutNumber(counter) = id_cut;
        ListFrameEnd(counter) = numel(ListFrame_cat);
    end
    Movie_deriv_cat = cat(3,Movie_deriv_cat,(Movie_deriv_resize(:,:,ListFrame_cat)));
end

