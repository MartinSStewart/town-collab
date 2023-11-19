module Toolbar exposing
    ( actualViewPoint
    , canDragView
    , findHyperlink
    , getTileGroupTile
    , hyperlinkInputWidth
    , isDisconnected
    , mapSize
    , notificationsViewWidth
    , offsetViewPoint
    , oneTimePasswordTextScale
    , screenToWorld
    , toolbarTileGroupsMaxPerPage
    , validateInviteEmailAddress
    , view
    )

import AdminPage
import AssocList
import Change exposing (AreTrainsAndAnimalsDisabled(..), LoggedIn_, UserStatus(..))
import Color exposing (Color, Colors)
import Coord exposing (Coord)
import Cursor
import Dict
import DisplayName
import Duration exposing (Duration)
import Effect.Time
import EmailAddress exposing (EmailAddress)
import Grid
import GridCell
import Hyperlink exposing (Hyperlink)
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
import String.Nonempty
import StringExtra
import TextInput
import TextInputMultiline
import Tile exposing (Category(..), DefaultColor(..), Tile(..), TileData, TileGroup(..))
import TimeOfDay exposing (TimeOfDay(..))
import Tool exposing (Tool(..))
import Train
import Types exposing (ContextMenu, FrontendLoaded, Hover(..), LoginError(..), MouseButtonState(..), Page(..), SubmitStatus(..), ToolButton(..), TopMenu(..), UiHover(..), ViewPoint(..))
import Ui exposing (BorderAndFill(..))
import Units exposing (WorldUnit)
import Unsafe
import User
import Vector2d exposing (Vector2d)


view : FrontendLoaded -> Hover -> Ui.Element UiHover
view model hover =
    let
        localModel : LocalGrid.LocalGrid_
        localModel =
            LocalGrid.localModel model.localModel

        ( cssWindowWidth, cssWindowHeight ) =
            Coord.toTuple model.cssWindowSize

        windowSize =
            Coord.xy
                (round (toFloat cssWindowWidth * model.devicePixelRatio))
                (round (toFloat cssWindowHeight * model.devicePixelRatio))
    in
    case ( localModel.userStatus, model.page ) of
        ( LoggedIn loggedIn, MailPage mailEditor ) ->
            MailEditor.ui
                (isDisconnected model)
                windowSize
                MailEditorHover
                localModel.users
                loggedIn.inbox
                mailEditor

        ( LoggedIn loggedIn, AdminPage adminPage ) ->
            case loggedIn.adminData of
                Just adminData ->
                    AdminPage.adminView
                        AdminHover
                        windowSize
                        loggedIn.isGridReadOnly
                        adminData
                        adminPage
                        localModel

                Nothing ->
                    normalView windowSize model hover

        ( _, InviteTreePage ) ->
            Ui.el
                { padding = Ui.noPadding
                , borderAndFill = Ui.defaultElBorderAndFill
                , inFront =
                    [ Ui.bottomLeft
                        { size = windowSize }
                        (Ui.el
                            { padding = Ui.paddingXY 16 16, inFront = [], borderAndFill = NoBorderOrFill }
                            (Ui.button
                                { id = CloseInviteTreeButton
                                , padding = Ui.paddingXY 10 4
                                }
                                (Ui.text "Close")
                            )
                        )
                    ]
                }
                (Ui.topLeft
                    { size = windowSize }
                    (Ui.column
                        { spacing = 12, padding = Ui.paddingXY 16 16 }
                        [ Ui.scaledText 3 "All users"
                        , User.drawInviteTree
                            (case localModel.userStatus of
                                LoggedIn loggedIn ->
                                    Just loggedIn.userId

                                NotLoggedIn _ ->
                                    Nothing
                            )
                            localModel.cursors
                            localModel.users
                            localModel.inviteTree
                        ]
                    )
                )

        _ ->
            normalView windowSize model hover


easterEgg : List (Ui.Element id)
easterEgg =
    [ Ui.el
        { inFront = []
        , padding = { topLeft = Coord.xy 32 1400, bottomRight = Coord.origin }
        , borderAndFill = NoBorderOrFill
        }
        (Ui.text "Big fan of the enter key huh?")
    ]


