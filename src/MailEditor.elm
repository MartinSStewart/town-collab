module MailEditor exposing
    ( BackendMail
    , FrontendMail
    , Hover(..)
    , Image(..)
    , MailEditorData
    , MailStatus(..)
    , Model
    , Msg
    , ShowMailEditor(..)
    , ToBackend(..)
    , ToFrontend(..)
    , backendMailToFrontend
    , backgroundLayer
    , close
    , drawMail
    , getImageData
    , getMailFrom
    , getMailTo
    , handleKeyDown
    , handleMouseDown
    , init
    , initEditor
    , isOpen
    , open
    , openAnimationLength
    , redo
    , ui
    , uiUpdate
    , undo
    , updateFromBackend
    )

import Array exposing (Array)
import AssocList
import Color exposing (Colors)
import Coord exposing (Coord)
import Cursor
import Duration exposing (Duration)
import Effect.Time
import Effect.WebGL
import Frame2d
import Id exposing (Id, MailId, TrainId, UserId)
import Keyboard exposing (Key(..))
import List.Extra
import List.Nonempty exposing (Nonempty(..))
import Math.Matrix4 as Mat4
import Math.Vector2 as Vec2 exposing (Vec2)
import Math.Vector3 as Vec3
import Math.Vector4 as Vec4
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Shaders exposing (Vertex)
import Sprite
import Tile exposing (DefaultColor(..), Tile, TileGroup(..))
import Ui exposing (BorderAndFill(..))
import Units exposing (MailPixelUnit, WorldUnit)
import Vector2d
import WebGL.Texture


type alias BackendMail =
    { content : List { position : Coord MailPixelUnit, image : Image }
    , status : MailStatus
    , from : Id UserId
    , to : Id UserId
    }


type alias FrontendMail =
    { status : MailStatus
    , from : Id UserId
    , to : Id UserId
    }


type Hover
    = BackgroundHover
    | MailHover
    | ImageButton Int


backendMailToFrontend : BackendMail -> FrontendMail
backendMailToFrontend mail =
    { status = mail.status, from = mail.from, to = mail.to }


getMailFrom :
    Id UserId
    -> AssocList.Dict (Id MailId) { a | from : Id UserId }
    -> List ( Id MailId, { a | from : Id UserId } )
getMailFrom userId dict =
    AssocList.toList dict
        |> List.filterMap
            (\( mailId, mail ) ->
                if mail.from == userId then
                    Just ( mailId, mail )

                else
                    Nothing
            )


getMailTo :
    Id UserId
    -> AssocList.Dict (Id MailId) { a | to : Id UserId }
    -> List ( Id MailId, { a | to : Id UserId } )
getMailTo userId dict =
    AssocList.toList dict
        |> List.filterMap
            (\( mailId, mail ) ->
                if mail.to == userId then
                    Just ( mailId, mail )

                else
                    Nothing
            )


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Id TrainId)
    | MailReceived
    | MailReceivedAndViewed


type alias Model =
    { mesh : Effect.WebGL.Mesh Vertex
    , currentImageMesh : Effect.WebGL.Mesh Vertex
    , currentImageIndex : Int
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , showMailEditor : ShowMailEditor
    , lastPlacedImage : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    }


type SubmitStatus
    = NotSubmitted
    | Submitting


type alias EditorState =
    { content : List Content, to : String }


type alias Content =
    { position : Coord MailPixelUnit, image : Image }


type alias MailEditorData =
    { to : String
    , content : List Content
    , currentImageIndex : Int
    }


type Image
    = BlueStamp Colors
    | SunglassesSmiley Colors
    | NormalSmiley Colors
    | TileImage Tile Colors
    | Grass
    | DefaultCursor Colors
    | DragCursor Colors
    | PinchCursor Colors


uiUpdate : { a | time : Effect.Time.Posix } -> Msg -> Model -> Model
uiUpdate config msg model =
    case msg of
        PressedImageButton index ->
            setCurrentImage index model

        PressedBackground ->
            close config model


currentImage : Model -> Image
currentImage model =
    Array.get model.currentImageIndex images |> Maybe.withDefault defaultBlueStamp


defaultBlueStamp : Image
defaultBlueStamp =
    BlueStamp { primaryColor = Color.rgb255 140 160 250, secondaryColor = Color.black }


