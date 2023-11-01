module Evergreen.V97.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V97.Color
import Evergreen.V97.Coord
import Evergreen.V97.GridCell
import Evergreen.V97.Id
import Evergreen.V97.Tile
import Evergreen.V97.Units


type alias LocalGridChange =
    { position : Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit
    , change : Evergreen.V97.Tile.Tile
    , colors : Evergreen.V97.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit
    , change : Evergreen.V97.Tile.Tile
    , userId : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , colors : Evergreen.V97.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V97.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V97.GridCell.CellData)
