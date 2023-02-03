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
    , eraserCursorMesh
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
import DisplayName exposing (DisplayName)
import Html
import Html.Attributes
import Id exposing (Id, UserId)
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
    , eraserSprite : WebGL.Mesh Vertex
    }


meshes : Maybe ( Id UserId, DisplayName ) -> Colors -> CursorMeshes
meshes showName colors =
    let
        nameTag2 : List Vertex
        nameTag2 =
            case showName of
                Just showName2 ->
                    nameTag showName2

                Nothing ->
                    []
    in
    { defaultSprite = nameTag2 ++ defaultCursorMesh colors |> Sprite.toMesh
    , pointerSprite = nameTag2 ++ pointerCursorMesh colors |> Sprite.toMesh
    , dragScreenSprite = dragScreenCursorMesh colors
    , pinchSprite = pinchCursorMesh colors
    , eyeDropperSprite = eyeDropperCursorMesh
    , eraserSprite = Sprite.toMesh eraserCursorMesh
    }


nameTag : ( Id UserId, DisplayName ) -> List Vertex
nameTag ( userId, name ) =
    let
        text =
            DisplayName.nameAndId name userId

        textSize =
            Sprite.textSize 1 text |> Coord.multiplyTuple_ ( -0.5, -1.4 ) |> Coord.plus (Coord.xy 12 0)
    in
    Sprite.outlinedText Color.outlineColor Color.white 1 text textSize


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
    | EraserSpriteCursor


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

        EraserSpriteCursor ->
            cursorMeshes.eraserSprite


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


defaultCursorMesh : Colors -> List Vertex
defaultCursorMesh colors =
    Sprite.spriteWithTwoColors
        colors
        (Coord.xy -2 -3)
        defaultCursorTextureSize
        defaultCursorTexturePosition
        defaultCursorTextureSize


defaultCursorTexturePosition : Coord units
defaultCursorTexturePosition =
    Coord.xy 533 28


defaultCursorMesh2 : Colors -> Ui.Element id msg
defaultCursorMesh2 colors =
    Ui.colorSprite
        { colors = colors
        , size = Coord.scalar 2 defaultCursorTextureSize
        , texturePosition = defaultCursorTexturePosition
        , textureSize = defaultCursorTextureSize
        }


eraserCursorMesh : List Vertex
eraserCursorMesh =
    Sprite.sprite (Coord.xy -2 -24) (Coord.xy 28 27) (Coord.xy 504 42) (Coord.xy 28 27)


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
        { size = Coord.scalar 2 eyeDropperSize
        , texturePosition = Coord.xy 534 78
        , textureSize = eyeDropperSize
        }


handPointerSize : Coord units
handPointerSize =
    Coord.xy 27 26


pointerCursorMesh : Colors -> List Vertex
pointerCursorMesh colors =
    Sprite.spriteWithTwoColors
        colors
        (Coord.xy -10 -1)
        handPointerSize
        (Coord.xy 563 28)
        handPointerSize
