module Evergreen.V112.Cursor exposing (..)

import Effect.Time
import Evergreen.V112.Coord
import Evergreen.V112.Id
import Evergreen.V112.Point2d
import Evergreen.V112.Sprite
import Evergreen.V112.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V112.Id.Id Evergreen.V112.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V112.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V112.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V112.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V112.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V112.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V112.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V112.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V112.Sprite.Vertex
    }
