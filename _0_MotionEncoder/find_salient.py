from dataclasses import dataclass, field
import numpy as np


@dataclass
class SalientData:
    Pos: np.ndarray = field(
        default_factory=lambda: np.empty((0, 3))
    )
    id_feature: np.ndarray = field(
        default_factory=lambda: np.empty((0,), dtype=np.int32)
    )
    Scale: np.ndarray = field(
        default_factory=lambda: np.empty((0,))
    )
    Metric: np.ndarray = field(
        default_factory=lambda: np.empty((0,))
    )
    Slice: np.ndarray = field(
        default_factory=lambda: np.empty((0,))
    )


def find_salient(Points, min_metric_std=None):

    Salient = SalientData()

    # -----------------------------
    # gather all metrics
    # -----------------------------
    Met = []

    for feature in Points:

        if feature.Metric.size > 0:
            Met.append(feature.Metric)

    if len(Met) > 0:
        Met = np.concatenate(Met)
    else:
        Met = np.array([])

    Metric_data = {
        "mean": np.mean(Met) if Met.size else np.nan,
        "std": np.std(Met, ddof=1) if Met.size > 1 else np.nan,
        "n": Met.size
    }

    # MATLAB:
    # min_metric = mean(Met)+min_metric_std*std(Met)

    if min_metric_std is not None and Met.size > 0:

        min_metric = (
            np.mean(Met)
            + min_metric_std * np.std(Met, ddof=1)
        )

    # -----------------------------
    # collect salient points
    # -----------------------------
    pos_list = []
    id_list = []
    scale_list = []
    metric_list = []

    for id_slice, feature in enumerate(
            Points,
            start=1):

        if min_metric_std is not None:

            list_salient = np.where(
                feature.Metric >= min_metric
            )[0]

        else:

            list_salient = np.arange(
                feature.Metric.size
            )

        if list_salient.size == 0:
            continue

        list_pos = feature.Location[
            list_salient,
            :
        ]

        list_pos3 = np.column_stack([
            list_pos,
            np.full(
                list_pos.shape[0],
                id_slice,
                dtype=np.float32
            )
        ])

        pos_list.append(list_pos3)

        # MATLABは1-origin
        id_list.append(
            list_salient + 1
        )

        scale_list.append(
            feature.Scale[list_salient]
        )

        metric_list.append(
            feature.Metric[list_salient]
        )

    # -----------------------------
    # convert to arrays
    # -----------------------------
    if len(pos_list):

        Salient.Pos = np.vstack(pos_list)

        Salient.id_feature = np.concatenate(
            id_list
        )

        Salient.Scale = np.concatenate(
            scale_list
        )

        Salient.Metric = np.concatenate(
            metric_list
        )

        Salient.Slice = Salient.Pos[:, 2].copy()#3列目を取り出して、メモリを確保してコピー。

    return Salient