images : Array Image
images =
    [ defaultBlueStamp
    , SunglassesSmiley { primaryColor = Color.rgb255 255 255 0, secondaryColor = Color.black }
    , NormalSmiley { primaryColor = Color.rgb255 255 255 0, secondaryColor = Color.black }
    , Grass
    , DefaultCursor Cursor.defaultColors
    , DragCursor Cursor.defaultColors
    , PinchCursor Cursor.defaultColors
    ]
        ++ List.concatMap
            (\group ->
                let
                    data =
                        Tile.getTileGroupData group
                in
                List.map
                    (\tile -> TileImage tile (Tile.defaultToPrimaryAndSecondary data.defaultColors))
                    (List.Nonempty.toList data.tiles)
            )
            (List.Extra.remove EmptyTileGroup Tile.allTileGroups)
        |> Array.fromList


openAnimationLength : Duration
openAnimationLength =
    Duration.milliseconds 300


isOpen : Model -> Bool
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
    | MailEditorOpening { startTime : Effect.Time.Posix, startPosition : Point2d Pixels Pixels }
    | MailEditorClosing { startTime : Effect.Time.Posix, startPosition : Point2d Pixels Pixels }


initEditor : MailEditorData -> Model
initEditor data =
    { current = { content = data.content, to = data.to }
    , undo = []
    , redo = []
    , mesh = Shaders.triangleFan []
    , currentImageMesh = Shaders.triangleFan []
    , currentImageIndex = 0
    , showMailEditor = MailEditorClosed
    , lastPlacedImage = Nothing
    , submitStatus = NotSubmitted
    }
        |> setCurrentImage data.currentImageIndex
        |> updateMailMesh


setCurrentImage : Int -> Model -> Model
setCurrentImage index model =
    let
        model2 =
            { model | currentImageIndex = index }
    in
    { model2 | currentImageMesh = imageMesh 1 { position = Coord.origin, image = currentImage model2 } |> Sprite.toMesh }


init : MailEditorData
init =
    { to = "", content = [], currentImageIndex = 0 }


type alias ImageData units =
    { textureSize : Coord units, texturePosition : List (Coord units), colors : Colors }


type ToBackend
    = SubmitMailRequest { content : List { position : Coord MailPixelUnit, image : Image }, to : Id UserId }
    | UpdateMailEditorRequest MailEditorData


type ToFrontend
    = SubmitMailResponse


getImageData : Image -> ImageData units
getImageData image =
    case image of
        BlueStamp colors ->
            { textureSize = Coord.xy 28 28, texturePosition = [ Coord.xy 504 0 ], colors = colors }

        SunglassesSmiley colors ->
            { textureSize = Coord.xy 24 24, texturePosition = [ Coord.xy 532 0 ], colors = colors }

        NormalSmiley colors ->
            { textureSize = Coord.xy 24 24, texturePosition = [ Coord.xy 556 0 ], colors = colors }

        TileImage tile colors ->
            let
                tileData =
                    Tile.getData tile
            in
            { textureSize = Coord.multiply Units.tileSize tileData.size
            , texturePosition =
                (case tileData.texturePosition of
                    Just texturePosition ->
                        [ Coord.multiply Units.tileSize texturePosition ]

                    Nothing ->
                        []
                )
                    ++ (case tileData.texturePositionTopLayer of
                            Just { texturePosition } ->
                                [ Coord.multiply Units.tileSize texturePosition ]

                            Nothing ->
                                []
                       )
            , colors = colors
            }

        Grass ->
            { textureSize = Coord.xy 80 72
            , texturePosition = [ Coord.xy 220 216 ]
            , colors = Tile.defaultToPrimaryAndSecondary ZeroDefaultColors
            }

        DefaultCursor colors ->
            { textureSize = Cursor.defaultCursorTextureSize
            , texturePosition = [ Cursor.defaultCursorTexturePosition ]
            , colors = colors
            }

        DragCursor colors ->
            { textureSize = Cursor.dragCursorTextureSize
            , texturePosition = [ Cursor.dragCursorTexturePosition ]
            , colors = colors
            }

        PinchCursor colors ->
            { textureSize = Cursor.pinchCursorTextureSize
            , texturePosition = [ Cursor.pinchCursorTexturePosition ]
            , colors = colors
            }


