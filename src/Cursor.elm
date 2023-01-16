module Cursor exposing
    ( CursorMeshes
    , CursorSprite(..)
    , CursorType(..)
    , defaultColors
    , defaultCursorMesh
    , defaultCursorMesh2
    , defaultCursorTexturePosition
    , defaultCursorTextureSize
    , dragCursorTexturePosition
    , dragCursorTextureSize
    , dragScreenCursorMesh
    , eyeDropperCursor2
    , eyeDropperCursorMesh
    , getSpriteMesh
    , htmlAttribute
    , meshes
    , pinchCursorTexturePosition
    , pinchCursorTextureSize
    , pointerCursorMesh
    )

import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Html
import Html.Attributes
import Shaders exposing (Vertex)
import Sprite
import Ui
import WebGL


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Vertex
    , pointerSprite : WebGL.Mesh Vertex
    , dragScreenSprite : WebGL.Mesh Vertex
    , pinchSprite : WebGL.Mesh Vertex
    , eyeDropperSprite : WebGL.Mesh Vertex
    }


meshes : Colors -> CursorMeshes
meshes colors =
    { defaultSprite = defaultCursorMesh colors
    , pointerSprite = pointerCursorMesh colors
    , dragScreenSprite = dragScreenCursorMesh colors
    , pinchSprite = pinchCursorMesh colors
    , eyeDropperSprite = eyeDropperCursorMesh
    }


type CursorType
    = DefaultCursor
    | PointerCursor
    | CursorSprite CursorSprite
    | NoCursor


type CursorSprite
    = DefaultSpriteCursor
    | PointerSpriteCursor
    | DragScreenSpriteCursor
    | PinchSpriteCursor
    | EyeDropperSpriteCursor


getSpriteMesh : CursorSprite -> CursorMeshes -> WebGL.Mesh Vertex
getSpriteMesh cursorSprite cursorMeshes =
    case cursorSprite of
        DefaultSpriteCursor ->
            cursorMeshes.defaultSprite

        PointerSpriteCursor ->
            cursorMeshes.pointerSprite

        DragScreenSpriteCursor ->
            cursorMeshes.dragScreenSprite

        PinchSpriteCursor ->
            cursorMeshes.pinchSprite

        EyeDropperSpriteCursor ->
            cursorMeshes.eyeDropperSprite


htmlAttribute : CursorType -> Html.Attribute msg
htmlAttribute cursor =
    Html.Attributes.style
        "cursor"
        (case cursor of
            DefaultCursor ->
                "default"

            PointerCursor ->
                "pointer"

            CursorSprite _ ->
                "none"

            NoCursor ->
                "none"
        )


defaultCursorTextureSize : Coord units
defaultCursorTextureSize =
    Coord.xy 30 23


defaultColors : { primaryColor : Color, secondaryColor : Color }
defaultColors =
    { primaryColor = Color.rgb255 190 190 185, secondaryColor = Color.rgb255 165 165 160 }


pinchCursorMesh : Colors -> WebGL.Mesh Vertex
pinchCursorMesh colors =
    Sprite.spriteWithTwoColors
        colors
        (Coord.xy -15 -19)
        pinchCursorTextureSize
        pinchCursorTexturePosition
        pinchCursorTextureSize
        |> Sprite.toMesh


pinchCursorTexturePosition : Coord units
pinchCursorTexturePosition =
    Coord.xy 560 54


pinchCursorTextureSize : Coord units
pinchCursorTextureSize =
    Coord.xy 31 20


dragScreenCursorMesh : Colors -> WebGL.Mesh Vertex
dragScreenCursorMesh colors =
    Sprite.spriteWithTwoColors
        colors
        (Coord.xy -14 -13)
        dragCursorTextureSize
        dragCursorTexturePosition
        dragCursorTextureSize
        |> Sprite.toMesh


dragCursorTexturePosition : Coord units
dragCursorTexturePosition =
    Coord.xy 532 51


dragCursorTextureSize : Coord units
dragCursorTextureSize =
    Coord.xy 28 26


defaultCursorMesh : Colors -> WebGL.Mesh Vertex
defaultCursorMesh colors =
    Sprite.spriteWithTwoColors
        colors
        (Coord.xy -2 -3)
        defaultCursorTextureSize
        defaultCursorTexturePosition
        defaultCursorTextureSize
        |> Sprite.toMesh


defaultCursorTexturePosition : Coord units
defaultCursorTexturePosition =
    Coord.xy 533 28


defaultCursorMesh2 : Colors -> Ui.Element id msg
defaultCursorMesh2 colors =
    Ui.colorSprite
        { colors = colors
        , size = Coord.multiply (Coord.xy 2 2) defaultCursorTextureSize
        , texturePosition = defaultCursorTexturePosition
        , textureSize = defaultCursorTextureSize
        }


eyeDropperCursorMesh : WebGL.Mesh Vertex
eyeDropperCursorMesh =
    Sprite.sprite
        (Coord.xy 0 -19)
        eyeDropperSize
        (Coord.xy 534 78)
        eyeDropperSize
        |> Sprite.toMesh


eyeDropperSize : Coord units
eyeDropperSize =
    Coord.xy 19 19


eyeDropperCursor2 : Ui.Element id msg
eyeDropperCursor2 =
    Ui.sprite
        { size = Coord.multiply (Coord.xy 2 2) eyeDropperSize
        , texturePosition = Coord.xy 534 78
        , textureSize = eyeDropperSize
        }


handPointerSize : Coord units
handPointerSize =
    Coord.xy 27 26


pointerCursorMesh : Colors -> WebGL.Mesh Vertex
pointerCursorMesh colors =
    Sprite.spriteWithTwoColors
        colors
        (Coord.xy -10 -1)
        handPointerSize
        (Coord.xy 563 28)
        handPointerSize
        |> Sprite.toMesh