findHyperlink : Coord Units.CellLocalUnit -> List GridCell.Value -> Maybe Hyperlink
findHyperlink startPos flattenedValues =
    let
        nextPos =
            Coord.plus (Coord.xy 1 0) startPos
    in
    case
        List.find
            (\value ->
                case value.tile of
                    BigText _ ->
                        nextPos == value.position

                    HyperlinkTile _ ->
                        nextPos == value.position

                    _ ->
                        False
            )
            flattenedValues
    of
        Just value ->
            case value.tile of
                HyperlinkTile hyperlink ->
                    Just hyperlink

                _ ->
                    findHyperlink nextPos flattenedValues

        Nothing ->
            Nothing


normalView : Coord Pixels -> FrontendLoaded -> Hover -> Ui.Element UiHover
normalView windowSize model hover =
    let
        maybeCurrentUserId =
            LocalGrid.currentUserId model

        onlineUsers : List (Ui.Element UiHover)
        onlineUsers =
            List.filterMap
                (\( userId, _ ) ->
                    if maybeCurrentUserId == Just userId then
                        Nothing

                    else
                        case IdDict.get userId localModel.users of
                            Just user ->
                                User.nameAndHand True maybeCurrentUserId userId user |> Just

                            Nothing ->
                                Nothing
                )
                (IdDict.toList localModel.cursors)

        otherUsersOnline =
            case localModel.userStatus of
                LoggedIn { userId } ->
                    IdDict.remove userId localModel.cursors |> IdDict.size

                NotLoggedIn _ ->
                    IdDict.size localModel.cursors

        localModel : LocalGrid.LocalGrid_
        localModel =
            LocalGrid.localModel model.localModel

        toolbarElement : Ui.Element UiHover
        toolbarElement =
            if model.hideUi then
                Ui.none

            else
                Ui.el
                    { padding = Ui.noPadding
                    , inFront = easterEgg
                    , borderAndFill = Ui.defaultElBorderAndFill
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
                                loggedIn
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
                            loginToolbarUi
                                model.pressedSubmitEmail
                                model.loginEmailInput
                                model.oneTimePasswordInput
                                model.loginError
                    )

        maybeHyperlink =
            case hover of
                TileHover tileHover ->
                    case tileHover.tile of
                        HyperlinkTile hyperlink ->
                            Just hyperlink

                        BigText _ ->
                            let
                                ( cellPos, startPos ) =
                                    Grid.worldToCellAndLocalCoord tileHover.position
                            in
                            case Grid.getCell cellPos (LocalGrid.localModel model.localModel).grid of
                                Just cell ->
                                    case findHyperlink startPos (GridCell.flatten cell) of
                                        Just hyperlink ->
                                            Just hyperlink

                                        Nothing ->
                                            Nothing

                                Nothing ->
                                    Nothing

                        _ ->
                            Nothing

                _ ->
                    Nothing
    in
    Ui.bottomCenter
        { size = windowSize
        , inFront =
            (if model.hideUi then
                []

             else
                [ case maybeHyperlink of
                    Just hyperlink ->
                        Ui.bottomLeft
                            { size = windowSize }
                            (Ui.el
                                { padding = Ui.paddingXY 8 4
                                , borderAndFill = Ui.defaultElBorderAndFill
                                , inFront = []
                                }
                                (Ui.text (Hyperlink.toUrl hyperlink))
                            )

                    Nothing ->
                        Ui.none
                , case model.contextMenu of
                    Just contextMenu ->
                        contextMenuView (Ui.size toolbarElement |> Coord.yRaw) contextMenu model

                    Nothing ->
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
                                        ( True, TrainsAndAnimalsEnabled ) ->
                                            Ui.el
                                                { padding = Ui.paddingXY 16 4, borderAndFill = FillOnly Color.errorColor, inFront = [] }
                                                (Ui.colorText Color.white "Placing tiles currently disabled")

                                        ( True, TrainsAndAnimalsDisabled ) ->
                                            Ui.el
                                                { padding = Ui.paddingXY 16 4, borderAndFill = FillOnly Color.errorColor, inFront = [] }
                                                (Ui.colorText Color.white "Trains and placing tiles disabled")

                                        ( False, TrainsAndAnimalsDisabled ) ->
                                            Ui.el
                                                { padding = Ui.paddingXY 16 4, borderAndFill = FillOnly Color.errorColor, inFront = [] }
                                                (Ui.colorText Color.white "Trains and animals disabled")

                                        ( False, TrainsAndAnimalsEnabled ) ->
                                            Ui.none

                                NotLoggedIn _ ->
                                    Ui.none
                            , if model.showOnlineUsers then
                                Ui.topRight
                                    { size = model.windowSize }
                                    (Ui.el
                                        { padding = Ui.paddingXY 8 8, inFront = [], borderAndFill = Ui.defaultElBorderAndFill }
                                        (Ui.column
                                            { spacing = 16, padding = Ui.noPadding }
                                            [ onlineUsersButton otherUsersOnline model
                                            , if List.isEmpty onlineUsers then
                                                Ui.el
                                                    { padding = Ui.paddingXY 8 0
                                                    , inFront = []
                                                    , borderAndFill = NoBorderOrFill
                                                    }
                                                    (Ui.text "Nobody is here")

                                              else
                                                Ui.column
                                                    { spacing = 8, padding = Ui.noPadding }
                                                    onlineUsers
                                            , Ui.button
                                                { id = ShowInviteTreeButton
                                                , padding = Ui.paddingXY 10 4
                                                }
                                                (Ui.text "Show all")
                                            ]
                                        )
                                    )

                              else
                                onlineUsersButton otherUsersOnline model
                            ]
                        )
                , Ui.row
                    { padding = Ui.noPadding, spacing = 4 }
                    [ case localModel.userStatus of
                        LoggedIn loggedIn ->
                            if loggedIn.showNotifications then
                                notificationsView loggedIn

                            else
                                Ui.button
                                    { id = NotificationsButton
                                    , padding = Ui.paddingXY 10 4
                                    }
                                    (Ui.text "Notifications")

                        NotLoggedIn _ ->
                            Ui.none
                    , case model.topMenuOpened of
                        Just (SettingsMenu nameTextInput) ->
                            case localModel.userStatus of
                                LoggedIn loggedIn ->
                                    settingsView
                                        model.musicVolume
                                        model.soundEffectVolume
                                        nameTextInput
                                        loggedIn

                                NotLoggedIn _ ->
                                    Ui.none

                        Just LoggedOutSettingsMenu ->
                            case localModel.userStatus of
                                LoggedIn _ ->
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
                ++ (case model.page of
                        WorldPage worldPage ->
                            if worldPage.showMap then
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

                        _ ->
                            []
                   )
        }
        toolbarElement


onlineUsersButton : Int -> { a | showOnlineUsers : Bool } -> Ui.Element UiHover
onlineUsersButton otherUsersOnline model =
    Ui.selectableButton
        { id = UsersOnlineButton
        , padding = Ui.paddingXY 10 4
        }
        model.showOnlineUsers
        (if otherUsersOnline == 1 then
            Ui.text "1 user online"

         else
            Ui.text (String.fromInt otherUsersOnline ++ " users online")
        )


notificationsView : LoggedIn_ -> Ui.Element UiHover
notificationsView loggedIn =
    Ui.el
        { padding = Ui.paddingXY 0 8
        , inFront = []
        , borderAndFill = Ui.defaultElBorderAndFill
        }
        (Ui.column
            { spacing = 16, padding = Ui.noPadding }
            [ notificationsHeader
            , if List.isEmpty loggedIn.notifications then
                Ui.el
                    { padding = Ui.paddingXY 12 0, inFront = [], borderAndFill = NoBorderOrFill }
                    (Ui.text "No notifications")

              else
                Ui.column
                    { spacing = 16, padding = Ui.noPadding }
                    [ Ui.el
                        { padding = Ui.paddingXY 8 0, inFront = [], borderAndFill = NoBorderOrFill }
                        (Ui.button
                            { id = ClearNotificationsButton
                            , padding = Ui.paddingXY 10 4
                            }
                            (Ui.text "Clear all")
                        )
                    , Ui.column
                        { spacing = 0
                        , padding = Ui.noPadding
                        }
                        (List.map
                            (\coord ->
                                "Change at "
                                    ++ "x="
                                    ++ String.fromInt (Coord.xRaw coord)
                                    ++ "&y="
                                    ++ String.fromInt (Coord.yRaw coord)
                                    |> Ui.underlinedColorText Color.linkColor
                                    |> Ui.customButton
                                        { id = MapChangeNotification coord
                                        , padding = Ui.paddingXY 8 4
                                        , inFront = []
                                        , borderAndFill = NoBorderOrFill
                                        , borderAndFillFocus = FillOnly Color.fillColor2
                                        }
                                    |> Ui.el { padding = Ui.paddingXY 2 0, inFront = [], borderAndFill = NoBorderOrFill }
                            )
                            loggedIn.notifications
                        )
                    ]
            ]
        )


notificationsHeader : Ui.Element UiHover
notificationsHeader =
    Ui.row
        { padding = Ui.paddingXY 8 0, spacing = 8 }
        [ Ui.button { id = CloseNotifications, padding = Ui.paddingXY 10 4 } (Ui.text "Close")
        , Ui.el
            { padding = Ui.paddingXY 4 4, inFront = [], borderAndFill = NoBorderOrFill }
            (Ui.text "Your notifications")
        ]


notificationsViewWidth : Int
notificationsViewWidth =
    Ui.size notificationsHeader |> Coord.xRaw


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
                    , case contextMenu.change of
                        Just change ->
                            if change.userId == Shaders.worldGenUserId then
                                Ui.wrappedText 400 "Placed by world gen"

                            else
                                case IdDict.get change.userId localModel.users of
                                    Just user ->
                                        let
                                            name =
                                                DisplayName.nameAndId user.name change.userId

                                            isYou =
                                                case localModel.userStatus of
                                                    LoggedIn loggedIn ->
                                                        loggedIn.userId == change.userId

                                                    NotLoggedIn _ ->
                                                        False
                                        in
                                        "Placed by "
                                            ++ name
                                            ++ (if isYou then
                                                    " (you) "

                                                else
                                                    " "
                                               )
                                            ++ durationToString model.time change.time
                                            |> Ui.wrappedText 400

                                    Nothing ->
                                        Ui.text "Not found"

                        Nothing ->
                            Ui.none

                    --, "Cell pos: "
                    --    ++ String.fromInt (Coord.xRaw cellPos)
                    --    ++ ","
                    --    ++ String.fromInt (Coord.yRaw cellPos)
                    --    |> Ui.text
                    --, Ui.column
                    --    { spacing = 4, padding = Ui.noPadding }
                    --    (Ui.text "History"
                    --        :: (case Grid.getCell cellPos localModel.grid of
                    --                Just cell ->
                    --                    List.map
                    --                        (\value -> Id.toInt value.userId |> String.fromInt |> Ui.text)
                    --                        (GridCell.history2 cell)
                    --
                    --                Nothing ->
                    --                    [ Ui.text "Empty" ]
                    --           )
                    --    )
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


durationToString : Effect.Time.Posix -> Effect.Time.Posix -> String
durationToString start end =
    let
        difference : Duration
        difference =
            Duration.from start end |> Quantity.abs

        months =
            Duration.inDays difference / 30 |> floor

        weeks =
            Duration.inWeeks difference |> floor

        days =
            Duration.inDays difference |> round

        hours =
            Duration.inHours difference |> floor

        minutes =
            Duration.inMinutes difference |> round

        suffix =
            if Effect.Time.posixToMillis start <= Effect.Time.posixToMillis end then
                ""

            else
                " ago"
    in
    if months >= 2 then
        String.fromInt months ++ " months" ++ suffix

    else if weeks >= 2 then
        String.fromInt weeks ++ " weeks" ++ suffix

    else if days > 1 then
        String.fromInt days ++ " days" ++ suffix

    else if hours > 22 then
        "1 day" ++ suffix

    else if hours > 6 then
        String.fromInt hours ++ " hours" ++ suffix

    else if Duration.inHours difference >= 1.2 then
        StringExtra.removeTrailing0s 1 (Duration.inHours difference) ++ " hours" ++ suffix

    else if minutes > 1 then
        String.fromInt minutes ++ " minutes" ++ suffix

    else
        "1 minute" ++ suffix


isDisconnected : FrontendLoaded -> Bool
isDisconnected model =
    Duration.from model.lastCheckConnection model.time |> Quantity.greaterThan (Duration.seconds 20)


mapSize : Coord Pixels -> Int
mapSize ( Quantity windowWidth, Quantity windowHeight ) =
    toFloat (min windowWidth windowHeight) * 0.7 |> round


settingsView : Int -> Int -> TextInput.Model -> LoggedIn_ -> Ui.Element UiHover
settingsView musicVolume soundEffectVolume nameTextInput loggedIn =
    let
        musicVolumeInput =
            volumeControl
                "Music volume "
                LowerMusicVolume
                RaiseMusicVolume
                musicVolume
    in
    Ui.el
        { padding = Ui.paddingXY 8 8
        , inFront = []
        , borderAndFill = Ui.defaultElBorderAndFill
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
             , Ui.checkbox
                AllowEmailNotificationsCheckbox
                loggedIn.allowEmailNotifications
                "Allow email notifications"
             ]
                ++ (case loggedIn.adminData of
                        Just _ ->
                            [ Ui.button
                                { id = ShowAdminPage, padding = Ui.paddingXY 10 4 }
                                (Ui.text "Open admin")
                            ]

                        Nothing ->
                            []
                   )
                ++ [ Ui.button
                        { id = LogoutButton
                        , padding = Ui.paddingXY 10 4
                        }
                        (Ui.text "Logout")
                   ]
            )
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
        , borderAndFill = Ui.defaultElBorderAndFill
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


