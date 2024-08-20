module Evergreen.V134.TileCountBot exposing (..)

import AssocList
import Dict
import Evergreen.V134.Coord
import Evergreen.V134.GridCell
import Evergreen.V134.Id
import Evergreen.V134.Tile


type alias Model =
    { userId : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , tileUsage : AssocList.Dict Evergreen.V134.Tile.TileGroup Int
    , changedCells : Dict.Dict Evergreen.V134.Coord.RawCellCoord (List Evergreen.V134.GridCell.Value)
    }
