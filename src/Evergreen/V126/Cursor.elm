module Evergreen.V126.Cursor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V126.Coord
import Evergreen.V126.Id
import Evergreen.V126.Point2d
import Evergreen.V126.Sprite
import Evergreen.V126.Units


type AnimalOrNpcId
    = AnimalId (Evergreen.V126.Id.Id Evergreen.V126.Id.AnimalId)
    | NpcId (Evergreen.V126.Id.Id Evergreen.V126.Id.NpcId)


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
            }
        )
    | ReportTool


type Holding
    = HoldingAnimalOrNpc
        { animalOrNpcId : AnimalOrNpcId
        , pickupTime : Effect.Time.Posix
        }
    | NotHolding


type alias Cursor =
    { position : Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit
    , holding : Holding
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : Effect.WebGL.Mesh Evergreen.V126.Sprite.Vertex
    , pointerSprite : Effect.WebGL.Mesh Evergreen.V126.Sprite.Vertex
    , dragScreenSprite : Effect.WebGL.Mesh Evergreen.V126.Sprite.Vertex
    , pinchSprite : Effect.WebGL.Mesh Evergreen.V126.Sprite.Vertex
    , eyeDropperSprite : Effect.WebGL.Mesh Evergreen.V126.Sprite.Vertex
    , eraserSprite : Effect.WebGL.Mesh Evergreen.V126.Sprite.Vertex
    , textSprite : Effect.WebGL.Mesh Evergreen.V126.Sprite.Vertex
    , gavelSprite : Effect.WebGL.Mesh Evergreen.V126.Sprite.Vertex
    }
