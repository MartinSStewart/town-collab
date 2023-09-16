module Toolbar exposing
    ( actualViewPoint
    , canDragView
    , getTileGroupTile
    , isDisconnected
    , mapSize
    , offsetViewPoint
    , screenToWorld
    , validateInviteEmailAddress
    , view
    )

import AssocList
import Change exposing (AdminData, AreTrainsDisabled(..), LoggedIn_, TimeOfDay(..), UserStatus(..))
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Cursor
import Dict exposing (Dict)
import DisplayName
import Duration
import Effect.Time
import EmailAddress exposing (EmailAddress)
import Env
import Id
import IdDict exposing (IdDict)
import List.Extra as List
import List.Nonempty
import LocalGrid
import MailEditor
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity(..), Rate)
import Shaders
import Sound
import Sprite
import TextInput
import Tile exposing (DefaultColor(..), Tile(..), TileData, TileGroup(..))
import Tool exposing (Tool(..))
import Train
import Types exposing (ContextMenu, FrontendLoaded, Hover(..), MouseButtonState(..), SubmitStatus(..), ToolButton(..), TopMenu(..), UiHover(..), ViewPoint(..))
import Ui exposing (BorderAndFill(..))
import Units exposing (WorldUnit)
import User
import Vector2d exposing (Vector2d)


view : FrontendLoaded -> Ui.Element UiHover
view model =
    let
        localModel : LocalGrid.LocalGrid_
        localModel =
            LocalGrid.localModel model.localModel

        otherUsersOnline =
            case localModel.userStatus of
                LoggedIn { userId } ->
                    IdDict.remove userId localModel.cursors |> IdDict.size

                NotLoggedIn _ ->
                    IdDict.size localModel.cursors

        toolbarElement =
            if model.hideUi then
                Ui.none

            else
                Ui.el
                    { padding = Ui.noPadding
                    , inFront = []
                    , borderAndFill = borderAndFill
                    }
                    (case localModel.userStatus of
                        LoggedIn loggedIn ->
                            toolbarUi
                                (case IdDict.get loggedIn.userId localModel.users of
                                    Just user ->
                                        user.handColor

                                    Nothing ->
                                        Cursor.defaultColors
                                )
                                model
                                (case model.currentTool of
                                    HandTool ->
                                        HandToolButton

                                    TilePlacerTool { tileGroup } ->
                                        TilePlacerToolButton tileGroup

                                    TilePickerTool ->
                                        TilePickerToolButton

                                    TextTool _ ->
                                        TextToolButton

                                    ReportTool ->
                                        ReportToolButton
                                )

                        NotLoggedIn _ ->
                            loginToolbarUi model.pressedSubmitEmail model.loginTextInput
                    )
    in
    case ( localModel.userStatus, model.mailEditor ) of
        ( LoggedIn loggedIn, Just mailEditor ) ->
            MailEditor.ui
                (isDisconnected model)
                model.windowSize
                MailEditorHover
                localModel.users
                loggedIn.inbox
                mailEditor

        _ ->
            Ui.bottomCenter
                { size = model.windowSize
                , inFront =
                    (if model.hideUi then
                        []

                     else
                        [ case model.contextMenu of
                            Just contextMenu ->
                                contextMenuView (Ui.size toolbarElement |> Coord.yRaw) contextMenu model

                            Nothing ->
                                Ui.none
                        , if model.showInviteTree then
                            Ui.topRight
                                { size = model.windowSize }
                                (Ui.el
                                    { padding = Ui.paddingXY 16 50, inFront = [], borderAndFill = NoBorderOrFill }
                                    (User.drawInviteTree localModel.users localModel.inviteTree)
                                )

                          else
                            Ui.none
                        , if isDisconnected model then
                            MailEditor.disconnectWarning model.windowSize

                          else
                            Ui.topRight
                                { size = model.windowSize }
                                (Ui.row
                                    { spacing = 5, padding = Ui.noPadding }
                                    [ case localModel.userStatus of
                                        LoggedIn loggedIn ->
                                            case ( loggedIn.isGridReadOnly, localModel.trainsDisabled ) of
                                                ( True, TrainsEnabled ) ->
                                                    Ui.el
                                                        { padding = Ui.paddingXY 16 4, borderAndFill = FillOnly Color.errorColor, inFront = [] }
                                                        (Ui.colorText Color.white "Placing tiles currently disabled")

                                                ( True, TrainsDisabled ) ->
                                                    Ui.el
                                                        { padding = Ui.paddingXY 16 4, borderAndFill = FillOnly Color.errorColor, inFront = [] }
                                                        (Ui.colorText Color.white "Trains and placing tiles disabled")

                                                ( False, TrainsDisabled ) ->
                                                    Ui.el
                                                        { padding = Ui.paddingXY 16 4, borderAndFill = FillOnly Color.errorColor, inFront = [] }
                                                        (Ui.colorText Color.white "Trains currently disabled")

                                                ( False, TrainsEnabled ) ->
                                                    Ui.none

                                        NotLoggedIn _ ->
                                            Ui.none
                                    , Ui.button
                                        { id = UsersOnlineButton
                                        , padding = Ui.paddingXY 10 4
                                        }
                                        (if otherUsersOnline == 1 then
                                            Ui.text "1 user online"

                                         else
                                            Ui.text (String.fromInt otherUsersOnline ++ " users online")
                                        )
                                    ]
                                )
                        , Ui.row
                            { padding = Ui.noPadding, spacing = 4 }
                            [ case model.topMenuOpened of
                                Just (SettingsMenu nameTextInput) ->
                                    case localModel.userStatus of
                                        LoggedIn loggedIn ->
                                            settingsView
                                                model.musicVolume
                                                model.soundEffectVolume
                                                nameTextInput
                                                localModel
                                                loggedIn

                                        NotLoggedIn _ ->
                                            Ui.none

                                Just LoggedOutSettingsMenu ->
                                    case localModel.userStatus of
                                        LoggedIn loggedIn ->
                                            Ui.none

                                        NotLoggedIn notLoggedIn ->
                                            loggedOutSettingsView notLoggedIn.timeOfDay model.musicVolume model.soundEffectVolume

                                _ ->
                                    Ui.button
                                        { id = SettingsButton
                                        , padding = Ui.paddingXY 10 4
                                        }
                                        (Ui.text "Settings")
                            , case localModel.userStatus of
                                LoggedIn loggedIn ->
                                    inviteView
                                        (model.topMenuOpened == Just InviteMenu)
                                        loggedIn.emailAddress
                                        model.inviteTextInput
                                        model.inviteSubmitStatus

                                NotLoggedIn _ ->
                                    Ui.none
                            , case localModel.userStatus of
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
                                            , borderAndFill = Ui.defaultButtonBorderAndFill
                                            , borderAndFillFocus = Ui.defaultButtonBorderAndFill
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

                                NotLoggedIn _ ->
                                    Ui.none
                            ]
                        ]
                    )
                        ++ (if model.showMap then
                                [ let
                                    mapSize2 =
                                        mapSize model.windowSize
                                  in
                                  Ui.el
                                    { padding =
                                        { topLeft = Coord.xy mapSize2 mapSize2 |> Coord.plus (Coord.xy 16 16)
                                        , bottomRight = Coord.origin
                                        }
                                    , borderAndFill =
                                        BorderAndFill
                                            { borderWidth = 2
                                            , borderColor = Color.outlineColor
                                            , fillColor = Color.fillColor
                                            }
                                    , inFront = []
                                    }
                                    Ui.none
                                    |> Ui.ignoreInputs
                                    |> Ui.center { size = model.windowSize }
                                ]

                            else
                                []
                           )
                }
                toolbarElement


