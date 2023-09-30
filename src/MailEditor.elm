module MailEditor exposing
    ( BackendMail
    , Content(..)
    , FrontendMail
    , Hover(..)
    , Image(..)
    , MailStatus(..)
    , MailStatus2(..)
    , Model
    , OutMsg(..)
    , ReceivedMail
    , Tool(..)
    , backendMailToFrontend
    , backgroundLayer
    , contentCodec
    , cursorSprite
    , date
    , disconnectWarning
    , drawMail
    , getImageData
    , getMailFrom
    , getMailTo
    , handleKeyDown
    , importMail
    , init
    , openAnimationLength
    , redo
    , scroll
    , ui
    , uiUpdate
    , undo
    )

import Animal exposing (AnimalData, AnimalType)
import Array exposing (Array)
import AssocList
import Audio exposing (AudioData)
import Bounds
import Codec exposing (Codec)
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Cursor exposing (CursorType)
import DisplayName exposing (DisplayName)
import Duration exposing (Duration)
import Effect.Time
import Effect.WebGL
import Flag
import Frame2d
import Grid
import Id exposing (Id, MailId, TrainId, UserId)
import IdDict exposing (IdDict)
import Keyboard exposing (Key(..))
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import Math.Matrix4 as Mat4
import Math.Vector4 as Vec4
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..))
import Shaders exposing (RenderData, Vertex)
import Sound exposing (Sound(..))
import Sprite
import Tile exposing (DefaultColor(..), Tile(..), TileData, TileGroup(..))
import Time exposing (Month(..))
import Ui exposing (BorderAndFill(..), UiEvent)
import Units
import User exposing (FrontendUser)
import Vector2d
import WebGL.Texture


type alias ReceivedMail =
    { content : List Content
    , isViewed : Bool
    , from : Id UserId
    , deliveryTime : Effect.Time.Posix
    }


