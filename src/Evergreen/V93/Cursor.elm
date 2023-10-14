module Evergreen.V93.Cursor exposing (..)

import Effect.Time
import Evergreen.V93.Coord
import Evergreen.V93.Id
import Evergreen.V93.Point2d
import Evergreen.V93.Sprite
import Evergreen.V93.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V93.Point2d.Point2d Evergreen.V93.Units.WorldUnit Evergreen.V93.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V93.Id.Id Evergreen.V93.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V93.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V93.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V93.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V93.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V93.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V93.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V93.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V93.Sprite.Vertex
    }