inviteView : EmailAddress -> TextInput.Model -> SubmitStatus EmailAddress -> Ui.Element UiHover
inviteView emailAddress inviteTextInput inviteSubmitStatus =
    let
        inviteForm : Ui.Element UiHover
        inviteForm =
            Ui.column
                { spacing = 8, padding = Ui.paddingXY 16 16 }
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
                        , width = Coord.xRaw toolbarUiSize |> (+) (-16 * 2)
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
    case inviteSubmitStatus of
        Submitted inviteEmailAddress ->
            Ui.column
                { spacing = 0, padding = Ui.paddingXY 16 16 }
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


pressedSubmit : SubmitStatus a -> Bool
pressedSubmit submitStatus =
    case submitStatus of
        NotSubmitted a ->
            a.pressedSubmit

        _ ->
            False


loginToolbarUi :
    SubmitStatus EmailAddress
    -> TextInput.Model
    -> TextInput.Model
    -> Maybe LoginError
    -> Ui.Element UiHover
loginToolbarUi pressedSubmitEmail emailTextInput oneTimePasswordInput maybeLoginError =
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
                loginExpired =
                    Ui.colorText Color.errorColor "Login expired, refresh the page to retry"

                centerHorizontally item =
                    Ui.centerHorizontally { parentWidth = Ui.size loginExpired |> Coord.xRaw } item

                ( isValid, statusUi ) =
                    case maybeLoginError of
                        Just (WrongOneTimePassword code) ->
                            if Id.secretToString code == oneTimePasswordInput.current.text then
                                ( False, Ui.colorText Color.errorColor "Wrong code" |> centerHorizontally )

                            else if String.length oneTimePasswordInput.current.text == Id.oneTimePasswordLength then
                                ( True, Ui.text "Sending..." |> centerHorizontally )

                            else
                                ( True, Ui.none )

                        Just OneTimePasswordExpiredOrTooManyAttempts ->
                            ( False, loginExpired )

                        Nothing ->
                            ( True
                            , if String.length oneTimePasswordInput.current.text == Id.oneTimePasswordLength then
                                Ui.text "Sending..." |> centerHorizontally

                              else
                                Ui.none
                            )

                submittedText : Ui.Element UiHover
                submittedText =
                    Ui.column
                        { spacing = 8, padding = Ui.noPadding }
                        [ "Login email sent to "
                            ++ EmailAddress.toString emailAddress
                            |> Ui.wrappedText 1000
                            |> centerHorizontally
                        , Ui.column
                            { spacing = 4, padding = Ui.noPadding }
                            [ Ui.text "Please type in the code you received" |> centerHorizontally
                            , Ui.textInputScaled
                                { id = OneTimePasswordInput
                                , width = 252
                                , textScale = oneTimePasswordTextScale
                                , isValid = isValid
                                , state = oneTimePasswordInput.current
                                }
                                |> centerHorizontally
                            , statusUi
                            ]
                        ]

                topPadding =
                    16
            in
            Ui.el
                { padding = { topLeft = Coord.xy 0 topPadding, bottomRight = Coord.origin }
                , inFront = []
                , borderAndFill = Ui.defaultElBorderAndFill
                }
                (Ui.topCenter { size = Ui.size loginUi |> Coord.minus (Coord.xy 0 topPadding) } submittedText)

        _ ->
            loginUi


