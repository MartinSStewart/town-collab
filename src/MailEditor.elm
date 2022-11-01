module MailEditor exposing
    ( BackendMail
    , FrontendMail
    , Image(..)
    , MailEditor
    , MailEditorData
    , MailStatus(..)
    , ShowMailEditor(..)
    , close
    , drawMail
    , getImageData
    , handleMouseDown
    , init
    , initEditor
    , isOpen
    , open
    , openAnimationLength
    , redo
    , undo
    )

import Audio exposing (Audio)
import Coord exposing (Coord)
import Duration exposing (Duration)
import Frame2d
import Grid exposing (Vertex)
import Id exposing (Id, TrainId, UserId)
import Math.Matrix4 as Mat4
import Math.Vector2 as Vec2 exposing (Vec2)
import Math.Vector3 as Vec3
import Math.Vector4 as Vec4
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Shaders exposing (SimpleVertex)
import Tile
import Time
import Units exposing (MailPixelUnit, UiPixelUnit, WorldUnit)
import Vector2d
import WebGL
import WebGL.Settings.Blend as Blend
import WebGL.Texture


type alias BackendMail =
    { message : String
    , status : MailStatus
    , sender : Id UserId
    , recipient : Id UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , sender : Id UserId
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Id TrainId)
    | MailReceived


type alias MailEditor =
    { mesh : WebGL.Mesh Vertex
    , currentImage : Image
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , showMailEditor : ShowMailEditor
    }


type alias EditorState =
    { content : List { position : Coord MailPixelUnit, image : Image }, recipient : Maybe (Id UserId) }


type alias MailEditorData =
    { recipient : Maybe (Id UserId)
    , content : List { position : Coord MailPixelUnit, image : Image }
    }


type Image
    = BlueStamp
    | SunglassesSmiley
    | NormalSmiley


openAnimationLength : Duration
openAnimationLength =
    Duration.milliseconds 300


isOpen : MailEditor -> Bool
isOpen { showMailEditor } =
    case showMailEditor of
        MailEditorClosed ->
            False

        MailEditorOpening _ ->
            True

        MailEditorClosing _ ->
            False


type ShowMailEditor
    = MailEditorClosed
    | MailEditorOpening { startTime : Time.Posix, startPosition : Point2d Pixels Pixels }
    | MailEditorClosing { startTime : Time.Posix, startPosition : Point2d Pixels Pixels }


initEditor : MailEditorData -> MailEditor
initEditor data =
    { current = { content = data.content, recipient = data.recipient }
    , undo = []
    , redo = []
    , mesh = mesh data.content
    , currentImage = BlueStamp
    , showMailEditor = MailEditorClosed
    }


mesh : List { position : Coord MailPixelUnit, image : Image } -> WebGL.Mesh Vertex
mesh content =
    WebGL.indexedTriangles
        (mailMesh ++ List.concatMap imageMesh content)
        (List.range 0 (List.length content) |> List.concatMap Grid.getIndices)


init : MailEditorData
init =
    { recipient = Nothing
    , content = []
    }


type alias ImageData =
    { textureSize : ( Int, Int ), texturePosition : ( Int, Int ) }


getImageData : Image -> ImageData
getImageData image =
    case image of
        BlueStamp ->
            { textureSize = ( 28, 28 ), texturePosition = ( 504, 0 ) }

        SunglassesSmiley ->
            { textureSize = ( 24, 24 ), texturePosition = ( 532, 0 ) }

        NormalSmiley ->
            { textureSize = ( 24, 24 ), texturePosition = ( 556, 0 ) }


handleMouseDown :
    Int
    -> Int
    -> { a | windowSize : Coord Pixels, devicePixelRatio : Float, time : Time.Posix }
    -> Point2d Pixels Pixels
    -> MailEditor
    -> MailEditor
handleMouseDown windowWidth windowHeight config mousePosition model =
    let
        mailCoord =
            screenToWorld windowWidth windowHeight config mousePosition
                |> Coord.roundPoint
                |> Coord.minusTuple
                    (Coord.fromTuple imageData.textureSize
                        |> Coord.divideTuple (Coord.fromTuple ( 2, 2 ))
                    )
                |> uiPixelToMailPixel

        imageData =
            getImageData model.currentImage

        oldEditorState =
            model.current

        newEditorState =
            { oldEditorState
                | content = oldEditorState.content ++ [ { position = mailCoord, image = BlueStamp } ]
            }
    in
    if validImagePosition imageData mailCoord then
        { model
            | current = newEditorState
            , undo = oldEditorState :: List.take 50 model.undo
            , redo = []
            , mesh = mesh newEditorState.content
        }

    else
        close config model


handleKeyDown : MailEditor -> MailEditor
handleKeyDown model =
    model


close : { a | time : Time.Posix } -> MailEditor -> MailEditor
close config model =
    { model
        | showMailEditor =
            case model.showMailEditor of
                MailEditorOpening { startPosition } ->
                    MailEditorClosing { startTime = config.time, startPosition = startPosition }

                MailEditorClosing _ ->
                    MailEditorClosed

                MailEditorClosed ->
                    MailEditorClosed
    }


