module Evergreen.V111.Cursor exposing (..)

import Effect.Time
import Evergreen.V111.Coord
import Evergreen.V111.Id
import Evergreen.V111.Point2d
import Evergreen.V111.Sprite
import Evergreen.V111.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V111.Id.Id Evergreen.V111.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V111.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V111.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V111.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V111.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V111.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V111.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V111.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V111.Sprite.Vertex
    }
