module Evergreen.V85.Tool exposing (..)

import Effect.WebGL
import Evergreen.V85.Coord
import Evergreen.V85.Shaders
import Evergreen.V85.Tile
import Evergreen.V85.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V85.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V85.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V85.Units.WorldUnit
            }
        )
    | ReportTool
