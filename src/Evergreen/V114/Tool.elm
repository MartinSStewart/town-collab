module Evergreen.V114.Tool exposing (..)

import Effect.WebGL
import Evergreen.V114.Coord
import Evergreen.V114.Sprite
import Evergreen.V114.Tile
import Evergreen.V114.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V114.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V114.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V114.Units.WorldUnit
            }
        )
    | ReportTool
