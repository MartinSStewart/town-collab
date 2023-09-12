module Evergreen.V84.Cursor exposing (..)

import Effect.Time
import Evergreen.V84.Coord
import Evergreen.V84.Id
import Evergreen.V84.Point2d
import Evergreen.V84.Shaders
import Evergreen.V84.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V84.Point2d.Point2d Evergreen.V84.Units.WorldUnit Evergreen.V84.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V84.Id.Id Evergreen.V84.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V84.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V84.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V84.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V84.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V84.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V84.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V84.Shaders.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V84.Shaders.Vertex
    }
