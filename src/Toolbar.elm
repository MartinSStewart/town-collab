module Toolbar exposing
    ( ViewData
    , getTileGroupTile
    , showColorTextInputs
    , validateInviteEmailAddress
    , view
    )

import AssocList
import Change exposing (UserStatus(..))
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Cursor
import Dict exposing (Dict)
import DisplayName
import Duration
import EmailAddress exposing (EmailAddress)
import Id exposing (Id, MailId, UserId)
import IdDict exposing (IdDict)
import Keyboard
import List.Extra as List
import List.Nonempty
import MailEditor
import PingData exposing (PingData)
import Pixels exposing (Pixels)
import Quantity exposing (Quantity(..))
import Sound
import Sprite
import TextInput
import Tile exposing (DefaultColor(..), Tile(..), TileData, TileGroup(..))
import Types exposing (Hover(..), SubmitStatus(..), Tool(..), ToolButton(..), TopMenu(..), UiHover(..), UiMsg(..))
import Ui exposing (BorderAndFill(..))
import Units
import User exposing (FrontendUser)


type alias ViewData =
    { devicePixelRatio : Float
    , windowSize : Coord Pixels
    , pressedSubmitEmail : SubmitStatus EmailAddress
    , loginTextInput : TextInput.Model
    , hasCmdKey : Bool
    , handColor : Maybe Colors
    , userStatus : UserStatus
    , primaryColorTextInput : TextInput.Model
    , secondaryColorTextInput : TextInput.Model
    , tileColors : AssocList.Dict TileGroup Colors
    , tileHotkeys : Dict String TileGroup
    , currentTool : Tool
    , pingData : Maybe PingData
    , userId : Maybe (Id UserId)
    , inviteTextInput : TextInput.Model
    , inviteSubmitStatus : SubmitStatus EmailAddress
    , musicVolume : Int
    , soundEffectVolume : Int
    , topMenuOpened : Maybe TopMenu
    , mailEditor : Maybe MailEditor.Model
    , users : IdDict UserId FrontendUser
    }


