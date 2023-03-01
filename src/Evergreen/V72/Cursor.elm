module Evergreen.V72.Cursor exposing (..)

import Effect.Time
import Evergreen.V72.Coord
import Evergreen.V72.Id
import Evergreen.V72.Point2d
import Evergreen.V72.Shaders
import Evergreen.V72.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V72.Point2d.Point2d Evergreen.V72.Units.WorldUnit Evergreen.V72.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V72.Id.Id Evergreen.V72.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V72.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V72.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V72.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V72.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V72.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V72.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V72.Shaders.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V72.Shaders.Vertex
    }