contextMenuView : Int -> ContextMenu -> FrontendLoaded -> Ui.Element UiHover
contextMenuView toolbarHeight contextMenu model =
    let
        localModel =
            LocalGrid.localModel model.localModel

        contextMenuElement : Ui.Element UiHover
        contextMenuElement =
            Ui.el
                { padding = Ui.paddingXY 12 12, borderAndFill = NoBorderOrFill, inFront = [] }
                (Ui.column
                    { padding = Ui.noPadding, spacing = 8 }
                    [ Ui.row
                        { padding = Ui.noPadding, spacing = 8 }
                        [ Ui.el
                            { padding = Ui.paddingXY 8 4, inFront = [], borderAndFill = NoBorderOrFill }
                            (Ui.text
                                (String.fromInt (Coord.xRaw contextMenu.position)
                                    ++ ","
                                    ++ String.fromInt (Coord.yRaw contextMenu.position)
                                )
                            )
                        , Ui.button
                            { id = CopyPositionUrlButton, padding = Ui.paddingXY 8 4 }
                            (Ui.text
                                (if contextMenu.linkCopied then
                                    " Copied! "

                                 else
                                    "Copy link"
                                )
                            )
                        ]
                    , case contextMenu.userId of
                        Just userId ->
                            if userId == Shaders.worldGenUserId then
                                Ui.wrappedText 400 "Last changed by server"

                            else
                                case IdDict.get userId localModel.users of
                                    Just user ->
                                        let
                                            name =
                                                DisplayName.nameAndId user.name userId

                                            isYou =
                                                case localModel.userStatus of
                                                    LoggedIn loggedIn ->
                                                        loggedIn.userId == userId

                                                    NotLoggedIn _ ->
                                                        False
                                        in
                                        "Last changed by "
                                            ++ name
                                            ++ (if isYou then
                                                    " (you)"

                                                else
                                                    ""
                                               )
                                            |> Ui.wrappedText 400

                                    Nothing ->
                                        Ui.text "Not found"

                        Nothing ->
                            Ui.none
                    ]
                )

        position =
            worldToScreen model (contextMenu.position |> Coord.plus (Coord.xy 1 1) |> Coord.toPoint2d) |> Coord.floorPoint

        position2 =
            worldToScreen model (Coord.toPoint2d contextMenu.position) |> Coord.floorPoint

        fitsWindow =
            model.windowSize |> Coord.minus position |> Coord.minus (Ui.size contextMenuElement)

        fitsX =
            Coord.xRaw fitsWindow > 0

        fitsY =
            Coord.yRaw fitsWindow > toolbarHeight

        offset =
            case ( fitsX, fitsY ) of
                ( True, True ) ->
                    position

                ( True, False ) ->
                    Coord.xy (Coord.xRaw position) (Coord.yRaw position2)
                        |> Coord.minus (Ui.size contextMenuElement |> Coord.yOnly)

                ( False, True ) ->
                    Coord.xy (Coord.xRaw position2) (Coord.yRaw position)
                        |> Coord.minus (Ui.size contextMenuElement |> Coord.xOnly)

                ( False, False ) ->
                    position2 |> Coord.minus (Ui.size contextMenuElement)
    in
    Ui.el
        { padding =
            { topLeft = offset, bottomRight = Coord.origin }
        , inFront =
            [ Ui.el
                { padding = { topLeft = offset, bottomRight = Coord.origin }
                , inFront = []
                , borderAndFill = NoBorderOrFill
                }
                contextMenuElement
            ]
        , borderAndFill = NoBorderOrFill
        }
        (Ui.quads
            { size = Ui.size contextMenuElement
            , vertices =
                Sprite.nineSlice
                    { topLeft =
                        if fitsX && fitsY then
                            Coord.xy 504 69

                        else
                            Coord.xy 504 29
                    , top = Coord.xy 510 29
                    , topRight =
                        if not fitsX && fitsY then
                            Coord.xy 511 69

                        else
                            Coord.xy 511 29
                    , left = Coord.xy 504 35
                    , center = Coord.xy 510 35
                    , right = Coord.xy 511 35
                    , bottomLeft =
                        if fitsX && not fitsY then
                            Coord.xy 504 76

                        else
                            Coord.xy 504 36
                    , bottom = Coord.xy 510 36
                    , bottomRight =
                        if not fitsX && not fitsY then
                            Coord.xy 511 76

                        else
                            Coord.xy 511 36
                    , cornerSize = Coord.xy 6 6
                    , position = Coord.origin
                    , size = Ui.size contextMenuElement
                    , scale = 2
                    }
                    { primaryColor = Color.fillColor, secondaryColor = Color.outlineColor }
            }
        )


