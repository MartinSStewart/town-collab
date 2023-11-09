module Evergreen.V109.TileCountBot exposing (..)

import AssocList
import Dict
import Evergreen.V109.Coord
import Evergreen.V109.GridCell
import Evergreen.V109.Id
import Evergreen.V109.Tile


type alias Model =
    { userId : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , tileUsage : AssocList.Dict Evergreen.V109.Tile.TileGroup Int
    , changedCells : Dict.Dict Evergreen.V109.Coord.RawCellCoord (List Evergreen.V109.GridCell.Value)
    }
