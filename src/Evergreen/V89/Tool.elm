module Evergreen.V89.Tool exposing (..)

import Effect.WebGL
import Evergreen.V89.Coord
import Evergreen.V89.Shaders
import Evergreen.V89.Tile
import Evergreen.V89.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V89.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V89.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V89.Units.WorldUnit
            }
        )
    | ReportTool
