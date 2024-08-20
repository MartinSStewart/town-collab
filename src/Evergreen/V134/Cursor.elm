module Evergreen.V134.Cursor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V134.Coord
import Evergreen.V134.Id
import Evergreen.V134.Point2d
import Evergreen.V134.Sprite
import Evergreen.V134.Units


type AnimalOrNpcId
    = AnimalId (Evergreen.V134.Id.Id Evergreen.V134.Id.AnimalId)
    | NpcId (Evergreen.V134.Id.Id Evergreen.V134.Id.NpcId)


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
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
    { position : Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit
    , holding : Holding
    , currentTool : OtherUsersTool
    }


type alias CursorMeshes =
    { defaultSprite : Effect.WebGL.Mesh Evergreen.V134.Sprite.Vertex
    , pointerSprite : Effect.WebGL.Mesh Evergreen.V134.Sprite.Vertex
    , dragScreenSprite : Effect.WebGL.Mesh Evergreen.V134.Sprite.Vertex
    , pinchSprite : Effect.WebGL.Mesh Evergreen.V134.Sprite.Vertex
    , eyeDropperSprite : Effect.WebGL.Mesh Evergreen.V134.Sprite.Vertex
    , eraserSprite : Effect.WebGL.Mesh Evergreen.V134.Sprite.Vertex
    , textSprite : Effect.WebGL.Mesh Evergreen.V134.Sprite.Vertex
    , gavelSprite : Effect.WebGL.Mesh Evergreen.V134.Sprite.Vertex
    }
