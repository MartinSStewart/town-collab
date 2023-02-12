module Evergreen.V62.Cursor exposing (..)

import Effect.Time
import Evergreen.V62.Coord
import Evergreen.V62.Id
import Evergreen.V62.Point2d
import Evergreen.V62.Shaders
import Evergreen.V62.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V62.Coord.Coord Evergreen.V62.Units.WorldUnit
            }
        )


type alias Cursor =
    { position : Evergreen.V62.Point2d.Point2d Evergreen.V62.Units.WorldUnit Evergreen.V62.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V62.Id.Id Evergreen.V62.Id.CowId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V62.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V62.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V62.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V62.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V62.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V62.Shaders.Vertex
    , textSprite : WebGL.Mesh Evergreen.V62.Shaders.Vertex
    }
