module Toolbar exposing
    ( ViewData
    , getTileGroupTile
    , showColorTextInputs
    , view
    )

import AssocList
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Cursor
import Dict exposing (Dict)
import Duration
import EmailAddress exposing (EmailAddress)
import Id exposing (Id, UserId)
import List.Extra as List
import List.Nonempty
import PingData exposing (PingData)
import Quantity exposing (Quantity(..))
import Sprite
import TextInput
import Tile exposing (DefaultColor(..), Tile(..), TileData, TileGroup(..))
import Types exposing (Hover(..), SubmitStatus(..), Tool(..), ToolButton(..), UiHover(..))
import Ui exposing (BorderAndBackground(..))
import Units


type alias ViewData units =
    { devicePixelRatio : Float
    , windowSize : Coord units
    , pressedSubmitEmail : SubmitStatus EmailAddress
    , loginTextInput : TextInput.Model
    , hasCmdKey : Bool
    , handColor : Maybe Colors
    , primaryColorTextInput : TextInput.Model
    , secondaryColorTextInput : TextInput.Model
    , tileColors : AssocList.Dict TileGroup Colors
    , tileHotkeys : Dict String TileGroup
    , currentTool : Tool
    , pingData : Maybe PingData
    , userId : Maybe (Id UserId)
    , showInvite : Bool
    , inviteTextInput : TextInput.Model
    , inviteSubmitStatus : SubmitStatus EmailAddress
    }


view : ViewData units -> Ui.Element UiHover units
view data =
    Ui.bottomCenter
        { size = Coord.multiplyTuple_ ( data.devicePixelRatio, data.devicePixelRatio ) data.windowSize
        , inFront = [ inviteView data.showInvite ]
        }
        (Ui.el
            { padding = Ui.noPadding
            , inFront = []
            , borderAndBackground = borderAndBackground
            }
            (case data.handColor of
                Just handColor ->
                    toolbarUi
                        data.hasCmdKey
                        handColor
                        data.primaryColorTextInput
                        data.secondaryColorTextInput
                        data.tileColors
                        data.tileHotkeys
                        data.currentTool

                Nothing ->
                    loginToolbarUi data.pressedSubmitEmail data.loginTextInput
            )
        )


inviteView : Bool -> Ui.Element UiHover units
inviteView showInvite =
    Ui.button { id = ShowInviteUser, padding = Ui.paddingXY 10 4, inFront = [] } (Ui.text "Invite")


borderAndBackground : BorderAndBackground units
borderAndBackground =
    BorderAndBackground
        { borderWidth = 2
        , borderColor = Color.outlineColor
        , backgroundColor = Color.fillColor
        }


loginToolbarUi : SubmitStatus EmailAddress -> TextInput.Model -> Ui.Element UiHover units
loginToolbarUi pressedSubmitEmail emailTextInput =
    let
        pressedSubmit2 : Bool
        pressedSubmit2 =
            case pressedSubmitEmail of
                NotSubmitted { pressedSubmit } ->
                    pressedSubmit

                _ ->
                    False

        loginUi : Ui.Element UiHover units
        loginUi =
            Ui.column
                { spacing = 10, padding = Ui.paddingXY 20 10 }
                [ Ui.text "Enter your email address and we'll send a login link"
                , Ui.column
                    { spacing = 6, padding = Ui.noPadding }
                    [ Ui.row
                        { spacing = 10, padding = Ui.noPadding }
                        [ Ui.textInput
                            { id = EmailAddressTextInputHover
                            , width = Quantity 780
                            , isValid =
                                if pressedSubmit2 then
                                    EmailAddress.fromString emailTextInput.current.text /= Nothing

                                else
                                    True
                            }
                            emailTextInput
                        , Ui.button
                            { id = SendEmailButtonHover, padding = Ui.paddingXY 30 4, inFront = [] }
                            (Ui.text "Send email")
                        ]
                    , case pressedSubmitEmail of
                        NotSubmitted { pressedSubmit } ->
                            if pressedSubmit then
                                case EmailAddress.fromString emailTextInput.current.text of
                                    Just _ ->
                                        Ui.text ""

                                    Nothing ->
                                        Ui.colorText (Color.rgb255 245 0 0) "Invalid email address"

                            else
                                Ui.text ""

                        Submitting ->
                            Ui.text "Sending..."

                        Submitted _ ->
                            Ui.text ""
                    ]
                , Ui.wrappedText 1000 "If you don't have an account you'll need to be invited by an existing player."
                ]
    in
    case pressedSubmitEmail of
        Submitted emailAddress ->
            let
                submittedText : Ui.Element id units
                submittedText =
                    "Login email sent to " ++ EmailAddress.toString emailAddress |> Ui.wrappedText 1000
            in
            Ui.el
                { padding =
                    Ui.size loginUi
                        |> Coord.minus (Ui.size submittedText)
                        |> Coord.divide (Coord.xy 2 2)
                        |> Ui.paddingXY2
                , inFront = []
                , borderAndBackground = borderAndBackground
                }
                submittedText

        _ ->
            loginUi


