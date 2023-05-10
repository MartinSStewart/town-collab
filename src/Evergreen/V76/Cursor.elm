module Evergreen.V76.Cursor exposing (..)

import Effect.Time
import Evergreen.V76.Coord
import Evergreen.V76.Id
import Evergreen.V76.Point2d
import Evergreen.V76.Shaders
import Evergreen.V76.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V76.Point2d.Point2d Evergreen.V76.Units.WorldUnit Evergreen.V76.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V76.Id.Id Evergreen.V76.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V76.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V76.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V76.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V76.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V76.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V76.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V76.Shaders.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V76.Shaders.Vertex
    }