view : ViewData -> Ui.Element UiHover UiMsg
view data =
    case ( data.userStatus, data.mailEditor ) of
        ( LoggedIn loggedIn, Just mailEditor ) ->
            MailEditor.ui
                (Coord.multiplyTuple_ ( data.devicePixelRatio, data.devicePixelRatio ) data.windowSize)
                MailEditorHover
                MailEditorUiMsg
                data.users
                loggedIn.inbox
                mailEditor

        _ ->
            Ui.bottomCenter
                { size = Coord.multiplyTuple_ ( data.devicePixelRatio, data.devicePixelRatio ) data.windowSize
                , inFront =
                    [ Ui.row
                        { padding = Ui.noPadding, spacing = 4 }
                        [ case data.topMenuOpened of
                            Just (SettingsMenu nameTextInput) ->
                                settingsView data.musicVolume data.soundEffectVolume nameTextInput

                            Just LoggedOutSettingsMenu ->
                                loggedOutSettingsView data.musicVolume data.soundEffectVolume

                            _ ->
                                Ui.button
                                    { id = SettingsButton
                                    , padding = Ui.paddingXY 10 4
                                    , onPress = PressedSettingsButton
                                    }
                                    (Ui.text "Settings")
                        , case data.userStatus of
                            LoggedIn loggedIn ->
                                inviteView
                                    (data.topMenuOpened == Just InviteMenu)
                                    loggedIn.emailAddress
                                    data.inviteTextInput
                                    data.inviteSubmitStatus

                            NotLoggedIn ->
                                Ui.none
                        , case data.userStatus of
                            LoggedIn loggedIn ->
                                let
                                    unviewedMail =
                                        IdDict.filter (\_ mail -> not mail.isViewed) loggedIn.inbox
                                in
                                if IdDict.isEmpty unviewedMail then
                                    Ui.none

                                else
                                    Ui.customButton
                                        { id = YouGotMailButton
                                        , padding = { topLeft = Coord.xy 10 4, bottomRight = Coord.xy 4 4 }
                                        , onPress = PressedYouGotMail
                                        , onMouseDown = Nothing
                                        , borderAndFill =
                                            BorderAndFill
                                                { borderWidth = 2
                                                , borderColor = Color.outlineColor
                                                , fillColor = Color.fillColor2
                                                }
                                        , borderAndFillFocus =
                                            BorderAndFill
                                                { borderWidth = 2
                                                , borderColor = Color.outlineColor
                                                , fillColor = Color.fillColor2
                                                }
                                        , inFront = []
                                        }
                                        (Ui.row
                                            { spacing = 4, padding = Ui.noPadding }
                                            [ Ui.text "You got mail"
                                            , Ui.el
                                                { padding = Ui.paddingXY 8 0
                                                , inFront = []
                                                , borderAndFill = FillOnly (Color.rgb255 255 50 50)
                                                }
                                                (Ui.colorText Color.white (String.fromInt (IdDict.size unviewedMail)))
                                            ]
                                        )

                            NotLoggedIn ->
                                Ui.none
                        ]
                    ]
                }
                (Ui.el
                    { padding = Ui.noPadding
                    , inFront = []
                    , borderAndFill = borderAndFill
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


settingsView : Int -> Int -> TextInput.Model -> Ui.Element UiHover UiMsg
settingsView musicVolume soundEffectVolume nameTextInput =
    let
        musicVolumeInput =
            volumeControl
                "Music volume "
                LowerMusicVolume
                RaiseMusicVolume
                PressedLowerMusicVolume
                PressedRaiseMusicVolume
                musicVolume
    in
    Ui.el
        { padding = Ui.paddingXY 8 8
        , inFront = []
        , borderAndFill = borderAndFill
        }
        (Ui.column
            { spacing = 8
            , padding = Ui.noPadding
            }
            [ Ui.button
                { id = CloseSettings, onPress = PressedCloseSettings, padding = Ui.paddingXY 10 4 }
                (Ui.text "Close")
            , Ui.column
                { spacing = 6
                , padding = Ui.noPadding
                }
                [ musicVolumeInput
                , volumeControl
                    "Sound effects"
                    LowerSoundEffectVolume
                    RaiseSoundEffectVolume
                    PressedLowerSoundEffectVolume
                    PressedRaiseSoundEffectVolume
                    soundEffectVolume
                , Ui.column
                    { spacing = 4
                    , padding = Ui.noPadding
                    }
                    [ Ui.text "Display name"
                    , Ui.textInput
                        { id = DisplayNameTextInput
                        , width = Ui.size musicVolumeInput |> Coord.xRaw
                        , isValid =
                            case DisplayName.fromString nameTextInput.current.text of
                                Ok _ ->
                                    True

                                Err _ ->
                                    False
                        , onKeyDown = ChangedDisplayNameTextInput
                        }
                        nameTextInput
                    ]
                ]
            ]
        )


volumeControl : String -> id -> id -> msg -> msg -> Int -> Ui.Element id msg
volumeControl name lowerId raiseId pressedLower pressedRaise volume =
    Ui.row
        { spacing = 8, padding = Ui.noPadding }
        [ Ui.text name
        , Ui.button
            { id = lowerId
            , padding = { topLeft = Coord.xy 6 0, bottomRight = Coord.xy 4 2 }
            , onPress = pressedLower
            }
            (Ui.text "-")
        , Ui.text (String.padLeft 2 ' ' (String.fromInt volume) ++ "/" ++ String.fromInt Sound.maxVolume)
        , Ui.button
            { id = raiseId
            , padding = { topLeft = Coord.xy 6 0, bottomRight = Coord.xy 4 2 }
            , onPress = pressedRaise
            }
            (Ui.text "+")
        ]


loggedOutSettingsView : Int -> Int -> Ui.Element UiHover UiMsg
loggedOutSettingsView musicVolume soundEffectVolume =
    Ui.el
        { padding = Ui.paddingXY 8 8
        , inFront = []
        , borderAndFill = borderAndFill
        }
        (Ui.column
            { spacing = 8
            , padding = Ui.noPadding
            }
            [ Ui.button
                { id = CloseSettings, onPress = PressedCloseSettings, padding = Ui.paddingXY 10 4 }
                (Ui.text "Close")
            , Ui.column
                { spacing = 6
                , padding = Ui.noPadding
                }
                [ volumeControl
                    "Music volume "
                    LowerMusicVolume
                    RaiseMusicVolume
                    PressedLowerMusicVolume
                    PressedRaiseMusicVolume
                    musicVolume
                , volumeControl
                    "Sound effects"
                    LowerSoundEffectVolume
                    RaiseSoundEffectVolume
                    PressedLowerSoundEffectVolume
                    PressedRaiseSoundEffectVolume
                    soundEffectVolume
                ]
            ]
        )


validateInviteEmailAddress : EmailAddress -> String -> Result String EmailAddress
validateInviteEmailAddress emailAddress inviteEmailAddressText =
    case EmailAddress.fromString inviteEmailAddressText of
        Just inviteEmailAddress ->
            if emailAddress == inviteEmailAddress then
                Err "You can't invite yourself"

            else
                Ok inviteEmailAddress

        Nothing ->
            Err "Invalid email"


inviteView : Bool -> EmailAddress -> TextInput.Model -> SubmitStatus EmailAddress -> Ui.Element UiHover UiMsg
inviteView showInvite emailAddress inviteTextInput inviteSubmitStatus =
    if showInvite then
        let
            inviteForm : Ui.Element UiHover UiMsg
            inviteForm =
                Ui.column
                    { spacing = 8, padding = Ui.noPadding }
                    [ Ui.button
                        { id = CloseInviteUser, onPress = PressedCloseInviteUser, padding = Ui.paddingXY 10 4 }
                        (Ui.text "Cancel")
                    , content
                    ]

            content : Ui.Element UiHover UiMsg
            content =
                Ui.column
                    { spacing = 0, padding = Ui.noPadding }
                    [ Ui.column
                        { spacing = 0, padding = Ui.noPadding }
                        [ Ui.text "Enter email address to send an invite to"
                        , Ui.textInput
                            { id = InviteEmailAddressTextInput
                            , width = 800
                            , isValid = True
                            , onKeyDown = ChangedInviteEmailAddressTextInput
                            }
                            inviteTextInput
                        ]
                    , Ui.row
                        { spacing = 4, padding = { topLeft = Coord.xy 0 8, bottomRight = Coord.origin } }
                        [ Ui.button
                            { id = SubmitInviteUser, onPress = PressedSendInviteUser, padding = Ui.paddingXY 10 4 }
                            (case inviteSubmitStatus of
                                NotSubmitted _ ->
                                    Ui.text "Send invite"

                                Submitting ->
                                    Ui.text "Submitting "

                                Submitted _ ->
                                    Ui.text "Submitting "
                            )
                        , case
                            ( pressedSubmit inviteSubmitStatus
                            , validateInviteEmailAddress emailAddress inviteTextInput.current.text
                            )
                          of
                            ( True, Err error ) ->
                                Ui.el
                                    { padding = Ui.paddingXY 4 4, inFront = [], borderAndFill = NoBorderOrFill }
                                    (Ui.colorText Color.errorColor error)

                            _ ->
                                Ui.none
                        ]
                    ]
        in
        Ui.el
            { padding = Ui.paddingXY 8 8, inFront = [], borderAndFill = borderAndFill }
            (case inviteSubmitStatus of
                Submitted inviteEmailAddress ->
                    Ui.column
                        { spacing = 0, padding = Ui.noPadding }
                        [ Ui.button
                            { id = CloseInviteUser, onPress = PressedCloseInviteUser, padding = Ui.paddingXY 10 4 }
                            (Ui.text "Close")
                        , Ui.center
                            { size = Ui.size content }
                            (Ui.wrappedText
                                (Ui.size content |> Coord.xRaw |> (+) -16)
                                ("An invite email as been sent to " ++ EmailAddress.toString inviteEmailAddress)
                            )
                        ]

                _ ->
                    inviteForm
            )

    else
        Ui.button
            { id = ShowInviteUser
            , onPress = PressedShowInviteUser
            , padding = Ui.paddingXY 10 4
            }
            (Ui.text "Invite")


borderAndFill : BorderAndFill
borderAndFill =
    BorderAndFill
        { borderWidth = 2
        , borderColor = Color.outlineColor
        , fillColor = Color.fillColor
        }


pressedSubmit : SubmitStatus a -> Bool
pressedSubmit submitStatus =
    case submitStatus of
        NotSubmitted a ->
            a.pressedSubmit

        _ ->
            False


loginToolbarUi : SubmitStatus EmailAddress -> TextInput.Model -> Ui.Element UiHover UiMsg
loginToolbarUi pressedSubmitEmail emailTextInput =
    let
        pressedSubmit2 =
            pressedSubmit pressedSubmitEmail

        loginUi : Ui.Element UiHover UiMsg
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
                            , width = 780
                            , isValid =
                                if pressedSubmit2 then
                                    EmailAddress.fromString emailTextInput.current.text /= Nothing

                                else
                                    True
                            , onKeyDown = KeyDownEmailAddressTextInputHover
                            }
                            emailTextInput
                        , Ui.button
                            { id = SendEmailButtonHover, onPress = PressedSendEmail, padding = Ui.paddingXY 30 4 }
                            (Ui.text "Send email")
                        ]
                    , case pressedSubmitEmail of
                        NotSubmitted a ->
                            if a.pressedSubmit then
                                case EmailAddress.fromString emailTextInput.current.text of
                                    Just _ ->
                                        Ui.text ""

                                    Nothing ->
                                        Ui.colorText Color.errorColor "Invalid email address"

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
                submittedText : Ui.Element id msg
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
                , borderAndFill = borderAndFill
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
    -> Ui.Element UiHover UiMsg
