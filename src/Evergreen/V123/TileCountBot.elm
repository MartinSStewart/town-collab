module Evergreen.V123.TileCountBot exposing (..)

import AssocList
import Dict
import Evergreen.V123.Coord
import Evergreen.V123.GridCell
import Evergreen.V123.Id
import Evergreen.V123.Tile


type alias Model =
    { userId : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
    , tileUsage : AssocList.Dict Evergreen.V123.Tile.TileGroup Int
    , changedCells : Dict.Dict Evergreen.V123.Coord.RawCellCoord (List Evergreen.V123.GridCell.Value)
    }
