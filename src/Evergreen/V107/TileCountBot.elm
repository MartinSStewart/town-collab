module Evergreen.V107.TileCountBot exposing (..)

import AssocList
import Dict
import Evergreen.V107.Coord
import Evergreen.V107.GridCell
import Evergreen.V107.Id
import Evergreen.V107.Tile


type alias Model =
    { userId : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
    , tileUsage : AssocList.Dict Evergreen.V107.Tile.TileGroup Int
    , changedCells : Dict.Dict Evergreen.V107.Coord.RawCellCoord (List Evergreen.V107.GridCell.Value)
    }
