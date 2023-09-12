module Evergreen.V84.Tool exposing (..)

import Effect.WebGL
import Evergreen.V84.Coord
import Evergreen.V84.Shaders
import Evergreen.V84.Tile
import Evergreen.V84.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V84.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V84.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V84.Units.WorldUnit
            }
        )
    | ReportTool
