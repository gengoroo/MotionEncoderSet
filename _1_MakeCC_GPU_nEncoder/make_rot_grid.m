%make_rot_grid
function [CellRot2Serial, Serial_out, ListRot] = make_rot_grid(varargin)

    nCell =25;
    for ii = 1:nargin
        if strcmp('nCell',varargin{ii})
            nCell = varargin{ii+1};
        end
    end
    
    nSide = sqrt(nCell);
    Grid = [nSide,nSide];
    newGrid = 2*Grid;
    counter = 0;
    for id_cell = 1:nCell
        [x, y] = ind2sub(Grid, id_cell);
        Pos2 = 2*[x, y] - [1 1];
        for add = 1:4
            counter = counter + 1;
            CellRot2Serial(id_cell, add) = 4*(id_cell - 1) + add;
            [shift(1), shift(2)] = ind2sub([2,2], add);
            Pos3 = Pos2 + shift - [1, 1];
            Serial_out(counter) = sub2ind(newGrid, Pos3(1), Pos3(2));
        end
    end
    ListRot = [0 90 270 180];
end