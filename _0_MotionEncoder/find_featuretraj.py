from dataclasses import dataclass, field
import numpy as np


@dataclass
class FeatureTrajectory:

    startframe: int = 0

    ListFrame: np.ndarray = field(
        default_factory=lambda: np.empty(
            (0,), dtype=np.int32
        )
    )

    node: np.ndarray = field(
        default_factory=lambda: np.empty(
            (0,), dtype=np.int32
        )
    )

    pos: np.ndarray = field(
        default_factory=lambda: np.empty(
            (0, 3)
        )
    )

    Metric: np.ndarray = field(
        default_factory=lambda: np.empty(
            (0,)
        )
    )

    Scale: np.ndarray = field(
        default_factory=lambda: np.empty(
            (0,)
        )
    )

    Layer: np.ndarray = field(
        default_factory=lambda: np.empty(
            (0,)
        )
    )

    Octave: np.ndarray = field(
        default_factory=lambda: np.empty(
            (0,)
        )
    )


def find_featuretraj(
        FeatureSeq,
        Points,
        yn_plot=False,
        min_conting=10,
        POS_overlay=None):

    FeatureTraj = []

    if yn_plot:

        import matplotlib.pyplot as plt

        from matplotlib.patches import Circle

        cmap = plt.cm.cool(
            np.linspace(0, 1, 100)
        )

        fig = plt.figure(
            "FeatureTrajectory"
        )

        ax = fig.add_subplot(111)

    for seq in FeatureSeq:

        traj = FeatureTrajectory()

        startframe = seq.startframe

        traj.startframe = startframe

        pos_list = []
        metric_list = []
        scale_list = []
        node_list = []
        frame_list = []
        layer_list = []
        octave_list = []

        for id_frame, id_node in enumerate(
                seq.seq,
                start=1):

            frame = (
                startframe
                + id_frame
                - 1
            )

            node_list.append(id_node)

            frame_list.append(frame)

            feature = Points[
                frame - 1
            ]

            loc = feature.Location[
                id_node - 1,
                :
            ]

            pos_list.append([
                loc[0],
                loc[1],
                frame
            ])

            metric_list.append(
                feature.Metric[
                    id_node - 1
                ]
            )

            scale_list.append(
                feature.Scale[
                    id_node - 1
                ]
            )

            if hasattr(
                    feature,
                    "Layer"):

                layer_list.append(
                    feature.Layer[
                        id_node - 1
                    ]
                )

            if hasattr(
                    feature,
                    "Octave"):

                octave_list.append(
                    feature.Octave[
                        id_node - 1
                    ]
                )

        traj.ListFrame = np.array(
            frame_list
        )

        traj.node = np.array(
            node_list
        )

        traj.pos = np.array(
            pos_list
        )

        traj.Metric = np.array(
            metric_list
        )

        traj.Scale = np.array(
            scale_list
        )

        if len(layer_list):
            traj.Layer = np.array(
                layer_list
            )

        if len(octave_list):
            traj.Octave = np.array(
                octave_list
            )

        FeatureTraj.append(
            traj
        )

        # --------------------------------
        # plot
        # --------------------------------

        if yn_plot:

            if traj.pos.shape[0] >= min_conting:

                ax.plot(
                    traj.pos[:, 0],
                    traj.pos[:, 1]
                )

                mmin = np.min(
                    traj.Metric
                )

                mmax = np.max(
                    traj.Metric
                )

                for k in range(
                        len(traj.Metric)):

                    value = traj.Metric[k]

                    if mmax == mmin:

                        id_color = 0

                    else:

                        id_color = int(
                            np.clip(
                                round(
                                    99
                                    * (
                                        value
                                        - mmin
                                    )
                                    / (
                                        mmax
                                        - mmin
                                    )
                                ),
                                0,
                                99
                            )
                        )

                    circle = Circle(
                        (
                            traj.pos[k, 0],
                            traj.pos[k, 1]
                        ),
                        traj.Scale[k],
                        fill=False,
                        linewidth=0.5,
                        color=cmap[
                            id_color
                        ]
                    )

                    ax.add_patch(
                        circle
                    )

    # --------------------------------
    # background features
    # --------------------------------

    if yn_plot:

        for id_frame in range(
                len(Points)):

            z = np.full(
                Points[
                    id_frame
                ].Location.shape[0],
                id_frame + 1
            )

            ax.plot(
                Points[
                    id_frame
                ].Location[:, 0],
                Points[
                    id_frame
                ].Location[:, 1],
                'k.'
            )

        if POS_overlay is not None:

            ax.plot(
                POS_overlay[:, 0],
                POS_overlay[:, 1],
                'r*'
            )

        plt.show(
            block=False
        )

    return FeatureTraj