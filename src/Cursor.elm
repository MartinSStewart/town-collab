module Cursor exposing
    ( Cursor
    , CursorMeshes
    , CursorSprite(..)
    , CursorType(..)
    , OtherUsersTool(..)
    , defaultColors
    , defaultCursor
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
    , fromOtherUsersTool
    , gavelCursor2
    , gavelCursorMesh
    , getSpriteMesh
    , htmlAttribute
    , meshes
    , pinchCursorTexturePosition
    , pinchCursorTextureSize
    , pointerCursorMesh
    , textCursorMesh2
    )

import Color exposing (Color, Colors)
import Coord exposing (Coord)
import DisplayName exposing (DisplayName)
import Effect.Time
import Effect.WebGL
import Html
import Html.Attributes
import Id exposing (AnimalId, Id, UserId)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Shaders exposing (Vertex)
import Sprite
import Ui
import Units exposing (WorldUnit)
import WebGL


type alias Cursor =
    { position : Point2d WorldUnit WorldUnit
    , holdingCow : Maybe { cowId : Id AnimalId, pickupTime : Effect.Time.Posix }
    , currentTool : OtherUsersTool
    }


defaultCursor : Point2d WorldUnit WorldUnit -> Maybe { cowId : Id AnimalId, pickupTime : Effect.Time.Posix } -> Cursor
defaultCursor position holdingCow =
    { position = position
    , holdingCow = holdingCow
    , currentTool = HandTool
    }


type OtherUsersTool
    = HandTool
    | TilePlacerTool
    | TilePickerTool
    | EraserTool
    | TextTool (Maybe { cursorPosition : Coord WorldUnit })
    | ReportTool


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Vertex
    , pointerSprite : WebGL.Mesh Vertex
    , dragScreenSprite : WebGL.Mesh Vertex
    , pinchSprite : WebGL.Mesh Vertex
    , eyeDropperSprite : WebGL.Mesh Vertex
    , eraserSprite : WebGL.Mesh Vertex
    , textSprite : WebGL.Mesh Vertex
    , gavelSprite : WebGL.Mesh Vertex
    }


fromOtherUsersTool : OtherUsersTool -> CursorSprite
fromOtherUsersTool tool =
    case tool of
        HandTool ->
            DefaultSpriteCursor

        EraserTool ->
            EraserSpriteCursor

        TilePlacerTool ->
            DefaultSpriteCursor

        TilePickerTool ->
            EyeDropperSpriteCursor

        TextTool (Just _) ->
            TextSpriteCursor

        TextTool Nothing ->
            DefaultSpriteCursor

        ReportTool ->
            GavelSpriteCursor


meshes : Maybe ( Id UserId, DisplayName ) -> Colors -> CursorMeshes
meshes showName colors =
    let
        nameTag2 : Coord Pixels -> List Vertex
        nameTag2 offset =
            case showName of
                Just showName2 ->
                    nameTag offset showName2

                Nothing ->
                    []
    in
    { defaultSprite = nameTag2 Coord.origin ++ defaultCursorMesh colors |> Sprite.toMesh
    , pointerSprite = nameTag2 Coord.origin ++ pointerCursorMesh colors |> Sprite.toMesh
    , dragScreenSprite = dragScreenCursorMesh colors
    , pinchSprite = nameTag2 (Coord.xy 0 -16) ++ pinchCursorMesh colors |> Sprite.toMesh
    , eyeDropperSprite = nameTag2 (Coord.xy 0 -16) ++ eyeDropperCursorMesh |> Sprite.toMesh
    , eraserSprite = nameTag2 (Coord.xy 0 -16) ++ eraserCursorMesh |> Sprite.toMesh
    , textSprite = nameTag2 Coord.origin ++ textCursorMesh |> Sprite.toMesh
    , gavelSprite = nameTag2 Coord.origin ++ gavelCursorMesh |> Sprite.toMesh
    }


textCursorMesh2 : Effect.WebGL.Mesh Vertex
textCursorMesh2 =
    Sprite.rectangle Color.white Coord.origin (Coord.multiply Units.tileSize (Coord.xy 1 2))
        |> Sprite.toMesh


nameTag : Coord Pixels -> ( Id UserId, DisplayName ) -> List Vertex
nameTag offset ( userId, name ) =
    let
        text =
            DisplayName.nameAndId name userId

        textOffset =
            Sprite.textSize 1 text
                |> Coord.multiplyTuple_ ( -0.5, -1.4 )
                |> Coord.plus (Coord.xy 12 0)
                |> Coord.plus offset
    in
    Sprite.outlinedText Color.outlineColor Color.white 1 text textOffset


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
    | TextSpriteCursor
    | GavelSpriteCursor


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

        TextSpriteCursor ->
            cursorMeshes.textSprite

        GavelSpriteCursor ->
            cursorMeshes.gavelSprite


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


pinchCursorMesh : Colors -> List Vertex
pinchCursorMesh colors =
    Sprite.spriteWithTwoColors
        colors
        (Coord.xy -15 -19)
        pinchCursorTextureSize
        pinchCursorTexturePosition
        pinchCursorTextureSize


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


defaultCursorMesh2 : Colors -> Ui.Element id
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


textCursorMesh : List Vertex
textCursorMesh =
    Sprite.sprite (Coord.xy -7 -9) (Coord.xy 14 33) (Coord.xy 560 74) (Coord.xy 14 33)


eyeDropperCursorMesh : List Vertex
eyeDropperCursorMesh =
    Sprite.sprite (Coord.xy 0 -19) eyeDropperSize (Coord.xy 534 78) eyeDropperSize


eyeDropperSize : Coord units
eyeDropperSize =
    Coord.xy 19 19


eyeDropperCursor2 : Ui.Element id
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


gavelSize =
    Coord.xy 21 21


gavelCursorMesh : List Vertex
gavelCursorMesh =
    Sprite.sprite
        (Coord.xy -4 -4)
        gavelSize
        (Coord.xy 504 82)
        gavelSize


gavelCursor2 : Ui.Element id
gavelCursor2 =
    Ui.sprite
        { size = Coord.scalar 2 gavelSize
        , texturePosition = Coord.xy 504 82
        , textureSize = gavelSize
        }
