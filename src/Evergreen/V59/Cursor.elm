module Evergreen.V59.Cursor exposing (..)

import Effect.Time
import Evergreen.V59.Coord
import Evergreen.V59.Id
import Evergreen.V59.Point2d
import Evergreen.V59.Shaders
import Evergreen.V59.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V59.Coord.Coord Evergreen.V59.Units.WorldUnit
            }
        )


type alias Cursor =
    { position : Evergreen.V59.Point2d.Point2d Evergreen.V59.Units.WorldUnit Evergreen.V59.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V59.Id.Id Evergreen.V59.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V59.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V59.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V59.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V59.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V59.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V59.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V59.Shaders.Vertex
    }
