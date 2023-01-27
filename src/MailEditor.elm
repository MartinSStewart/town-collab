module MailEditor exposing
    ( BackendMail
    , Content
    , FrontendMail
    , Hover(..)
    , Image(..)
    , MailStatus(..)
    , Model
    , Msg
    , OutMsg(..)
    , ReceivedMail
    , Tool(..)
    , backendMailToFrontend
    , backgroundLayer
    , disconnectWarning
    , drawMail
    , getImageData
    , getMailFrom
    , getMailTo
    , handleKeyDown
    , init
    , openAnimationLength
    , redo
    , scroll
    , ui
    , uiUpdate
    , undo
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
import IdDict exposing (IdDict)
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
import Time exposing (Month(..))
import Ui exposing (BorderAndFill(..))
import Units exposing (MailPixelUnit, WorldUnit)
import User exposing (FrontendUser)
import Vector2d
import WebGL.Texture


type alias ReceivedMail =
    { content : List { position : Coord Pixels, image : Image }
    , isViewed : Bool
    , from : Id UserId
    , deliveryTime : Effect.Time.Posix
    }


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
    | InboxRowButton (Id MailId)


backendMailToFrontend : BackendMail -> FrontendMail
backendMailToFrontend mail =
    { status = mail.status, from = mail.from, to = mail.to }


getMailFrom : Id UserId -> IdDict MailId { a | from : Id UserId } -> List ( Id MailId, { a | from : Id UserId } )
getMailFrom userId dict =
    IdDict.toList dict
        |> List.filterMap
            (\( mailId, mail ) ->
                if mail.from == userId then
                    Just ( mailId, mail )

                else
                    Nothing
            )


getMailTo : Id UserId -> IdDict MailId { a | to : Id UserId } -> List ( Id MailId, { a | to : Id UserId } )
getMailTo userId dict =
    IdDict.toList dict
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
    | MailReceived { deliveryTime : Effect.Time.Posix }
    | MailReceivedAndViewed { deliveryTime : Effect.Time.Posix }


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
    , inboxMailViewed : Maybe (Id MailId)
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias EditorState =
    { content : List Content }


type alias Content =
    { position : Coord Pixels, image : Image }


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


type OutMsg
    = NoOutMsg
    | SubmitMail { to : Id UserId, content : List Content }
    | UpdateDraft { to : Id UserId, content : List Content }
    | ViewedMail (Id MailId)


uiUpdate :
    { a | windowSize : Coord Pixels, devicePixelRatio : Float, time : Effect.Time.Posix }
    -> Coord Pixels
    -> Coord Pixels
    -> Msg
    -> Model
    -> ( Maybe Model, OutMsg )
uiUpdate config elementPosition mousePosition msg model =
    case msg of
        PressedImageButton index ->
            ( updateCurrentImageMesh { model | currentTool = ImagePlacer { imageIndex = index, rotationIndex = 0 } } |> Just
            , NoOutMsg
            )

        PressedBackground ->
            ( Nothing, NoOutMsg )

        MouseDownMail ->
            case model.to of
                Just ( to, _ ) ->
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
                            ( Just model2, UpdateDraft (toData to model2) )

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
                                , UpdateDraft (toData to model2)
                                )

                            else
                                ( Just { model | lastErase = Just config.time }, NoOutMsg )

                        ImagePicker ->
                            ( Just model, NoOutMsg )

                Nothing ->
                    ( Just model, NoOutMsg )

        PressedMail ->
            ( Just model, NoOutMsg )

        PressedEraserButton ->
            ( { model | currentTool = EraserTool } |> updateCurrentImageMesh |> Just, NoOutMsg )

        PressedSendLetter ->
            case model.to of
                Just ( userId, _ ) ->
                    ( Just { model | submitStatus = Submitted }
                    , SubmitMail { content = model.current.content, to = userId }
                    )

                Nothing ->
                    ( Just model, NoOutMsg )

        TypedToUser _ _ _ _ ->
            ( Just model, NoOutMsg )

        PressedCloseSendLetterInstructions ->
            ( Nothing, NoOutMsg )

        PressedInboxRow mailId ->
            ( Just
                { model
                    | inboxMailViewed =
                        if model.inboxMailViewed == Just mailId then
                            Nothing

                        else
                            Just mailId
                }
            , ViewedMail mailId
            )


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
            Tile.allTileGroups
        |> List.sortBy
            (\image ->
                let
                    data =
                        getImageData image
                in
                data.textureSize |> Coord.xRaw |> (*) (imageButtonScale data.textureSize)
            )
        |> Array.fromList


openAnimationLength : Duration
openAnimationLength =
    Duration.milliseconds 300


