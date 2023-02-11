module Evergreen.V58.Cursor exposing (..)

import Effect.Time
import Evergreen.V58.Coord
import Evergreen.V58.Id
import Evergreen.V58.Point2d
import Evergreen.V58.Shaders
import Evergreen.V58.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V58.Coord.Coord Evergreen.V58.Units.WorldUnit
            }
        )


type alias Cursor =
    { position : Evergreen.V58.Point2d.Point2d Evergreen.V58.Units.WorldUnit Evergreen.V58.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V58.Id.Id Evergreen.V58.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V58.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V58.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V58.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V58.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V58.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V58.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V58.Shaders.Vertex
    }
