module MailEditor exposing
    ( BackendMail
    , FrontendMail
    , Hover(..)
    , Image(..)
    , MailEditorData
    , MailStatus(..)
    , Model
    , Msg
    , ToBackend(..)
    , ToFrontend(..)
    , Tool(..)
    , backendMailToFrontend
    , backgroundLayer
    , drawMail
    , getImageData
    , getMailFrom
    , getMailTo
    , handleKeyDown
    , init
    , initEditor
    , openAnimationLength
    , redo
    , scroll
    , ui
    , uiUpdate
    , undo
    , updateFromBackend
    )

import Array exposing (Array)
import AssocList
import Audio exposing (AudioData)
import Bounds
import Color exposing (Colors)
import Coord exposing (Coord)
import Cow
import Cursor
import DisplayName exposing (DisplayName)
import Duration exposing (Duration)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera as Lamdera
import Effect.Time
import Effect.WebGL
import Flag
import Frame2d
import Grid
import Id exposing (Id, MailId, TrainId, UserId)
import Keyboard exposing (Key(..))
import List.Nonempty exposing (Nonempty(..))
import Math.Matrix4 as Mat4
import Math.Vector2 as Vec2 exposing (Vec2)
import Math.Vector3 as Vec3
import Math.Vector4 as Vec4
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Shaders exposing (Vertex)
import Sound exposing (Sound(..))
import Sprite
import TextInput
import Tile exposing (DefaultColor(..), Tile, TileData, TileGroup(..))
import Ui exposing (BorderAndFill(..))
import Units exposing (MailPixelUnit, WorldUnit)
import Vector2d
import WebGL.Texture


type alias BackendMail =
    { content : List { position : Coord Pixels, image : Image }
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
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton


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


type Tool
    = ImagePlacer ImagePlacer_
    | ImagePicker
    | EraserTool


type alias ImagePlacer_ =
    { imageIndex : Int, rotationIndex : Int }


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Id UserId, DisplayName )
    , showSendLetterInstructions : Bool
    }


type SubmitStatus
    = NotSubmitted
    | Submitting


type alias EditorState =
    { content : List Content }


type alias Content =
    { position : Coord Pixels, image : Image }


type alias MailEditorData =
    { content : List Content
    }


type Image
    = Stamp Colors
    | SunglassesEmoji Colors
    | NormalEmoji Colors
    | SadEmoji Colors
    | Cow Colors
    | Man Colors
    | TileImage TileGroup Int Colors
    | Grass
    | DefaultCursor Colors
    | DragCursor Colors
    | PinchCursor Colors


scroll :
    Bool
    -> AudioData
    -> { a | time : Effect.Time.Posix, sounds : AssocList.Dict Sound (Result Audio.LoadError Audio.Source) }
    -> Model
    -> Model
scroll scrollUp audioData config model =
    case model.currentTool of
        ImagePlacer imagePlacer ->
            { model
                | currentTool =
                    ImagePlacer
                        { imagePlacer
                            | rotationIndex =
                                imagePlacer.rotationIndex
                                    + (if scrollUp then
                                        1

                                       else
                                        -1
                                      )
                        }
                , lastRotation =
                    config.time
                        :: List.filter
                            (\time ->
                                Duration.from time config.time
                                    |> Quantity.lessThan (Sound.length audioData config.sounds WhooshSound)
                            )
                            model.lastRotation
            }
                |> updateCurrentImageMesh

        ImagePicker ->
            model

        EraserTool ->
            model


uiUpdate :
    { a | windowSize : Coord Pixels, devicePixelRatio : Float, time : Effect.Time.Posix }
    -> Coord Pixels
    -> Coord Pixels
    -> Msg
    -> Model
    -> ( Maybe Model, Command FrontendOnly ToBackend msg )