toolbarUi :
    Bool
    -> Colors
    -> TextInput.Model
    -> TextInput.Model
    -> AssocList.Dict TileGroup Colors
    -> Dict String TileGroup
    -> Tool
    -> Ui.Element UiHover units
toolbarUi hasCmdKey handColor primaryColorTextInput secondaryColorTextInput colors hotkeys currentTool =
    let
        { showPrimaryColorTextInput, showSecondaryColorTextInput } =
            showColorTextInputs currentTool

        currentToolButton : ToolButton
        currentToolButton =
            case currentTool of
                HandTool ->
                    HandToolButton

                TilePlacerTool { tileGroup } ->
                    TilePlacerToolButton tileGroup

                TilePickerTool ->
                    TilePickerToolButton
    in
    Ui.row
        { spacing = 0, padding = Ui.noPadding }
        [ List.map (toolButtonUi hasCmdKey handColor colors hotkeys currentToolButton) buttonTiles
            |> List.greedyGroupsOf 3
            |> List.map (Ui.column { spacing = 2, padding = Ui.noPadding })
            |> Ui.row { spacing = 2, padding = Ui.noPadding }
        , Ui.row
            { spacing = 10, padding = Ui.paddingXY 12 8 }
            [ Ui.column
                { spacing = 10, padding = Ui.noPadding }
                [ if showPrimaryColorTextInput then
                    Ui.textInput
                        { id = PrimaryColorInput, width = primaryColorInputWidth, isValid = True }
                        primaryColorTextInput

                  else
                    Ui.empty
                , if showSecondaryColorTextInput then
                    Ui.textInput
                        { id = SecondaryColorInput, width = secondaryColorInputWidth, isValid = True }
                        secondaryColorTextInput

                  else
                    Ui.empty
                , Ui.el
                    { padding =
                        { topLeft = Coord.xy (Quantity.unwrap primaryColorInputWidth) 0
                        , bottomRight = Coord.xy 0 0
                        }
                    , inFront = []
                    , borderAndBackground = NoBorderOrBackground
                    }
                    Ui.empty
                ]
            , Ui.center
                { size = buttonSize }
                (case currentTool of
                    TilePlacerTool { tileGroup } ->
                        case AssocList.get tileGroup colors of
                            Just color ->
                                (Tile.getTileGroupData tileGroup).tiles
                                    |> List.Nonempty.head
                                    |> tileMesh color

                            Nothing ->
                                Ui.empty

                    TilePickerTool ->
                        Cursor.eyeDropperCursor2

                    HandTool ->
                        Cursor.defaultCursorMesh2 handColor
                )
            ]
        ]


toolButtonUi :
    Bool
    -> Colors
    -> AssocList.Dict TileGroup Colors
    -> Dict String TileGroup
    -> ToolButton
    -> ToolButton
    -> Ui.Element UiHover units
