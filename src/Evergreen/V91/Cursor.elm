module Evergreen.V91.Cursor exposing (..)

import Effect.Time
import Evergreen.V91.Coord
import Evergreen.V91.Id
import Evergreen.V91.Point2d
import Evergreen.V91.Shaders
import Evergreen.V91.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V91.Point2d.Point2d Evergreen.V91.Units.WorldUnit Evergreen.V91.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V91.Id.Id Evergreen.V91.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V91.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V91.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V91.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V91.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V91.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V91.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V91.Shaders.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V91.Shaders.Vertex
    }