uiUpdate config elementPosition mousePosition msg model =
    case msg of
        PressedImageButton index ->
            ( updateCurrentImageMesh { model | currentTool = ImagePlacer { imageIndex = index, rotationIndex = 0 } } |> Just
            , Command.none
            )

        PressedBackground ->
            ( Nothing, Command.none )

        MouseDownMail ->
            case model.currentTool of
                ImagePlacer imagePlacer ->
                    let
                        imageData : ImageData units
                        imageData =
                            getImageData (currentImage imagePlacer)

                        windowSize =
                            Coord.multiplyTuple_ ( config.devicePixelRatio, config.devicePixelRatio ) config.windowSize

                        mailScale =
                            mailZoomFactor windowSize

                        oldEditorState : EditorState
                        oldEditorState =
                            model.current

                        newEditorState : EditorState
                        newEditorState =
                            { oldEditorState
                                | content =
                                    oldEditorState.content
                                        ++ [ { position =
                                                mousePosition
                                                    |> Coord.minus elementPosition
                                                    |> Coord.divide (Coord.xy mailScale mailScale)
                                                    |> Coord.minus (Coord.divide (Coord.xy 2 2) imageData.textureSize)
                                             , image = currentImage imagePlacer
                                             }
                                           ]
                            }

                        model2 =
                            addChange newEditorState { model | lastPlacedImage = Just config.time }
                    in
                    ( Just model2, UpdateMailEditorRequest (toData model2) |> Lamdera.sendToBackend )

                EraserTool ->
                    let
                        mailMousePosition : Coord Pixels
                        mailMousePosition =
                            mousePosition
                                |> Coord.minus elementPosition
                                |> Coord.divide (Coord.xy mailScale mailScale)

                        windowSize =
                            Coord.multiplyTuple_ ( config.devicePixelRatio, config.devicePixelRatio ) config.windowSize

                        mailScale =
                            mailZoomFactor windowSize

                        oldEditorState : EditorState
                        oldEditorState =
                            model.current

                        { newContent, erased } =
                            List.foldr
                                (\content state ->
                                    let
                                        imageData : ImageData units
                                        imageData =
                                            getImageData content.image

                                        isOverImage : Bool
                                        isOverImage =
                                            Bounds.contains
                                                mailMousePosition
                                                (Bounds.fromCoordAndSize content.position imageData.textureSize)
                                    in
                                    if not state.erased && isOverImage then
                                        { newContent = state.newContent, erased = True }

                                    else
                                        { newContent = content :: state.newContent, erased = state.erased }
                                )
                                { newContent = [], erased = False }
                                oldEditorState.content
                    in
                    if erased then
                        let
                            model2 =
                                addChange { oldEditorState | content = newContent } model
                        in
                        ( Just { model2 | lastErase = Just config.time }
                        , UpdateMailEditorRequest (toData model2) |> Lamdera.sendToBackend
                        )

                    else
                        ( Just { model | lastErase = Just config.time }, Command.none )

                ImagePicker ->
                    Debug.todo ""

        PressedMail ->
            ( Just model, Command.none )

        PressedEraserButton ->
            ( { model | currentTool = EraserTool } |> updateCurrentImageMesh |> Just, Command.none )

        PressedSendLetter ->
            case model.to of
                Just ( userId, _ ) ->
                    ( Just { model | submitStatus = Submitting }
                    , SubmitMailRequest { content = model.current.content, to = userId } |> Lamdera.sendToBackend
                    )

                Nothing ->
                    ( Just model, Command.none )

        TypedToUser _ _ _ _ ->
            ( Just model, Command.none )

        PressedCloseSendLetterInstructions ->
            ( Nothing, Command.none )


currentImage : ImagePlacer_ -> Image
currentImage imagePlacer =
    Array.get imagePlacer.imageIndex images
        |> Maybe.withDefault defaultBlueStamp
        |> (\a ->
                case a of
                    TileImage tileGroup _ colors ->
                        TileImage tileGroup imagePlacer.rotationIndex colors

                    _ ->
                        a
           )


defaultBlueStamp : Image
defaultBlueStamp =
    Stamp { primaryColor = Color.rgb255 140 160 250, secondaryColor = Color.black }