type alias BackendMail =
    { content : List Content
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
    | TextToolButton
    | ExportButton
    | ImportButton
    | CloseMailViewButton


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
    | MailDeletedByAdmin { previousStatus : MailStatus2, deletedAt : Effect.Time.Posix }


type MailStatus2
    = MailWaitingPickup2
    | MailInTransit2 (Id TrainId)
    | MailReceived2 { deliveryTime : Effect.Time.Posix }
    | MailReceivedAndViewed2 { deliveryTime : Effect.Time.Posix }


type Tool
    = ImagePlacer ImagePlacer_
    | ImagePicker
    | EraserTool
    | TextTool (Coord TextUnit)


type TextUnit
    = TextUnit Never


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
    , lastTextInput : Maybe Effect.Time.Posix
    , importFailed : Bool
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias EditorState =
    { content : List Content }


type Content
    = ImageType (Coord Pixels) Image
    | TextType (Coord Pixels) String


type Image
    = Stamp Colors
    | SunglassesEmoji Colors
    | NormalEmoji Colors
    | SadEmoji Colors
    | Man Colors
    | TileImage TileGroup Int Colors
    | Grass
    | DefaultCursor Colors
    | DragCursor Colors
    | PinchCursor Colors
    | Line Int Color
    | Animal AnimalType Colors


scroll :
    Bool
    -> AudioData
    -> { a | time : Effect.Time.Posix, sounds : AssocList.Dict Sound (Result Audio.LoadError Audio.Source) }
    -> Model
    -> Model
scroll scrollUp audioData config model =
    case model.currentTool of
        ImagePlacer imagePlacer ->
            rotateImage audioData config imagePlacer scrollUp model

        ImagePicker ->
            model

        EraserTool ->
            model

        TextTool _ ->
            model


rotateImage :
    AudioData
    -> { a | time : Time.Posix, sounds : AssocList.Dict Sound (Result Audio.LoadError Audio.Source) }
    -> ImagePlacer_
    -> Bool
    -> Model
    -> Model
rotateImage audioData config imagePlacer scrollUp model =
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


type OutMsg
    = NoOutMsg
    | SubmitMail { to : Id UserId, content : List Content }
    | UpdateDraft { to : Id UserId, content : List Content }
    | ViewedMail (Id MailId)
    | ExportMail (List Content)
    | ImportMail


mailMousePosition : Coord Pixels -> Maybe ImageData -> Coord Pixels -> Coord Pixels -> Coord Pixels
mailMousePosition elementPosition maybeImageData windowSize mousePosition =
    let
        mailScale =
            mailZoomFactor windowSize
    in
    mousePosition
        |> Coord.minus elementPosition
        |> Coord.divide (Coord.xy mailScale mailScale)
        |> (case maybeImageData of
                Just imageData ->
                    Coord.minus (Coord.divide (Coord.xy 2 2) imageData.textureSize)

                Nothing ->
                    Coord.minus (Coord.yOnly Units.tileSize |> Coord.divide (Coord.xy 2 2))
           )
        |> Coord.toVector2d
        |> Vector2d.scaleBy 0.5
        |> Coord.roundVector
        |> Coord.scalar 2


onPress event updateFunc model =
    case event of
        Ui.MousePressed data ->
            updateFunc ()

        Ui.KeyDown _ Keyboard.Enter ->
            updateFunc ()

        _ ->
            ( Just model, NoOutMsg )


uiUpdate :
    { a | windowSize : Coord Pixels, time : Effect.Time.Posix }
    -> Coord Pixels
    -> Hover
    -> UiEvent
    -> Model
    -> ( Maybe Model, OutMsg )
uiUpdate config mousePosition id event model =
    case id of
        ImageButton index ->
            onPress
                event
                (\() ->
                    ( updateCurrentImageMesh { model | currentTool = ImagePlacer { imageIndex = index, rotationIndex = 0 } } |> Just
                    , NoOutMsg
                    )
                )
                model

        BackgroundHover ->
            case event of
                Ui.MousePressed _ ->
                    ( Nothing, NoOutMsg )

                _ ->
                    ( Just model, NoOutMsg )

        MailButton ->
            case event of
                Ui.MouseDown { elementPosition } ->
                    case model.to of
                        Just ( to, _ ) ->
                            case model.currentTool of
                                ImagePlacer imagePlacer ->
                                    let
                                        imageData : ImageData
                                        imageData =
                                            getImageData (currentImage imagePlacer)

                                        position : Coord Pixels
                                        position =
                                            mailMousePosition
                                                elementPosition
                                                (Just imageData)
                                                config.windowSize
                                                mousePosition

                                        model2 =
                                            addContent
                                                (ImageType position (currentImage imagePlacer))
                                                { model | lastPlacedImage = Just config.time }
                                    in
                                    ( Just model2, UpdateDraft (toData to model2) )

                                EraserTool ->
                                    let
                                        mailMousePosition2 : Coord Pixels
                                        mailMousePosition2 =
                                            mousePosition
                                                |> Coord.minus elementPosition
                                                |> Coord.divide (Coord.xy mailScale mailScale)

                                        mailScale =
                                            mailZoomFactor config.windowSize

                                        oldEditorState : EditorState
                                        oldEditorState =
                                            model.current

                                        { newContent, erased } =
                                            List.foldr
                                                (\content state ->
                                                    case content of
                                                        ImageType position image ->
                                                            let
                                                                imageData : ImageData
                                                                imageData =
                                                                    getImageData image

                                                                isOverImage : Bool
                                                                isOverImage =
                                                                    Bounds.contains
                                                                        mailMousePosition2
                                                                        (Bounds.fromCoordAndSize position imageData.textureSize)
                                                            in
                                                            if not state.erased && isOverImage then
                                                                { newContent = state.newContent, erased = True }

                                                            else
                                                                { newContent = content :: state.newContent
                                                                , erased = state.erased
                                                                }

                                                        TextType position text ->
                                                            let
                                                                isOverImage : Bool
                                                                isOverImage =
                                                                    Bounds.contains
                                                                        mailMousePosition2
                                                                        (Bounds.fromCoordAndSize
                                                                            position
                                                                            (Sprite.textSize 2 text)
                                                                        )
                                                            in
                                                            if not state.erased && isOverImage then
                                                                { newContent = state.newContent, erased = True }

                                                            else
                                                                { newContent = content :: state.newContent
                                                                , erased = state.erased
                                                                }
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

                                TextTool _ ->
                                    ( addContent
                                        (TextType
                                            (mailMousePosition
                                                elementPosition
                                                Nothing
                                                config.windowSize
                                                mousePosition
                                            )
                                            ""
                                        )
                                        { model | currentTool = TextTool Coord.origin }
                                        |> Just
                                    , NoOutMsg
                                    )

                        Nothing ->
                            ( Just model, NoOutMsg )

                _ ->
                    ( Just model, NoOutMsg )

        EraserButton ->
            onPress
                event
                (\() -> ( { model | currentTool = EraserTool } |> updateCurrentImageMesh |> Just, NoOutMsg ))
                model

        SendLetterButton ->
            onPress
                event
                (\() ->
                    case model.to of
                        Just ( userId, _ ) ->
                            ( Just { model | submitStatus = Submitted }
                            , SubmitMail { content = model.current.content, to = userId }
                            )

                        Nothing ->
                            ( Just model, NoOutMsg )
                )
                model

        CloseSendLetterInstructionsButton ->
            onPress event (\() -> ( Nothing, NoOutMsg )) model

        InboxRowButton mailId ->
            onPress
                event
                (\() ->
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
                )
                model

        TextToolButton ->
            onPress
                event
                (\() -> ( { model | currentTool = TextTool Coord.origin } |> updateCurrentImageMesh |> Just, NoOutMsg ))
                model

        ExportButton ->
            onPress event (\() -> ( Just { model | importFailed = False }, ExportMail model.current.content )) model

        ImportButton ->
            onPress event (\() -> ( Just { model | importFailed = False }, ImportMail )) model

        CloseMailViewButton ->
            onPress event (\() -> ( Just { model | inboxMailViewed = Nothing }, NoOutMsg )) model


quantityCodec : Codec (Quantity Int units)
quantityCodec =
    Codec.map Quantity.unsafe Quantity.unwrap Codec.int


contentCodec : Codec Content
contentCodec =
    Codec.custom
        (\a b value ->
            case value of
                ImageType data0 data1 ->
                    a data0 data1

                TextType data0 data1 ->
                    b data0 data1
        )
        |> Codec.variant2 "image" ImageType (Codec.tuple quantityCodec quantityCodec) imageCodec
        |> Codec.variant2 "text" TextType (Codec.tuple quantityCodec quantityCodec) Codec.string
        |> Codec.buildCustom


imageCodec : Codec Image
imageCodec =
    Codec.custom
        (\a b c d e f g h i j k l value ->
            case value of
                Stamp data0 ->
                    a data0

                SunglassesEmoji data0 ->
                    b data0

                NormalEmoji data0 ->
                    c data0

                SadEmoji data0 ->
                    d data0

                Man data0 ->
                    e data0

                TileImage data0 data1 data2 ->
                    f data0 data1 data2

                Grass ->
                    g

                DefaultCursor data0 ->
                    h data0

                DragCursor data0 ->
                    i data0

                PinchCursor data0 ->
                    j data0

                Line data0 data1 ->
                    k data0 data1

                Animal data0 data1 ->
                    l data0 data1
        )
        |> Codec.variant1 "Stamp" Stamp colorsCodec
        |> Codec.variant1 "SunglassesEmoji" SunglassesEmoji colorsCodec
        |> Codec.variant1 "NormalEmoji" NormalEmoji colorsCodec
        |> Codec.variant1 "SadEmoji" SadEmoji colorsCodec
        |> Codec.variant1 "Man" Man colorsCodec
        |> Codec.variant3 "TileImage" TileImage Tile.codec Codec.int colorsCodec
        |> Codec.variant0 "Grass" Grass
        |> Codec.variant1 "DefaultCursor" DefaultCursor colorsCodec
        |> Codec.variant1 "DragCursor" DragCursor colorsCodec
        |> Codec.variant1 "PinchCursor" PinchCursor colorsCodec
        |> Codec.variant2 "Line" Line Codec.int colorCodec
        |> Codec.variant2 "Animal" Animal Animal.animalTypeCodec colorsCodec
        |> Codec.buildCustom


colorsCodec : Codec Colors
colorsCodec =
    Codec.object Colors
        |> Codec.field "primary" .primaryColor colorCodec
        |> Codec.field "secondary" .secondaryColor colorCodec
        |> Codec.buildObject


colorCodec : Codec Color
colorCodec =
    Codec.andThen
        (\text ->
            case Color.fromHexCode text of
                Just hex ->
                    Codec.succeed hex

                Nothing ->
                    Codec.fail "Invalid hex color"
        )
        Color.toHexCode
        Codec.string



--= Stamp Colors
--| SunglassesEmoji Colors
--| NormalEmoji Colors
--| SadEmoji Colors
--| Man Colors
--| TileImage TileGroup Int Colors
--| Grass
--| DefaultCursor Colors
--| DragCursor Colors
--| PinchCursor Colors
--| Line Int Color
--| Animal AnimalType Colors


addContent : Content -> Model -> Model
addContent newItem model =
    let
        oldEditor =
            model.current
    in
    case List.unconsLast oldEditor.content of
        Just ( last, rest ) ->
            case last of
                TextType _ "" ->
                    replaceChange { oldEditor | content = rest ++ [ newItem ] } model

                _ ->
                    addChange { oldEditor | content = oldEditor.content ++ [ newItem ] } model

        _ ->
            addChange { oldEditor | content = oldEditor.content ++ [ newItem ] } model


currentImage : ImagePlacer_ -> Image
currentImage imagePlacer =
    Array.get imagePlacer.imageIndex images
        |> Maybe.withDefault defaultBlueStamp
        |> (\a ->
                case a of
                    TileImage tileGroup _ colors ->
                        TileImage tileGroup imagePlacer.rotationIndex colors

                    Line _ color ->
                        Line imagePlacer.rotationIndex color

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
    , Man { primaryColor = Color.rgb255 188 155 102, secondaryColor = Color.rgb255 63 63 93 }
    , Grass
    , DefaultCursor Cursor.defaultColors
    , DragCursor Cursor.defaultColors
    , PinchCursor Cursor.defaultColors
    , Line 0 Color.black
    ]
        ++ List.map (\animal -> Animal animal Animal.defaultColors) Animal.all
        ++ List.map
            (\group ->
                let
                    data =
                        Tile.getTileGroupData group
                in
                TileImage group 0 (Tile.defaultToPrimaryAndSecondary data.defaultColors)
            )
            (List.remove EmptyTileGroup Tile.allTileGroupsExceptText)
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
    , lastTextInput = Nothing
    , importFailed = False
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

                imageData : ImageData
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

        TextTool _ ->
            model


type alias ImageData =
    { textureSize : Coord Pixels, texturePosition : List (Coord Pixels), colors : Colors }


getImageData : Image -> ImageData
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
            , texturePosition = [ tileData.texturePosition ]
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

        Man colors ->
            { textureSize = Coord.xy 10 17
            , texturePosition = [ Coord.xy 494 0 ]
            , colors = colors
            }

        Line rotationIndex color ->
            let
                rotationIndex2 =
                    modBy 4 rotationIndex

                ( texturePosition, textureSize ) =
                    if rotationIndex2 == 0 then
                        ( Coord.xy 604 0, Coord.xy 20 2 )

                    else if rotationIndex2 == 1 then
                        ( Coord.xy 606 2, Coord.xy 16 16 )

                    else if rotationIndex2 == 2 then
                        ( Coord.xy 604 0, Coord.xy 2 20 )

                    else
                        ( Coord.xy 622 2, Coord.xy 16 16 )
            in
            { textureSize = textureSize
            , texturePosition = [ texturePosition ]
            , colors = { primaryColor = color, secondaryColor = Color.black }
            }

        Animal animalType colors ->
            let
                data : AnimalData
                data =
                    Animal.getData animalType
            in
            { textureSize = data.size
            , texturePosition = [ data.texturePosition ]
            , colors = colors
            }


toData : Id UserId -> Model -> { to : Id UserId, content : List Content }
toData to model =
    { to = to, content = model.current.content }


handleKeyDown : Effect.Time.Posix -> Bool -> Key -> Model -> Maybe ( Model, OutMsg )
handleKeyDown currentTime ctrlHeld key model =
    (case ( key, ctrlHeld ) of
        ( Escape, _ ) ->
            Nothing

        ( Character "z", True ) ->
            undo model |> Just

        ( Character "y", True ) ->
            redo model |> Just

        ( Character "Z", True ) ->
            redo model |> Just

        ( Character string, False ) ->
            case model.currentTool of
                TextTool _ ->
                    String.foldl (typeCharacter currentTime) model string |> Just

                _ ->
                    Just model

        ( Spacebar, False ) ->
            case model.currentTool of
                TextTool _ ->
                    typeCharacter currentTime ' ' model |> Just

                _ ->
                    Just model

        ( Backspace, False ) ->
            let
                oldEditor =
                    model.current
            in
            case ( List.unconsLast oldEditor.content, model.currentTool ) of
                ( Just ( last, rest ), TextTool cursorPosition ) ->
                    case last of
                        TextType position text ->
                            let
                                index =
                                    cursorPositionToIndex cursorPosition text

                                newCursorPosition =
                                    indexToCursorPosition (max 0 (index - 1)) text

                                newText =
                                    String.left (index - 1) text
                                        ++ String.right (String.length text - index) text
                            in
                            (case model.lastTextInput of
                                Just lastTextInput ->
                                    if Duration.from lastTextInput currentTime |> Quantity.lessThan (Duration.seconds 0.3) then
                                        replaceChange

                                    else
                                        addChange

                                Nothing ->
                                    addChange
                            )
                                { oldEditor | content = rest ++ [ TextType position newText ] }
                                { model | currentTool = TextTool newCursorPosition }
                                |> Just

                        ImageType _ _ ->
                            Just model

                _ ->
                    Just model

        ( Enter, _ ) ->
            case model.currentTool of
                TextTool _ ->
                    typeCharacter currentTime '\n' model |> Just

                _ ->
                    Just model

        ( ArrowLeft, False ) ->
            moveCursor
                (\position lines ->
                    let
                        ( x, y ) =
                            Coord.toTuple position
                    in
                    if x == 0 then
                        if y == 0 then
                            position

                        else
                            Coord.xy (lineLength (y - 1) lines) (y - 1)

                    else
                        Coord.plus (Coord.xy -1 0) position
                )
                model
                |> Just

        ( ArrowLeft, True ) ->
            moveCursor
                (\position lines ->
                    let
                        ( x, y ) =
                            Coord.toTuple position
                    in
                    if x == 0 then
                        if y == 0 then
                            position

                        else
                            Coord.xy (lineLength (y - 1) lines) (y - 1)

                    else
                        Coord.xy 0 y
                )
                model
                |> Just

        ( ArrowRight, False ) ->
            moveCursor
                (\position lines ->
                    let
                        ( x, y ) =
                            Coord.toTuple position

                        xMax =
                            lineLength y lines

                        yMax =
                            List.length lines - 1
                    in
                    if x >= xMax then
                        if y >= yMax then
                            position

                        else
                            Coord.xy 0 (y + 1)

                    else
                        Coord.plus (Coord.xy 1 0) position
                )
                model
                |> Just

        ( ArrowRight, True ) ->
            moveCursor
                (\position lines ->
                    let
                        ( x, y ) =
                            Coord.toTuple position

                        xMax =
                            lineLength y lines

                        yMax =
                            List.length lines - 1
                    in
                    if x >= xMax then
                        if y >= yMax then
                            position

                        else
                            Coord.xy 0 (y + 1)

                    else
                        Coord.xy xMax y
                )
                model
                |> Just

        ( ArrowUp, False ) ->
            moveCursor
                (\position lines ->
                    let
                        ( x, y ) =
                            Coord.toTuple position
                    in
                    if y == 0 then
                        Coord.origin

                    else
                        Coord.xy
                            (min x (lineLength (y - 1) lines))
                            (max 0 (y - 1))
                )
                model
                |> Just

        ( ArrowDown, False ) ->
            moveCursor
                (\position lines ->
                    let
                        ( x, y ) =
                            Coord.toTuple position

                        yNext =
                            min (y + 1) yMax

                        xMax =
                            lineLength yNext lines

                        yMax =
                            List.length lines - 1
                    in
                    if y == yMax then
                        Coord.xy xMax yNext

                    else
                        Coord.xy (min x xMax) yNext
                )
                model
                |> Just

        _ ->
            Just model
    )
        |> Maybe.map
            (\model2 ->
                case model.to of
                    Just ( to, _ ) ->
                        let
                            data =
                                toData to model2
                        in
                        ( model2
                        , if toData to model == data then
                            NoOutMsg

                          else
                            UpdateDraft data
                        )

                    Nothing ->
                        ( model2, NoOutMsg )
            )


lineLength : Int -> List String -> Int
lineLength y lines =
    case List.getAt y lines of
        Just line ->
            String.length line

        Nothing ->
            0


moveCursor : (Coord TextUnit -> List String -> Coord TextUnit) -> Model -> Model
moveCursor moveFunc model =
    case ( model.currentTool, List.last model.current.content ) of
        ( TextTool position, Just last ) ->
            case last of
                TextType _ text ->
                    { model | currentTool = moveFunc position (String.lines text) |> TextTool }

                ImageType _ _ ->
                    model

        _ ->
            model


cursorPositionToIndex : Coord TextUnit -> String -> Int
cursorPositionToIndex cursorPosition text =
    List.take (Coord.yRaw cursorPosition) (String.lines text)
        |> List.map (\a -> String.length a + 1)
        |> List.sum
        |> (+) (Coord.xRaw cursorPosition)


indexToCursorPosition : Int -> String -> Coord TextUnit
indexToCursorPosition index text =
    let
        lines =
            String.left index text |> String.lines
    in
    Coord.xy
        (case List.last lines of
            Just line ->
                String.length line

            Nothing ->
                0
        )
        (List.length lines - 1)


typeCharacter : Effect.Time.Posix -> Char -> Model -> Model
typeCharacter currentTime newText model =
    let
        oldEditor =
            model.current
    in
    case ( List.unconsLast oldEditor.content, model.currentTool ) of
        ( Just ( last, rest ), TextTool cursorPosition ) ->
            case last of
                TextType position text ->
                    let
                        index : Int
                        index =
                            cursorPositionToIndex cursorPosition text
                    in
                    (case model.lastTextInput of
                        Just lastTextInput ->
                            if Duration.from lastTextInput currentTime |> Quantity.lessThan (Duration.seconds 0.3) then
                                replaceChange

                            else
                                addChange

                        Nothing ->
                            addChange
                    )
                        { oldEditor
                            | content =
                                rest
                                    ++ [ TextType
                                            position
                                            (String.left index text
                                                ++ String.fromChar newText
                                                ++ String.right (String.length text - index) text
                                            )
                                       ]
                        }
                        { model
                            | lastTextInput = Just currentTime
                            , currentTool =
                                (case newText of
                                    '\n' ->
                                        Coord.plus (Coord.xy 0 1) (Coord.yOnly cursorPosition)

                                    _ ->
                                        Coord.plus (Coord.xy 1 0) cursorPosition
                                )
                                    |> TextTool
                        }

                ImageType _ _ ->
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


replaceChange : EditorState -> Model -> Model
replaceChange editorState model =
    { model
        | current = editorState
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
                , currentTool =
                    case List.last head.content of
                        Just last ->
                            case last of
                                TextType _ text ->
                                    let
                                        lines =
                                            String.lines text
                                    in
                                    case List.last lines of
                                        Just lastLine ->
                                            TextTool (Coord.xy (String.length lastLine) (List.length lines - 1))

                                        Nothing ->
                                            model.currentTool

                                ImageType _ _ ->
                                    model.currentTool

                        Nothing ->
                            model.currentTool
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
                - Coord.yRaw (Ui.size (sendLetterButton identity ( Id.fromInt 0, DisplayName.default )))
            )
            / mailHeight
        )
        |> floor
        |> clamp 1 3


screenToWorld :
    Coord Pixels
    -> { a | windowSize : Coord Pixels }
    -> Point2d Pixels Pixels
    -> Point2d UiPixelUnit UiPixelUnit
screenToWorld windowSize model =
    let
        ( w, h ) =
            model.windowSize
    in
    Point2d.translateBy
        (Vector2d.xy (Quantity.toFloatQuantity w) (Quantity.toFloatQuantity h) |> Vector2d.scaleBy -0.5)
        >> Point2d.at (scaleForScreenToWorld windowSize)
        >> Point2d.placeIn (Point2d.unsafe { x = 0, y = 0 } |> Frame2d.atPoint)


scaleForScreenToWorld windowSize =
    1 / toFloat (mailZoomFactor windowSize) |> Quantity


backgroundLayer : RenderData -> Float -> Effect.WebGL.Entity
backgroundLayer { lights, nightFactor, texture, depth } shaderTime =
    Effect.WebGL.entityWith
        [ Shaders.blend ]
        Shaders.vertexShader
        Shaders.fragmentShader
        square
        { color = Vec4.vec4 0.2 0.2 0.2 0.75
        , view = Mat4.makeTranslate3 -1 -1 0 |> Mat4.scale3 2 2 1
        , texture = texture
        , lights = lights
        , textureSize = WebGL.Texture.size texture |> Coord.tuple |> Coord.toVec2
        , userId = Shaders.noUserIdSelected
        , time = shaderTime
        , night = nightFactor
        , depth = depth
        }


drawMail :
    RenderData
    -> Coord Pixels
    -> Coord Pixels
    -> Point2d Pixels Pixels
    -> Int
    -> Int
    -> { a | windowSize : Coord Pixels, time : Effect.Time.Posix, zoomFactor : Int }
    -> Model
    -> Float
    -> List Effect.WebGL.Entity
drawMail { lights, nightFactor, texture, depth } mailPosition mailSize2 mousePosition windowWidth windowHeight config model shaderTime2 =
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
                |> Bounds.contains (Coord.floorPoint mousePosition)

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
            , lights = lights
            , textureSize = textureSize
            , color =
                case model.currentTool of
                    ImagePlacer _ ->
                        Vec4.vec4 1 1 1 0.5

                    ImagePicker ->
                        Vec4.vec4 1 1 1 1

                    EraserTool ->
                        Vec4.vec4 1 1 1 1

                    TextTool _ ->
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
            , userId = Shaders.noUserIdSelected
            , time = shaderTime2
            , night = nightFactor
            , depth = depth
            }
        ]

    else
        []


