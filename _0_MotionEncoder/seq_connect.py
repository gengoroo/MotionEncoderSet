from dataclasses import dataclass, field
import numpy as np


@dataclass
class FeatureSequence:

    seq: list = field(default_factory=list)

    startframe: int = 0

    pos: np.ndarray = field(
        default_factory=lambda: np.empty((0, 2))
    )


def seq_connect(
        Pair,
        Points=None,
        yn_plot=False):

    FeatureSeq = []

    list_active_seq = []

    if yn_plot:

        import matplotlib.pyplot as plt

        cmap = plt.cm.jet(
            np.linspace(0, 1, 200)
        )

        plt.figure()

    for id_frame in range(len(Pair)):

        # MATLAB:
        # previous_ends = []
        previous_ends = []

        for id_active in list_active_seq:

            previous_ends.append(
                FeatureSeq[id_active].seq[-1]
            )

        previous_ends = np.array(
            previous_ends,
            dtype=np.int32
        )

        pair_now = Pair[id_frame]

        # MATLAB:
        # if isempty(Pair{id_frame})

        if pair_now.size == 0:

            list_active_seq = []

            continue

        start_ends = pair_now[:, 0]
        stop_ends = pair_now[:, 1]

        # ---------------------------------
        # extend existing sequences
        # ---------------------------------

        common_values = np.intersect1d(
            previous_ends,
            start_ends
        )

        ia = []
        ib = []

        for value in common_values:

            ia.append(
                np.where(
                    previous_ends == value
                )[0][0]
            )

            ib.append(
                np.where(
                    start_ends == value
                )[0][0]
            )

        for k in range(len(ia)):

            seq_id = list_active_seq[
                ia[k]
            ]

            FeatureSeq[
                seq_id
            ].seq.append(
                int(stop_ends[ib[k]])
            )

            if Points is not None:

                newpos = Points[
                    id_frame + 1
                ].Location[
                    stop_ends[ib[k]] - 1,
                    :
                ]

                FeatureSeq[
                    seq_id
                ].pos = np.vstack([
                    FeatureSeq[
                        seq_id
                    ].pos,
                    newpos
                ])

                if yn_plot:

                    plt.plot(
                        newpos[0],
                        newpos[1],
                        '.',
                        color=cmap[
                            seq_id % 200
                        ]
                    )

        list_active_seq = [
            list_active_seq[i]
            for i in ia
        ]

        # ---------------------------------
        # create new sequences
        # ---------------------------------

        new_starts = np.setdiff1d(
            start_ends,
            previous_ends
        )

        n_previous = len(
            FeatureSeq
        )

        for jj, value in enumerate(
                new_starts):

            idx = np.where(
                start_ends == value
            )[0][0]

            fs = FeatureSequence()

            fs.seq = [
                int(start_ends[idx]),
                int(stop_ends[idx])
            ]

            fs.startframe = (
                id_frame + 1
            )

            if Points is not None:

                start_pos = Points[
                    id_frame
                ].Location[
                    int(value) - 1,
                    :
                ]

                stop_pos = Points[
                    id_frame + 1
                ].Location[
                    int(
                        stop_ends[idx]
                    ) - 1,
                    :
                ]

                fs.pos = np.vstack([
                    start_pos,
                    stop_pos
                ])

                if yn_plot:

                    plt.plot(
                        start_pos[0],
                        start_pos[1],
                        '.',
                        color=cmap[
                            (n_previous + jj)
                            % 200
                        ]
                    )

            FeatureSeq.append(fs)

            list_active_seq.append(
                n_previous + jj
            )

    # ---------------------------------
    # plot sequence trajectory
    # ---------------------------------

    if Points is not None and yn_plot:

        plt.figure()

        for id_seq, seq in enumerate(
                FeatureSeq):

            if seq.pos.shape[0] > 0:

                plt.plot(
                    seq.pos[:, 0],
                    seq.pos[:, 1],
                    color=cmap[
                        id_seq % 200
                    ]
                )

        plt.show(block=False)

    return FeatureSeq