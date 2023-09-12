module Evergreen.V85.Cursor exposing (..)

import Effect.Time
import Evergreen.V85.Coord
import Evergreen.V85.Id
import Evergreen.V85.Point2d
import Evergreen.V85.Shaders
import Evergreen.V85.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V85.Point2d.Point2d Evergreen.V85.Units.WorldUnit Evergreen.V85.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V85.Id.Id Evergreen.V85.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V85.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V85.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V85.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V85.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V85.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V85.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V85.Shaders.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V85.Shaders.Vertex
    }