toolbarUi hasCmdKey handColor primaryColorTextInput secondaryColorTextInput tileColors hotkeys currentTool =
    let
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
        [ List.map (toolButtonUi hasCmdKey handColor tileColors hotkeys currentToolButton) buttonTiles
            |> List.greedyGroupsOf toolbarRowCount
            |> List.map (Ui.column { spacing = 2, padding = Ui.noPadding })
            |> Ui.row { spacing = 2, padding = Ui.noPadding }
        , selectedToolView handColor primaryColorTextInput secondaryColorTextInput tileColors currentTool
        ]


selectedToolView :
    Colors
    -> TextInput.Model
    -> TextInput.Model
    -> AssocList.Dict TileGroup Colors
    -> Tool
    -> Ui.Element UiHover UiMsg
selectedToolView handColor primaryColorTextInput secondaryColorTextInput tileColors currentTool =
    let
        { showPrimaryColorTextInput, showSecondaryColorTextInput } =
            showColorTextInputs handColor tileColors currentTool
    in
    Ui.column
        { spacing = 6, padding = Ui.paddingXY 12 8 }
        [ Ui.text
            (case currentTool of
                HandTool ->
                    "Pointer tool"

                TilePickerTool ->
                    "Tile picker"

                TilePlacerTool { tileGroup } ->
                    Tile.getTileGroupData tileGroup |> .name
            )
        , Ui.row
            { spacing = 10, padding = Ui.noPadding }
            [ Ui.column
                { spacing = 10, padding = Ui.noPadding }
                [ case showPrimaryColorTextInput of
                    Just color ->
                        colorTextInput PrimaryColorInput ChangedPrimaryColorInput primaryColorTextInput color

                    Nothing ->
                        Ui.none
                , case showSecondaryColorTextInput of
                    Just color ->
                        colorTextInput SecondaryColorInput ChangedSecondaryColorInput secondaryColorTextInput color

                    Nothing ->
                        Ui.none
                , Ui.el
                    { padding =
                        { topLeft =
                            Coord.xy
                                (colorTextInput
                                    PrimaryColorInput
                                    ChangedPrimaryColorInput
                                    primaryColorTextInput
                                    Color.black
                                    |> Ui.size
                                    |> Coord.xRaw
                                )
                                0
                        , bottomRight = Coord.xy 0 0
                        }
                    , inFront = []
                    , borderAndFill = NoBorderOrFill
                    }
                    Ui.none
                ]
            , Ui.center
                { size = buttonSize }
                (case currentTool of
                    TilePlacerTool { tileGroup } ->
                        case AssocList.get tileGroup tileColors of
                            Just color ->
                                (Tile.getTileGroupData tileGroup).tiles
                                    |> List.Nonempty.head
                                    |> tileMesh color

                            Nothing ->
                                Ui.none

                    TilePickerTool ->
                        Cursor.eyeDropperCursor2

                    HandTool ->
                        Cursor.defaultCursorMesh2 handColor
                )
            ]
        ]


