module Evergreen.V110.TileCountBot exposing (..)

import AssocList
import Dict
import Evergreen.V110.Coord
import Evergreen.V110.GridCell
import Evergreen.V110.Id
import Evergreen.V110.Tile


type alias Model =
    { userId : Evergreen.V110.Id.Id Evergreen.V110.Id.UserId
    , tileUsage : AssocList.Dict Evergreen.V110.Tile.TileGroup Int
    , changedCells : Dict.Dict Evergreen.V110.Coord.RawCellCoord (List Evergreen.V110.GridCell.Value)
    }