toolButtonUi hasCmdKey handColor colors hotkeys currentTool tool =
    let
        tileColors =
            case tool of
                TilePlacerToolButton tileGroup ->
                    case AssocList.get tileGroup colors of
                        Just a ->
                            a

                        Nothing ->
                            Tile.getTileGroupData tileGroup |> .defaultColors |> Tile.defaultToPrimaryAndSecondary

                HandToolButton ->
                    handColor

                TilePickerToolButton ->
                    Tile.defaultToPrimaryAndSecondary ZeroDefaultColors

        hotkeyText : Maybe String
        hotkeyText =
            case tool of
                TilePlacerToolButton tileGroup ->
                    Dict.toList hotkeys |> List.find (Tuple.second >> (==) tileGroup) |> Maybe.map Tuple.first

                HandToolButton ->
                    Just "Esc"

                TilePickerToolButton ->
                    if hasCmdKey then
                        Just "Cmd"

                    else
                        Just "Ctrl"

        label : Ui.Element UiHover units
        label =
            case tool of
                TilePlacerToolButton tileGroup ->
                    tileMesh tileColors (getTileGroupTile tileGroup 0)

                HandToolButton ->
                    Cursor.defaultCursorMesh2 handColor

                TilePickerToolButton ->
                    Cursor.eyeDropperCursor2
    in
    Ui.customButton
        { id = ToolButtonHover tool
        , padding = Ui.noPadding
        , inFront =
            case hotkeyText of
                Just hotkey ->
                    [ Ui.outlinedText { outline = Color.outlineColor, color = Color.white, text = hotkey }
                        |> Ui.el
                            { padding = { topLeft = Coord.xy 2 0, bottomRight = Coord.xy 0 0 }
                            , inFront = []
                            , borderAndBackground = NoBorderOrBackground
                            }
                        |> Ui.bottomLeft { size = buttonSize }
                    ]

                Nothing ->
                    []
        , borderAndBackground =
            BorderAndBackground
                { borderWidth = 2
                , borderColor = Color.outlineColor
                , backgroundColor =
                    if currentTool == tool then
                        Color.highlightColor

                    else
                        Color.fillColor
                }
        , borderAndBackgroundFocus =
            BorderAndBackground
                { borderWidth = 2
                , borderColor = Color.outlineColor
                , backgroundColor = Color.highlightColor
                }
        }
        (Ui.center { size = buttonSize } label)


buttonTiles : List ToolButton
buttonTiles =
    [ HandToolButton
    , TilePickerToolButton
    , TilePlacerToolButton EmptyTileGroup
    , TilePlacerToolButton PostOfficeGroup
    , TilePlacerToolButton HouseGroup
    , TilePlacerToolButton LogCabinGroup
    , TilePlacerToolButton TrainHouseGroup
    , TilePlacerToolButton RailTurnGroup
    , TilePlacerToolButton RailTurnSplitGroup
    , TilePlacerToolButton RailTurnSplitMirrorGroup
    , TilePlacerToolButton RailStrafeSmallGroup
    , TilePlacerToolButton RailStrafeGroup
    , TilePlacerToolButton RailTurnLargeGroup
    , TilePlacerToolButton RailStraightGroup
    , TilePlacerToolButton RailCrossingGroup
    , TilePlacerToolButton SidewalkRailGroup
    , TilePlacerToolButton SidewalkGroup
    , TilePlacerToolButton PineTreeGroup
    , TilePlacerToolButton RoadStraightGroup
    , TilePlacerToolButton RoadTurnGroup
    , TilePlacerToolButton Road4WayGroup
    , TilePlacerToolButton RoadSidewalkCrossingGroup
    , TilePlacerToolButton Road3WayGroup
    , TilePlacerToolButton RoadRailCrossingGroup
    , TilePlacerToolButton RoadDeadendGroup
    , TilePlacerToolButton FenceStraightGroup
    ]


toolbarRowCount : number
toolbarRowCount =
    3


