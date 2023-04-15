module Evergreen.V75.Cursor exposing (..)

import Effect.Time
import Evergreen.V75.Coord
import Evergreen.V75.Id
import Evergreen.V75.Point2d
import Evergreen.V75.Shaders
import Evergreen.V75.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V75.Point2d.Point2d Evergreen.V75.Units.WorldUnit Evergreen.V75.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V75.Id.Id Evergreen.V75.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V75.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V75.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V75.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V75.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V75.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V75.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V75.Shaders.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V75.Shaders.Vertex
    }
