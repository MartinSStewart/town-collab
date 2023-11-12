module Evergreen.V112.TileCountBot exposing (..)

import AssocList
import Dict
import Evergreen.V112.Coord
import Evergreen.V112.GridCell
import Evergreen.V112.Id
import Evergreen.V112.Tile


type alias Model =
    { userId : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , tileUsage : AssocList.Dict Evergreen.V112.Tile.TileGroup Int
    , changedCells : Dict.Dict Evergreen.V112.Coord.RawCellCoord (List Evergreen.V112.GridCell.Value)
    }
