module Evergreen.V100.Cursor exposing (..)

import Effect.Time
import Evergreen.V100.Coord
import Evergreen.V100.Id
import Evergreen.V100.Point2d
import Evergreen.V100.Sprite
import Evergreen.V100.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V100.Id.Id Evergreen.V100.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V100.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V100.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V100.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V100.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V100.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V100.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V100.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V100.Sprite.Vertex
    }
