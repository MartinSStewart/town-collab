module Evergreen.V99.Cursor exposing (..)

import Effect.Time
import Evergreen.V99.Coord
import Evergreen.V99.Id
import Evergreen.V99.Point2d
import Evergreen.V99.Sprite
import Evergreen.V99.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V99.Id.Id Evergreen.V99.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V99.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V99.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V99.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V99.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V99.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V99.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V99.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V99.Sprite.Vertex
    }
