module Evergreen.V95.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V95.Color
import Evergreen.V95.Coord
import Evergreen.V95.GridCell
import Evergreen.V95.Id
import Evergreen.V95.Tile
import Evergreen.V95.Units


type alias LocalGridChange =
    { position : Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit
    , change : Evergreen.V95.Tile.Tile
    , colors : Evergreen.V95.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit
    , change : Evergreen.V95.Tile.Tile
    , userId : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
    , colors : Evergreen.V95.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V95.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V95.GridCell.CellData)