tileMesh : Colors -> Tile -> Ui.Element id units
tileMesh colors tile =
    let
        data : TileData b
        data =
            Tile.getData tile

        size =
            Coord.multiply Units.tileSize data.size
                |> Coord.minimum buttonSize

        spriteSize =
            if data.size == Coord.xy 1 1 then
                Coord.multiplyTuple ( 2, 2 ) size

            else
                size
    in
    Ui.quads
        { size =
            if tile == EmptyTile then
                Coord.tuple ( 28 * 2, 27 * 2 )

            else
                spriteSize
        , vertices =
            \position3 ->
                if tile == EmptyTile then
                    Sprite.sprite
                        position3
                        (Coord.tuple ( 28 * 2, 27 * 2 ))
                        (Coord.xy 504 42)
                        (Coord.xy 28 27)

                else
                    (case data.texturePosition of
                        Just texturePosition ->
                            Sprite.spriteWithTwoColors
                                colors
                                position3
                                spriteSize
                                (Coord.multiply Units.tileSize texturePosition)
                                size

                        Nothing ->
                            []
                    )
                        ++ (case data.texturePositionTopLayer of
                                Just topLayer ->
                                    let
                                        texturePosition2 =
                                            Coord.multiply Units.tileSize topLayer.texturePosition
                                    in
                                    Sprite.spriteWithTwoColors
                                        colors
                                        position3
                                        spriteSize
                                        texturePosition2
                                        size

                                Nothing ->
                                    []
                           )
        }


primaryColorInputWidth : Quantity Int units
primaryColorInputWidth =
    6 * Coord.xRaw Sprite.charSize * TextInput.charScale + Coord.xRaw TextInput.padding * 2 + 2 |> Quantity


secondaryColorInputWidth : Quantity Int units
secondaryColorInputWidth =
    primaryColorInputWidth


buttonSize : Coord units
buttonSize =
    Coord.xy 80 80


showColorTextInputs : Tool -> { showPrimaryColorTextInput : Bool, showSecondaryColorTextInput : Bool }
showColorTextInputs tool =
    case tool of
        TilePlacerTool { tileGroup } ->
            case Tile.getTileGroupData tileGroup |> .defaultColors of
                ZeroDefaultColors ->
                    { showPrimaryColorTextInput = False, showSecondaryColorTextInput = False }

                OneDefaultColor _ ->
                    { showPrimaryColorTextInput = True, showSecondaryColorTextInput = False }

                TwoDefaultColors _ _ ->
                    { showPrimaryColorTextInput = True, showSecondaryColorTextInput = True }

        HandTool ->
            { showPrimaryColorTextInput = True, showSecondaryColorTextInput = True }

        TilePickerTool ->
            { showPrimaryColorTextInput = False, showSecondaryColorTextInput = False }


getTileGroupTile : TileGroup -> Int -> Tile
getTileGroupTile tileGroup index =
    Tile.getTileGroupData tileGroup |> .tiles |> List.Nonempty.get index


createInfoMesh : Maybe PingData -> Maybe (Id UserId) -> Ui.Element id units
createInfoMesh maybePingData maybeUserId =
    let
        durationToString duration =
            Duration.inMilliseconds duration |> round |> String.fromInt
    in
    "Warning! Game is in alpha. The world is reset often.\n"
        ++ "User ID: "
        ++ (case maybeUserId of
                Just userId ->
                    String.fromInt (Id.toInt userId)

                Nothing ->
                    "Not logged in"
           )
        ++ "\n"
        ++ (case maybePingData of
                Just pingData ->
                    ("RTT: " ++ durationToString pingData.roundTripTime ++ "ms\n")
                        ++ ("Server offset: " ++ durationToString (PingData.pingOffset { pingData = maybePingData }) ++ "ms")

                Nothing ->
                    ""
           )
        |> Ui.text
        |> Ui.el { padding = Ui.paddingXY 8 4, inFront = [], borderAndBackground = NoBorderOrBackground }
