module Evergreen.V111.TileCountBot exposing (..)

import AssocList
import Dict
import Evergreen.V111.Coord
import Evergreen.V111.GridCell
import Evergreen.V111.Id
import Evergreen.V111.Tile


type alias Model =
    { userId : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
    , tileUsage : AssocList.Dict Evergreen.V111.Tile.TileGroup Int
    , changedCells : Dict.Dict Evergreen.V111.Coord.RawCellCoord (List Evergreen.V111.GridCell.Value)
    }
