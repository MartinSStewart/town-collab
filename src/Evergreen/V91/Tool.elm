module Evergreen.V91.Tool exposing (..)

import Effect.WebGL
import Evergreen.V91.Coord
import Evergreen.V91.Shaders
import Evergreen.V91.Tile
import Evergreen.V91.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V91.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V91.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V91.Units.WorldUnit
            }
        )
    | ReportTool
