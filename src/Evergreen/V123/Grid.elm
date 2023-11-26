module Evergreen.V123.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V123.Color
import Evergreen.V123.Coord
import Evergreen.V123.GridCell
import Evergreen.V123.Id
import Evergreen.V123.Tile
import Evergreen.V123.Units


type alias LocalGridChange =
    { position : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
    , change : Evergreen.V123.Tile.Tile
    , colors : Evergreen.V123.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
    , change : Evergreen.V123.Tile.Tile
    , userId : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
    , colors : Evergreen.V123.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid a
    = Grid (Dict.Dict ( Int, Int ) (Evergreen.V123.GridCell.Cell a))


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V123.GridCell.CellData)
