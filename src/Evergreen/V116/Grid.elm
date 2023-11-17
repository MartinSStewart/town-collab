module Evergreen.V116.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V116.Color
import Evergreen.V116.Coord
import Evergreen.V116.GridCell
import Evergreen.V116.Id
import Evergreen.V116.Tile
import Evergreen.V116.Units


type alias LocalGridChange =
    { position : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
    , change : Evergreen.V116.Tile.Tile
    , colors : Evergreen.V116.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
    , change : Evergreen.V116.Tile.Tile
    , userId : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , colors : Evergreen.V116.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid a
    = Grid (Dict.Dict ( Int, Int ) (Evergreen.V116.GridCell.Cell a))


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V116.GridCell.CellData)
