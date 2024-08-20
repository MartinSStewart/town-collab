module Evergreen.V134.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V134.Color
import Evergreen.V134.Coord
import Evergreen.V134.GridCell
import Evergreen.V134.Id
import Evergreen.V134.Tile
import Evergreen.V134.Units


type alias LocalGridChange =
    { position : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
    , change : Evergreen.V134.Tile.Tile
    , colors : Evergreen.V134.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
    , change : Evergreen.V134.Tile.Tile
    , userId : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , colors : Evergreen.V134.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid a
    = Grid (Dict.Dict ( Int, Int ) (Evergreen.V134.GridCell.Cell a))


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V134.GridCell.CellData)
