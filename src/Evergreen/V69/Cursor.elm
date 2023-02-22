module Evergreen.V69.Cursor exposing (..)

import Effect.Time
import Evergreen.V69.Coord
import Evergreen.V69.Id
import Evergreen.V69.Point2d
import Evergreen.V69.Shaders
import Evergreen.V69.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V69.Point2d.Point2d Evergreen.V69.Units.WorldUnit Evergreen.V69.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V69.Id.Id Evergreen.V69.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V69.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V69.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V69.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V69.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V69.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V69.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V69.Shaders.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V69.Shaders.Vertex
    }