updateFromBackend : { a | time : Effect.Time.Posix } -> ToFrontend -> Model -> Model
updateFromBackend config toFrontend mailEditor =
    case toFrontend of
        SubmitMailResponse ->
            case mailEditor.submitStatus of
                NotSubmitted ->
                    mailEditor

                Submitting ->
                    { mailEditor
                        | submitStatus = NotSubmitted
                        , undo = []
                        , redo = []
                        , current = { content = [], to = "" }
                    }
                        |> updateMailMesh
                        |> close config


handleMouseDown :
    cmd
    -> (ToBackend -> cmd)
    -> Int
    -> Int
    -> { a | windowSize : Coord Pixels, devicePixelRatio : Float, time : Effect.Time.Posix }
    -> Point2d Pixels Pixels
    -> Model
    -> ( Model, cmd )
handleMouseDown cmdNone sendToBackend windowWidth windowHeight config mousePosition model =
    let
        uiCoord : Coord UiPixelUnit
        uiCoord =
            screenToWorld windowWidth windowHeight config mousePosition
                |> Coord.roundPoint

        mailCoord : Coord MailPixelUnit
        mailCoord =
            uiCoord
                |> Coord.minus (imageData.textureSize |> Coord.divide (Coord.tuple ( 2, 2 )))
                |> uiPixelToMailPixel

        imageData : ImageData units
        imageData =
            getImageData (currentImage model)
    in
    if validImagePosition imageData mailCoord then
        let
            oldEditorState : EditorState
            oldEditorState =
                model.current

            newEditorState : EditorState
            newEditorState =
                { oldEditorState
                    | content =
                        oldEditorState.content
                            ++ [ { position = mailCoord, image = currentImage model } ]
                }

            model3 =
                addChange newEditorState { model | lastPlacedImage = Just config.time }
        in
        ( model3, UpdateMailEditorRequest (toData model3) |> sendToBackend )

    else
        ( model, cmdNone )


validateUserId : String -> Maybe (Id UserId)
validateUserId string =
    case String.toInt string of
        Just int ->
            Id.fromInt int |> Just

        Nothing ->
            Nothing


toData : Model -> MailEditorData
toData model =
    { to = model.current.to
    , content = model.current.content
    , currentImageIndex = model.currentImageIndex
    }


handleKeyDown : { a | time : Effect.Time.Posix } -> Bool -> Key -> Model -> Model
handleKeyDown config ctrlHeld key model =
    case key of
        Escape ->
            close config model

        Character "z" ->
            if ctrlHeld then
                undo model

            else
                model

        Character "y" ->
            if ctrlHeld then
                redo model

            else
                model

        Character "Z" ->
            if ctrlHeld then
                redo model

            else
                model

        _ ->
            model


addChange : EditorState -> Model -> Model
addChange editorState model =
    { model
        | undo = model.current :: model.undo
        , current = editorState
        , redo = []
    }
        |> updateMailMesh


addChange_ : (EditorState -> EditorState) -> Model -> Model
addChange_ editorStateFunc model =
    addChange (editorStateFunc model.current) model


close : { a | time : Effect.Time.Posix } -> Model -> Model
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


open : { a | time : Effect.Time.Posix } -> Point2d Pixels Pixels -> Model -> Model
open config startPosition model =
    { model | showMailEditor = MailEditorOpening { startTime = config.time, startPosition = startPosition } }


