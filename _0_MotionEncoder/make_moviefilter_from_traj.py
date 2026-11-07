from dataclasses import dataclass, field
import numpy as np


@dataclass
class MovieInfo:

    pix_max: list = field(default_factory=list)
    pix_min: list = field(default_factory=list)
    size: list = field(default_factory=list)


def make_gaussian_image(
        GC,
        sigma,
        halfside):

    X, Y = np.meshgrid(
        np.arange(-halfside, halfside + 1),
        np.arange(-halfside, halfside + 1)
    )

    im = (
        1.0
        / (np.sqrt(2 * np.pi) * sigma)
        * np.exp(
            (
                -(X - GC[0])**2
                - (Y - GC[1])**2
            )
            / (2 * sigma**2)
        )
    )

    return im


def make_moviefilter_from_traj(
        Points_Traj_ref_pair,
        Points_Traj_found_pair,
        margin_start,
        margin_stop,
        ref_wb):

    MOV_onoff = []

    Info = MovieInfo()

    print(
        "Npair =",
        len(Points_Traj_ref_pair)
    )

    for id_pair in range(
            len(Points_Traj_ref_pair)):

        print(
            "\n===== Pair",
            id_pair,
            "====="
        )

        traj_ref = Points_Traj_ref_pair[id_pair]
        traj_found = Points_Traj_found_pair[id_pair]

        List_z_found = traj_found.pos[:, 2]
        List_z_ref = traj_ref.pos[:, 2]

        z_peak_1st = traj_found.peak
        z_peak_2nd = traj_ref.peak

        print(
            "peak_found =",
            z_peak_1st
        )

        print(
            "peak_ref =",
            z_peak_2nd
        )

        print(
            "List_z_ref min/max =",
            np.min(List_z_ref),
            np.max(List_z_ref)
        )

        print(
            "List_z_found min/max =",
            np.min(List_z_found),
            np.max(List_z_found)
        )

        print(
            "exact match =",
            np.any(
                List_z_ref == z_peak_2nd
            )
        )

        print(
            "isclose match =",
            np.any(
                np.isclose(
                    List_z_ref,
                    z_peak_2nd
                )
            )
        )

        frameid_ref = np.where(
            np.isclose(
                List_z_ref,
                z_peak_2nd
            )
        )[0]

        print(
            "frameid_ref.size =",
            frameid_ref.size
        )

        if frameid_ref.size == 0:

            print(
                "SKIP pair because peak frame not found"
            )

            continue

        frameid_ref = frameid_ref[0]

        z_start = (
            z_peak_1st
            - margin_start
        )

        z_stop = (
            z_peak_2nd
            + margin_stop
        )

        ListFrames_abs = np.arange(
            z_start,
            z_stop + 1
        )

        Cen = traj_ref.pos[
            frameid_ref,
            :
        ]

        sigma_ori = (
            traj_ref.Scale[
                frameid_ref
            ]
            * 1.5
        )

        halfside = int(
            np.round(
                sigma_ori * 4
            )
        )

        print(
            "halfside =",
            halfside
        )

        movie_list = []

        for frame_abs in ListFrames_abs:

            frameid = np.where(
                np.isclose(
                    List_z_found,
                    frame_abs
                )
            )[0]

            if frameid.size > 0:

                frameid = frameid[0]

                GC = traj_found.pos[
                    frameid,
                    0:2
                ]

                sigma = (
                    traj_found.Scale[
                        frameid
                    ]
                    * 1.5
                )

                IM_found = make_gaussian_image(
                    GC - Cen[0:2],
                    sigma,
                    halfside
                )

            else:

                IM_found = np.zeros(
                    (
                        2 * halfside + 1,
                        2 * halfside + 1
                    )
                )

            frameid = np.where(
                np.isclose(
                    List_z_ref,
                    frame_abs
                )
            )[0]

            if frameid.size > 0:

                frameid = frameid[0]

                GC = traj_ref.pos[
                    frameid,
                    0:2
                ]

                sigma = (
                    traj_ref.Scale[
                        frameid
                    ]
                    * 1.5
                )

                IM_ref = make_gaussian_image(
                    GC - Cen[0:2],
                    sigma,
                    halfside
                )

            else:

                IM_ref = np.zeros(
                    (
                        2 * halfside + 1,
                        2 * halfside + 1
                    )
                )

            if str(ref_wb) == "b":

                frame_out = (
                    IM_found
                    - IM_ref
                )

            elif str(ref_wb) == "w":

                frame_out = (
                    IM_ref
                    - IM_found
                )

            else:

                raise ValueError(
                    f"ref_wb={ref_wb}"
                )

            movie_list.append(
                frame_out
            )

        print(
            "movie_list length =",
            len(movie_list)
        )

        if len(movie_list) == 0:

            print(
                "SKIP because movie_list empty"
            )

            continue

        movie = np.stack(
            movie_list,
            axis=2
        )

        print(
            "movie shape =",
            movie.shape
        )

        MOV_onoff.append(
            movie
        )

        Info.pix_max.append(
            np.max(movie)
        )

        Info.pix_min.append(
            np.min(movie)
        )

        Info.size.append(
            movie.shape
        )

    print(
        "TOTAL MOVIES =",
        len(MOV_onoff)
    )

    return MOV_onoff, Info