module Evergreen.V97.Tool exposing (..)

import Effect.WebGL
import Evergreen.V97.Coord
import Evergreen.V97.Sprite
import Evergreen.V97.Tile
import Evergreen.V97.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V97.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V97.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V97.Units.WorldUnit
            }
        )
    | ReportTool
