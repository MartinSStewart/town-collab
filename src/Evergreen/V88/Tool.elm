module Evergreen.V88.Tool exposing (..)

import Effect.WebGL
import Evergreen.V88.Coord
import Evergreen.V88.Shaders
import Evergreen.V88.Tile
import Evergreen.V88.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V88.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V88.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V88.Units.WorldUnit
            }
        )
    | ReportTool
