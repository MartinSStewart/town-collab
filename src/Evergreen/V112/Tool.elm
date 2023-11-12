module Evergreen.V112.Tool exposing (..)

import Effect.WebGL
import Evergreen.V112.Coord
import Evergreen.V112.Sprite
import Evergreen.V112.Tile
import Evergreen.V112.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V112.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V112.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V112.Units.WorldUnit
            }
        )
    | ReportTool