open : { a | time : Time.Posix } -> Point2d Pixels Pixels -> MailEditor -> MailEditor
open config startPosition model =
    { model | showMailEditor = MailEditorOpening { startTime = config.time, startPosition = startPosition } }


uiPixelToMailPixel : Coord UiPixelUnit -> Coord MailPixelUnit
uiPixelToMailPixel coord =
    coord |> Coord.addTuple (Coord.fromTuple ( mailWidth // 2, mailHeight // 2 )) |> Coord.toTuple |> Coord.fromTuple


validImagePosition : ImageData -> Coord MailPixelUnit -> Bool
validImagePosition imageData position =
    let
        ( w, h ) =
            imageData.textureSize

        ( x, y ) =
            Coord.toTuple position
    in
    (x > round (toFloat w / -2))
        && (x < mailWidth + round (toFloat w / -2))
        && (y > round (toFloat h / -2))
        && (y < mailHeight + round (toFloat h / -2))


undo : MailEditor -> MailEditor
undo model =
    case model.undo of
        head :: rest ->
            { model
                | undo = rest
                , current = head
                , mesh = mesh head.content
                , redo = model.current :: model.redo
            }

        [] ->
            model


redo : MailEditor -> MailEditor
redo model =
    case model.redo of
        head :: rest ->
            { model
                | redo = rest
                , current = head
                , mesh = mesh head.content
                , undo = model.current :: model.undo
            }

        [] ->
            model


mailWidth =
    270


mailHeight =
    144


mailMesh : List Vertex
mailMesh =
    let
        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePositionPixels ( 234, 0 ) ( mailWidth, mailHeight )
    in
    [ { position = Vec3.vec3 0 0 0, texturePosition = topLeft }
    , { position = Vec3.vec3 mailWidth 0 0, texturePosition = topRight }
    , { position = Vec3.vec3 mailWidth mailHeight 0, texturePosition = bottomRight }
    , { position = Vec3.vec3 0 mailHeight 0, texturePosition = bottomLeft }
    ]


mailZoomFactor : Int -> Int -> Int
mailZoomFactor windowWidth windowHeight =
    min
        (toFloat windowWidth / (30 + mailWidth))
        (toFloat windowHeight / (30 + mailHeight))
        |> floor


screenToWorld :
    Int
    -> Int
    -> { a | windowSize : Coord Pixels, devicePixelRatio : Float }
    -> Point2d Pixels Pixels
    -> Point2d UiPixelUnit UiPixelUnit
screenToWorld windowWidth windowHeight model =
    let
        ( w, h ) =
            model.windowSize
    in
    Point2d.translateBy
        (Vector2d.xy (Quantity.toFloatQuantity w) (Quantity.toFloatQuantity h) |> Vector2d.scaleBy -0.5)
        >> Point2d.at (scaleForScreenToWorld windowWidth windowHeight model)
        >> Point2d.placeIn (Point2d.unsafe { x = 0, y = 0 } |> Frame2d.atPoint)


worldToScreen :
    Int
    -> Int
    -> { a | windowSize : Coord Pixels, devicePixelRatio : Float }
    -> Point2d UiPixelUnit UiPixelUnit
    -> Point2d Pixels Pixels
worldToScreen windowWidth windowHeight model =
    let
        ( w, h ) =
            model.windowSize
    in
    Point2d.translateBy
        (Vector2d.xy (Quantity.toFloatQuantity w) (Quantity.toFloatQuantity h) |> Vector2d.scaleBy -0.5 |> Vector2d.reverse)
        << Point2d.at_ (scaleForScreenToWorld windowWidth windowHeight model)
        << Point2d.relativeTo (Point2d.unsafe { x = 0, y = 0 } |> Frame2d.atPoint)


scaleForScreenToWorld windowWidth windowHeight model =
    model.devicePixelRatio / toFloat (mailZoomFactor windowWidth windowHeight) |> Quantity


drawMail :
    WebGL.Texture.Texture
    -> Point2d Pixels Pixels
    -> Int
    -> Int
    ->
        { a
            | windowSize : Coord Pixels
            , devicePixelRatio : Float
            , time : Time.Posix
            , zoomFactor : Int
            , viewPoint : Point2d WorldUnit WorldUnit
        }
    -> MailEditor
    -> List WebGL.Entity
drawMail texture mousePosition windowWidth windowHeight config model =
    let
        isOpen_ =
            case model.showMailEditor of
                MailEditorOpening a ->
                    Just a

                MailEditorClosed ->
                    Nothing

                MailEditorClosing a ->
                    if Duration.from a.startTime config.time |> Quantity.lessThan openAnimationLength then
                        Just a

                    else
                        Nothing
    in
    case isOpen_ of
        Just { startTime, startPosition } ->
            let
                startPosition_ : { x : Float, y : Float }
                startPosition_ =
                    screenToWorld windowWidth windowHeight config startPosition |> Point2d.unwrap

                zoomFactor : Float
                zoomFactor =
                    mailZoomFactor windowWidth windowHeight |> toFloat

                mousePosition_ : Coord UiPixelUnit
                mousePosition_ =
                    screenToWorld windowWidth windowHeight config mousePosition
                        |> Coord.roundPoint

                imageData =
                    getImageData model.currentImage

                ( imageWidth, imageHeight ) =
                    imageData.textureSize

                { topLeft, bottomRight, bottomLeft, topRight } =
                    Tile.texturePositionPixels imageData.texturePosition ( imageWidth, imageHeight )

                tilePosition : Coord UiPixelUnit
                tilePosition =
                    mousePosition_
                        |> Coord.addTuple (Coord.fromTuple ( imageWidth // -2, imageHeight // -2 ))

                ( tileX, tileY ) =
                    Coord.toTuple tilePosition

                showHoverImage : Bool
                showHoverImage =
                    case model.showMailEditor of
                        MailEditorOpening mailEditorOpening ->
                            (Duration.from mailEditorOpening.startTime config.time
                                |> Quantity.greaterThan openAnimationLength
                            )
                                && validImagePosition imageData (uiPixelToMailPixel tilePosition)

                        MailEditorClosed ->
                            False

                        MailEditorClosing _ ->
                            False

                t =
                    case model.showMailEditor of
                        MailEditorOpening _ ->
                            Quantity.ratio (Duration.from startTime config.time) openAnimationLength |> min 1

                        _ ->
                            1 - Quantity.ratio (Duration.from startTime config.time) openAnimationLength |> max 0

                endX =
                    mailWidth / -2

                endY =
                    mailHeight / -2

                mailX =
                    (endX - startPosition_.x) * t + startPosition_.x

                mailY =
                    (endY - startPosition_.y) * t + startPosition_.y

                scaleStart =
                    0.13 * toFloat config.zoomFactor / zoomFactor

                mailScale =
                    (1 - scaleStart) * t * t + scaleStart
            in
            WebGL.entityWith
                [ Shaders.blend ]
                Shaders.colorVertexShader
                Shaders.colorFragmentShader
                square
                { color = Vec4.vec4 0.2 0.2 0.2 (t * t * 0.75)
                , view = Mat4.makeTranslate3 -1 -1 0 |> Mat4.scale3 2 2 1
                }
                :: WebGL.entityWith
                    [ Shaders.blend ]
                    Shaders.vertexShader
                    Shaders.fragmentShader
                    model.mesh
                    { texture = texture
                    , textureSize = WebGL.Texture.size texture |> Coord.fromTuple |> Coord.toVec2
                    , view =
                        Mat4.makeScale3
                            (zoomFactor * 2 / toFloat windowWidth)
                            (zoomFactor * -2 / toFloat windowHeight)
                            1
                            |> Mat4.translate3
                                (mailX |> round |> toFloat)
                                (mailY |> round |> toFloat)
                                0
                            |> Mat4.scale3 mailScale mailScale 0
                    }
                :: (if showHoverImage then
                        [ WebGL.entityWith
                            [ Shaders.blend ]
                            Shaders.simpleVertexShader
                            Shaders.simpleFragmentShader
                            square
                            { texture = texture
                            , textureSize = WebGL.Texture.size texture |> Coord.fromTuple |> Coord.toVec2
                            , texturePosition = Coord.fromTuple imageData.texturePosition |> Coord.toVec2
                            , textureScale = Coord.fromTuple imageData.textureSize |> Coord.toVec2
                            , view =
                                Mat4.makeScale3
                                    (zoomFactor * 2 / toFloat windowWidth)
                                    (zoomFactor * -2 / toFloat windowHeight)
                                    1
                                    |> Mat4.translate3
                                        (toFloat tileX |> round |> toFloat)
                                        (toFloat tileY |> round |> toFloat)
                                        0
                            }
                        ]

                    else
                        []
                   )

        Nothing ->
            []


imageMesh : { position : Coord MailPixelUnit, image : Image } -> List Vertex
imageMesh { position, image } =
    let
        imageData =
            getImageData image

        ( width, height ) =
            imageData.textureSize

        ( Quantity x, Quantity y ) =
            position

        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePositionPixels imageData.texturePosition ( width, height )
    in
    [ { position = Vec3.vec3 (toFloat x) (toFloat y) 0, texturePosition = topLeft }
    , { position = Vec3.vec3 (toFloat (x + width)) (toFloat y) 0, texturePosition = topRight }
    , { position = Vec3.vec3 (toFloat (x + width)) (toFloat (y + height)) 0, texturePosition = bottomRight }
    , { position = Vec3.vec3 (toFloat x) (toFloat (y + height)) 0, texturePosition = bottomLeft }
    ]


square : WebGL.Mesh SimpleVertex
square =
    WebGL.triangleFan
        [ { position = Vec2.vec2 0 0 }
        , { position = Vec2.vec2 1 0 }
        , { position = Vec2.vec2 1 1 }
        , { position = Vec2.vec2 0 1 }
        ]
