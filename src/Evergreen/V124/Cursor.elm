module Evergreen.V124.Cursor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V124.Coord
import Evergreen.V124.Id
import Evergreen.V124.Point2d
import Evergreen.V124.Sprite
import Evergreen.V124.Units


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V124.Id.Id Evergreen.V124.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : Effect.WebGL.Mesh Evergreen.V124.Sprite.Vertex
    , pointerSprite : Effect.WebGL.Mesh Evergreen.V124.Sprite.Vertex
    , dragScreenSprite : Effect.WebGL.Mesh Evergreen.V124.Sprite.Vertex
    , pinchSprite : Effect.WebGL.Mesh Evergreen.V124.Sprite.Vertex
    , eyeDropperSprite : Effect.WebGL.Mesh Evergreen.V124.Sprite.Vertex
    , eraserSprite : Effect.WebGL.Mesh Evergreen.V124.Sprite.Vertex
    , textSprite : Effect.WebGL.Mesh Evergreen.V124.Sprite.Vertex
    , gavelSprite : Effect.WebGL.Mesh Evergreen.V124.Sprite.Vertex
    }
