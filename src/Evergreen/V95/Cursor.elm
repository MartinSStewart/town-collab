module Evergreen.V95.Cursor exposing (..)

import Effect.Time
import Evergreen.V95.Coord
import Evergreen.V95.Id
import Evergreen.V95.Point2d
import Evergreen.V95.Sprite
import Evergreen.V95.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V95.Point2d.Point2d Evergreen.V95.Units.WorldUnit Evergreen.V95.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V95.Id.Id Evergreen.V95.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V95.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V95.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V95.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V95.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V95.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V95.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V95.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V95.Sprite.Vertex
    }