mainColumnSpacing =
    40


toolbarMaxHeight =
    250


sendLetterButton : (Hover -> id) -> ( Id UserId, DisplayName ) -> Ui.Element id
sendLetterButton idMap ( userId, name ) =
    Ui.button
        { id = idMap SendLetterButton
        , padding = Ui.paddingXY 16 8
        }
        (Ui.text ("Send letter to " ++ DisplayName.nameAndId name userId))


submittedView : (Hover -> id) -> DisplayName -> Ui.Element id
submittedView idMap name =
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
                , padding = Ui.paddingXY 16 8
                }
                (Ui.text "Close")
            ]
        )


grassSize : Coord Pixels
grassSize =
    Coord.xy 80 72


yourPostOffice : Ui.Element id
yourPostOffice =
    Ui.quads
        { size = Tile.getData Tile.PostOffice |> .size |> Coord.multiply Units.tileSize |> Coord.scalar 2
        , vertices =
            Sprite.sprite
                (Coord.yOnly Units.tileSize |> Coord.scalar 2)
                (Coord.scalar 2 grassSize)
                (Coord.xy 220 216)
                grassSize
                ++ Sprite.sprite
                    Coord.origin
                    (Coord.scalar 2 grassSize)
                    (Coord.xy 220 216)
                    grassSize
                ++ tileMesh
                    Tile.PostOffice
                    Coord.origin
                    2
                    (Tile.defaultToPrimaryAndSecondary Tile.defaultPostOfficeColor)
                ++ Flag.flagMesh
                    (Coord.scalar 2 Flag.postOfficeSendingMailFlagOffset2)
                    2
                    Flag.sendingMailFlagColor
                    1
        }


