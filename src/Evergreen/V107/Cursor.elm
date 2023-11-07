module Evergreen.V107.Cursor exposing (..)

import Effect.Time
import Evergreen.V107.Coord
import Evergreen.V107.Id
import Evergreen.V107.Point2d
import Evergreen.V107.Sprite
import Evergreen.V107.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V107.Id.Id Evergreen.V107.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V107.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V107.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V107.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V107.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V107.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V107.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V107.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V107.Sprite.Vertex
    }