oneTimePasswordTextScale : number
oneTimePasswordTextScale =
    4


dummyEmail : EmailAddress
dummyEmail =
    Unsafe.emailAddress "a@a.se"


toolbarUiSize : Coord Pixels
toolbarUiSize =
    toolbarUi
        { primaryColor = Color.black, secondaryColor = Color.black }
        { tileHotkeys = AssocList.empty, emailAddress = dummyEmail }
        { page = WorldPage { showMap = False, showInvite = False }
        , hasCmdKey = False
        , tileColors = AssocList.empty
        , selectedTileCategory = Scenery
        , tileCategoryPageIndex = AssocList.empty
        , primaryColorTextInput = TextInput.init
        , secondaryColorTextInput = TextInput.init
        , inviteTextInput = TextInput.init
        , inviteSubmitStatus = NotSubmitted { pressedSubmit = False }
        , hyperlinkInput = TextInputMultiline.init
        }
        HandToolButton
        |> Ui.size


toolbarUi :
    Colors
    -> { a | tileHotkeys : AssocList.Dict Change.TileHotkey TileGroup, emailAddress : EmailAddress }
    ->
        { b
            | page : Page
            , hasCmdKey : Bool
            , tileColors : AssocList.Dict TileGroup Colors
            , selectedTileCategory : Category
            , tileCategoryPageIndex : AssocList.Dict Category Int
            , primaryColorTextInput : TextInput.Model
            , secondaryColorTextInput : TextInput.Model
            , inviteTextInput : TextInput.Model
            , inviteSubmitStatus : SubmitStatus EmailAddress
            , hyperlinkInput : TextInputMultiline.Model
        }
    -> ToolButton
    -> Ui.Element UiHover