images : Array Image
images =
    [ defaultBlueStamp
    , SunglassesEmoji { primaryColor = Color.rgb255 255 255 0, secondaryColor = Color.black }
    , NormalEmoji { primaryColor = Color.rgb255 255 255 0, secondaryColor = Color.black }
    , SadEmoji { primaryColor = Color.rgb255 255 255 0, secondaryColor = Color.black }
    , Cow Cow.defaultColors
    , Man { primaryColor = Color.rgb255 188 155 102, secondaryColor = Color.rgb255 63 63 93 }
    , Grass
    , DefaultCursor Cursor.defaultColors
    , DragCursor Cursor.defaultColors
    , PinchCursor Cursor.defaultColors
    ]
        ++ List.map
            (\group ->
                let
                    data =
                        Tile.getTileGroupData group
                in
                TileImage group 0 (Tile.defaultToPrimaryAndSecondary data.defaultColors)
            )
            [ FenceStraightGroup
            , BusStopGroup
            , PineTreeGroup
            , LogCabinGroup
            , HouseGroup
            , RailStraightGroup
            , RailTurnLargeGroup
            , RailTurnGroup
            , RailStrafeGroup
            , RailStrafeSmallGroup
            , RailCrossingGroup
            , TrainHouseGroup
            , SidewalkGroup
            , SidewalkRailGroup
            , RailTurnSplitGroup
            , RailTurnSplitMirrorGroup
            , PostOfficeGroup
            , RoadStraightGroup
            , RoadTurnGroup
            , Road4WayGroup
            , RoadSidewalkCrossingGroup
            , Road3WayGroup
            , RoadRailCrossingGroup
            , RoadDeadendGroup
            ]
        |> Array.fromList


openAnimationLength : Duration
openAnimationLength =
    Duration.milliseconds 300


initEditor : List Content -> Maybe ( Id UserId, DisplayName ) -> Model
initEditor content maybeUserIdAndName =
    { current = { content = content }
    , undo = []
    , redo = []
    , currentImageMesh = Shaders.triangleFan []
    , currentTool = ImagePlacer { imageIndex = 0, rotationIndex = 0 }
    , lastRotation = []
    , lastPlacedImage = Nothing
    , lastErase = Nothing
    , submitStatus = NotSubmitted
    , to = maybeUserIdAndName
    , showSendLetterInstructions = False
    }
        |> updateCurrentImageMesh


updateCurrentImageMesh : Model -> Model
updateCurrentImageMesh model =
    case model.currentTool of
        ImagePlacer imagePlacer ->
            let
                image : Image
                image =
                    currentImage imagePlacer

                imageData : ImageData units
                imageData =
                    getImageData image
            in
            { model
                | currentImageMesh =
                    imageMesh (Coord.divide (Coord.xy -2 -2) imageData.textureSize) 1 image |> Sprite.toMesh
            }

        ImagePicker ->
            { model
                | currentImageMesh = Effect.WebGL.triangleFan []
            }

        EraserTool ->
            model


init : MailEditorData
init =
    { content = [] }


type alias ImageData units =
    { textureSize : Coord units, texturePosition : List (Coord units), colors : Colors }


type ToBackend
    = SubmitMailRequest { content : List Content, to : Id UserId }
    | UpdateMailEditorRequest MailEditorData


type ToFrontend
    = SubmitMailResponse


getImageData : Image -> ImageData units
getImageData image =
    case image of
        Stamp colors ->
            { textureSize = Coord.xy 48 48, texturePosition = [ Coord.xy 591 24 ], colors = colors }

        SunglassesEmoji colors ->
            { textureSize = Coord.xy 24 24, texturePosition = [ Coord.xy 532 0 ], colors = colors }

        NormalEmoji colors ->
            { textureSize = Coord.xy 24 24, texturePosition = [ Coord.xy 556 0 ], colors = colors }

        SadEmoji colors ->
            { textureSize = Coord.xy 24 24, texturePosition = [ Coord.xy 580 0 ], colors = colors }

        TileImage tileGroup rotationIndex colors ->
            let
                tileGroupData =
                    Tile.getTileGroupData tileGroup

                tileData : TileData unit
                tileData =
                    Tile.getData (List.Nonempty.get rotationIndex tileGroupData.tiles)
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

        Cow colors ->
            { textureSize = Cow.textureSize
            , texturePosition = [ Cow.texturePosition ]
            , colors = colors
            }

        Man colors ->
            { textureSize = Coord.xy 10 17
            , texturePosition = [ Coord.xy 494 0 ]
            , colors = colors
            }


updateFromBackend : ToFrontend -> Model -> Model
updateFromBackend toFrontend mailEditor =
    case toFrontend of
        SubmitMailResponse ->
            case mailEditor.submitStatus of
                NotSubmitted ->
                    mailEditor

                Submitting ->
                    { mailEditor | showSendLetterInstructions = True }


toData : Model -> MailEditorData
toData model =
    { content = model.current.content }


