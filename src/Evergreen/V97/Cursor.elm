module Evergreen.V97.Cursor exposing (..)

import Effect.Time
import Evergreen.V97.Coord
import Evergreen.V97.Id
import Evergreen.V97.Point2d
import Evergreen.V97.Sprite
import Evergreen.V97.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V97.Point2d.Point2d Evergreen.V97.Units.WorldUnit Evergreen.V97.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V97.Id.Id Evergreen.V97.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V97.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V97.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V97.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V97.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V97.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V97.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V97.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V97.Sprite.Vertex
    }
