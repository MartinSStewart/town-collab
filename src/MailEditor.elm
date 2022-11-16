module MailEditor exposing
    ( BackendMail
    , FrontendMail
    , Image(..)
    , MailEditorData
    , MailStatus(..)
    , Model
    , ShowMailEditor(..)
    , ToBackend(..)
    , ToFrontend(..)
    , backendMailToFrontend
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
    , textMesh
    , undo
    , updateFromBackend
    )

import AssocList
import Bounds
import Coord exposing (Coord)
import Duration exposing (Duration)
import Frame2d
import Id exposing (Id, MailId, TrainId, UserId)
import Keyboard exposing (Key(..))
import Math.Matrix4 as Mat4
import Math.Vector2 as Vec2 exposing (Vec2)
import Math.Vector3 as Vec3
import Math.Vector4 as Vec4
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Shaders exposing (SimpleVertex, Vertex)
import Sprite
import Tile
import Time
import Units exposing (MailPixelUnit, UiPixelUnit, WorldUnit)
import Vector2d
import WebGL
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
    { mesh : WebGL.Mesh Vertex
    , textInputMesh : WebGL.Mesh Vertex
    , currentImage : Image
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , showMailEditor : ShowMailEditor
    , lastPlacedImage : Maybe Time.Posix
    , submitStatus : SubmitStatus
    , textInputFocused : Bool
    }


type SubmitStatus
    = NotSubmitted
    | Submitting


type alias EditorState =
    { content : List { position : Coord MailPixelUnit, image : Image }, to : String }


type alias MailEditorData =
    { to : String
    , content : List { position : Coord MailPixelUnit, image : Image }
    , currentImage : Image
    }


type Image
    = BlueStamp
    | SunglassesSmiley
    | NormalSmiley


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
    | MailEditorOpening { startTime : Time.Posix, startPosition : Point2d Pixels Pixels }
    | MailEditorClosing { startTime : Time.Posix, startPosition : Point2d Pixels Pixels }


initEditor : MailEditorData -> Model
initEditor data =
    { current = { content = data.content, to = data.to }
    , undo = []
    , redo = []
    , mesh = WebGL.triangleFan []
    , textInputMesh = WebGL.triangleFan []
    , currentImage = BlueStamp
    , showMailEditor = MailEditorClosed
    , lastPlacedImage = Nothing
    , submitStatus = NotSubmitted
    , textInputFocused = False
    }
        |> updateMailMesh


init : MailEditorData
init =
    { to = ""
    , content = []
    , currentImage = BlueStamp
    }


type alias ImageData =
    { textureSize : ( Int, Int ), texturePosition : ( Int, Int ) }


type ToBackend
    = SubmitMailRequest { content : List { position : Coord MailPixelUnit, image : Image }, to : Id UserId }
    | UpdateMailEditorRequest MailEditorData


type ToFrontend
    = SubmitMailResponse


getImageData : Image -> ImageData
getImageData image =
    case image of
        BlueStamp ->
            { textureSize = ( 28, 28 ), texturePosition = ( 504, 0 ) }

        SunglassesSmiley ->
            { textureSize = ( 24, 24 ), texturePosition = ( 532, 0 ) }

        NormalSmiley ->
            { textureSize = ( 24, 24 ), texturePosition = ( 556, 0 ) }


updateFromBackend : { a | time : Time.Posix } -> ToFrontend -> Model -> Model
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
    -> { a | windowSize : Coord Pixels, devicePixelRatio : Float, time : Time.Posix }
    -> Point2d Pixels Pixels
    -> Model
    -> ( Model, cmd )