handleKeyDown : Bool -> Key -> Model -> Maybe Model
handleKeyDown ctrlHeld key model =
    case key of
        Escape ->
            Nothing

        Character "z" ->
            (if ctrlHeld then
                undo model

             else
                model
            )
                |> Just

        Character "y" ->
            (if ctrlHeld then
                redo model

             else
                model
            )
                |> Just

        Character "Z" ->
            (if ctrlHeld then
                redo model

             else
                model
            )
                |> Just

        _ ->
            Just model


addChange : EditorState -> Model -> Model
addChange editorState model =
    { model
        | undo = model.current :: model.undo
        , current = editorState
        , redo = []
    }


undo : Model -> Model
undo model =
    case model.undo of
        head :: rest ->
            { model
                | undo = rest
                , current = head
                , redo = model.current :: model.redo
            }

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

        [] ->
            model


mailWidth : number
mailWidth =
    500


mailHeight : number
mailHeight =
    320


mailSize : Coord units
mailSize =
    Coord.xy mailWidth mailHeight


mailZoomFactor : Coord Pixels -> Int
mailZoomFactor windowSize =
    min
        (toFloat (Coord.xRaw windowSize) / (30 + mailWidth))
        (toFloat
            (Coord.yRaw windowSize
                - toolbarMaxHeight
                - (mainColumnSpacing * 2)
                - Coord.yRaw (Ui.size (sendLetterButton identity identity ( Id.fromInt 0, DisplayName.default )))
            )
            / mailHeight
        )
        |> floor
        |> clamp 1 3


screenToWorld :
    Coord Pixels
    -> { a | windowSize : Coord Pixels, devicePixelRatio : Float }
    -> Point2d Pixels Pixels
    -> Point2d UiPixelUnit UiPixelUnit
screenToWorld windowSize model =
    let
        ( w, h ) =
            model.windowSize
    in
    Point2d.translateBy
        (Vector2d.xy (Quantity.toFloatQuantity w) (Quantity.toFloatQuantity h) |> Vector2d.scaleBy -0.5)
        >> Point2d.at (scaleForScreenToWorld windowSize model)
        >> Point2d.placeIn (Point2d.unsafe { x = 0, y = 0 } |> Frame2d.atPoint)


scaleForScreenToWorld windowSize model =
    model.devicePixelRatio / toFloat (mailZoomFactor windowSize) |> Quantity


backgroundLayer : WebGL.Texture.Texture -> Effect.WebGL.Entity
backgroundLayer texture =
    Effect.WebGL.entityWith
        [ Shaders.blend ]
        Shaders.vertexShader
        Shaders.fragmentShader
        square
        { color = Vec4.vec4 0.2 0.2 0.2 0.75
        , view = Mat4.makeTranslate3 -1 -1 0 |> Mat4.scale3 2 2 1
        , texture = texture
        , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
        }