toolbarUi handColor loggedIn model currentToolButton =
    let
        showInvite =
            case model.page of
                WorldPage worldPage ->
                    worldPage.showInvite

                _ ->
                    False
    in
    if showInvite then
        inviteView loggedIn.emailAddress model.inviteTextInput model.inviteSubmitStatus

    else
        Ui.row
            { spacing = 4, padding = Ui.noPadding }
            [ Ui.column
                { spacing = 4, padding = Ui.noPadding }
                [ Ui.row
                    { spacing = 4, padding = Ui.noPadding }
                    [ Ui.button { id = ZoomInButton, padding = smallToolButtonPadding } zoomInSprite
                    , Ui.button { id = ZoomOutButton, padding = smallToolButtonPadding } zoomOutSprite
                    ]
                , Ui.row
                    { spacing = 4, padding = Ui.noPadding }
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
                    { spacing = 4, padding = Ui.noPadding }
                    [ Ui.customButton
                        { id = ShowMapButton
                        , padding = smallToolButtonPadding
                        , inFront = hotkeyTextOverlay (Coord.xy 56 56) "m"
                        , borderAndFill =
                            BorderAndFill
                                { borderWidth = 2
                                , borderColor = Color.outlineColor
                                , fillColor =
                                    case model.page of
                                        WorldPage worldPage ->
                                            if worldPage.showMap then
                                                Color.highlightColor

                                            else
                                                Color.fillColor2

                                        _ ->
                                            Color.fillColor2
                                }
                        , borderAndFillFocus =
                            BorderAndFill
                                { borderWidth = 2
                                , borderColor = Color.focusedUiColor
                                , fillColor =
                                    case model.page of
                                        WorldPage worldPage ->
                                            if worldPage.showMap then
                                                Color.highlightColor

                                            else
                                                Color.fillColor2

                                        _ ->
                                            Color.fillColor2
                                }
                        }
                        mapSprite
                    , Ui.selectableButton
                        { id = ToolButtonHover ReportToolButton
                        , padding = smallToolButtonPadding
                        }
                        (currentToolButton == ReportToolButton)
                        Cursor.gavelCursor2
                    ]
                , Ui.row
                    { spacing = 4, padding = Ui.noPadding }
                    [ Ui.button
                        { id = ShowInviteUser
                        , padding = smallToolButtonPadding
                        }
                        inviteUserSprite
                    ]
                ]
            , List.map
                (toolButtonUi model.hasCmdKey handColor model.tileColors loggedIn.tileHotkeys currentToolButton)
                [ HandToolButton
                , TilePickerToolButton
                , TextToolButton
                , TilePlacerToolButton EmptyTileGroup
                , TilePlacerToolButton HyperlinkGroup
                ]
                |> List.greedyGroupsOf toolbarRowCount
                |> List.map (Ui.column { spacing = 2, padding = Ui.noPadding })
                |> Ui.row { spacing = 2, padding = Ui.noPadding }
            , Ui.column
                { spacing = -2
                , padding = { topLeft = Coord.xy 0 -38, bottomRight = Coord.xy 0 0 }
                }
                [ List.map
                    (\category ->
                        let
                            text =
                                Tile.categoryToString category
                        in
                        Ui.selectableButton
                            { id = CategoryButton category
                            , padding = Ui.paddingXY 6 2
                            }
                            (model.selectedTileCategory == category)
                            (Ui.row
                                { spacing = 0, padding = Ui.noPadding }
                                [ Ui.underlinedText (String.fromChar (String.Nonempty.head text))
                                , Ui.text (String.Nonempty.tail text)
                                ]
                            )
                    )
                    Tile.allCategories
                    |> Ui.row { spacing = 4, padding = Ui.noPadding }
                , let
                    pageIndex : Int
                    pageIndex =
                        case AssocList.get model.selectedTileCategory model.tileCategoryPageIndex of
                            Just index ->
                                index

                            Nothing ->
                                0

                    ( tileGroups, remainingTileGroups ) =
                        List.drop
                            (pageIndex * toolbarTileGroupsMaxPerPage)
                            (Tile.categoryToTiles model.selectedTileCategory)
                            |> List.splitAt toolbarTileGroupsMaxPerPage

                    content =
                        toolbarTileGroups tileGroups loggedIn.tileHotkeys currentToolButton handColor model
                  in
                  Ui.row
                    { spacing = -2, padding = Ui.noPadding }
                    [ nextPreviousTilesButton (pageIndex > 0) False (Coord.yRaw toolbarTileGroupsSize)
                    , Ui.topLeft { size = toolbarTileGroupsSize } content
                    , nextPreviousTilesButton
                        (List.isEmpty remainingTileGroups |> not)
                        True
                        (Coord.yRaw toolbarTileGroupsSize)
                    ]
                ]
            , selectedToolView handColor model currentToolButton
            ]


