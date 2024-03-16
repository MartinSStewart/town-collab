module Evergreen.V125.Tool exposing (..)

import Effect.WebGL
import Evergreen.V125.Coord
import Evergreen.V125.Sprite
import Evergreen.V125.Tile
import Evergreen.V125.Units
import Quantity


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V125.Tile.TileGroup
        , index : Int
        , mesh : Effect.WebGL.Mesh Evergreen.V125.Sprite.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V125.Units.WorldUnit
            }
        )
    | ReportTool