isDisconnected : FrontendLoaded -> Bool
isDisconnected model =
    Duration.from model.lastCheckConnection model.time |> Quantity.greaterThan (Duration.seconds 20)


mapSize : Coord Pixels -> Int
mapSize ( Quantity windowWidth, Quantity windowHeight ) =
    toFloat (min windowWidth windowHeight) * 0.7 |> round


settingsView : Int -> Int -> TextInput.Model -> LocalGrid.LocalGrid_ -> LoggedIn_ -> Ui.Element UiHover
settingsView musicVolume soundEffectVolume nameTextInput localModel loggedIn =
    let
        musicVolumeInput =
            volumeControl
                "Music volume "
                LowerMusicVolume
                RaiseMusicVolume
                musicVolume

        allowEmailNotifications =
            checkbox
                AllowEmailNotificationsCheckbox
                loggedIn.allowEmailNotifications
                "Allow email notifications"
    in
    Ui.el
        { padding = Ui.paddingXY 8 8
        , inFront = []
        , borderAndFill = borderAndFill
        }
        (Ui.column
            { spacing = 16
            , padding = Ui.noPadding
            }
            ([ Ui.button { id = CloseSettings, padding = Ui.paddingXY 10 4 } (Ui.text "Close")
             , Ui.column
                { spacing = 6
                , padding = Ui.noPadding
                }
                [ musicVolumeInput
                , volumeControl
                    "Sound effects"
                    LowerSoundEffectVolume
                    RaiseSoundEffectVolume
                    soundEffectVolume
                ]
             , timeOfDayRadio loggedIn.timeOfDay
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
                    , state = nameTextInput.current
                    }
                ]
             , allowEmailNotifications
             ]
                ++ (case loggedIn.adminData of
                        Just adminData ->
                            [ adminView
                                (Ui.size allowEmailNotifications |> Coord.xRaw)
                                loggedIn.isGridReadOnly
                                localModel.trainsDisabled
                                adminData
                            ]

                        Nothing ->
                            []
                   )
            )
        )


