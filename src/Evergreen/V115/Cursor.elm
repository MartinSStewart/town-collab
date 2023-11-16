module Evergreen.V115.Cursor exposing (..)

import Effect.Time
import Evergreen.V115.Coord
import Evergreen.V115.Id
import Evergreen.V115.Point2d
import Evergreen.V115.Sprite
import Evergreen.V115.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V115.Id.Id Evergreen.V115.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V115.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V115.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V115.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V115.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V115.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V115.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V115.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V115.Sprite.Vertex
    }
