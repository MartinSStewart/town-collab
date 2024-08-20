module Evergreen.V134.Types exposing (..)

import Array
import AssocList
import AssocSet
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL
import Effect.WebGL.Texture
import Evergreen.V134.AdminPage
import Evergreen.V134.Animal
import Evergreen.V134.Audio
import Evergreen.V134.Bounds
import Evergreen.V134.Change
import Evergreen.V134.Color
import Evergreen.V134.Coord
import Evergreen.V134.Cursor
import Evergreen.V134.DisplayName
import Evergreen.V134.EmailAddress
import Evergreen.V134.Grid
import Evergreen.V134.GridCell
import Evergreen.V134.Id
import Evergreen.V134.Keyboard
import Evergreen.V134.Local
import Evergreen.V134.LocalGrid
import Evergreen.V134.MailEditor
import Evergreen.V134.Npc
import Evergreen.V134.PingData
import Evergreen.V134.Point2d
import Evergreen.V134.Postmark
import Evergreen.V134.Route
import Evergreen.V134.Shaders
import Evergreen.V134.Sound
import Evergreen.V134.Sprite
import Evergreen.V134.TextInput
import Evergreen.V134.TextInputMultiline
import Evergreen.V134.Tile
import Evergreen.V134.TileCountBot
import Evergreen.V134.TimeOfDay
import Evergreen.V134.Tool
import Evergreen.V134.Train
import Evergreen.V134.Ui
import Evergreen.V134.Units
import Evergreen.V134.Untrusted
import Evergreen.V134.User
import Html.Events.Extra.Mouse
import Html.Events.Extra.Wheel
import Lamdera
import List.Nonempty
import Pixels
import SeqDict
import Set
import Time
import Url


type CssPixels
    = CssPixel Never


type alias UserSettings =
    { musicVolume : Int
    , soundEffectVolume : Int
    }


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOpFrontendMsg
    | TextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | LightsTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | DepthTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainLightsTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainDepthTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | KeyUp Evergreen.V134.Keyboard.RawKey
    | KeyDown Evergreen.V134.Keyboard.RawKey
    | WindowResized (Evergreen.V134.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V134.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V134.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V134.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel
        { deltaY : Float
        , deltaMode : Html.Events.Extra.Wheel.DeltaMode
        }
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V134.Sound.Sound (Result Evergreen.V134.Audio.LoadError Evergreen.V134.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V134.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V134.Local.Local Evergreen.V134.Change.Change Evergreen.V134.LocalGrid.LocalGrid
    , trains : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.TrainId) Evergreen.V134.Train.Train
    , mail : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.MailId) Evergreen.V134.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V134.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V134.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V134.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V134.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
    , route : Evergreen.V134.Route.PageRoute
    , mousePosition : Evergreen.V134.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V134.Sound.Sound (Result Evergreen.V134.Audio.LoadError Evergreen.V134.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , lightsTexture : Maybe Effect.WebGL.Texture.Texture
    , depthTexture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V134.Id.Id Evergreen.V134.Id.TrainId
        , startViewPoint : Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V134.Tile.TileGroup
    | TilePickerToolButton
    | TextToolButton
    | ReportToolButton


type UiId
    = EmailAddressTextInput
    | SendEmailButton
    | ToolButton ToolButton
    | PrimaryColorInput
    | SecondaryColorInput
    | ShowInviteUser
    | CloseInviteUser
    | SubmitInviteUser
    | InviteEmailAddressTextInput
    | LowerMusicVolume
    | RaiseMusicVolume
    | LowerSoundEffectVolume
    | RaiseSoundEffectVolume
    | SettingsButton
    | CloseSettings
    | DisplayNameTextInput
    | MailEditorUi Evergreen.V134.MailEditor.Hover
    | YouGotMailButton
    | ShowMapButton
    | AllowEmailNotificationsCheckbox
    | UsersOnlineButton
    | CopyPositionUrlButton
    | ZoomInButton
    | ZoomOutButton
    | RotateLeftButton
    | RotateRightButton
    | AutomaticTimeOfDayButton
    | AlwaysDayTimeOfDayButton
    | AlwaysNightTimeOfDayButton
    | ShowAdminPage
    | AdminUi Evergreen.V134.AdminPage.Hover
    | CategoryButton Evergreen.V134.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton
    | OneTimePasswordInput
    | HyperlinkInput
    | CategoryNextPageButton
    | CategoryPreviousPageButton
    | TileContainer
    | WorldContainer
    | BlockInputContainer
    | NpcContextMenuInput
    | AnimalContextMenuInput


type Hover
    = TileHover
        { tile : Evergreen.V134.Tile.Tile
        , userId : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
        , position : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
        , colors : Evergreen.V134.Color.Colors
        , time : Effect.Time.Posix
        }
    | TrainHover
        { trainId : Evergreen.V134.Id.Id Evergreen.V134.Id.TrainId
        , train : Evergreen.V134.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V134.Id.Id Evergreen.V134.Id.AnimalId
        , animal : Evergreen.V134.Animal.Animal
        }
    | NpcHover
        { npcId : Evergreen.V134.Id.Id Evergreen.V134.Id.NpcId
        , npc : Evergreen.V134.Npc.Npc
        }
    | UiHover
        (List
            ( UiId
            , { relativePositionToUi : Evergreen.V134.Coord.Coord Pixels.Pixels
              , ui : Evergreen.V134.Ui.Element UiId
              }
            )
        )


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V134.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V134.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit
        , current : Evergreen.V134.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
    , tile : Evergreen.V134.Tile.Tile
    , colors : Evergreen.V134.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V134.TextInput.Model
    | LoggedOutSettingsMenu


type alias MapContextMenuData =
    { change :
        Maybe
            { userId : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
            , tile : Evergreen.V134.Tile.Tile
            , position : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
            , colors : Evergreen.V134.Color.Colors
            , time : Effect.Time.Posix
            }
    , position : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
    , linkCopied : Bool
    }


type ContextMenu
    = MapContextMenu MapContextMenuData
    | NpcContextMenu
        { npcId : Evergreen.V134.Id.Id Evergreen.V134.Id.NpcId
        , openedAt : Evergreen.V134.Coord.Coord Pixels.Pixels
        , nameInput : Evergreen.V134.TextInput.Model
        }
    | AnimalContextMenu
        { animalId : Evergreen.V134.Id.Id Evergreen.V134.Id.AnimalId
        , openedAt : Evergreen.V134.Coord.Coord Pixels.Pixels
        , nameInput : Evergreen.V134.TextInput.Model
        }
    | NoContextMenu


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V134.MailEditor.Model
    | AdminPage Evergreen.V134.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V134.Local.Local Evergreen.V134.Change.Change Evergreen.V134.LocalGrid.LocalGrid
    , pressedKeys : AssocSet.Set Evergreen.V134.Keyboard.Key
    , currentTool : Evergreen.V134.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V134.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , time : Effect.Time.Posix
    }