adminView : Int -> Bool -> AreTrainsDisabled -> AdminData -> Ui.Element UiHover
adminView parentWidth isGridReadOnly trainsDisabled adminData =
    Ui.column
        { spacing = 8, padding = Ui.noPadding }
        [ Ui.el
            { padding =
                { topLeft = Coord.xy parentWidth 2
                , bottomRight = Coord.origin
                }
            , inFront = []
            , borderAndFill = FillOnly Color.outlineColor
            }
            Ui.none
        , Ui.row { spacing = 0, padding = Ui.noPadding }
            [ Ui.text "Admin stuff"
            , if Env.isProduction then
                Ui.colorText Color.errorColor "(PRODUCTION)"

              else
                Ui.text "(dev)"
            ]
        , checkbox ToggleIsGridReadOnlyButton isGridReadOnly "Read only grid"
        , checkbox ToggleTrainsDisabledButton (trainsDisabled == TrainsDisabled) "Disable trains"
        , Ui.text
            ("Last cache regen: "
                ++ (case adminData.lastCacheRegeneration of
                        Just time ->
                            MailEditor.date time

                        Nothing ->
                            "Never"
                   )
            )
        , Ui.text "Sessions (id:count)"
        , Ui.button
            { id = ResetConnectionsButton
            , padding = Ui.paddingXY 10 4
            }
            (Ui.text "Reset connections")
        , Ui.column
            { spacing = 4, padding = Ui.noPadding }
            (List.map
                (\data ->
                    "  "
                        ++ (case data.userId of
                                Just userId ->
                                    Id.toInt userId |> String.fromInt

                                Nothing ->
                                    "-"
                           )
                        ++ ":"
                        ++ String.fromInt data.connectionCount
                        |> Ui.text
                )
                (List.filter (\a -> a.connectionCount > 0) adminData.userSessions)
            )
        ]


checkbox : id -> Bool -> String -> Ui.Element id
checkbox id isChecked text =
    Ui.customButton
        { id = id
        , padding = Ui.paddingXY 2 2
        , inFront = []
        , borderAndFill = NoBorderOrFill
        , borderAndFillFocus = FillOnly Color.fillColor2
        }
        (Ui.row
            { spacing = 8, padding = Ui.noPadding }
            [ if isChecked then
                Ui.colorSprite
                    { colors = { primaryColor = Color.outlineColor, secondaryColor = Color.fillColor }
                    , size = Coord.xy 36 36
                    , texturePosition = Coord.xy 591 72
                    , textureSize = Coord.xy 36 36
                    }

              else
                Ui.colorSprite
                    { colors = { primaryColor = Color.outlineColor, secondaryColor = Color.fillColor }
                    , size = Coord.xy 36 36
                    , texturePosition = Coord.xy 627 72
                    , textureSize = Coord.xy 36 36
                    }
            , Ui.text text
            ]
        )


volumeControl : String -> id -> id -> Int -> Ui.Element id
volumeControl name lowerId raiseId volume =
    Ui.row
        { spacing = 8, padding = Ui.noPadding }
        [ Ui.text name
        , Ui.button
            { id = lowerId
            , padding = { topLeft = Coord.xy 6 0, bottomRight = Coord.xy 4 2 }
            }
            (Ui.text "-")
        , Ui.text (String.padLeft 2 ' ' (String.fromInt volume) ++ "/" ++ String.fromInt Sound.maxVolume)
        , Ui.button
            { id = raiseId
            , padding = { topLeft = Coord.xy 6 0, bottomRight = Coord.xy 4 2 }
            }
            (Ui.text "+")
        ]


loggedOutSettingsView : TimeOfDay -> Int -> Int -> Ui.Element UiHover
loggedOutSettingsView timeOfDay musicVolume soundEffectVolume =
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
                { id = CloseSettings, padding = Ui.paddingXY 10 4 }
                (Ui.text "Close")
            , Ui.column
                { spacing = 6
                , padding = Ui.noPadding
                }
                [ volumeControl
                    "Music volume "
                    LowerMusicVolume
                    RaiseMusicVolume
                    musicVolume
                , volumeControl
                    "Sound effects"
                    LowerSoundEffectVolume
                    RaiseSoundEffectVolume
                    soundEffectVolume
                ]
            , Ui.text "Press F1 to toggle UI"
            , timeOfDayRadio timeOfDay
            ]
        )


timeOfDayRadio : TimeOfDay -> Ui.Element UiHover
timeOfDayRadio timeOfDay =
    Ui.column
        { spacing = 4, padding = Ui.noPadding }
        [ Ui.text "Time of day"
        , radioButton AutomaticTimeOfDayButton (timeOfDay == Automatic) "Automatic"
        , radioButton AlwaysDayTimeOfDayButton (timeOfDay == AlwaysDay) "Always day"
        , radioButton AlwaysNightTimeOfDayButton (timeOfDay == AlwaysNight) "Always night"
        ]


