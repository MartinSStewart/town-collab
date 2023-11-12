module Evergreen.V112.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V112.Color
import Evergreen.V112.Coord
import Evergreen.V112.GridCell
import Evergreen.V112.Id
import Evergreen.V112.Tile
import Evergreen.V112.Units


type alias LocalGridChange =
    { position : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
    , change : Evergreen.V112.Tile.Tile
    , colors : Evergreen.V112.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
    , change : Evergreen.V112.Tile.Tile
    , userId : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , colors : Evergreen.V112.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid a
    = Grid (Dict.Dict ( Int, Int ) (Evergreen.V112.GridCell.Cell a))


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V112.GridCell.CellData)