handleMouseDown cmdNone sendToBackend windowWidth windowHeight config mousePosition model =
    let
        model2 =
            { model | textInputFocused = False }

        uiCoord : Coord UiPixelUnit
        uiCoord =
            screenToWorld windowWidth windowHeight config mousePosition
                |> Coord.roundPoint

        mailCoord : Coord MailPixelUnit
        mailCoord =
            uiCoord
                |> Coord.minusTuple
                    (Coord.tuple imageData.textureSize
                        |> Coord.divideTuple (Coord.tuple ( 2, 2 ))
                    )
                |> uiPixelToMailPixel

        imageData : ImageData
        imageData =
            getImageData model2.currentImage

        oldEditorState : EditorState
        oldEditorState =
            model2.current

        newEditorState : EditorState
        newEditorState =
            { oldEditorState
                | content = oldEditorState.content ++ [ { position = mailCoord, image = model2.currentImage } ]
            }
    in
    if Bounds.fromCoordAndSize textInputPosition textInputSize |> Bounds.contains uiCoord then
        ( { model2 | textInputFocused = True }, cmdNone )

    else if model.textInputFocused then
        ( model2, cmdNone )

    else if validImagePosition imageData mailCoord then
        let
            model3 =
                addChange newEditorState { model2 | lastPlacedImage = Just config.time }
        in
        ( model3, UpdateMailEditorRequest (toData model3) |> sendToBackend )

    else if Bounds.fromCoordAndSize submitButtonPosition submitButtonSize |> Bounds.contains uiCoord then
        case ( model2.submitStatus, validateUserId model2.current.to ) of
            ( NotSubmitted, Just recipient ) ->
                ( { model2 | submitStatus = Submitting }
                , sendToBackend (SubmitMailRequest { content = model2.current.content, to = recipient })
                )

            _ ->
                ( model2, cmdNone )

    else
        ( close config model2, cmdNone )


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
    , currentImage = model.currentImage
    }


handleKeyDown : { a | time : Time.Posix } -> Bool -> Key -> Model -> Model
handleKeyDown config ctrlHeld key model =
    if model.textInputFocused then
        case key of
            Escape ->
                { model | textInputFocused = False }

            Character char ->
                addChange_
                    (\editorState ->
                        { editorState
                            | to = editorState.to ++ char
                        }
                    )
                    model

            Backspace ->
                addChange_
                    (\editorState ->
                        { editorState | to = String.dropRight 1 editorState.to }
                    )
                    model

            Spacebar ->
                addChange_
                    (\editorState ->
                        { editorState
                            | to = editorState.to ++ " "
                        }
                    )
                    model

            _ ->
                model

    else
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


close : { a | time : Time.Posix } -> Model -> Model
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
        , textInputFocused = False
    }


open : { a | time : Time.Posix } -> Point2d Pixels Pixels -> Model -> Model
open config startPosition model =
    { model | showMailEditor = MailEditorOpening { startTime = config.time, startPosition = startPosition } }


