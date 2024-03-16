module Evergreen.V125.TileCountBot exposing (..)

import AssocList
import Dict
import Evergreen.V125.Coord
import Evergreen.V125.GridCell
import Evergreen.V125.Id
import Evergreen.V125.Tile


type alias Model =
    { userId : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , tileUsage : AssocList.Dict Evergreen.V125.Tile.TileGroup Int
    , changedCells : Dict.Dict Evergreen.V125.Coord.RawCellCoord (List Evergreen.V125.GridCell.Value)
    }
