module Cursor exposing (CursorSprite(..), CursorType(..), defaultCursorMesh, dragScreenCursorMesh, htmlAttribute, pointerCursorMesh, toMesh)

import Color exposing (Color)
import Coord exposing (Coord)
import Html
import Html.Attributes
import Shaders exposing (Vertex)
import Sprite
import WebGL


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


toMesh : CursorSprite -> WebGL.Mesh Vertex
toMesh cursorSprite =
    case cursorSprite of
        DefaultSpriteCursor ->
            defaultCursorMesh

        PointerSpriteCursor ->
            pointerCursorMesh

        DragScreenSpriteCursor ->
            dragScreenCursorMesh

        PinchSpriteCursor ->
            pinchCursorMesh


handSize =
    Coord.xy 30 23


handPrimaryColor : Color
handPrimaryColor =
    Color.rgb255 190 190 185


handSecondaryColor : Color
handSecondaryColor =
    Color.rgb255 165 165 160


pinchCursorMesh : WebGL.Mesh Vertex
pinchCursorMesh =
    Sprite.spriteWithTwoColors
        { primaryColor = handPrimaryColor, secondaryColor = handSecondaryColor }
        (Coord.xy -15 -19)
        (Coord.xy 31 20)
        (Coord.xy 560 54)
        (Coord.xy 31 20)
        |> Sprite.toMesh


dragScreenCursorMesh : WebGL.Mesh Vertex
dragScreenCursorMesh =
    Sprite.spriteWithTwoColors
        { primaryColor = handPrimaryColor, secondaryColor = handSecondaryColor }
        (Coord.xy -14 -13)
        (Coord.xy 28 26)
        (Coord.xy 532 51)
        (Coord.xy 28 26)
        |> Sprite.toMesh


defaultCursorMesh : WebGL.Mesh Vertex
defaultCursorMesh =
    Sprite.spriteWithTwoColors
        { primaryColor = handPrimaryColor, secondaryColor = handSecondaryColor }
        (Coord.xy -2 -3)
        handSize
        (Coord.xy 533 28)
        handSize
        |> Sprite.toMesh


handPointerSize : Coord units
handPointerSize =
    Coord.xy 27 26


pointerCursorMesh : WebGL.Mesh Vertex
pointerCursorMesh =
    Sprite.spriteWithTwoColors
        { primaryColor = handPrimaryColor, secondaryColor = handSecondaryColor }
        (Coord.xy -10 -1)
        handPointerSize
        (Coord.xy 563 28)
        handPointerSize
        |> Sprite.toMesh