tileMesh : Tile -> Coord Pixels -> Int -> Colors -> List Vertex
tileMesh tile position scale colors =
    let
        data : TileData unit
        data =
            Tile.getData tile
    in
    Grid.tileMeshHelper2
        Shaders.opaque
        colors
        position
        (case tile of
            BigText _ ->
                2 * scale

            _ ->
                scale
        )
        data.texturePosition
        (Coord.scalar scale data.size)


mailView : Int -> List Content -> Maybe Tool -> Ui.Element id
mailView mailScale mailContent maybeTool =
    let
        stampSize =
            Coord.xy 46 46

        line y =
            Sprite.rectangle
                Color.outlineColor
                (Coord.xy (mailWidth - 200) y
                    |> Coord.scalar mailScale
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
                Sprite.rectangle
                    Color.outlineColor
                    (Coord.xy (mailWidth - Coord.xRaw stampSize - 20) 20
                        |> Coord.scalar mailScale
                    )
                    (Coord.scalar mailScale stampSize)
                    ++ Sprite.rectangle
                        Color.fillColor
                        (Coord.xy (mailWidth - Coord.xRaw stampSize - 18) 22
                            |> Coord.scalar mailScale
                        )
                        (stampSize |> Coord.minus (Coord.xy 4 4) |> Coord.scalar mailScale)
                    ++ line 120
                    ++ line (120 + 18 * 2)
                    ++ line (120 + 18 * 4)
                    ++ line (120 + 18 * 6)
                    ++ List.concatMap
                        (\content ->
                            case content of
                                ImageType position image ->
                                    imageMesh (Coord.scalar mailScale position) mailScale image

                                TextType position text ->
                                    Sprite.text Color.black (2 * mailScale) text (Coord.scalar mailScale position)
                        )
                        mailContent
                    ++ (case ( List.last mailContent, maybeTool ) of
                            ( Just lastContent, Just (TextTool cursorPosition) ) ->
                                case lastContent of
                                    TextType position _ ->
                                        Sprite.rectangleWithOpacity
                                            0.5
                                            Color.black
                                            (Coord.scalar mailScale position
                                                |> Coord.plus
                                                    (Coord.multiply (Coord.scalar (2 * mailScale) Sprite.charSize) cursorPosition
                                                        |> Coord.toTuple
                                                        |> Coord.tuple
                                                    )
                                            )
                                            (Coord.scalar (2 * mailScale) Sprite.charSize)

                                    ImageType _ _ ->
                                        []

                            _ ->
                                []
                       )
            }
        )


