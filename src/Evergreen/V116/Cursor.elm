module Evergreen.V116.Cursor exposing (..)

import Effect.Time
import Evergreen.V116.Coord
import Evergreen.V116.Id
import Evergreen.V116.Point2d
import Evergreen.V116.Sprite
import Evergreen.V116.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V116.Id.Id Evergreen.V116.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V116.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V116.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V116.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V116.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V116.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V116.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V116.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V116.Sprite.Vertex
    }
