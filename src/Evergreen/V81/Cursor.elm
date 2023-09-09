module Evergreen.V81.Cursor exposing (..)

import Effect.Time
import Evergreen.V81.Coord
import Evergreen.V81.Id
import Evergreen.V81.Point2d
import Evergreen.V81.Shaders
import Evergreen.V81.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V81.Point2d.Point2d Evergreen.V81.Units.WorldUnit Evergreen.V81.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V81.Id.Id Evergreen.V81.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V81.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V81.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V81.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V81.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V81.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V81.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V81.Shaders.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V81.Shaders.Vertex
    }
