module Evergreen.V81.Grid exposing (..)

import Dict
import Evergreen.V81.Color
import Evergreen.V81.Coord
import Evergreen.V81.GridCell
import Evergreen.V81.Id
import Evergreen.V81.Tile
import Evergreen.V81.Units


type alias LocalGridChange =
    { position : Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit
    , change : Evergreen.V81.Tile.Tile
    , colors : Evergreen.V81.Color.Colors
    }


type alias GridChange =
    { position : Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit
    , change : Evergreen.V81.Tile.Tile
    , userId : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
    , colors : Evergreen.V81.Color.Colors
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V81.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V81.GridCell.CellData)
