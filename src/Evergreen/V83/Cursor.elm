module Evergreen.V83.Cursor exposing (..)

import Effect.Time
import Evergreen.V83.Coord
import Evergreen.V83.Id
import Evergreen.V83.Point2d
import Evergreen.V83.Shaders
import Evergreen.V83.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V83.Point2d.Point2d Evergreen.V83.Units.WorldUnit Evergreen.V83.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V83.Id.Id Evergreen.V83.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V83.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V83.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V83.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V83.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V83.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V83.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V83.Shaders.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V83.Shaders.Vertex
    }
