module Evergreen.V93.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V93.Color
import Evergreen.V93.Coord
import Evergreen.V93.GridCell
import Evergreen.V93.Id
import Evergreen.V93.Tile
import Evergreen.V93.Units


type alias LocalGridChange =
    { position : Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit
    , change : Evergreen.V93.Tile.Tile
    , colors : Evergreen.V93.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit
    , change : Evergreen.V93.Tile.Tile
    , userId : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , colors : Evergreen.V93.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid
    = Grid (Dict.Dict ( Int, Int ) Evergreen.V93.GridCell.Cell)


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V93.GridCell.CellData)
