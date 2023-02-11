module Evergreen.V60.Cursor exposing (..)

import Effect.Time
import Evergreen.V60.Coord
import Evergreen.V60.Id
import Evergreen.V60.Point2d
import Evergreen.V60.Shaders
import Evergreen.V60.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V60.Coord.Coord Evergreen.V60.Units.WorldUnit
            }
        )


type alias Cursor =
    { position : Evergreen.V60.Point2d.Point2d Evergreen.V60.Units.WorldUnit Evergreen.V60.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V60.Id.Id Evergreen.V60.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V60.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V60.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V60.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V60.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V60.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V60.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V60.Shaders.Vertex
    }
