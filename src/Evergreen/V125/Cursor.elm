module Evergreen.V125.Cursor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V125.Coord
import Evergreen.V125.Id
import Evergreen.V125.Point2d
import Evergreen.V125.Sprite
import Evergreen.V125.Units


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
            }
        )
    | ReportTool


type alias Cursor =
    { position : Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit
    , holdingCow :
        Maybe
            { cowId : Evergreen.V125.Id.Id Evergreen.V125.Id.AnimalId
            , pickupTime : Effect.Time.Posix
            }
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : Effect.WebGL.Mesh Evergreen.V125.Sprite.Vertex
    , pointerSprite : Effect.WebGL.Mesh Evergreen.V125.Sprite.Vertex
    , dragScreenSprite : Effect.WebGL.Mesh Evergreen.V125.Sprite.Vertex
    , pinchSprite : Effect.WebGL.Mesh Evergreen.V125.Sprite.Vertex
    , eyeDropperSprite : Effect.WebGL.Mesh Evergreen.V125.Sprite.Vertex
    , eraserSprite : Effect.WebGL.Mesh Evergreen.V125.Sprite.Vertex
    , textSprite : Effect.WebGL.Mesh Evergreen.V125.Sprite.Vertex
    , gavelSprite : Effect.WebGL.Mesh Evergreen.V125.Sprite.Vertex
    }
