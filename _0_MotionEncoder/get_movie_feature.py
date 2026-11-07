print("MODULE get_movie_feature LOADED")
from dataclasses import dataclass, field
from typing import Optional

import cv2
import numpy as np
import matplotlib.pyplot as plt

# =====================================================
# MATLAB compatibility
# =====================================================

def numel(x):
    return len(x)

class MatlabList(list):# Not in use

    def __getitem__(self, idx):

        if isinstance(idx, int):

            if idx < 1:
                raise IndexError(
                    "MATLAB indices start from 1"
                )

            return super().__getitem__(idx - 1)

        return super().__getitem__(idx)

    @property
    def numel(self):
        return len(self)

# =====================================================
# detectSIFTFeatures output
# =====================================================

@dataclass
class SIFTFeature:

    Location: np.ndarray
    Metric: np.ndarray
    Scale: np.ndarray

    KeyPoints: list

    Descriptors: Optional[np.ndarray] = None


# =====================================================
# Points
# =====================================================

@dataclass
class PointsData:

    #x: MatlabList = field(default_factory=MatlabList)
    #y: MatlabList = field(default_factory=MatlabList)
    #z: MatlabList = field(default_factory=MatlabList)

    x: list = field(default_factory=list)
    y: list = field(default_factory=list)
    z: list = field(default_factory=list)

# =====================================================
# Pos.Feature
# =====================================================

@dataclass
class FeaturePos:

    x: Optional[np.ndarray] = None
    y: Optional[np.ndarray] = None
    z: Optional[np.ndarray] = None


@dataclass
class PosData:

    Feature: FeaturePos = field(
        default_factory=FeaturePos
    )


# =====================================================
# detectSIFTFeatures replacement
# =====================================================

def detect_sift_features(im):

    sift = cv2.SIFT_create()

    keypoints, descriptors = sift.detectAndCompute(
        im,
        None
    )

    if len(keypoints) > 0:

        location = np.array(
            [kp.pt for kp in keypoints],
            dtype=np.float32
        )

        metric = np.array(
            [kp.response for kp in keypoints],
            dtype=np.float32
        )

        scale = np.array(
            [kp.size for kp in keypoints],
            dtype=np.float32
        )

    else:

        location = np.empty(
            (0, 2),
            dtype=np.float32
        )

        metric = np.empty(
            (0,),
            dtype=np.float32
        )

        scale = np.empty(
            (0,),
            dtype=np.float32
        )

    return SIFTFeature(
        Location=location,
        Metric=metric,
        Scale=scale,
        KeyPoints=keypoints,
        Descriptors=descriptors
    )


# =====================================================
# VideoReader replacement
# =====================================================

def read_movie(fn_full):

    cap = cv2.VideoCapture(
        fn_full,
        cv2.CAP_ANY
    )

    print("Opened =", cap.isOpened())

    frames = []

    while True:
        ret, frame = cap.read()
        if not ret:
            break
        gray = cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
        frames.append(gray)
    cap.release()
    
    print("TOTAL =", len(frames))
    
    IM = np.stack(frames, axis=2)
    print("IM shape =", IM.shape)

    if len(frames) == 0:
        raise RuntimeError(f"Cannot read movie: {fn_full}")

    return np.stack(frames,axis=2)


# =====================================================
# get_movie_feature
# =====================================================