init : Maybe { userId : Id UserId, name : DisplayName, draft : List Content } -> Model
init maybeUserIdAndName =
    { current =
        { content =
            case maybeUserIdAndName of
                Just { draft } ->
                    draft

                Nothing ->
                    []
        }
    , undo = []
    , redo = []
    , currentImageMesh = Shaders.triangleFan []
    , currentTool = ImagePlacer { imageIndex = 0, rotationIndex = 0 }
    , lastRotation = []
    , lastPlacedImage = Nothing
    , lastErase = Nothing
    , submitStatus = NotSubmitted
    , to =
        case maybeUserIdAndName of
            Just { userId, name } ->
                Just ( userId, name )

            Nothing ->
                Nothing
    , inboxMailViewed = Nothing
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


type alias ImageData units =
    { textureSize : Coord units, texturePosition : List (Coord units), colors : Colors }


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


toData : Id UserId -> Model -> { to : Id UserId, content : List Content }
toData to model =
    { to = to, content = model.current.content }


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
    | PressedInboxRow (Id MailId)


mainColumnSpacing =
    40


toolbarMaxHeight =
    250


sendLetterButton : (Hover -> id) -> (Msg -> msg) -> ( Id UserId, DisplayName ) -> Ui.Element id msg
sendLetterButton idMap msgMap ( userId, name ) =
    Ui.button
        { id = idMap SendLetterButton
        , padding = Ui.paddingXY 16 8
        , onPress = msgMap PressedSendLetter
        }
        (Ui.text ("Send letter to " ++ DisplayName.nameAndId name userId))


submittedView : (Hover -> id) -> (Msg -> msg) -> DisplayName -> Ui.Element id msg
submittedView idMap msgMap name =
    let
        paragraph1 =
            Ui.row
                { padding = Ui.noPadding, spacing = 16 }
                [ Ui.wrappedText 400 "Your letter is now waiting at your post office."
                , yourPostOffice
                ]
    in
    Ui.el
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


grassSize : Coord Pixels
grassSize =
    Coord.xy 80 72


yourPostOffice : Ui.Element id msg
yourPostOffice =
    Ui.quads
        { size = Tile.getData Tile.PostOffice |> .size |> Coord.multiply Units.tileSize |> Coord.scalar 2
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


mailView : Int -> List Content -> Ui.Element id msg
mailView mailScale mailContent =
    let
        stampSize =
            Coord.xy 46 46

        line position y =
            Sprite.rectangle
                Color.outlineColor
                (Coord.xy (mailWidth - 200) y
                    |> Coord.scalar mailScale
                    |> Coord.plus position
                )
                (Coord.xy 180 2 |> Coord.scalar mailScale)
    in
    Ui.el
        { padding = Ui.noPadding
        , borderAndFill =
            BorderAndFill
                { borderWidth = 2, borderColor = Color.outlineColor, fillColor = Color.fillColor }
        , inFront = []
        }
        (Ui.quads
            { size = Coord.scalar mailScale mailSize
            , vertices =
                \position ->
                    Sprite.rectangle
                        Color.outlineColor
                        (Coord.xy (mailWidth - Coord.xRaw stampSize - 20) 20
                            |> Coord.scalar mailScale
                            |> Coord.plus position
                        )
                        (Coord.scalar mailScale stampSize)
                        ++ Sprite.rectangle
                            Color.fillColor
                            (Coord.xy (mailWidth - Coord.xRaw stampSize - 18) 22
                                |> Coord.scalar mailScale
                                |> Coord.plus position
                            )
                            (stampSize |> Coord.minus (Coord.xy 4 4) |> Coord.scalar mailScale)
                        ++ line position 120
                        ++ line position 170
                        ++ line position 220
                        ++ List.concatMap
                            (\content ->
                                imageMesh
                                    (Coord.plus position (Coord.scalar mailScale content.position))
                                    mailScale
                                    content.image
                            )
                            mailContent
            }
        )


editorView :
    (Hover -> id)
    -> (Msg -> msg)
    -> ( Id UserId, DisplayName )
    -> Coord Pixels
    -> Model
    -> List (Ui.Element id msg)
editorView idMap msgMap userIdAndName windowSize model =
    let
        mailScale =
            mailZoomFactor windowSize
    in
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
                , borderAndFill = NoBorderOrFill
                , borderAndFillFocus = NoBorderOrFill
                }
                (mailView mailScale model.current.content)
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
                            (Ui.paddingXY 4 4)
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


monthToString : Month -> String
monthToString month =
    case month of
        Jan ->
            "1"

        Feb ->
            "2"

        Mar ->
            "3"

        Apr ->
            "4"

        May ->
            "5"

        Jun ->
            "6"

        Jul ->
            "7"

        Aug ->
            "8"

        Sep ->
            "9"

        Oct ->
            "10"

        Nov ->
            "11"

        Dec ->
            "12"


date : Effect.Time.Posix -> String
date time =
    String.padLeft 2 '0' (String.fromInt (Time.toHour Time.utc time))
        ++ ":"
        ++ String.padLeft 2 '0' (String.fromInt (Time.toMinute Time.utc time))
        ++ " "
        ++ String.fromInt (Time.toDay Time.utc time)
        ++ "/"
        ++ monthToString (Time.toMonth Time.utc time)
        ++ "/"
        ++ String.fromInt (Time.toYear Time.utc time)


inboxView :
    (Hover -> id)
    -> (Msg -> msg)
    -> IdDict UserId FrontendUser
    -> IdDict MailId ReceivedMail
    -> Model
    -> Ui.Element id msg
inboxView idMap msgMap users inbox model =
    let
        rows =
            IdDict.toList inbox
                |> List.sortBy (\( _, mail ) -> Effect.Time.posixToMillis mail.deliveryTime |> negate)
                |> List.map
                    (\( mailId, mail ) ->
                        Ui.row
                            { spacing = 8, padding = Ui.noPadding }
                            [ case IdDict.get mail.from users of
                                Just user ->
                                    let
                                        name =
                                            DisplayName.nameAndId user.name mail.from |> String.padRight 15 ' '
                                    in
                                    Ui.text
                                        ((if mail.isViewed then
                                            "      "

                                          else
                                            "(new) "
                                         )
                                            ++ name
                                            ++ date mail.deliveryTime
                                        )

                                Nothing ->
                                    Ui.text "Not found"
                            , highlightButton
                                (Ui.paddingXY 8 0)
                                (model.inboxMailViewed == Just mailId)
                                (InboxRowButton mailId |> idMap)
                                (PressedInboxRow mailId |> msgMap)
                                (Ui.text "View")
                            ]
                    )

        fromText =
            String.padRight 15 ' ' "From"
    in
    Ui.column
        { spacing = 16, padding = Ui.noPadding }
        [ Ui.el
            { padding = Ui.paddingXY 16 8
            , borderAndFill = BorderAndFill { borderWidth = 2, borderColor = Color.outlineColor, fillColor = Color.fillColor }
            , inFront = []
            }
            (Ui.column
                { spacing = 16, padding = Ui.noPadding }
                [ Ui.scaledText 3 "Inbox"
                , if IdDict.isEmpty inbox then
                    Ui.wrappedText 500 "Here you can view all the mail you've received.\n\nCurrently you don't have any mail but you can send letters to other people by clicking on their post office."

                  else
                    Ui.column
                        { spacing = 0, padding = Ui.noPadding }
                        (Ui.text ("      " ++ fromText ++ "Delivered at(UTC)") :: rows)
                ]
            )
        , case model.inboxMailViewed of
            Just mailId ->
                case IdDict.get mailId inbox of
                    Just mail ->
                        mailView 2 mail.content

                    Nothing ->
                        Ui.text "Mail not found"

            Nothing ->
                Ui.none
        ]


ui :
    Bool
    -> Coord Pixels
    -> (Hover -> uiHover)
    -> (Msg -> msg)
    -> IdDict UserId FrontendUser
    -> IdDict MailId ReceivedMail
    -> Model
    -> Ui.Element uiHover msg
ui isDisconnected windowSize idMap msgMap users inbox model =
    Ui.el
        { padding = Ui.noPadding
        , borderAndFill = NoBorderOrFill
        , inFront =
            (if isDisconnected then
                [ disconnectWarning windowSize ]

             else
                []
            )
                ++ (case ( model.submitStatus, model.to ) of
                        ( Submitted, Just ( _, name ) ) ->
                            [ Ui.center { size = windowSize } (submittedView idMap msgMap name) ]

                        ( NotSubmitted, Just userIdAndName ) ->
                            editorView idMap msgMap userIdAndName windowSize model

                        ( _, Nothing ) ->
                            [ Ui.center { size = windowSize } (inboxView idMap msgMap users inbox model) ]
                   )
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


disconnectWarning : Coord Pixels -> Ui.Element id msg
disconnectWarning windowSize =
    Ui.topRight
        { size = windowSize }
        (Ui.el
            { padding = Ui.paddingXY 16 4, borderAndFill = FillOnly Color.errorColor, inFront = [] }
            (Ui.colorText Color.white "No connection to server! Changes you make might be lost.")
        )


highlightButton : Ui.Padding -> Bool -> id -> msg -> Ui.Element id msg -> Ui.Element id msg
highlightButton padding isSelected id onPress child =
    Ui.customButton
        { id = id
        , padding = padding
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


imageButtonScale : Coord units -> number
imageButtonScale size =
    if Coord.xRaw size < 36 && Coord.yRaw size < 36 then
        2

    else
        1


imageButton : (Hover -> uiHover) -> (Msg -> msg) -> Maybe Int -> Int -> Image -> Ui.Element uiHover msg
imageButton idMap msgMap selectedIndex index image =
    let
        imageData : ImageData units
        imageData =
            getImageData image

        scale =
            imageButtonScale imageData.textureSize
    in
    highlightButton
        (Ui.paddingXY 4 4)
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
