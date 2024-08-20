module Evergreen.V134.Tool exposing (..)

import Effect.WebGL
import Evergreen.V134.Coord
import Evergreen.V134.Sprite
import Evergreen.V134.Tile
import Evergreen.V134.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V134.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V134.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V134.Units.WorldUnit
            }
        )
    | ReportTool