importMail : Result () (List Content) -> Model -> Model
importMail result model =
    case result of
        Ok contents ->
            let
                editorState : EditorState
                editorState =
                    model.current
            in
            addChange { editorState | content = contents } model

        Err () ->
            { model | importFailed = True }


cursorSprite : Coord Pixels -> Hover -> Model -> { cursorType : CursorType, scale : Int }
cursorSprite windowSize uiHover model =
    { cursorType =
        case uiHover of
            BackgroundHover ->
                Cursor.DefaultCursor

            ImageButton _ ->
                Cursor.PointerCursor

            MailButton ->
                case model.currentTool of
                    ImagePlacer _ ->
                        Cursor.NoCursor

                    ImagePicker ->
                        Cursor.PointerCursor

                    EraserTool ->
                        Cursor.CursorSprite Cursor.EraserSpriteCursor

                    TextTool _ ->
                        Cursor.CursorSprite Cursor.TextSpriteCursor

            _ ->
                Cursor.PointerCursor
    , scale = mailZoomFactor windowSize
    }


editorView :
    (Hover -> id)
    -> ( Id UserId, DisplayName )
    -> Coord Pixels
    -> Model
    -> List (Ui.Element id)
editorView idMap userIdAndName windowSize model =
    let
        mailScale =
            mailZoomFactor windowSize
    in
    [ Ui.bottomCenter
        { size = windowSize, inFront = [] }
        (Ui.column
            { spacing = mainColumnSpacing, padding = Ui.noPadding }
            [ sendLetterButton idMap userIdAndName
            , Ui.customButton
                { id = idMap MailButton
                , padding = Ui.noPadding
                , inFront = []
                , borderAndFill = NoBorderOrFill
                , borderAndFillFocus = NoBorderOrFill
                }
                (mailView mailScale model.current.content (Just model.currentTool))
            , Ui.el
                { padding = Ui.paddingXY 2 2
                , inFront = []
                , borderAndFill =
                    BorderAndFill
                        { borderWidth = 2, borderColor = Color.outlineColor, fillColor = Color.fillColor }
                }
                (Ui.row
                    { spacing = 0, padding = Ui.noPadding }
                    [ Ui.column
                        { spacing = 8, padding = Ui.paddingXY 8 8 }
                        [ highlightButton
                            (Ui.paddingXY 4 4)
                            (model.currentTool == EraserTool)
                            (idMap EraserButton)
                            (Ui.text "Eraser")
                        , highlightButton
                            (Ui.paddingXY 4 4)
                            (case model.currentTool of
                                TextTool _ ->
                                    True

                                _ ->
                                    False
                            )
                            (idMap TextToolButton)
                            (Ui.text " Text ")
                        , Ui.button { id = idMap ExportButton, padding = Ui.paddingXY 6 6 } (Ui.text "Export")
                        , Ui.button { id = idMap ImportButton, padding = Ui.paddingXY 6 6 } (Ui.text "Import")
                        , if model.importFailed then
                            Ui.colorText Color.errorColor "Import\nfailed"

                          else
                            Ui.none
                        ]
                    , imageButtons
                        idMap
                        (case model.currentTool of
                            ImagePlacer imagePlacer ->
                                Just imagePlacer.imageIndex

                            ImagePicker ->
                                Nothing

                            EraserTool ->
                                Nothing

                            TextTool _ ->
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
    -> IdDict UserId FrontendUser
    -> IdDict MailId ReceivedMail
    -> Model
    -> Ui.Element id
inboxView idMap users inbox model =
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
                                (Ui.text "View")
                            ]
                    )

        fromText =
            String.padRight 15 ' ' "From"
    in
    case model.inboxMailViewed of
        Just mailId ->
            let
                padding =
                    6

                button =
                    Ui.button
                        { id = idMap CloseMailViewButton, padding = Ui.paddingXY 12 6 }
                        (Ui.text "Back to inbox")
            in
            case IdDict.get mailId inbox of
                Just mail ->
                    Ui.column
                        { spacing = 16, padding = Ui.noPadding }
                        [ Ui.el
                            { padding = Ui.paddingXY padding padding
                            , inFront = []
                            , borderAndFill =
                                BorderAndFill
                                    { borderWidth = 2
                                    , borderColor = Color.outlineColor
                                    , fillColor = Color.fillColor
                                    }
                            }
                            (Ui.row
                                { spacing = 0, padding = Ui.noPadding }
                                [ button
                                , "From:"
                                    ++ (case IdDict.get mail.from users of
                                            Just user ->
                                                DisplayName.nameAndId user.name mail.from

                                            Nothing ->
                                                "Not found"
                                       )
                                    ++ " "
                                    |> Ui.text
                                    |> Ui.centerRight
                                        { size =
                                            Coord.xy (mailWidth * 2) (Ui.size button |> Coord.yRaw)
                                                |> Coord.minus (Coord.xOnly (Ui.size button))
                                                |> Coord.minus (Coord.xy (2 * padding) 0)
                                        }
                                ]
                            )
                        , mailView 2 mail.content Nothing
                        ]

                Nothing ->
                    Ui.row
                        { spacing = 16, padding = Ui.noPadding }
                        [ button, Ui.text "Mail not found" ]

        Nothing ->
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
                ]


ui :
    Bool
    -> Coord Pixels
    -> (Hover -> uiHover)
    -> IdDict UserId FrontendUser
    -> IdDict MailId ReceivedMail
    -> Model
    -> Ui.Element uiHover
ui isDisconnected windowSize idMap users inbox model =
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
                            [ Ui.center { size = windowSize } (submittedView idMap name) ]

                        ( NotSubmitted, Just userIdAndName ) ->
                            editorView idMap userIdAndName windowSize model

                        ( _, Nothing ) ->
                            [ Ui.center { size = windowSize } (inboxView idMap users inbox model) ]
                   )
        }
        (Ui.customButton
            { id = idMap BackgroundHover
            , inFront = []
            , padding = { topLeft = windowSize, bottomRight = Coord.origin }
            , borderAndFill = NoBorderOrFill
            , borderAndFillFocus = NoBorderOrFill
            }
            Ui.none
        )


disconnectWarning : Coord Pixels -> Ui.Element id
disconnectWarning windowSize =
    Ui.topRight
        { size = windowSize }
        (Ui.el
            { padding = Ui.paddingXY 16 4, borderAndFill = FillOnly Color.errorColor, inFront = [] }
            (Ui.colorText Color.white "No connection to server! Changes you make might be lost.")
        )


highlightButton : Ui.Padding -> Bool -> id -> Ui.Element id -> Ui.Element id
highlightButton padding isSelected id child =
    Ui.customButton
        { id = id
        , padding = padding
        , inFront = []
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


imageButtons : (Hover -> uiHover) -> Maybe Int -> Ui.Element uiHover
imageButtons idMap currentImageIndex =
    List.foldl
        (\image state ->
            let
                button =
                    imageButton idMap currentImageIndex state.index image

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


imageButton : (Hover -> uiHover) -> Maybe Int -> Int -> Image -> Ui.Element uiHover
imageButton idMap selectedIndex index image =
    let
        imageData : ImageData
        imageData =
            getImageData image

        scale =
            imageButtonScale imageData.textureSize
    in
    highlightButton
        (Ui.paddingXY 4 4)
        (selectedIndex == Just index)
        (ImageButton index |> idMap)
        (Ui.quads
            { size = Coord.scalar scale imageData.textureSize
            , vertices = imageMesh Coord.origin scale image
            }
        )


type UiPixelUnit
    = UiPixelUnit Never


imageMesh : Coord Pixels -> Int -> Image -> List Vertex
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
    Sprite.sprite Coord.origin (Coord.xy 1 1) (Coord.xy 512 28) Coord.origin |> Sprite.toMesh
