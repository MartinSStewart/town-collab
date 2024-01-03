module Evergreen.V124.TileCountBot exposing (..)

import AssocList
import Dict
import Evergreen.V124.Coord
import Evergreen.V124.GridCell
import Evergreen.V124.Id
import Evergreen.V124.Tile


type alias Model =
    { userId : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , tileUsage : AssocList.Dict Evergreen.V124.Tile.TileGroup Int
    , changedCells : Dict.Dict Evergreen.V124.Coord.RawCellCoord (List Evergreen.V124.GridCell.Value)
    }
