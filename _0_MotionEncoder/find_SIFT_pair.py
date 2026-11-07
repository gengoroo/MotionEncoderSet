import numpy as np
import matplotlib.pyplot as plt


class Struct:
    pass


# ==========================================================
# find_traj_by_pos
# ==========================================================
def find_traj_by_pos(
        List_POS,
        Traj,
        threshold):

    ListTrajPos = []
    ListTrajPos_ID = []

    for id_pos in range(List_POS.shape[0]):

        POS = List_POS[id_pos, 0:3]

        A = []

        for traj in Traj:

            dist2 = np.sum(
                (traj[:, 0:3] - POS) ** 2,
                axis=1
            )

            A.append(dist2)

        ListTraj = []

        for traj_number, dist2 in enumerate(A):

            if np.any(dist2 < threshold):

                #print(
                #    "hit traj",
                #    traj_number + 1,
                #    "idx",
                #    np.where(dist2 < threshold)[0] + 1
                #)

                # MATLAB互換
                ListTraj.append(
                    traj_number + 1
                )

        traj_pos = []
        traj_pos_id = []

        for ii, traj_number in enumerate(ListTraj):

            List_id_pos = np.where(
                A[traj_number - 1] < threshold
            )[0] + 1

            nfound = len(List_id_pos)

            if nfound == 0:
                continue

            traj_pos.append(
                np.column_stack([
                    np.full(
                        nfound,
                        traj_number
                    ),
                    List_id_pos
                ])
            )

            traj_pos_id.append(
                np.column_stack([
                    np.full(
                        nfound,
                        ii + 1
                    ),
                    List_id_pos
                ])
            )

        if len(traj_pos) == 0:

            ListTrajPos.append(
                np.empty(
                    (0, 2),
                    dtype=int
                )
            )

            ListTrajPos_ID.append(
                np.empty(
                    (0, 2),
                    dtype=int
                )
            )

        else:

            ListTrajPos.append(
                np.vstack(traj_pos)
            )

            ListTrajPos_ID.append(
                np.vstack(traj_pos_id)
            )

    return (
        ListTrajPos,
        ListTrajPos_ID
    )


# ==========================================================
# find_longest_traj
# ==========================================================
def find_longest_traj(
        ListTrajPos,
        Traj,
        EorL):

    n_pos = len(ListTrajPos)

    ListTrajPos_longest = np.zeros(
        (n_pos, 2),
        dtype=int
    )

    ListTrajPos_longest_ID = np.zeros(
        n_pos,
        dtype=int
    )

    for id_pos in range(n_pos):

        if len(ListTrajPos[id_pos]) == 0:

            ListTrajPos_longest[
                id_pos, :
            ] = [0, 0]

            ListTrajPos_longest_ID[
                id_pos
            ] = 0

            continue

        ListTraj = ListTrajPos[
            id_pos
        ][:, 0]

        if len(ListTraj) == 1:

            traj_earliest = 0
            traj_last = 0

        else:

            ListStart = []
            ListEnd = []

            for traj_no in ListTraj:

                data = Traj[
                    int(traj_no) - 1
                ]

                ListStart.append(
                    data[0, 2]
                )

                ListEnd.append(
                    data[-1, 2]
                )

            ListStart = np.asarray(
                ListStart
            )

            ListEnd = np.asarray(
                ListEnd
            )

            #print("-----")
            #print("id_pos =", id_pos)
            #print("ListTraj =", ListTraj)
            #print("ListStart =", ListStart)
            #print("ListEnd =", ListEnd)

            traj_earliest = np.where(
                ListStart ==
                np.min(ListStart)
            )[0][0]

            traj_last = np.where(
                ListEnd ==
                np.max(ListEnd)
            )[0][-1]

            #print(
            #    "traj_earliest =",
            #    traj_earliest
            #)

            #print(
            #    "traj_last =",
            #    traj_last
            #)

        if EorL == 'e':

            ListTrajPos_longest[
                id_pos, :
            ] = ListTrajPos[
                id_pos
            ][traj_earliest, :]

            ListTrajPos_longest_ID[
                id_pos
            ] = traj_earliest + 1

        else:

            ListTrajPos_longest[
                id_pos, :
            ] = ListTrajPos[
                id_pos
            ][traj_last, :]

            ListTrajPos_longest_ID[
                id_pos
            ] = traj_last + 1

    return (
        ListTrajPos_longest,
        ListTrajPos_longest_ID
    )

