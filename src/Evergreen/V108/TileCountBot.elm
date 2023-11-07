module Evergreen.V108.TileCountBot exposing (..)

import AssocList
import Dict
import Evergreen.V108.Coord
import Evergreen.V108.GridCell
import Evergreen.V108.Id
import Evergreen.V108.Tile


type alias Model =
    { userId : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , tileUsage : AssocList.Dict Evergreen.V108.Tile.TileGroup Int
    , changedCells : Dict.Dict Evergreen.V108.Coord.RawCellCoord (List Evergreen.V108.GridCell.Value)
    }