uiPixelToMailPixel : Coord UiPixelUnit -> Coord MailPixelUnit
uiPixelToMailPixel coord =
    coord |> Coord.plus (Coord.tuple ( mailWidth // 2, mailHeight // 2 )) |> Coord.toTuple |> Coord.tuple


validImagePosition : ImageData units -> Coord MailPixelUnit -> Bool
validImagePosition imageData position =
    let
        ( w, h ) =
            Coord.toTuple imageData.textureSize

        ( x, y ) =
            Coord.toTuple position
    in
    (x > round (toFloat w / -2))
        && (x < mailWidth + round (toFloat w / -2))
        && (y > round (toFloat h / -2))
        && (y < mailHeight + round (toFloat h / -2))


undo : Model -> Model
undo model =
    case model.undo of
        head :: rest ->
            { model
                | undo = rest
                , current = head
                , redo = model.current :: model.redo
            }
                |> updateMailMesh

        [] ->
            model


redo : Model -> Model
redo model =
    case model.redo of
        head :: rest ->
            { model
                | redo = rest
                , current = head
                , undo = model.current :: model.undo
            }
                |> updateMailMesh

        [] ->
            model


mailWidth : number
mailWidth =
    400


mailHeight : number
mailHeight =
    240


mailSize =
    Coord.xy mailWidth mailHeight


updateMailMesh : Model -> Model
updateMailMesh model =
    { model | mesh = (mailMesh ++ List.concatMap (imageMesh 1) model.current.content) |> Sprite.toMesh }


mailMesh : List Vertex
mailMesh =
    Sprite.rectangle Color.outlineColor (Coord.xy 0 0) mailSize
        ++ Sprite.rectangle Color.fillColor (Coord.xy 1 1) (mailSize |> Coord.minus (Coord.xy 2 2))


mailZoomFactor : Int -> Int -> Int
mailZoomFactor windowWidth windowHeight =
    min
        (toFloat windowWidth / (30 + mailWidth))
        (toFloat (windowHeight - 400) / (30 + mailHeight))
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
        >> Point2d.placeIn (Point2d.unsafe { x = 0, y = -mailYOffset } |> Frame2d.atPoint)


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
        << Point2d.relativeTo (Point2d.unsafe { x = 0, y = -mailYOffset } |> Frame2d.atPoint)


scaleForScreenToWorld windowWidth windowHeight model =
    model.devicePixelRatio / toFloat (mailZoomFactor windowWidth windowHeight) |> Quantity


backgroundLayer : { b | time : Effect.Time.Posix } -> Model -> WebGL.Texture.Texture -> Maybe Effect.WebGL.Entity
backgroundLayer config model texture =
    case isOpenAnimation config model of
        Just { startTime } ->
            let
                t =
                    getT config model startTime
            in
            Effect.WebGL.entityWith
                [ Shaders.blend ]
                Shaders.vertexShader
                Shaders.fragmentShader
                square
                { color = Vec4.vec4 0.2 0.2 0.2 (t * t * 0.75)
                , view = Mat4.makeTranslate3 -1 -1 0 |> Mat4.scale3 2 2 1
                , texture = texture
                , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                }
                |> Just

        Nothing ->
            Nothing


getT : { b | time : Effect.Time.Posix } -> Model -> Effect.Time.Posix -> Float
getT config model startTime =
    case model.showMailEditor of
        MailEditorOpening _ ->
            Quantity.ratio (Duration.from startTime config.time) openAnimationLength |> min 1

        _ ->
            1 - Quantity.ratio (Duration.from startTime config.time) openAnimationLength |> max 0


isOpenAnimation config model =
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


drawMail :
    WebGL.Texture.Texture
    -> Point2d Pixels Pixels
    -> Int
    -> Int
    ->
        { a
            | windowSize : Coord Pixels
            , devicePixelRatio : Float
            , time : Effect.Time.Posix
            , zoomFactor : Int
        }
    -> Model
    -> List Effect.WebGL.Entity
drawMail texture mousePosition windowWidth windowHeight config model =
    case isOpenAnimation config model of
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
                    getImageData (currentImage model)

                tilePosition : Coord UiPixelUnit
                tilePosition =
                    mousePosition_
                        |> Coord.plus (imageData.textureSize |> Coord.divide (Coord.xy -2 -2))

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
                    (toFloat mailHeight / -2) + mailYOffset

                mailX =
                    (endX - startPosition_.x) * t + startPosition_.x

                mailY =
                    (endY - startPosition_.y) * t + startPosition_.y

                scaleStart =
                    0.13 * toFloat config.zoomFactor / zoomFactor

                mailScale =
                    (1 - scaleStart) * t * t + scaleStart

                textureSize =
                    WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
            in
            Effect.WebGL.entityWith
                [ Shaders.blend ]
                Shaders.vertexShader
                Shaders.fragmentShader
                model.mesh
                { texture = texture
                , textureSize = textureSize
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
                , color = Vec4.vec4 1 1 1 1
                }
                :: (if showHoverImage then
                        [ Effect.WebGL.entityWith
                            [ Shaders.blend ]
                            Shaders.vertexShader
                            Shaders.fragmentShader
                            model.currentImageMesh
                            { texture = texture
                            , textureSize = textureSize
                            , color = Vec4.vec4 1 1 1 1
                            , view =
                                Mat4.makeScale3
                                    (zoomFactor * 2 / toFloat windowWidth)
                                    (zoomFactor * -2 / toFloat windowHeight)
                                    1
                                    |> Mat4.translate3
                                        (toFloat tileX |> round |> toFloat)
                                        (toFloat tileY + mailYOffset |> round |> toFloat)
                                        0
                            }
                        ]

                    else
                        []
                   )

        Nothing ->
            []


mailYOffset =
    -50


type Msg
    = PressedImageButton Int
    | PressedBackground


ui : Coord Pixels -> (Hover -> uiHover) -> (Msg -> msg) -> Ui.Element uiHover msg
ui windowSize idMap msgMap =
    Ui.el
        { padding = Ui.noPadding
        , borderAndFill = NoBorderOrFill
        , inFront =
            [ Ui.bottomCenter
                { size = windowSize
                , inFront = []
                }
                (Ui.el
                    { padding = Ui.paddingXY 2 2
                    , inFront = []
                    , borderAndFill = BorderAndFill { borderWidth = 2, borderColor = Color.outlineColor, fillColor = Color.fillColor }
                    }
                    (List.foldl
                        (\image state ->
                            let
                                button =
                                    imageButton idMap msgMap state.index image

                                newHeight =
                                    state.height + Coord.yRaw (Ui.size button)
                            in
                            if newHeight > 300 then
                                { index = state.index + 1
                                , height = Coord.yRaw (Ui.size button)
                                , columns = List.Nonempty.cons [ button ] state.columns
                                }

                            else
                                { index = state.index + 1
                                , height = newHeight
                                , columns =
                                    List.Nonempty.replaceHead (button :: List.Nonempty.head state.columns) state.columns
                                }
                        )
                        { index = 0, columns = Nonempty [] [], height = 0 }
                        (Array.toList images)
                        |> .columns
                        |> List.Nonempty.toList
                        |> List.map (Ui.column { padding = Ui.noPadding, spacing = 2 })
                        |> Ui.row { padding = Ui.noPadding, spacing = 2 }
                    )
                )
            ]
        }
        (Ui.customButton
            { id = idMap BackgroundHover
            , inFront = []
            , onPress = msgMap PressedBackground
            , padding = { topLeft = windowSize, bottomRight = Coord.origin }
            , borderAndFill = NoBorderOrFill
            , borderAndFillFocus = NoBorderOrFill
            }
            Ui.none
        )


imageButton : (Hover -> uiHover) -> (Msg -> msg) -> Int -> Image -> Ui.Element uiHover msg
imageButton idMap msgMap index image =
    let
        imageData : ImageData units
        imageData =
            getImageData image

        ( width, height ) =
            Coord.toTuple imageData.textureSize

        scale =
            if width < 36 && height < 36 then
                2

            else
                1
    in
    Ui.button
        { id = ImageButton index |> idMap
        , onPress = PressedImageButton index |> msgMap
        , padding = Ui.paddingXY 2 2
        }
        (Ui.quads
            { size = Coord.multiply (Coord.xy scale scale) imageData.textureSize
            , vertices = \position -> imageMesh scale { position = position, image = image }
            }
        )


type UiPixelUnit
    = UiPixelUnit Never


imageMesh : Int -> { position : Coord units, image : Image } -> List Vertex
imageMesh scale { position, image } =
    let
        imageData =
            getImageData image
    in
    List.concatMap
        (\texturePosition ->
            Sprite.spriteWithTwoColors
                imageData.colors
                position
                (Coord.multiply (Coord.xy scale scale) imageData.textureSize)
                texturePosition
                imageData.textureSize
        )
        imageData.texturePosition


square : Effect.WebGL.Mesh Vertex
square =
    Shaders.triangleFan
        [ { position = Vec3.vec3 0 0 0
          , opacity = 1
          , primaryColor = Vec3.vec3 0 0 0
          , secondaryColor = Vec3.vec3 0 0 0
          , texturePosition = Vec2.vec2 512 28
          }
        , { position = Vec3.vec3 1 0 0
          , opacity = 1
          , primaryColor = Vec3.vec3 0 0 0
          , secondaryColor = Vec3.vec3 0 0 0
          , texturePosition = Vec2.vec2 512 28
          }
        , { position = Vec3.vec3 1 1 0
          , opacity = 1
          , primaryColor = Vec3.vec3 0 0 0
          , secondaryColor = Vec3.vec3 0 0 0
          , texturePosition = Vec2.vec2 512 28
          }
        , { position = Vec3.vec3 0 1 0
          , opacity = 1
          , primaryColor = Vec3.vec3 0 0 0
          , secondaryColor = Vec3.vec3 0 0 0
          , texturePosition = Vec2.vec2 512 28
          }
        ]