drawMail :
    Coord Pixels
    -> Coord Pixels
    -> WebGL.Texture.Texture
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
drawMail mailPosition mailSize2 texture mousePosition windowWidth windowHeight config model =
    let
        zoomFactor : Float
        zoomFactor =
            mailZoomFactor (Coord.xy windowWidth windowHeight) |> toFloat

        mousePosition_ : Coord UiPixelUnit
        mousePosition_ =
            screenToWorld (Coord.xy windowWidth windowHeight) config mousePosition
                |> Coord.roundPoint

        tilePosition : Coord UiPixelUnit
        tilePosition =
            mousePosition_

        ( tileX, tileY ) =
            Coord.toTuple tilePosition

        mailHover : Bool
        mailHover =
            Bounds.fromCoordAndSize mailPosition mailSize2
                |> Bounds.contains
                    (mousePosition
                        |> Point2d.scaleAbout Point2d.origin config.devicePixelRatio
                        |> Coord.floorPoint
                    )

        showHoverImage : Bool
        showHoverImage =
            case model.currentTool of
                ImagePlacer _ ->
                    mailHover

                _ ->
                    False

        textureSize =
            WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
    in
    if showHoverImage then
        [ Effect.WebGL.entityWith
            [ Shaders.blend ]
            Shaders.vertexShader
            Shaders.fragmentShader
            model.currentImageMesh
            { texture = texture
            , textureSize = textureSize
            , color =
                case model.currentTool of
                    ImagePlacer _ ->
                        Vec4.vec4 1 1 1 0.5

                    ImagePicker ->
                        Vec4.vec4 1 1 1 1

                    EraserTool ->
                        Vec4.vec4 1 1 1 1
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


type Msg
    = PressedImageButton Int
    | PressedBackground
    | MouseDownMail
    | PressedMail
    | PressedEraserButton
    | PressedSendLetter
    | TypedToUser Bool Bool Keyboard.Key TextInput.Model
    | PressedCloseSendLetterInstructions


mainColumnSpacing =
    40


toolbarMaxHeight =
    250


sendLetterButton : (Hover -> id) -> (Msg -> msg) -> ( Id a, DisplayName ) -> Ui.Element id msg
sendLetterButton idMap msgMap ( userId, name ) =
    Ui.button
        { id = idMap SendLetterButton
        , padding = Ui.paddingXY 16 8
        , onPress = msgMap PressedSendLetter
        }
        (Ui.text
            ("Send letter to "
                ++ DisplayName.toString name
                ++ "#"
                ++ String.fromInt (Id.toInt userId)
            )
        )


ui :
    Coord Pixels
    -> (Hover -> uiHover)
    -> (Msg -> msg)
    -> Model
    -> Ui.Element uiHover msg
ui windowSize idMap msgMap model =
    let
        mailScale =
            mailZoomFactor windowSize
    in
    Ui.el
        { padding = Ui.noPadding
        , borderAndFill = NoBorderOrFill
        , inFront =
            case ( model.showSendLetterInstructions, model.to ) of
                ( True, Just ( _, name ) ) ->
                    let
                        grassSize : Coord Pixels
                        grassSize =
                            Coord.xy 80 72

                        paragraph1 =
                            Ui.row
                                { padding = Ui.noPadding, spacing = 16 }
                                [ Ui.wrappedText 400 "Your letter is now waiting at your post office."
                                , Ui.quads
                                    { size =
                                        Tile.getData Tile.PostOffice
                                            |> .size
                                            |> Coord.multiply Units.tileSize
                                            |> Coord.scalar 2
                                    , vertices =
                                        \position ->
                                            Sprite.sprite
                                                (Coord.plus (Coord.yOnly Units.tileSize |> Coord.scalar 2) position)
                                                (Coord.scalar 2 grassSize)
                                                (Coord.xy 220 216)
                                                grassSize
                                                ++ Sprite.sprite
                                                    position
                                                    (Coord.scalar 2 grassSize)
                                                    (Coord.xy 220 216)
                                                    grassSize
                                                ++ Grid.tileMesh
                                                    Tile.PostOffice
                                                    position
                                                    2
                                                    (Tile.defaultToPrimaryAndSecondary Tile.defaultPostOfficeColor)
                                                ++ Flag.flagMesh
                                                    (Coord.plus
                                                        (Coord.scalar 2 Flag.postOfficeSendingMailFlagOffset2)
                                                        position
                                                    )
                                                    2
                                                    Flag.sendingMailFlagColor
                                                    1
                                    }
                                ]
                    in
                    [ Ui.center
                        { size = windowSize }
                        (Ui.el
                            { padding = Ui.paddingXY 16 16
                            , borderAndFill =
                                BorderAndFill
                                    { borderWidth = 2
                                    , borderColor = Color.outlineColor
                                    , fillColor = Color.fillColor
                                    }
                            , inFront = []
                            }
                            (Ui.column
                                { spacing = 16, padding = Ui.noPadding }
                                [ paragraph1
                                , Ui.wrappedText
                                    (Ui.size paragraph1 |> Coord.xRaw)
                                    ("Send a train to pick it up and deliver it to "
                                        ++ DisplayName.toString name
                                        ++ "'s post office."
                                    )
                                , Ui.button
                                    { id = idMap CloseSendLetterInstructionsButton
                                    , onPress = msgMap PressedCloseSendLetterInstructions
                                    , padding = Ui.paddingXY 16 8
                                    }
                                    (Ui.text "Close")
                                ]
                            )
                        )
                    ]

                ( False, Just userIdAndName ) ->
                    [ Ui.bottomCenter
                        { size = windowSize, inFront = [] }
                        (Ui.column
                            { spacing = mainColumnSpacing
                            , padding = Ui.noPadding
                            }
                            [ sendLetterButton idMap msgMap userIdAndName
                            , Ui.customButton
                                { id = idMap MailButton
                                , padding = Ui.noPadding
                                , inFront = []
                                , onPress = msgMap PressedMail
                                , onMouseDown = msgMap MouseDownMail |> Just
                                , borderAndFill =
                                    BorderAndFill
                                        { borderWidth = 2, borderColor = Color.outlineColor, fillColor = Color.fillColor }
                                , borderAndFillFocus =
                                    BorderAndFill
                                        { borderWidth = 2, borderColor = Color.outlineColor, fillColor = Color.fillColor }
                                }
                                (Ui.quads
                                    { size = Coord.scalar mailScale mailSize
                                    , vertices =
                                        \position ->
                                            List.concatMap
                                                (\content ->
                                                    imageMesh
                                                        (Coord.plus position (Coord.scalar mailScale content.position))
                                                        mailScale
                                                        content.image
                                                )
                                                model.current.content
                                    }
                                )
                            , Ui.el
                                { padding = Ui.paddingXY 2 2
                                , inFront = []
                                , borderAndFill =
                                    BorderAndFill
                                        { borderWidth = 2, borderColor = Color.outlineColor, fillColor = Color.fillColor }
                                }
                                (Ui.row
                                    { spacing = 16
                                    , padding = Ui.noPadding
                                    }
                                    [ Ui.column
                                        { spacing = 8
                                        , padding = Ui.noPadding
                                        }
                                        [ highlightButton
                                            (model.currentTool == EraserTool)
                                            (idMap EraserButton)
                                            (msgMap PressedEraserButton)
                                            (Ui.text "Eraser")
                                        ]
                                    , imageButtons
                                        idMap
                                        msgMap
                                        (case model.currentTool of
                                            ImagePlacer imagePlacer ->
                                                Just imagePlacer.imageIndex

                                            ImagePicker ->
                                                Nothing

                                            EraserTool ->
                                                Nothing
                                        )
                                    ]
                                )
                            ]
                        )
                    ]

                ( _, Nothing ) ->
                    []
        }
        (Ui.customButton
            { id = idMap BackgroundHover
            , inFront = []
            , onPress = msgMap PressedBackground
            , onMouseDown = Nothing
            , padding = { topLeft = windowSize, bottomRight = Coord.origin }
            , borderAndFill = NoBorderOrFill
            , borderAndFillFocus = NoBorderOrFill
            }
            Ui.none
        )


highlightButton : Bool -> id -> msg -> Ui.Element id msg -> Ui.Element id msg
highlightButton isSelected id onPress child =
    Ui.customButton
        { id = id
        , padding = Ui.paddingXY 4 4
        , onPress = onPress
        , inFront = []
        , onMouseDown = Nothing
        , borderAndFill =
            BorderAndFill
                { borderWidth = 2
                , borderColor = Color.outlineColor
                , fillColor =
                    if isSelected then
                        Color.highlightColor

                    else
                        Color.fillColor2
                }
        , borderAndFillFocus =
            BorderAndFill
                { borderWidth = 2
                , borderColor = Color.outlineColor
                , fillColor = Color.highlightColor
                }
        }
        child


imageButtons : (Hover -> uiHover) -> (Msg -> msg) -> Maybe Int -> Ui.Element uiHover msg
imageButtons idMap msgMap currentImageIndex =
    List.foldl
        (\image state ->
            let
                button =
                    imageButton idMap msgMap currentImageIndex state.index image

                newHeight =
                    state.height + Coord.yRaw (Ui.size button)
            in
            if newHeight > toolbarMaxHeight then
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


imageButton : (Hover -> uiHover) -> (Msg -> msg) -> Maybe Int -> Int -> Image -> Ui.Element uiHover msg
imageButton idMap msgMap selectedIndex index image =
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
    highlightButton
        (selectedIndex == Just index)
        (ImageButton index |> idMap)
        (PressedImageButton index |> msgMap)
        (Ui.quads
            { size = Coord.scalar scale imageData.textureSize
            , vertices = \position -> imageMesh position scale image
            }
        )


type UiPixelUnit
    = UiPixelUnit Never


imageMesh : Coord units -> Int -> Image -> List Vertex
imageMesh position scale image =
    let
        imageData =
            getImageData image
    in
    List.concatMap
        (\texturePosition ->
            Sprite.spriteWithTwoColors
                imageData.colors
                position
                (Coord.scalar scale imageData.textureSize)
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
