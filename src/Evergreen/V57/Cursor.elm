module Evergreen.V57.Cursor exposing (..)

import Effect.Time
import Evergreen.V57.Coord
import Evergreen.V57.Id
import Evergreen.V57.Point2d
import Evergreen.V57.Shaders
import Evergreen.V57.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V57.Coord.Coord Evergreen.V57.Units.WorldUnit
            }
        )


type alias Cursor =
    { position : Evergreen.V57.Point2d.Point2d Evergreen.V57.Units.WorldUnit Evergreen.V57.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V57.Id.Id Evergreen.V57.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V57.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V57.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V57.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V57.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V57.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V57.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V57.Shaders.Vertex
    }