radioButton : id -> Bool -> String -> Ui.Element id
radioButton id isSelected text =
    Ui.customButton
        { id = id
        , padding = Ui.paddingXY 2 2
        , inFront = []
        , borderAndFill = NoBorderOrFill
        , borderAndFillFocus = FillOnly Color.fillColor2
        }
        (Ui.row
            { spacing = 8, padding = Ui.noPadding }
            [ Ui.colorSprite
                { colors = { primaryColor = Color.outlineColor, secondaryColor = Color.fillColor }
                , size = Coord.xy 36 36
                , texturePosition =
                    if isSelected then
                        Coord.xy 627 108

                    else
                        Coord.xy 591 108
                , textureSize = Coord.xy 36 36
                }
            , Ui.text text
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


inviteView : Bool -> EmailAddress -> TextInput.Model -> SubmitStatus EmailAddress -> Ui.Element UiHover
inviteView showInvite emailAddress inviteTextInput inviteSubmitStatus =
    if showInvite then
        let
            inviteForm : Ui.Element UiHover
            inviteForm =
                Ui.column
                    { spacing = 8, padding = Ui.noPadding }
                    [ Ui.button
                        { id = CloseInviteUser, padding = Ui.paddingXY 10 4 }
                        (Ui.text "Cancel")
                    , content
                    ]

            content : Ui.Element UiHover
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
                            , state = inviteTextInput.current
                            }
                        ]
                    , Ui.row
                        { spacing = 4, padding = { topLeft = Coord.xy 0 8, bottomRight = Coord.origin } }
                        [ Ui.button
                            { id = SubmitInviteUser, padding = Ui.paddingXY 10 4 }
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
                            { id = CloseInviteUser, padding = Ui.paddingXY 10 4 }
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


loginToolbarUi : SubmitStatus EmailAddress -> TextInput.Model -> Ui.Element UiHover
loginToolbarUi pressedSubmitEmail emailTextInput =
    let
        pressedSubmit2 =
            pressedSubmit pressedSubmitEmail

        loginUi : Ui.Element UiHover
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
                            , state = emailTextInput.current
                            }
                        , Ui.button
                            { id = SendEmailButtonHover, padding = Ui.paddingXY 30 4 }
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
                submittedText : Ui.Element id
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


toolbarUi : Colors -> FrontendLoaded -> ToolButton -> Ui.Element UiHover
toolbarUi handColor model currentToolButton =
    Ui.row
        { spacing = 0, padding = Ui.noPadding }
        [ Ui.column
            { spacing = 2, padding = { topLeft = Coord.origin, bottomRight = Coord.xy 2 0 } }
            [ Ui.row
                { spacing = 2, padding = Ui.noPadding }
                [ Ui.button { id = ZoomInButton, padding = smallToolButtonPadding } zoomInSprite
                , Ui.button { id = ZoomOutButton, padding = smallToolButtonPadding } zoomOutSprite
                ]
            , Ui.row
                { spacing = 2, padding = Ui.noPadding }
                [ Ui.customButton
                    { id = RotateLeftButton
                    , padding = smallToolButtonPadding
                    , inFront = hotkeyTextOverlay (Coord.xy 56 56) "q"
                    , borderAndFill = Ui.defaultButtonBorderAndFill
                    , borderAndFillFocus = Ui.defaultButtonBorderAndFillFocus
                    }
                    rotateLeftSprite
                , Ui.customButton
                    { id = RotateRightButton
                    , padding = smallToolButtonPadding
                    , inFront = hotkeyTextOverlay (Coord.xy 56 56) "w"
                    , borderAndFill = Ui.defaultButtonBorderAndFill
                    , borderAndFillFocus = Ui.defaultButtonBorderAndFillFocus
                    }
                    rotateRightSprite
                ]
            , Ui.row
                { spacing = 2, padding = Ui.noPadding }
                [ Ui.customButton
                    { id = ShowMapButton
                    , padding = smallToolButtonPadding
                    , inFront = hotkeyTextOverlay (Coord.xy 56 56) "m"
                    , borderAndFill =
                        BorderAndFill
                            { borderWidth = 2
                            , borderColor = Color.outlineColor
                            , fillColor =
                                if model.showMap then
                                    Color.highlightColor

                                else
                                    Color.fillColor2
                            }
                    , borderAndFillFocus =
                        BorderAndFill
                            { borderWidth = 2
                            , borderColor = Color.focusedUiColor
                            , fillColor =
                                if model.showMap then
                                    Color.highlightColor

                                else
                                    Color.fillColor2
                            }
                    }
                    mapSprite
                ]
            ]
        , List.map (toolButtonUi model.hasCmdKey handColor model.tileColors model.tileHotkeys currentToolButton) buttonTiles
            |> List.greedyGroupsOf toolbarRowCount
            |> List.map (Ui.column { spacing = 2, padding = Ui.noPadding })
            |> Ui.row { spacing = 2, padding = Ui.noPadding }
        , selectedToolView handColor model.primaryColorTextInput model.secondaryColorTextInput model.tileColors currentToolButton
        ]


