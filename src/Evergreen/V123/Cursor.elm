module Evergreen.V123.Cursor exposing (..)

import Effect.Time
import Evergreen.V123.Coord
import Evergreen.V123.Id
import Evergreen.V123.Point2d
import Evergreen.V123.Sprite
import Evergreen.V123.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V123.Id.Id Evergreen.V123.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V123.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V123.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V123.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V123.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V123.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V123.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V123.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V123.Sprite.Vertex
    }