type LoginError
    = OneTimePasswordExpiredOrTooManyAttempts
    | WrongOneTimePassword (Evergreen.V134.Id.SecretId Evergreen.V134.Id.OneTimePasswordId)


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V134.Local.Local Evergreen.V134.Change.Change Evergreen.V134.LocalGrid.LocalGrid
    , meshes :
        Dict.Dict
            Evergreen.V134.Coord.RawCellCoord
            { foreground : Effect.WebGL.Mesh Evergreen.V134.Sprite.Vertex
            , background : Effect.WebGL.Mesh Evergreen.V134.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : AssocSet.Set Evergreen.V134.Keyboard.Key
    , windowSize : Evergreen.V134.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V134.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V134.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V134.Id.Id Evergreen.V134.Id.EventId, Evergreen.V134.Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Effect.Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V134.Tile.Tile
            , position : Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V134.Sound.Sound (Result Evergreen.V134.Audio.LoadError Evergreen.V134.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : Effect.WebGL.Mesh Evergreen.V134.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V134.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V134.Ui.Element UiId
    , uiMesh : Effect.WebGL.Mesh Evergreen.V134.Sprite.Vertex
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V134.Id.Id Evergreen.V134.Id.EventId
    , pingData : Maybe Evergreen.V134.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V134.Tile.TileGroup Evergreen.V134.Color.Colors
    , primaryColorTextInput : Evergreen.V134.TextInput.Model
    , secondaryColorTextInput : Evergreen.V134.TextInput.Model
    , previousFocus : Maybe UiId
    , focus : Maybe UiId
    , previousHover : Maybe UiId
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V134.Sound.Sound
        }
    , previousCursorPositions :
        SeqDict.SeqDict
            (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
            { position : Evergreen.V134.Point2d.Point2d Evergreen.V134.Units.WorldUnit Evergreen.V134.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginEmailInput : Evergreen.V134.TextInput.Model
    , oneTimePasswordInput : Evergreen.V134.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V134.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V134.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V134.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit )
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : Effect.WebGL.Mesh Evergreen.V134.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V134.Tile.Category
    , tileCategoryPageIndex : AssocList.Dict Evergreen.V134.Tile.Category Int
    , lastHotkeyChange : Maybe Time.Posix
    , loginError : Maybe LoginError
    , hyperlinkInput : Evergreen.V134.TextInputMultiline.Model
    , lastTrainUpdate : Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V134.Audio.Model FrontendMsg_ FrontendModel_


type alias UserSession =
    { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V134.Bounds.Bounds Evergreen.V134.Units.CellUnit))
    , userId : Maybe (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
    }


type alias HumanUserData =
    { emailAddress : Evergreen.V134.EmailAddress.EmailAddress
    , acceptedInvites : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) ()
    , timeOfDay : Evergreen.V134.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V134.Change.TileHotkey Evergreen.V134.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    , allowEmailNotifications : Bool
    , hyperlinksVisited : Set.Set String
    }