toolbarTileGroupsSize : Coord Pixels
toolbarTileGroupsSize =
    toolbarTileGroups
        (List.repeat (toolbarRowCount * toolbarColumnCount) HouseGroup)
        AssocList.empty
        HandToolButton
        { primaryColor = Color.black, secondaryColor = Color.black }
        { hasCmdKey = False, tileColors = AssocList.empty }
        |> Ui.size


toolbarTileGroupsMaxPerPage : number
toolbarTileGroupsMaxPerPage =
    toolbarRowCount * toolbarColumnCount


toolbarTileGroups :
    List TileGroup
    -> AssocList.Dict Change.TileHotkey TileGroup
    -> ToolButton
    -> Colors
    -> { a | hasCmdKey : Bool, tileColors : AssocList.Dict TileGroup Colors }
    -> Ui.Element UiHover
toolbarTileGroups category tileHotkeys currentToolButton handColor model =
    category
        |> List.map
            (\a ->
                TilePlacerToolButton a
                    |> toolButtonUi model.hasCmdKey handColor model.tileColors tileHotkeys currentToolButton
            )
        |> List.greedyGroupsOf toolbarRowCount
        |> List.map (Ui.column { spacing = 2, padding = Ui.noPadding })
        |> Ui.row { spacing = 2, padding = Ui.noPadding }