# ==========================================================
# plot_paird_traj
# ==========================================================
def plot_paird_traj(
        Traj_ref,
        ListTrajPos_ref,
        Traj_found,
        ListTrajPos_found):

    fig = plt.figure(
        "Paired trajectories"
    )

    ax = fig.add_subplot(
        111,
        projection="3d"
    )

    for ii in range(
            ListTrajPos_ref.shape[0]):

        id_traj_ref = int(
            ListTrajPos_ref[ii, 0]
        ) - 1

        traj_ref = Traj_ref[
            id_traj_ref
        ]

        ax.plot(
            traj_ref[:, 0],
            traj_ref[:, 1],
            traj_ref[:, 2],
            'k'
        )

        id_traj_found = int(
            ListTrajPos_found[ii, 0]
        ) - 1

        traj_found = Traj_found[
            id_traj_found
        ]

        ax.plot(
            traj_found[:, 0],
            traj_found[:, 1],
            traj_found[:, 2],
            'r'
        )

    plt.show(
        block=False
    )


# ==========================================================
# find_SIFT_pair
# ==========================================================
def find_SIFT_pair(
        Points_Traj_ref,
        Points_Traj_search,
        PairOverlap):

    Traj_ref = [
        traj.pos
        for traj in Points_Traj_ref
    ]

    Traj_found = [
        traj.pos
        for traj in Points_Traj_search
    ]

    match_threshold = 1.5

    ListTrajPos_ref_all, _ = (
        find_traj_by_pos(
            PairOverlap.ref.Location,
            Traj_ref,
            match_threshold
        )
    )

    ListTrajPos_ref_temp, _ = (
        find_longest_traj(
            ListTrajPos_ref_all,
            Traj_ref,
            'e'
        )
    )

    ListTrajPos_found_all, _ = (
        find_traj_by_pos(
            PairOverlap.found.Location,
            Traj_found,
            match_threshold
        )
    )

    ListTrajPos_found_temp, _ = (
        find_longest_traj(
            ListTrajPos_found_all,
            Traj_found,
            'l'
        )
    )

    mask = (
        ListTrajPos_ref_temp[:, 0]
        * ListTrajPos_ref_temp[:, 1]
        * ListTrajPos_found_temp[:, 0]
        * ListTrajPos_found_temp[:, 1]
    ) != 0

    ListExist = np.where(mask)[0]

    ListTrajPos_ref = (
        ListTrajPos_ref_temp[ListExist]
    )

    ListTrajPos_found = (
        ListTrajPos_found_temp[ListExist]
    )

    # デバッグ中は無効化
    # plot_paird_traj(
    #     Traj_ref,
    #     ListTrajPos_ref,
    #     Traj_found,
    #     ListTrajPos_found
    # )

    Points_Traj_pair = Struct()

    Points_Traj_pair.ref = [
        Points_Traj_ref[int(i) - 1]
        for i in ListTrajPos_ref[:, 0]
    ]

    Points_Traj_pair.found = [
        Points_Traj_search[int(i) - 1]
        for i in ListTrajPos_found[:, 0]
    ]

    for id_pair in range(
            len(
                Points_Traj_pair.ref
            )):

        traj_idx = (
            int(
                ListTrajPos_ref[
                    id_pair,
                    0
                ]
            ) - 1
        )

        pos_idx = (
            int(
                ListTrajPos_ref[
                    id_pair,
                    1
                ]
            ) - 1
        )

        Points_Traj_pair.ref[
            id_pair
        ].peak = (
            Points_Traj_ref[
                traj_idx
            ].pos[
                pos_idx,
                2
            ]
        )

        traj_idx = (
            int(
                ListTrajPos_found[
                    id_pair,
                    0
                ]
            ) - 1
        )

        pos_idx = (
            int(
                ListTrajPos_found[
                    id_pair,
                    1
                ]
            ) - 1
        )

        Points_Traj_pair.found[
            id_pair
        ].peak = (
            Points_Traj_search[
                traj_idx
            ].pos[
                pos_idx,
                2
            ]
        )

    print(
        "Npair =",
        len(
            Points_Traj_pair.ref
        )
    )

    return Points_Traj_pair

