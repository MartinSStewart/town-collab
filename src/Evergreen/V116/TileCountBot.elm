module Evergreen.V116.TileCountBot exposing (..)

import AssocList
import Dict
import Evergreen.V116.Coord
import Evergreen.V116.GridCell
import Evergreen.V116.Id
import Evergreen.V116.Tile


type alias Model =
    { userId : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , tileUsage : AssocList.Dict Evergreen.V116.Tile.TileGroup Int
    , changedCells : Dict.Dict Evergreen.V116.Coord.RawCellCoord (List Evergreen.V116.GridCell.Value)
    }