smallToolButtonPadding =
    Ui.paddingXY 8 8


zoomInSprite : Ui.Element id
zoomInSprite =
    Ui.sprite { size = Coord.xy 42 42, texturePosition = Coord.xy 504 103, textureSize = Coord.xy 21 21 }


zoomOutSprite : Ui.Element id
zoomOutSprite =
    Ui.sprite { size = Coord.xy 42 42, texturePosition = Coord.xy 504 124, textureSize = Coord.xy 21 21 }


mapSprite : Ui.Element id
mapSprite =
    Ui.sprite { size = Coord.xy 42 42, texturePosition = Coord.xy 504 145, textureSize = Coord.xy 21 21 }


rotateLeftSprite : Ui.Element id
rotateLeftSprite =
    Ui.sprite { size = Coord.xy 42 42, texturePosition = Coord.xy 525 103, textureSize = Coord.xy 21 21 }


rotateRightSprite : Ui.Element id
rotateRightSprite =
    Ui.sprite { size = Coord.xy 42 42, texturePosition = Coord.xy 525 124, textureSize = Coord.xy 21 21 }


selectedToolView :
    Colors
    -> TextInput.Model
    -> TextInput.Model
    -> AssocList.Dict TileGroup Colors
    -> ToolButton
    -> Ui.Element UiHover