type BackendUserType
    = HumanUser HumanUserData
    | BotUser


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V134.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V134.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V134.Coord.RawCellCoord Int
    , mailDrafts : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (List Evergreen.V134.MailEditor.Content)
    , cursor : Maybe Evergreen.V134.Cursor.Cursor
    , handColor : Evergreen.V134.Color.Colors
    , userType : BackendUserType
    , name : Evergreen.V134.DisplayName.DisplayName
    }


type BackendError
    = PostmarkError Evergreen.V134.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V134.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V134.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V134.Grid.Grid Evergreen.V134.GridCell.BackendHistory
    , userSessions : Dict.Dict Lamdera.SessionId UserSession
    , users : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.TrainId) Evergreen.V134.Train.Train
    , animals : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.AnimalId) Evergreen.V134.Animal.Animal
    , npcs : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.NpcId) Evergreen.V134.Npc.Npc
    , lastWorldUpdateTrains : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.TrainId) Evergreen.V134.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.MailId) Evergreen.V134.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V134.Id.SecretId Evergreen.V134.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
            }
    , pendingOneTimePasswords :
        AssocList.Dict
            Effect.Lamdera.SessionId
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V134.Id.Id Evergreen.V134.Id.UserId
            , loginAttempts : Int
            , oneTimePassword : Evergreen.V134.Id.SecretId Evergreen.V134.Id.OneTimePasswordId
            }
    , invites : AssocList.Dict (Evergreen.V134.Id.SecretId Evergreen.V134.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) (List.Nonempty.Nonempty Evergreen.V134.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V134.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    , tileCountBot : Maybe Evergreen.V134.TileCountBot.Model
    }


type alias FrontendMsg =
    Evergreen.V134.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V134.Bounds.Bounds Evergreen.V134.Units.CellUnit) (Maybe Evergreen.V134.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V134.Id.Id Evergreen.V134.Id.EventId, Evergreen.V134.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V134.Untrusted.Untrusted Evergreen.V134.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V134.Untrusted.Untrusted Evergreen.V134.EmailAddress.EmailAddress)
    | PostOfficePositionRequest
    | ResetTileBotRequest
    | LoginAttemptRequest (Evergreen.V134.Id.SecretId Evergreen.V134.Id.OneTimePasswordId)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.ClientId
    | SentLoginEmail Effect.Time.Posix Evergreen.V134.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V134.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V134.Id.SecretId Evergreen.V134.Route.InviteToken) (Result Effect.Http.Error Evergreen.V134.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V134.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V134.Postmark.PostmarkSendResponse)
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V134.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V134.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix
    | TileCountBotUpdate Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V134.Grid.GridData
    , userStatus : Evergreen.V134.Change.UserStatus
    , viewBounds : Evergreen.V134.Bounds.Bounds Evergreen.V134.Units.CellUnit
    , trains : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.TrainId) Evergreen.V134.Train.Train
    , mail : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.MailId) Evergreen.V134.MailEditor.FrontendMail
    , animals : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.AnimalId) Evergreen.V134.Animal.Animal
    , cursors : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.Cursor.Cursor
    , users : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.User.FrontendUser
    , inviteTree : Evergreen.V134.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V134.Change.AreTrainsAndAnimalsDisabled
    , npcs : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.NpcId) Evergreen.V134.Npc.Npc
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V134.Change.Change)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V134.EmailAddress.EmailAddress
    | SendInviteEmailResponse Evergreen.V134.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V134.Coord.Coord Evergreen.V134.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
    | LoginAttemptResponse LoginError
