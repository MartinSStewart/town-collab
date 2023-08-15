module Evergreen.V77.Cursor exposing (..)

import Effect.Time
import Evergreen.V77.Coord
import Evergreen.V77.Id
import Evergreen.V77.Point2d
import Evergreen.V77.Shaders
import Evergreen.V77.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V77.Point2d.Point2d Evergreen.V77.Units.WorldUnit Evergreen.V77.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V77.Id.Id Evergreen.V77.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V77.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V77.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V77.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V77.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V77.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V77.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V77.Shaders.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V77.Shaders.Vertex
    }
