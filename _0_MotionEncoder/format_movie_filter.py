import numpy as np


def format_moviefilter(
        MOV_onoff,
        Info_MOV_onoff,
        rep_value='mode'):

    # MATLAB:
    # side_max = max(Info_MOV_onoff.size(:,1));
    # dur_max  = max(Info_MOV_onoff.size(:,3));

    size_array = np.asarray(
        Info_MOV_onoff.size
    )

    side_max = int(
        np.max(size_array[:, 0])
    )

    dur_max = int(
        np.max(size_array[:, 2])
    )

    if rep_value == 'mode':

        side_mode = int(
            np.bincount(
                size_array[:, 0].astype(int)
            ).argmax()
        )

        dur_mode = int(
            np.bincount(
                size_array[:, 2].astype(int)
            ).argmax()
        )

    MOV_adjust = []

    for id_pair in range(
            len(MOV_onoff)):

        # MATLAB:
        # MOV_max=zeros(side_max,side_max,dur_max);

        MOV_max = np.zeros(
            (
                side_max,
                side_max,
                dur_max
            ),
            dtype=np.float32
        )

        movie = MOV_onoff[id_pair]

        side1 = movie.shape[0]
        side2 = movie.shape[1]
        dur = movie.shape[2]

        # MATLAB互換
        xy_start1 = max(
            int(
                np.floor(
                    (side_max - side1) / 2
                )
            ),
            1
        )

        xy_stop1 = (
            xy_start1
            + side1
            - 1
        )

        xy_start2 = max(
            int(
                np.floor(
                    (side_max - side2) / 2
                )
            ),
            1
        )

        xy_stop2 = (
            xy_start2
            + side2
            - 1
        )

        z_start = (
            dur_max
            - dur
            + 1
        )

        # MATLAB 1-origin → Python 0-origin

        MOV_max[
            xy_start1 - 1:xy_stop1,
            xy_start2 - 1:xy_stop2,
            z_start - 1:dur_max
        ] = movie

        xy_start_crop = max(
            int(
                np.ceil(
                    (
                        side_max
                        - side_mode
                    ) / 2
                )
            ),
            1
        )

        xy_stop_crop = (
            xy_start_crop
            + side_mode
            - 1
        )

        z_start_crop = (
            dur_max
            - dur_mode
            + 1
        )

        movie_crop = MOV_max[
            xy_start_crop - 1:
            xy_stop_crop,

            xy_start_crop - 1:
            xy_stop_crop,

            z_start_crop - 1:
            dur_max
        ]

        MOV_adjust.append(
            movie_crop
        )

    return MOV_adjust
