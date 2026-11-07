import numpy as np


def find_conn(Points):

    Pair = []

    for ii in range(len(Points) - 1):

        Xa = Points[ii].Location[:, 0]
        Ya = Points[ii].Location[:, 1]

        Xb = Points[ii + 1].Location[:, 0]
        Yb = Points[ii + 1].Location[:, 1]

        # MATLAB:
        # D = hypot(Xa-Xb',Ya-Yb');

        D = np.hypot(
            Xa[:, None] - Xb[None, :],
            Ya[:, None] - Yb[None, :]
        )

        D_linear = D.ravel()

        if D_linear.size == 0:

            Pair.append(
                np.empty((0,2),dtype=np.int32)
            )
        
            continue

        elif D_linear.size >= 4:
            threshold = (
                np.mean(D_linear)
                - np.std(D_linear)
            )

        elif D_linear.size >= 2:
            threshold = np.mean(D_linear)

        else:
            threshold = D_linear[0]

        # MATLAB:
        # b_sel = find(D_linear <= threshold)

        b_sel = np.where(
            D_linear <= threshold
        )[0]

        # MATLAB ind2sub
        X, Y = np.unravel_index(
            b_sel,
            D.shape
        )

        List_row = []

        for x_unique in np.unique(X):

            idx = np.where(X == x_unique)[0]

            if idx.size == 1:

                List_row.append(idx[0])

            else:

                d_compare = D[
                    X[idx],
                    Y[idx]
                ]

                idx_best = idx[
                    np.argmin(d_compare)
                ]

                List_row.append(idx_best)

        if len(List_row) > 0:

            X_sel = X[List_row]
            Y_sel = Y[List_row]

            # MATLAB互換なら1-origin
            Pair.append(
                np.column_stack([
                    X_sel + 1,
                    Y_sel + 1
                ])
            )

            # error check

            if np.max(X_sel) >= \
               Points[ii].Location.shape[0]:

                print(
                    f"Data X exceed at frame#{ii+1}"
                )

            if np.max(Y_sel) >= \
               Points[ii+1].Location.shape[0]:

                print(
                    f"Data Y exceed at frame#{ii+1}"
                )

        else:

            Pair.append(
                np.empty((0, 2), dtype=np.int32)
            )

    return Pair