def get_movie_feature(
        fn_full,
        DIM_select=(3,),
        yn_plot=True):

    if isinstance(DIM_select, int):
        DIM_select = [DIM_select]

    IM = read_movie(fn_full)
    print(IM.shape)

    Points = PointsData()
    Pos = PosData()

    # -----------------------------------------
    # Z scan
    # -----------------------------------------

    if 3 in DIM_select:

        print("START SIFT")

        pos_z = []

        print("FRAME/NFEATURES=",end="")
        for id_z in range(
                1,
                IM.shape[2] + 1):
            
            print(id_z, "/", end="")#FRAME

            im = IM[:, :, id_z - 1]

            feature = detect_sift_features(im)

            if id_z % 20 == 0 and id_z > 0:
                print(feature.Location.shape[0])#NFEATURES
            else:
                print(feature.Location.shape[0], end=", ")#NFEATURES

            Points.z.append(feature)

            ndata = (feature.Location.shape[0])

            if ndata > 0:

                add = np.column_stack([

                    feature.Location,

                    np.full(
                        ndata,
                        id_z,
                        dtype=np.float32
                    )

                ])

                pos_z.append(add)

        if len(pos_z):

            Pos.Feature.z = np.vstack(
                pos_z
            )

        else:

            Pos.Feature.z = np.empty(
                (0, 3)
            )

    # -----------------------------------------
    # X scan
    # -----------------------------------------

    if 1 in DIM_select:

        pos_x = []

        for id_x in range(
                1,
                IM.shape[0] + 1):

            im = IM[id_x - 1, :, :]

            feature = detect_sift_features(
                im.astype(np.uint8)
            )

            Points.x.append(feature)

            ndata = (
                feature.Location.shape[0]
            )

            if ndata > 0:

                add = np.column_stack([

                    feature.Location[:, 1],

                    np.full(
                        ndata,
                        id_x,
                        dtype=np.float32
                    ),

                    feature.Location[:, 0]

                ])

                pos_x.append(add)

        if len(pos_x):

            Pos.Feature.x = np.vstack(
                pos_x
            )

        else:

            Pos.Feature.x = np.empty(
                (0, 3)
            )

    # -----------------------------------------
    # Y scan
    # -----------------------------------------

    if 2 in DIM_select:

        pos_y = []

        for id_y in range(
                1,
                IM.shape[1] + 1):

            im = IM[:, id_y - 1, :]

            feature = detect_sift_features(
                im.astype(np.uint8)
            )

            Points.y.append(feature)

            ndata = (
                feature.Location.shape[0]
            )

            if ndata > 0:

                add = np.column_stack([

                    np.full(
                        ndata,
                        id_y,
                        dtype=np.float32
                    ),

                    feature.Location[:, 1],

                    feature.Location[:, 0]

                ])

                pos_y.append(add)

        if len(pos_y):

            Pos.Feature.y = np.vstack(
                pos_y
            )

        else:

            Pos.Feature.y = np.empty(
                (0, 3)
            )

    # -----------------------------------------
    # plot
    # -----------------------------------------

    if yn_plot:

        fig = plt.figure()

        ax = fig.add_subplot(
            111,
            projection="3d"
        )

        if Pos.Feature.z is not None \
           and len(Pos.Feature.z):

            ax.scatter(
                Pos.Feature.z[:, 0],
                Pos.Feature.z[:, 1],
                Pos.Feature.z[:, 2],
                c="r",
                s=1
            )

        if Pos.Feature.x is not None \
           and len(Pos.Feature.x):

            ax.scatter(
                Pos.Feature.x[:, 0],
                Pos.Feature.x[:, 1],
                Pos.Feature.x[:, 2],
                c="g",
                s=1
            )

        if Pos.Feature.y is not None \
           and len(Pos.Feature.y):

            ax.scatter(
                Pos.Feature.y[:, 0],
                Pos.Feature.y[:, 1],
                Pos.Feature.y[:, 2],
                c="b",
                s=1
            )

        ax.set_xlabel("X")
        ax.set_ylabel("Y")
        ax.set_zlabel("Frame")

        plt.show(block=False)
        fig.canvas.draw()#Figureを明示的に描画
        fig.canvas.flush_events()#Figureを明示的に描画
        plt.pause(0.1)

    print("END")

    return Points, Pos


# =====================================================
# test
# =====================================================

if __name__ == "__main__":

    Points, Pos = get_movie_feature(
        "test.avi",
        DIM_select=(3,)
    )

    print(
        Points.z[1].Location.shape
    )

    print(
        Points.z[1].Metric.shape
    )

    print(
        numel(Points.z)
    )

    print(
        Pos.Feature.z.shape
    )