uiPixelToMailPixel : Coord UiPixelUnit -> Coord MailPixelUnit
uiPixelToMailPixel coord =
    coord |> Coord.addTuple (Coord.tuple ( mailWidth // 2, mailHeight // 2 )) |> Coord.toTuple |> Coord.tuple


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


mailWidth =
    270


mailHeight =
    144


updateMailMesh : Model -> Model
updateMailMesh model =
    { model
        | mesh =
            WebGL.indexedTriangles
                (mailMesh ++ List.concatMap imageMesh model.current.content)
                (List.range 0 (List.length model.current.content) |> List.concatMap Sprite.getIndices)
        , textInputMesh =
            WebGL.indexedTriangles
                (textMesh model.current.to ( 15, 7 ))
                (List.range 0 (String.length model.current.to) |> List.concatMap Sprite.getIndices)
    }


mailMesh : List Vertex
mailMesh =
    let
        { topLeft, bottomRight, bottomLeft, topRight } =
            Tile.texturePositionPixels ( 234, 0 ) ( mailWidth, mailHeight )
    in
    [ { position = Vec3.vec3 0 0 0, texturePosition = topLeft, opacity = 1 }
    , { position = Vec3.vec3 mailWidth 0 0, texturePosition = topRight, opacity = 1 }
    , { position = Vec3.vec3 mailWidth mailHeight 0, texturePosition = bottomRight, opacity = 1 }
    , { position = Vec3.vec3 0 mailHeight 0, texturePosition = bottomLeft, opacity = 1 }
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
    -> Model
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
                        |> Coord.addTuple (Coord.tuple ( imageWidth // -2, imageHeight // -2 ))

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
                                && not model.textInputFocused

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
                    , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
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
                :: WebGL.entityWith
                    [ Shaders.blend ]
                    Shaders.vertexShader
                    Shaders.fragmentShader
                    (if
                        model.textInputFocused
                            || Bounds.contains mousePosition_ (Bounds.fromCoordAndSize textInputPosition textInputSize)
                     then
                        textInputHoverMesh

                     else
                        textInputMesh
                    )
                    { texture = texture
                    , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                    , view =
                        Mat4.makeScale3
                            (zoomFactor * 2 / toFloat windowWidth)
                            (zoomFactor * -2 / toFloat windowHeight)
                            1
                            |> Coord.translateMat4 textInputPosition
                    }
                :: WebGL.entityWith
                    [ Shaders.blend ]
                    Shaders.vertexShader
                    Shaders.fragmentShader
                    model.textInputMesh
                    { texture = texture
                    , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                    , view =
                        Mat4.makeScale3
                            (zoomFactor * 2 / toFloat windowWidth)
                            (zoomFactor * -2 / toFloat windowHeight)
                            1
                            |> Coord.translateMat4 textInputPosition
                    }
                :: (case validateUserId model.current.to of
                        Just _ ->
                            [ WebGL.entityWith
                                [ Shaders.blend ]
                                Shaders.vertexShader
                                Shaders.fragmentShader
                                (if model.submitStatus == Submitting then
                                    submittingButtonMesh

                                 else if Bounds.fromCoordAndSize submitButtonPosition submitButtonSize |> Bounds.contains mousePosition_ then
                                    submitButtonHoverMesh

                                 else
                                    submitButtonMesh
                                )
                                { texture = texture
                                , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                                , view =
                                    Mat4.makeScale3
                                        (zoomFactor * 2 / toFloat windowWidth)
                                        (zoomFactor * -2 / toFloat windowHeight)
                                        1
                                        |> Coord.translateMat4 submitButtonPosition
                                }
                            ]

                        Nothing ->
                            []
                   )
                ++ (if showHoverImage then
                        [ WebGL.entityWith
                            [ Shaders.blend ]
                            Shaders.simpleVertexShader
                            Shaders.simpleFragmentShader
                            square
                            { texture = texture
                            , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
                            , texturePosition = Coord.tuple imageData.texturePosition |> Coord.toVec2
                            , textureScale = Coord.tuple imageData.textureSize |> Coord.toVec2
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


submitButtonPosition : Coord UiPixelUnit
submitButtonPosition =
    Coord.tuple ( 75, 80 )


submitButtonSize : Coord UiPixelUnit
submitButtonSize =
    Coord.tuple ( 50, 19 )


submitButtonMesh : WebGL.Mesh Vertex
submitButtonMesh =
    let
        vertices =
            Sprite.spriteMesh ( 0, 0 ) submitButtonSize ( 380, 153 ) ( 1, 1 )
                ++ Sprite.spriteMesh ( 1, 1 ) (submitButtonSize |> Coord.minusTuple_ ( 2, 2 )) ( 381, 153 ) ( 1, 1 )
                ++ textMesh "SUBMIT" ( 12, 7 )
    in
    WebGL.indexedTriangles vertices (Sprite.getQuadIndices vertices)


submittingButtonMesh : WebGL.Mesh Vertex
submittingButtonMesh =
    let
        vertices =
            Sprite.spriteMesh ( 0, 0 ) submitButtonSize ( 380, 153 ) ( 1, 1 )
                ++ Sprite.spriteMesh ( 1, 1 ) (submitButtonSize |> Coord.minusTuple_ ( 2, 2 )) ( 379, 153 ) ( 1, 1 )
                ++ textMesh "SUBMITTING" ( 2, 7 )
    in
    WebGL.indexedTriangles vertices (Sprite.getQuadIndices vertices)


submitButtonHoverMesh : WebGL.Mesh Vertex
submitButtonHoverMesh =
    let
        vertices =
            Sprite.spriteMesh ( 0, 0 ) submitButtonSize ( 380, 153 ) ( 1, 1 )
                ++ Sprite.spriteMesh ( 1, 1 ) (submitButtonSize |> Coord.minusTuple_ ( 2, 2 )) ( 379, 153 ) ( 1, 1 )
                ++ textMesh "SUBMIT" ( 12, 7 )
    in
    WebGL.indexedTriangles vertices (Sprite.getQuadIndices vertices)


textInputPosition =
    Coord.tuple ( 0, 80 )


textInputSize =
    Coord.tuple ( 70, 19 )


textInputMesh : WebGL.Mesh Vertex
textInputMesh =
    let
        vertices =
            Sprite.spriteMesh ( 0, 0 ) textInputSize ( 380, 153 ) ( 1, 1 )
                ++ Sprite.spriteMesh ( 1, 1 ) (textInputSize |> Coord.minusTuple_ ( 2, 2 )) ( 381, 153 ) ( 1, 1 )
                ++ textMesh "TO:" ( 3, 7 )
    in
    WebGL.indexedTriangles vertices (Sprite.getQuadIndices vertices)


textInputHoverMesh : WebGL.Mesh Vertex
textInputHoverMesh =
    let
        vertices =
            Sprite.spriteMesh ( 0, 0 ) textInputSize ( 380, 153 ) ( 1, 1 )
                ++ Sprite.spriteMesh ( 1, 1 ) (textInputSize |> Coord.minusTuple_ ( 2, 2 )) ( 379, 153 ) ( 1, 1 )
                ++ textMesh "TO:" ( 3, 7 )
    in
    WebGL.indexedTriangles vertices (Sprite.getQuadIndices vertices)


charSize : Coord UiPixelUnit
charSize =
    Coord.tuple ( 5, 5 )


textMesh : String -> ( Int, Int ) -> List Vertex
textMesh string position =
    let
        position_ =
            Coord.tuple position
    in
    String.toList string
        |> List.foldl
            (\char state ->
                let
                    code =
                        Char.toCode char

                    index : Int
                    index =
                        code - Char.toCode '\''
                in
                if char == ' ' then
                    { offset = state.offset + 4
                    , vertices = state.vertices
                    }

                else if code >= 39 && code <= 90 then
                    { offset = state.offset + charWidth char
                    , vertices =
                        state.vertices
                            ++ Sprite.spriteMesh
                                (Coord.addTuple_ ( state.offset, 0 ) position_ |> Coord.toTuple)
                                charSize
                                ( 764 + index * 5, 0 )
                                ( 5, 5 )
                    }

                else
                    { offset = state.offset + 6
                    , vertices =
                        state.vertices
                            ++ Sprite.spriteMesh
                                (Coord.addTuple_ ( state.offset, 0 ) position_ |> Coord.toTuple)
                                charSize
                                ( 1019, 5 )
                                ( 5, 5 )
                    }
            )
            { offset = 0, vertices = [] }
        |> .vertices


charWidth : Char -> number
charWidth char =
    case char of
        'T' ->
            4

        'J' ->
            4

        'I' ->
            4

        'M' ->
            6

        'W' ->
            6

        '@' ->
            6

        'Y' ->
            4

        _ ->
            5


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
    [ { position = Vec3.vec3 (toFloat x) (toFloat y) 0, texturePosition = topLeft, opacity = 1 }
    , { position = Vec3.vec3 (toFloat (x + width)) (toFloat y) 0, texturePosition = topRight, opacity = 1 }
    , { position = Vec3.vec3 (toFloat (x + width)) (toFloat (y + height)) 0, texturePosition = bottomRight, opacity = 1 }
    , { position = Vec3.vec3 (toFloat x) (toFloat (y + height)) 0, texturePosition = bottomLeft, opacity = 1 }
    ]


square : WebGL.Mesh SimpleVertex
square =
    WebGL.triangleFan
        [ { position = Vec2.vec2 0 0 }
        , { position = Vec2.vec2 1 0 }
        , { position = Vec2.vec2 1 1 }
        , { position = Vec2.vec2 0 1 }
        ]
