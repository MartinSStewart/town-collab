module Evergreen.V89.Cursor exposing (..)

import Effect.Time
import Evergreen.V89.Coord
import Evergreen.V89.Id
import Evergreen.V89.Point2d
import Evergreen.V89.Shaders
import Evergreen.V89.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V89.Point2d.Point2d Evergreen.V89.Units.WorldUnit Evergreen.V89.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V89.Id.Id Evergreen.V89.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V89.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V89.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V89.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V89.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V89.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V89.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V89.Shaders.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V89.Shaders.Vertex
    }