nextPreviousTilesButton : Bool -> Bool -> Int -> Ui.Element UiHover
nextPreviousTilesButton isEnabled isNext height =
    Ui.colorSprite
        { colors =
            { primaryColor =
                if isEnabled then
                    Color.black

                else
                    Color.rgb255 124 115 110
            , secondaryColor = Color.black
            }
        , size = Coord.xy 20 36
        , texturePosition =
            if isNext then
                Coord.xy 557 109

            else
                Coord.xy 546 109
        , textureSize = Coord.xy 10 18
        }
        |> Ui.center { size = Coord.xy 40 height }
        |> Ui.button
            { id =
                if isNext then
                    CategoryNextPageButton

                else
                    CategoryPreviousPageButton
            , padding = Ui.noPadding
            }


smallToolButtonPadding : Ui.Padding
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


inviteUserSprite : Ui.Element id
inviteUserSprite =
    Ui.colorSprite
        { colors = { primaryColor = Color.rgb255 200 200 220, secondaryColor = Color.rgb255 134 253 98 }
        , size = Coord.xy 42 42
        , texturePosition = Coord.xy 525 145
        , textureSize = Coord.xy 21 21
        }


hyperlinkInputWidth : number
hyperlinkInputWidth =
    270


selectedToolView :
    Colors
    ->
        { b
            | tileColors : AssocList.Dict TileGroup Colors
            , primaryColorTextInput : TextInput.Model
            , secondaryColorTextInput : TextInput.Model
            , hyperlinkInput : TextInputMultiline.Model
        }
    -> ToolButton
    -> Ui.Element UiHover
