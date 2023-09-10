module Evergreen.V82.Tool exposing (..)

import Effect.WebGL
import Evergreen.V82.Coord
import Evergreen.V82.Shaders
import Evergreen.V82.Tile
import Evergreen.V82.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V82.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V82.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V82.Units.WorldUnit
            }
        )
    | ReportTool
