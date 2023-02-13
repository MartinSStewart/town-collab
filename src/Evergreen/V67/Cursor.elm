module Evergreen.V67.Cursor exposing (..)

import Effect.Time
import Evergreen.V67.Coord
import Evergreen.V67.Id
import Evergreen.V67.Point2d
import Evergreen.V67.Shaders
import Evergreen.V67.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V67.Coord.Coord Evergreen.V67.Units.WorldUnit
            }
        )


type alias Cursor =
    { position : Evergreen.V67.Point2d.Point2d Evergreen.V67.Units.WorldUnit Evergreen.V67.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V67.Id.Id Evergreen.V67.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V67.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V67.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V67.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V67.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V67.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V67.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V67.Shaders.Vertex
    }
