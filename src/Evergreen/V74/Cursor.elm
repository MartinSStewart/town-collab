module Evergreen.V74.Cursor exposing (..)

import Effect.Time
import Evergreen.V74.Coord
import Evergreen.V74.Id
import Evergreen.V74.Point2d
import Evergreen.V74.Shaders
import Evergreen.V74.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V74.Point2d.Point2d Evergreen.V74.Units.WorldUnit Evergreen.V74.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V74.Id.Id Evergreen.V74.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V74.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V74.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V74.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V74.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V74.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V74.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V74.Shaders.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V74.Shaders.Vertex
    }
