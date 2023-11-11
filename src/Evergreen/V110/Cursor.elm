module Evergreen.V110.Cursor exposing (..)

import Effect.Time
import Evergreen.V110.Coord
import Evergreen.V110.Id
import Evergreen.V110.Point2d
import Evergreen.V110.Sprite
import Evergreen.V110.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V110.Coord.Coord Evergreen.V110.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V110.Point2d.Point2d Evergreen.V110.Units.WorldUnit Evergreen.V110.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V110.Id.Id Evergreen.V110.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V110.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V110.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V110.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V110.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V110.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V110.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V110.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V110.Sprite.Vertex
    }
