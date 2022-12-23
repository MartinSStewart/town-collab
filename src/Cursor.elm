module Cursor exposing
    ( CursorMeshes
    , CursorSprite(..)
    , CursorType(..)
    , defaultColors
    , defaultCursorMesh
    , dragScreenCursorMesh
    , getSpriteMesh
    , htmlAttribute
    , meshes
    , pointerCursorMesh
    )

import Color exposing (Color)
import Coord exposing (Coord)
import Html
import Html.Attributes
import Shaders exposing (Vertex)
import Sprite
import WebGL


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Vertex
    , pointerSprite : WebGL.Mesh Vertex
    , dragScreenSprite : WebGL.Mesh Vertex
    , pinchSprite : WebGL.Mesh Vertex
    , eyeDropperSprite : WebGL.Mesh Vertex
    }


meshes : { primaryColor : Color, secondaryColor : Color } -> CursorMeshes
meshes colors =
    { defaultSprite = defaultCursorMesh colors
    , pointerSprite = pointerCursorMesh colors
    , dragScreenSprite = dragScreenCursorMesh colors
    , pinchSprite = pinchCursorMesh colors
    , eyeDropperSprite = eyeDropperCursorMesh colors
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


handSize =
    Coord.xy 30 23


defaultColors =
    { primaryColor = Color.rgb255 190 190 185, secondaryColor = Color.rgb255 165 165 160 }


pinchCursorMesh : { primaryColor : Color, secondaryColor : Color } -> WebGL.Mesh Vertex
pinchCursorMesh colors =
    Sprite.spriteWithTwoColors
        colors
        (Coord.xy -15 -19)
        (Coord.xy 31 20)
        (Coord.xy 560 54)
        (Coord.xy 31 20)
        |> Sprite.toMesh


dragScreenCursorMesh : { primaryColor : Color, secondaryColor : Color } -> WebGL.Mesh Vertex
dragScreenCursorMesh colors =
    Sprite.spriteWithTwoColors
        colors
        (Coord.xy -14 -13)
        (Coord.xy 28 26)
        (Coord.xy 532 51)
        (Coord.xy 28 26)
        |> Sprite.toMesh


defaultCursorMesh : { primaryColor : Color, secondaryColor : Color } -> WebGL.Mesh Vertex
defaultCursorMesh colors =
    Sprite.spriteWithTwoColors
        colors
        (Coord.xy -2 -3)
        handSize
        (Coord.xy 533 28)
        handSize
        |> Sprite.toMesh


handPointerSize : Coord units
handPointerSize =
    Coord.xy 27 26


pointerCursorMesh : { primaryColor : Color, secondaryColor : Color } -> WebGL.Mesh Vertex
pointerCursorMesh colors =
    Sprite.spriteWithTwoColors
        colors
        (Coord.xy -10 -1)
        handPointerSize
        (Coord.xy 563 28)
        handPointerSize
        |> Sprite.toMesh


eyeDropperCursorMesh : { primaryColor : Color, secondaryColor : Color } -> WebGL.Mesh Vertex
eyeDropperCursorMesh colors =
    Sprite.spriteWithTwoColors
        colors
        (Coord.xy -10 -1)
        handPointerSize
        (Coord.xy 563 28)
        handPointerSize
        |> Sprite.toMesh
