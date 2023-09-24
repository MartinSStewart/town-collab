module Evergreen.V88.Cursor exposing (..)

import Effect.Time
import Evergreen.V88.Coord
import Evergreen.V88.Id
import Evergreen.V88.Point2d
import Evergreen.V88.Shaders
import Evergreen.V88.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V88.Point2d.Point2d Evergreen.V88.Units.WorldUnit Evergreen.V88.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V88.Id.Id Evergreen.V88.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V88.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V88.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V88.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V88.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V88.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V88.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V88.Shaders.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V88.Shaders.Vertex
    }
