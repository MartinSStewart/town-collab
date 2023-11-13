module Evergreen.V113.TileCountBot exposing (..)

import AssocList
import Dict
import Evergreen.V113.Coord
import Evergreen.V113.GridCell
import Evergreen.V113.Id
import Evergreen.V113.Tile


type alias Model =
    { userId : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
    , tileUsage : AssocList.Dict Evergreen.V113.Tile.TileGroup Int
    , changedCells : Dict.Dict Evergreen.V113.Coord.RawCellCoord (List Evergreen.V113.GridCell.Value)
    }
