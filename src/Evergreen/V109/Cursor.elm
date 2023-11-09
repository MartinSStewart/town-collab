module Evergreen.V109.Cursor exposing (..)

import Effect.Time
import Evergreen.V109.Coord
import Evergreen.V109.Id
import Evergreen.V109.Point2d
import Evergreen.V109.Sprite
import Evergreen.V109.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V109.Id.Id Evergreen.V109.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V109.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V109.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V109.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V109.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V109.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V109.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V109.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V109.Sprite.Vertex
    }
