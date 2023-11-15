module Evergreen.V114.Cursor exposing (..)

import Effect.Time
import Evergreen.V114.Coord
import Evergreen.V114.Id
import Evergreen.V114.Point2d
import Evergreen.V114.Sprite
import Evergreen.V114.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V114.Id.Id Evergreen.V114.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V114.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V114.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V114.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V114.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V114.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V114.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V114.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V114.Sprite.Vertex
    }
