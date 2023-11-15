module Evergreen.V114.TileCountBot exposing (..)

import AssocList
import Dict
import Evergreen.V114.Coord
import Evergreen.V114.GridCell
import Evergreen.V114.Id
import Evergreen.V114.Tile


type alias Model =
    { userId : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , tileUsage : AssocList.Dict Evergreen.V114.Tile.TileGroup Int
    , changedCells : Dict.Dict Evergreen.V114.Coord.RawCellCoord (List Evergreen.V114.GridCell.Value)
    }
