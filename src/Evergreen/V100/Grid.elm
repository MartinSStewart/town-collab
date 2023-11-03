module Evergreen.V100.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V100.Color
import Evergreen.V100.Coord
import Evergreen.V100.GridCell
import Evergreen.V100.Id
import Evergreen.V100.Tile
import Evergreen.V100.Units


type alias LocalGridChange =
    { position : Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit
    , change : Evergreen.V100.Tile.Tile
    , colors : Evergreen.V100.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit
    , change : Evergreen.V100.Tile.Tile
    , userId : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
    , colors : Evergreen.V100.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V100.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V100.GridCell.CellData)
