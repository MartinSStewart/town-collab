module Evergreen.V125.Grid exposing (..)

import Dict
import Effect.Time
import Evergreen.V125.Color
import Evergreen.V125.Coord
import Evergreen.V125.GridCell
import Evergreen.V125.Id
import Evergreen.V125.Tile
import Evergreen.V125.Units


type alias LocalGridChange =
    { position : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
    , change : Evergreen.V125.Tile.Tile
    , colors : Evergreen.V125.Color.Colors
    , time : Effect.Time.Posix
    }


type alias GridChange =
    { position : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
    , change : Evergreen.V125.Tile.Tile
    , userId : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , colors : Evergreen.V125.Color.Colors
    , time : Effect.Time.Posix
    }


type Grid a
    = Grid (Dict.Dict ( Int, Int ) (Evergreen.V125.GridCell.Cell a))


type GridData
    = GridData (Dict.Dict ( Int, Int ) Evergreen.V125.GridCell.CellData)
