module Evergreen.V108.Cursor exposing (..)

import Effect.Time
import Evergreen.V108.Coord
import Evergreen.V108.Id
import Evergreen.V108.Point2d
import Evergreen.V108.Sprite
import Evergreen.V108.Units
import WebGL


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V108.Id.Id Evergreen.V108.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V108.Sprite.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V108.Sprite.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V108.Sprite.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V108.Sprite.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V108.Sprite.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V108.Sprite.Vertex
    , textSprite : WebGL.Mesh Evergreen.V108.Sprite.Vertex
    , gavelSprite : WebGL.Mesh Evergreen.V108.Sprite.Vertex
    }
