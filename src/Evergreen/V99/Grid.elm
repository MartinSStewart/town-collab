module Evergreen.V99.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V99.Color
import Evergreen.V99.Coord
import Evergreen.V99.GridCell
import Evergreen.V99.Id
import Evergreen.V99.Tile
import Evergreen.V99.Units


type alias LocalGridChange =
    { position : Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit
    , change : Evergreen.V99.Tile.Tile
    , colors : Evergreen.V99.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit
    , change : Evergreen.V99.Tile.Tile
    , userId : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
    , colors : Evergreen.V99.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V99.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V99.GridCell.CellData)
