module Evergreen.V82.Cursor exposing (..)

import Effect.Time
import Evergreen.V82.Coord
import Evergreen.V82.Id
import Evergreen.V82.Point2d
import Evergreen.V82.Shaders
import Evergreen.V82.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V82.Point2d.Point2d Evergreen.V82.Units.WorldUnit Evergreen.V82.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V82.Id.Id Evergreen.V82.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V82.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V82.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V82.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V82.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V82.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V82.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V82.Shaders.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V82.Shaders.Vertex
    }
