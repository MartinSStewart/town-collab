module Evergreen.V115.TileCountBot exposing (..)

import AssocList
import Dict
import Evergreen.V115.Coord
import Evergreen.V115.GridCell
import Evergreen.V115.Id
import Evergreen.V115.Tile


type alias Model =
    { userId : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , tileUsage : AssocList.Dict Evergreen.V115.Tile.TileGroup Int
    , changedCells : Dict.Dict Evergreen.V115.Coord.RawCellCoord (List Evergreen.V115.GridCell.Value)
    }