selectedToolView handColor model currentTool =
    let
        { showPrimaryColorTextInput, showSecondaryColorTextInput } =
            showColorTextInputs handColor model.tileColors currentTool
    in
    case currentTool of
        TilePlacerToolButton HyperlinkGroup ->
            Ui.column
                { spacing = 4, padding = Ui.paddingXY 8 8 }
                [ Ui.text "Hyperlink"
                , Ui.textInputMultiline
                    { id = HyperlinkInput
                    , width = hyperlinkInputWidth
                    , isValid = True
                    , state = model.hyperlinkInput.current
                    }
                ]

        _ ->
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
                                colorTextInput PrimaryColorInput model.primaryColorTextInput color

                            Nothing ->
                                Ui.none
                        , case showSecondaryColorTextInput of
                            Just color ->
                                colorTextInput SecondaryColorInput model.secondaryColorTextInput color

                            Nothing ->
                                Ui.none
                        , Ui.el
                            { padding =
                                { topLeft =
                                    Coord.xy
                                        (colorTextInput
                                            PrimaryColorInput
                                            model.primaryColorTextInput
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
                                case AssocList.get tileGroup model.tileColors of
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
                                case AssocList.get BigTextGroup model.tileColors of
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
            TextInput.size TextInput.defaultTextScale (Quantity primaryColorInputWidth) |> Coord.yRaw |> (\a -> a // 2)
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
    -> AssocList.Dict Change.TileHotkey TileGroup
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
                    case AssocList.toList hotkeys |> List.find (\( _, tileGroup2 ) -> tileGroup2 == tileGroup) of
                        Just ( hotkey, _ ) ->
                            case Dict.toList Change.tileHotkeyDict |> List.find (\( _, hotkey2 ) -> hotkey2 == hotkey) of
                                Just ( text, _ ) ->
                                    String.right 1 text |> Just

                                Nothing ->
                                    Nothing

                        Nothing ->
                            Nothing

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


toolbarRowCount : number
toolbarRowCount =
    3


toolbarColumnCount : number
toolbarColumnCount =
    7


tileMesh : Colors -> Tile -> Ui.Element id
tileMesh colors tile =
    let
        data : TileData b
        data =
            Tile.getData tile

        size =
            Coord.multiply Units.tileSize data.size
                |> Coord.minimum buttonSize

        spriteSize : Coord Pixels
        spriteSize =
            case tile of
                EmptyTile ->
                    Coord.tuple ( 28 * 2, 27 * 2 )

                HyperlinkTile _ ->
                    Coord.multiplyTuple ( 2, 2 ) size

                _ ->
                    if data.size == Coord.xy 1 1 then
                        Coord.multiplyTuple ( 2, 2 ) size

                    else
                        size
    in
    Ui.quads
        { size = spriteSize
        , vertices =
            if tile == EmptyTile then
                Sprite.sprite
                    Coord.origin
                    (Coord.tuple ( 28 * 2, 27 * 2 ))
                    (Coord.xy 504 42)
                    (Coord.xy 28 27)

            else
                Sprite.spriteWithTwoColors
                    colors
                    Coord.origin
                    spriteSize
                    data.texturePosition
                    (case tile of
                        BigText _ ->
                            size |> Coord.divide (Coord.xy 2 2)

                        _ ->
                            size
                    )
        }


primaryColorInputWidth : Int
primaryColorInputWidth =
    6 * Coord.xRaw Sprite.charSize * TextInput.defaultTextScale + Coord.xRaw TextInput.padding * 2 + 2


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
        , page : Page
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

        AnimalHover _ ->
            True

        UiHover _ _ ->
            False


actualViewPoint :
    { a
        | page : Page
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
    case ( model.page, model.mouseLeft, model.mouseMiddle ) of
        ( WorldPage _, _, MouseButtonDown { start, current, hover } ) ->
            offsetViewPoint model hover start current

        ( WorldPage _, MouseButtonDown { start, current, hover }, _ ) ->
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