selectedToolView handColor primaryColorTextInput secondaryColorTextInput tileColors currentTool =
    let
        { showPrimaryColorTextInput, showSecondaryColorTextInput } =
            showColorTextInputs handColor tileColors currentTool
    in
    Ui.column
        { spacing = 6, padding = Ui.paddingXY 12 8 }
        [ Ui.wrappedText
            260
            (case currentTool of
                HandToolButton ->
                    "Pointer tool"

                TilePickerToolButton ->
                    "Tile picker"

                TilePlacerToolButton tileGroup ->
                    Tile.getTileGroupData tileGroup |> .name

                TextToolButton ->
                    "Text"

                ReportToolButton ->
                    "Report vandalism"
            )
        , Ui.row
            { spacing = 10, padding = Ui.noPadding }
            [ Ui.column
                { spacing = 10, padding = Ui.noPadding }
                [ case showPrimaryColorTextInput of
                    Just color ->
                        colorTextInput PrimaryColorInput primaryColorTextInput color

                    Nothing ->
                        Ui.none
                , case showSecondaryColorTextInput of
                    Just color ->
                        colorTextInput SecondaryColorInput secondaryColorTextInput color

                    Nothing ->
                        Ui.none
                , Ui.el
                    { padding =
                        { topLeft =
                            Coord.xy
                                (colorTextInput
                                    PrimaryColorInput
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
                    TilePlacerToolButton tileGroup ->
                        case AssocList.get tileGroup tileColors of
                            Just color ->
                                (Tile.getTileGroupData tileGroup).tiles
                                    |> List.Nonempty.head
                                    |> tileMesh color

                            Nothing ->
                                Ui.none

                    TilePickerToolButton ->
                        Cursor.eyeDropperCursor2

                    HandToolButton ->
                        Cursor.defaultCursorMesh2 handColor

                    TextToolButton ->
                        case AssocList.get BigTextGroup tileColors of
                            Just color ->
                                tileMesh color (BigText 'A')

                            Nothing ->
                                Ui.none

                    ReportToolButton ->
                        Cursor.gavelCursor2
                )
            ]
        ]


colorTextInput :
    id
    -> TextInput.Model
    -> Color
    -> Ui.Element id
colorTextInput id textInput color =
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
        , Ui.textInput { id = id, width = primaryColorInputWidth, isValid = True, state = textInput.current }
        ]


hotkeyTextOverlay : Coord Pixels -> String -> List (Ui.Element id)
hotkeyTextOverlay buttonSize2 hotkey =
    [ Ui.outlinedText { outline = Color.outlineColor, color = Color.white, text = hotkey }
        |> Ui.el
            { padding = { topLeft = Coord.xy 2 0, bottomRight = Coord.xy 0 0 }
            , inFront = []
            , borderAndFill = NoBorderOrFill
            }
        |> Ui.bottomLeft { size = buttonSize2 }
    ]


toolButtonUi :
    Bool
    -> Colors
    -> AssocList.Dict TileGroup Colors
    -> Dict String TileGroup
    -> ToolButton
    -> ToolButton
    -> Ui.Element UiHover
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

                TextToolButton ->
                    case AssocList.get BigTextGroup colors of
                        Just a ->
                            a

                        Nothing ->
                            Tile.getTileGroupData BigTextGroup |> .defaultColors |> Tile.defaultToPrimaryAndSecondary

                ReportToolButton ->
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

                TextToolButton ->
                    Nothing

                ReportToolButton ->
                    Nothing

        label : Ui.Element UiHover
        label =
            case tool of
                TilePlacerToolButton tileGroup ->
                    tileMesh tileColors (getTileGroupTile tileGroup 0)

                HandToolButton ->
                    Cursor.defaultCursorMesh2 handColor

                TilePickerToolButton ->
                    Cursor.eyeDropperCursor2

                TextToolButton ->
                    tileMesh tileColors (getTileGroupTile BigTextGroup 77)

                ReportToolButton ->
                    Cursor.gavelCursor2
    in
    Ui.customButton
        { id = ToolButtonHover tool
        , padding = Ui.noPadding
        , inFront =
            case hotkeyText of
                Just hotkey ->
                    hotkeyTextOverlay buttonSize hotkey

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
                , borderColor = Color.focusedUiColor
                , fillColor =
                    if currentTool == tool then
                        Color.highlightColor

                    else
                        Color.fillColor2
                }
        }
        (Ui.center { size = buttonSize } label)


buttonTiles : List ToolButton
buttonTiles =
    [ HandToolButton
    , TilePickerToolButton
    , ReportToolButton
    , TextToolButton
    ]
        ++ List.map TilePlacerToolButton Tile.allTileGroupsExceptText


toolbarRowCount : number
toolbarRowCount =
    3


tileMesh : Colors -> Tile -> Ui.Element id
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
            if tile == EmptyTile then
                Sprite.sprite
                    Coord.origin
                    (Coord.tuple ( 28 * 2, 27 * 2 ))
                    (Coord.xy 504 42)
                    (Coord.xy 28 27)

            else
                (case data.texturePosition of
                    Just texturePosition ->
                        Sprite.spriteWithTwoColors
                            colors
                            Coord.origin
                            spriteSize
                            texturePosition
                            (case tile of
                                BigText _ ->
                                    size |> Coord.divide (Coord.xy 2 2)

                                _ ->
                                    size
                            )

                    Nothing ->
                        []
                )
                    ++ (case data.texturePositionTopLayer of
                            Just topLayer ->
                                Sprite.spriteWithTwoColors
                                    colors
                                    Coord.origin
                                    spriteSize
                                    topLayer.texturePosition
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
    -> ToolButton
    -> { showPrimaryColorTextInput : Maybe Color, showSecondaryColorTextInput : Maybe Color }
showColorTextInputs handColor tileColors tool =
    case tool of
        TilePlacerToolButton tileGroup ->
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

        HandToolButton ->
            { showPrimaryColorTextInput = Just handColor.primaryColor
            , showSecondaryColorTextInput = Just handColor.secondaryColor
            }

        TilePickerToolButton ->
            { showPrimaryColorTextInput = Nothing, showSecondaryColorTextInput = Nothing }

        TextToolButton ->
            case ( AssocList.get BigTextGroup tileColors, Tile.getTileGroupData BigTextGroup |> .defaultColors ) of
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

        ReportToolButton ->
            { showPrimaryColorTextInput = Nothing, showSecondaryColorTextInput = Nothing }


getTileGroupTile : TileGroup -> Int -> Tile
getTileGroupTile tileGroup index =
    Tile.getTileGroupData tileGroup |> .tiles |> List.Nonempty.get index


screenToWorld :
    { a
        | windowSize : ( Quantity Int sourceUnits, Quantity Int sourceUnits )
        , devicePixelRatio : Float
        , zoomFactor : Int
        , mailEditor : Maybe b
        , mouseLeft : MouseButtonState
        , mouseMiddle : MouseButtonState
        , viewPoint : ViewPoint
        , trains : IdDict Id.TrainId Train.Train
        , time : Effect.Time.Posix
        , currentTool : Tool
    }
    -> Point2d sourceUnits Pixels
    -> Point2d WorldUnit WorldUnit
screenToWorld model =
    let
        ( w, h ) =
            model.windowSize
    in
    Point2d.translateBy
        (Vector2d.xy (Quantity.toFloatQuantity w) (Quantity.toFloatQuantity h) |> Vector2d.scaleBy -0.5)
        >> point2dAt2 (scaleForScreenToWorld model)
        >> Point2d.placeIn (Units.screenFrame (actualViewPoint model))


worldToScreen : FrontendLoaded -> Point2d WorldUnit WorldUnit -> Point2d Pixels Pixels
worldToScreen model =
    let
        ( w, h ) =
            model.windowSize
    in
    Point2d.translateBy
        (Vector2d.xy (Quantity.toFloatQuantity w) (Quantity.toFloatQuantity h) |> Vector2d.scaleBy -0.5 |> Vector2d.reverse)
        << point2dAt2_ (scaleForScreenToWorld model)
        << Point2d.relativeTo (Units.screenFrame (actualViewPoint model))


point2dAt2 :
    ( Quantity Float (Rate sourceUnits destinationUnits)
    , Quantity Float (Rate sourceUnits destinationUnits)
    )
    -> Point2d sourceUnits coordinates
    -> Point2d destinationUnits coordinates
point2dAt2 ( Quantity rateX, Quantity rateY ) point =
    let
        { x, y } =
            Point2d.unwrap point
    in
    { x = x * rateX
    , y = y * rateY
    }
        |> Point2d.unsafe


point2dAt2_ :
    ( Quantity Float (Rate sourceUnits destinationUnits)
    , Quantity Float (Rate sourceUnits destinationUnits)
    )
    -> Point2d sourceUnits coordinates
    -> Point2d destinationUnits coordinates
point2dAt2_ ( Quantity rateX, Quantity rateY ) point =
    let
        { x, y } =
            Point2d.unwrap point
    in
    { x = x / rateX
    , y = y / rateY
    }
        |> Point2d.unsafe


scaleForScreenToWorld : { a | devicePixelRatio : Float, zoomFactor : Int } -> ( Quantity Float units, Quantity Float units )
scaleForScreenToWorld model =
    ( 1 / (toFloat model.zoomFactor * toFloat Units.tileWidth) |> Quantity
    , 1 / (toFloat model.zoomFactor * toFloat Units.tileHeight) |> Quantity
    )


offsetViewPoint :
    { a
        | devicePixelRatio : Float
        , zoomFactor : Int
        , viewPoint : ViewPoint
        , trains : IdDict Id.TrainId Train.Train
        , time : Effect.Time.Posix
    }
    -> Hover
    -> Point2d sourceUnits Pixels
    -> Point2d sourceUnits Pixels
    -> Point2d WorldUnit WorldUnit
offsetViewPoint model hover mouseStart mouseCurrent =
    if canDragView hover then
        let
            delta : Vector2d WorldUnit WorldUnit
            delta =
                Vector2d.from mouseCurrent mouseStart
                    |> vector2dAt2 (scaleForScreenToWorld model)
                    |> Vector2d.placeIn (Units.screenFrame viewPoint2)

            viewPoint2 =
                actualViewPointHelper model
        in
        Point2d.translateBy delta viewPoint2

    else
        actualViewPointHelper model


canDragView : Hover -> Bool
canDragView hover =
    case hover of
        TileHover _ ->
            True

        TrainHover _ ->
            True

        UiBackgroundHover ->
            False

        MapHover ->
            True

        CowHover _ ->
            True

        UiHover _ _ ->
            False


actualViewPoint :
    { a
        | mailEditor : Maybe b
        , mouseLeft : MouseButtonState
        , mouseMiddle : MouseButtonState
        , devicePixelRatio : Float
        , zoomFactor : Int
        , viewPoint : ViewPoint
        , trains : IdDict Id.TrainId Train.Train
        , time : Effect.Time.Posix
        , currentTool : Tool
    }
    -> Point2d WorldUnit WorldUnit
actualViewPoint model =
    case ( model.mailEditor, model.mouseLeft, model.mouseMiddle ) of
        ( Nothing, _, MouseButtonDown { start, current, hover } ) ->
            offsetViewPoint model hover start current

        ( Nothing, MouseButtonDown { start, current, hover }, _ ) ->
            case model.currentTool of
                TilePlacerTool _ ->
                    actualViewPointHelper model

                TilePickerTool ->
                    offsetViewPoint model hover start current

                HandTool ->
                    offsetViewPoint model hover start current

                TextTool _ ->
                    actualViewPointHelper model

                ReportTool ->
                    offsetViewPoint model hover start current

        _ ->
            actualViewPointHelper model


actualViewPointHelper :
    { a | viewPoint : ViewPoint, trains : IdDict Id.TrainId Train.Train, time : Effect.Time.Posix }
    -> Point2d WorldUnit WorldUnit
actualViewPointHelper model =
    case model.viewPoint of
        NormalViewPoint viewPoint ->
            viewPoint

        TrainViewPoint trainViewPoint ->
            case IdDict.get trainViewPoint.trainId model.trains of
                Just train ->
                    let
                        t =
                            Quantity.ratio
                                (Duration.from trainViewPoint.startTime model.time)
                                (Duration.milliseconds 600)
                                |> min 1
                    in
                    Point2d.interpolateFrom trainViewPoint.startViewPoint (Train.trainPosition model.time train) t

                Nothing ->
                    trainViewPoint.startViewPoint


vector2dAt2 :
    ( Quantity Float (Rate sourceUnits destinationUnits)
    , Quantity Float (Rate sourceUnits destinationUnits)
    )
    -> Vector2d sourceUnits coordinates
    -> Vector2d destinationUnits coordinates
vector2dAt2 ( Quantity rateX, Quantity rateY ) vector =
    let
        { x, y } =
            Vector2d.unwrap vector
    in
    { x = x * rateX
    , y = y * rateY
    }
        |> Vector2d.unsafe
