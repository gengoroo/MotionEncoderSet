import numpy as np
import matplotlib.pyplot as plt


class Struct:
    pass


def search_cylinder(
        PosXYZ,
        XYZ,
        r,
        Range,
        List_feature_search):

    Found = Struct()

    Found.id_slice = None
    Found.id_feature = None
    Found.Pos = None

    # MATLAB:
    # if Range(1) < Range(2)
    #     dir = 'u';
    # else
    #     dir = 'd';
    # end

    if Range[0] < Range[1]:
        direction = 'u'
    else:
        direction = 'd'

    Range_limit = (
        np.asarray(
            Range,
            dtype=float
        )
        + PosXYZ[2]
    )

    # MATLAB:
    # DataRadius =
    # ((XYZ(:,1)-PosXYZ(1)).^2 +
    #  (XYZ(:,2)-PosXYZ(2)).^2);

    DataRadius = (
        (XYZ[:, 0] - PosXYZ[0]) ** 2 +
        (XYZ[:, 1] - PosXYZ[1]) ** 2
    )

    # MATLAB:
    # ListRadius = find(DataRadius < r^2);

    ListRadius = np.where(
        DataRadius < r ** 2
    )[0]

    # MATLAB:
    # ListDepth = find(
    # (XYZ(:,3)-Range_limit(1))
    # .*
    # (Range_limit(2)-XYZ(:,3))
    # > 0);

    ListDepth = np.where(
        (
            (XYZ[:, 2] - Range_limit[0])
            *
            (Range_limit[1] - XYZ[:, 2])
        ) > 0
    )[0]

    # MATLAB:
    # [ListCylinder,iR,iD] =
    # intersect(ListRadius,ListDepth);

    ListCylinder, iR, iD = np.intersect1d(
        ListRadius,
        ListDepth,
        return_indices=True
    )

    if len(ListCylinder) == 0:
        return Found

    # MATLAB:
    # DataRadius_select = DataRadius(iR);

    DataRadius_select = DataRadius[
        ListRadius[iR]
    ]

    # MATLAB:
    # List_min_radius =
    # ListCylinder(
    #     find(
    #         DataRadius_select
    #         ==
    #         min(DataRadius_select)
    #     )
    # );

    List_min_radius = ListCylinder[
        DataRadius_select
        ==
        np.min(DataRadius_select)
    ]

    if len(List_min_radius) == 0:
        return Found

    LiztZ = XYZ[
        List_min_radius,
        2
    ]

    if len(LiztZ) == 0:
        return Found

    if direction == 'u':

        candidates = List_min_radius[
            LiztZ == np.min(LiztZ)
        ]

        id_pick = int(
            np.min(candidates)
        )

    else:

        candidates = List_min_radius[
            LiztZ == np.max(LiztZ)
        ]

        id_pick = int(
            np.min(candidates)
        )

    # MATLAB:
    # Found.id_feature =
    # List_feature_search(id_pick);

    Found.id_feature = (
        List_feature_search[id_pick]
    )

    # MATLAB:
    # Found.Pos = XYZ(id_pick,:);

    Found.Pos = XYZ[
        id_pick,
        :
    ]

    # MATLAB:
    # Found.id_slice =
    # Found.Pos(:,3);

    Found.id_slice = (
        Found.Pos[2]
    )

    return Found


def find_overlap(
        Salient_ref,
        Salient_search,
        Salient_ref_all,
        z_range):

    z_range = np.asarray(
        z_range,
        dtype=float
    )

    fig = plt.figure("overlap")
    ax = fig.add_subplot(
        111,
        projection="3d"
    )

    ax.plot(
        Salient_search.Pos[:, 0],
        Salient_search.Pos[:, 1],
        Salient_search.Pos[:, 2],
        "m."
    )

    ax.plot(
        Salient_ref_all.Pos[:, 0],
        Salient_ref_all.Pos[:, 1],
        Salient_ref_all.Pos[:, 2],
        "k."
    )

    ax.set_title(
        "XYT plot of keypoints pair"
    )

    PairOverlap = Struct()

    PairOverlap.ref = Struct()
    PairOverlap.found = Struct()

    PairOverlap.ref.id_slice = []
    PairOverlap.ref.id_feature = []
    PairOverlap.ref.Location = []
    PairOverlap.ref.Scale = []

    PairOverlap.found.id_slice = []
    PairOverlap.found.id_feature = []
    PairOverlap.found.Location = []
    PairOverlap.found.Scale = []

    XYZ = Salient_search.Pos

    nPos = Salient_ref.Pos.shape[0]

    for idx in range(nPos):

        PosXYZ = Salient_ref.Pos[idx, :]

        id_slice = PosXYZ[2]

        r = (
            Salient_ref.Scale[idx]
            * 1.5
            * 1.5
        )

        id_feature = int(
            Salient_ref.id_feature[idx]
        )

        Found = search_cylinder(
            PosXYZ,
            XYZ,
            r,
            z_range,
            Salient_search.id_feature
        )

        if Found.id_slice is None:
            continue

        PairOverlap.ref.id_slice.append(
            id_slice
        )

        PairOverlap.ref.id_feature.append(
            id_feature
        )

        PairOverlap.ref.Location.append(
            PosXYZ
        )

        PairOverlap.ref.Scale.append(
            r
        )

        PairOverlap.found.id_slice.append(
            Found.id_slice
        )

        PairOverlap.found.id_feature.append(
            Found.id_feature
        )

        PairOverlap.found.Location.append(
            Found.Pos
        )

        PairOverlap.found.Scale.append(
            Salient_search.Scale[
                Found.id_feature
            ]
        )

        ax.plot(
            [PosXYZ[0]],
            [PosXYZ[1]],
            [PosXYZ[2]],
            "k*"
        )

        ax.plot(
            [Found.Pos[0]],
            [Found.Pos[1]],
            [Found.Pos[2]],
            "m*"
        )

        ax.plot(
            [PosXYZ[0], Found.Pos[0]],
            [PosXYZ[1], Found.Pos[1]],
            [PosXYZ[2], Found.Pos[2]],
            "b-"
        )

    PairOverlap.ref.id_slice = np.asarray(
        PairOverlap.ref.id_slice
    )

    PairOverlap.ref.id_feature = np.asarray(
        PairOverlap.ref.id_feature
    )

    PairOverlap.ref.Location = np.asarray(
        PairOverlap.ref.Location
    )

    PairOverlap.ref.Scale = np.asarray(
        PairOverlap.ref.Scale
    )

    PairOverlap.found.id_slice = np.asarray(
        PairOverlap.found.id_slice
    )

    PairOverlap.found.id_feature = np.asarray(
        PairOverlap.found.id_feature
    )

    PairOverlap.found.Location = np.asarray(
        PairOverlap.found.Location
    )

    PairOverlap.found.Scale = np.asarray(
        PairOverlap.found.Scale
    )

    ax.legend(["search", "ref"])

    plt.show(block=False)
    fig.canvas.draw()#Figureを明示的に描画
    fig.canvas.flush_events()#Figureを明示的に描画
    plt.pause(0.1)

    return PairOverlap

    print(
        "N overlap =",
        len(PairOverlap.ref.Location)
    )