colorTextInput :
    id
    -> (Bool -> Bool -> Keyboard.Key -> TextInput.Model -> UiMsg)
    -> TextInput.Model
    -> Color
    -> Ui.Element id UiMsg
colorTextInput id onChange textInput color =
    let
        padding =
            TextInput.size (Quantity primaryColorInputWidth) |> Coord.yRaw |> (\a -> a // 2)
    in
    Ui.row
        { spacing = -2, padding = Ui.noPadding }
        [ Ui.el
            { padding = Ui.paddingXY padding padding
            , inFront = []
            , borderAndFill =
                BorderAndFill
                    { borderWidth = 2
                    , borderColor = Color.outlineColor
                    , fillColor = color
                    }
            }
            Ui.none
        , Ui.textInput
            { id = id, width = primaryColorInputWidth, isValid = True, onKeyDown = onChange }
            textInput
        ]


toolButtonUi :
    Bool
    -> Colors
    -> AssocList.Dict TileGroup Colors
    -> Dict String TileGroup
    -> ToolButton
    -> ToolButton
    -> Ui.Element UiHover UiMsg
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

        label : Ui.Element UiHover UiMsg
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
        , onPress = PressedTool tool
        , onMouseDown = Nothing
        , padding = Ui.noPadding
        , inFront =
            case hotkeyText of
                Just hotkey ->
                    [ Ui.outlinedText { outline = Color.outlineColor, color = Color.white, text = hotkey }
                        |> Ui.el
                            { padding = { topLeft = Coord.xy 2 0, bottomRight = Coord.xy 0 0 }
                            , inFront = []
                            , borderAndFill = NoBorderOrFill
                            }
                        |> Ui.bottomLeft { size = buttonSize }
                    ]

                Nothing ->
                    []
        , borderAndFill =
            BorderAndFill
                { borderWidth = 2
                , borderColor = Color.outlineColor
                , fillColor =
                    if currentTool == tool then
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
        (Ui.center { size = buttonSize } label)


buttonTiles : List ToolButton
buttonTiles =
    [ HandToolButton
    , TilePickerToolButton
    ]
        ++ List.map TilePlacerToolButton Tile.allTileGroups


toolbarRowCount : number
toolbarRowCount =
    3


tileMesh : Colors -> Tile -> Ui.Element id msg
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


primaryColorInputWidth : Int
primaryColorInputWidth =
    6 * Coord.xRaw Sprite.charSize * TextInput.charScale + Coord.xRaw TextInput.padding * 2 + 2


buttonSize : Coord units
buttonSize =
    Coord.xy 80 80


showColorTextInputs :
    Colors
    -> AssocList.Dict TileGroup Colors
    -> Tool
    -> { showPrimaryColorTextInput : Maybe Color, showSecondaryColorTextInput : Maybe Color }
showColorTextInputs handColor tileColors tool =
    case tool of
        TilePlacerTool { tileGroup } ->
            case ( AssocList.get tileGroup tileColors, Tile.getTileGroupData tileGroup |> .defaultColors ) of
                ( _, ZeroDefaultColors ) ->
                    { showPrimaryColorTextInput = Nothing, showSecondaryColorTextInput = Nothing }

                ( Just colors, OneDefaultColor _ ) ->
                    { showPrimaryColorTextInput = Just colors.primaryColor, showSecondaryColorTextInput = Nothing }

                ( Nothing, OneDefaultColor color ) ->
                    { showPrimaryColorTextInput = Just color, showSecondaryColorTextInput = Nothing }

                ( Just colors, TwoDefaultColors _ ) ->
                    { showPrimaryColorTextInput = Just colors.primaryColor
                    , showSecondaryColorTextInput = Just colors.secondaryColor
                    }

                ( Nothing, TwoDefaultColors colors ) ->
                    { showPrimaryColorTextInput = Just colors.primaryColor
                    , showSecondaryColorTextInput = Just colors.secondaryColor
                    }

        HandTool ->
            { showPrimaryColorTextInput = Just handColor.primaryColor
            , showSecondaryColorTextInput = Just handColor.secondaryColor
            }

        TilePickerTool ->
            { showPrimaryColorTextInput = Nothing, showSecondaryColorTextInput = Nothing }


getTileGroupTile : TileGroup -> Int -> Tile
getTileGroupTile tileGroup index =
    Tile.getTileGroupData tileGroup |> .tiles |> List.Nonempty.get index


createInfoMesh : Maybe PingData -> Maybe (Id UserId) -> Ui.Element id msg
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
        |> Ui.el { padding = Ui.paddingXY 8 4, inFront = [], borderAndFill = NoBorderOrFill }
