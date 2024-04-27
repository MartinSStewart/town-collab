module Evergreen.V126.TileCountBot exposing (..)

import AssocList
import Dict
import Evergreen.V126.Coord
import Evergreen.V126.GridCell
import Evergreen.V126.Id
import Evergreen.V126.Tile


type alias Model =
    { userId : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
    , tileUsage : AssocList.Dict Evergreen.V126.Tile.TileGroup Int
    , changedCells : Dict.Dict Evergreen.V126.Coord.RawCellCoord (List Evergreen.V126.GridCell.Value)
    }
