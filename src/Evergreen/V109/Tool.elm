module Evergreen.V109.Tool exposing (..)

import Effect.WebGL
import Evergreen.V109.Coord
import Evergreen.V109.Sprite
import Evergreen.V109.Tile
import Evergreen.V109.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V109.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V109.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V109.Units.WorldUnit
            }
        )
    | ReportTool
