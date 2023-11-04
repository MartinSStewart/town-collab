module Evergreen.V106.Cursor exposing (..)

import Effect.Time
import Evergreen.V106.Coord
import Evergreen.V106.Id
import Evergreen.V106.Point2d
import Evergreen.V106.Sprite
import Evergreen.V106.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V106.Id.Id Evergreen.V106.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V106.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V106.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V106.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V106.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V106.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V106.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V106.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V106.Sprite.Vertex
    }
