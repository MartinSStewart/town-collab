module Evergreen.V83.Tool exposing (..)

import Effect.WebGL
import Evergreen.V83.Coord
import Evergreen.V83.Shaders
import Evergreen.V83.Tile
import Evergreen.V83.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V83.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V83.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V83.Units.WorldUnit
            }
        )
    | ReportTool
