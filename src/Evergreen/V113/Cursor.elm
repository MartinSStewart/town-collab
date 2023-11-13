module Evergreen.V113.Cursor exposing (..)

import Effect.Time
import Evergreen.V113.Coord
import Evergreen.V113.Id
import Evergreen.V113.Point2d
import Evergreen.V113.Sprite
import Evergreen.V113.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V113.Id.Id Evergreen.V113.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V113.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V113.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V113.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V113.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V113.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V113.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V113.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V113.Sprite.Vertex
    }
