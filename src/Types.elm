module Types exposing
    ( BackendError(..)
    , BackendModel
    , BackendMsg(..)
    , BackendUserData
    , BackendUserType(..)
    , ContextMenu(..)
    , CssPixels
    , EmailResult(..)
    , FrontendLoaded
    , FrontendLoading
    , FrontendModel
    , FrontendModel_(..)
    , FrontendMsg
    , FrontendMsg_(..)
    , Hover(..)
    , HumanUserData
    , Invite
    , LoadedLocalModel_
    , LoadingData_
    , LoadingLocalModel(..)
    , LoginError(..)
    , MapContextMenuData
    , MouseButtonState(..)
    , Page(..)
    , RemovedTileParticle
    , SubmitStatus(..)
    , ToBackend(..)
    , ToFrontend(..)
    , ToolButton(..)
    , TopMenu(..)
    , UiHover(..)
    , UpdateMeshesData
    , UserSettings
    , ViewPoint(..)
    , WorldPage2
    )

import AdminPage
import Animal exposing (Animal)
import Array exposing (Array)
import AssocList
import AssocSet
import Audio
import Bounds exposing (Bounds)
import Browser
import Change exposing (AreTrainsAndAnimalsDisabled, BackendReport, Change, UserStatus)
import Color exposing (Colors)
import Coord exposing (Coord, RawCellCoord)
import Cursor exposing (Cursor, CursorMeshes)
import Dict exposing (Dict)
import DisplayName exposing (DisplayName)
import Duration exposing (Duration)
import Effect.Browser.Navigation
import Effect.File exposing (File)
import Effect.Http
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Time
import Effect.WebGL
import Effect.WebGL.Texture exposing (Texture)
import EmailAddress exposing (EmailAddress)
import Grid exposing (Grid, GridData)
import GridCell exposing (BackendHistory)
import Html.Events.Extra.Mouse exposing (Button)
import Html.Events.Extra.Wheel exposing (DeltaMode)
import Id exposing (AnimalId, EventId, Id, MailId, NpcId, OneTimePasswordId, SecretId, TrainId, UserId)
import IdDict exposing (IdDict)
import Keyboard
import Lamdera
import List.Nonempty exposing (Nonempty)
import Local exposing (Local)
import LocalGrid exposing (LocalGrid)
import MailEditor exposing (BackendMail, FrontendMail)
import Npc exposing (Npc)
import PingData exposing (PingData)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Postmark exposing (PostmarkSendResponse)
import Route exposing (InviteToken, LoginOrInviteToken, LoginToken, PageRoute)
import Set exposing (Set)
import Shaders exposing (DebrisVertex)
import Sound exposing (Sound)
import Sprite exposing (Vertex)
import TextInput
import TextInputMultiline
import Tile exposing (Category, Tile, TileGroup)
import TileCountBot
import Time
import TimeOfDay exposing (TimeOfDay)
import Tool exposing (Tool)
import Train exposing (Train)
import Ui
import Units exposing (CellUnit, WorldUnit)
import Untrusted exposing (Untrusted)
import Url exposing (Url)
import User exposing (FrontendUser, InviteTree)


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Coord Pixels
    , cssWindowSize : Coord CssPixels
    , cssCanvasSize : Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Coord WorldUnit
    , route : PageRoute
    , mousePosition : Point2d Pixels Pixels
    , sounds : AssocList.Dict Sound (Result Audio.LoadError Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Texture
    , lightsTexture : Maybe Texture
    , depthTexture : Maybe Texture
    , simplexNoiseLookup : Maybe Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type LoadingLocalModel
    = LoadingLocalModel (List Change)
    | LoadedLocalModel LoadedLocalModel_


type alias LoadedLocalModel_ =
    { localModel : Local Change LocalGrid
    , trains : IdDict TrainId Train
    , mail : IdDict MailId FrontendMail
    }


type ViewPoint
    = NormalViewPoint (Point2d WorldUnit WorldUnit)
    | TrainViewPoint { trainId : Id TrainId, startViewPoint : Point2d WorldUnit WorldUnit, startTime : Effect.Time.Posix }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton TileGroup
    | TilePickerToolButton
    | TextToolButton
    | ReportToolButton


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Local Change LocalGrid
    , meshes : Dict RawCellCoord { foreground : Effect.WebGL.Mesh Vertex, background : Effect.WebGL.Mesh Vertex }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Point2d WorldUnit WorldUnit
    , texture : Texture
    , lightsTexture : Texture
    , depthTexture : Texture
    , simplexNoiseLookup : Texture
    , trainTexture : Maybe Texture
    , trainLightsTexture : Maybe Texture
    , trainDepthTexture : Maybe Texture
    , pressedKeys : AssocSet.Set Keyboard.Key
    , windowSize : Coord Pixels
    , cssWindowSize : Coord CssPixels
    , cssCanvasSize : Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Id EventId, Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced : Maybe { time : Effect.Time.Posix, overwroteTiles : Bool, tile : Tile, position : Coord WorldUnit }
    , sounds : AssocList.Dict Sound (Result Audio.LoadError Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : Effect.WebGL.Mesh DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Ui.Element UiHover
    , uiMesh : Effect.WebGL.Mesh Vertex
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Id EventId
    , pingData : Maybe PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict TileGroup Colors
    , primaryColorTextInput : TextInput.Model
    , secondaryColorTextInput : TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , previousHover : Maybe UiHover
    , music : { startTime : Effect.Time.Posix, sound : Sound }
    , previousCursorPositions : IdDict UserId { position : Point2d WorldUnit WorldUnit, time : Effect.Time.Posix }
    , handMeshes : IdDict UserId CursorMeshes
    , hasCmdKey : Bool
    , loginEmailInput : TextInput.Model
    , oneTimePasswordInput : TextInput.Model
    , pressedSubmitEmail : SubmitStatus EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : TextInput.Model
    , inviteSubmitStatus : SubmitStatus EmailAddress
    , railToggles : List ( Time.Posix, Coord WorldUnit )
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : Effect.WebGL.Mesh Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Category
    , tileCategoryPageIndex : AssocList.Dict Category Int
    , lastHotkeyChange : Maybe Time.Posix
    , loginError : Maybe LoginError
    , hyperlinkInput : TextInputMultiline.Model
    , lastTrainUpdate : Time.Posix
    }


type Page
    = MailPage MailEditor.Model
    | AdminPage AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type alias UpdateMeshesData =
    { localModel : Local Change LocalGrid
    , pressedKeys : AssocSet.Set Keyboard.Key
    , currentTool : Tool
    , mouseLeft : MouseButtonState
    , windowSize : Coord Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , time : Effect.Time.Posix
    }


type alias MapContextMenuData =
    { change :
        Maybe
            { userId : Id UserId
            , tile : Tile
            , position : Coord WorldUnit
            , colors : Colors
            , time : Effect.Time.Posix
            }
    , position : Coord WorldUnit
    , linkCopied : Bool
    }


type ContextMenu
    = MapContextMenu MapContextMenuData
    | NpcContextMenu { npcId : Id NpcId, menuPosition : Coord Pixels }
    | AnimalContextMenu { animalId : Id AnimalId, menuPosition : Coord Pixels }
    | NoContextMenu


type TopMenu
    = SettingsMenu TextInput.Model
    | LoggedOutSettingsMenu


type SubmitStatus a
    = NotSubmitted { pressedSubmit : Bool }
    | Submitting
    | Submitted a


type alias RemovedTileParticle =
    { time : Effect.Time.Posix, position : Coord WorldUnit, tile : Tile, colors : Colors }


type MouseButtonState
    = MouseButtonUp { current : Point2d Pixels Pixels }
    | MouseButtonDown
        { start : Point2d Pixels Pixels
        , start_ : Point2d WorldUnit WorldUnit
        , current : Point2d Pixels Pixels
        , hover : Hover
        }


type alias UserSettings =
    { musicVolume : Int, soundEffectVolume : Int }


type Hover
    = TileHover
        { tile : Tile
        , userId : Id UserId
        , position : Coord WorldUnit
        , colors : Colors
        , time : Effect.Time.Posix
        }
    | TrainHover { trainId : Id TrainId, train : Train }
    | MapHover
    | AnimalHover { animalId : Id AnimalId, animal : Animal }
    | NpcHover { npcId : Id NpcId, npc : Npc }
    | UiHover (List ( UiHover, { relativePositionToUi : Coord Pixels, ui : Ui.Element UiHover } ))


type UiHover
    = EmailAddressTextInputHover
    | SendEmailButtonHover
    | ToolButtonHover ToolButton
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
    | MailEditorHover MailEditor.Hover
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
    | AdminHover AdminPage.Hover
    | CategoryButton Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Coord WorldUnit)
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


type alias BackendModel =
    { grid : Grid BackendHistory
    , userSessions :
        Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict ClientId (List (Bounds CellUnit))
            , userId : Maybe (Id UserId)
            }
    , users : IdDict UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : IdDict TrainId Train
    , animals : IdDict AnimalId Animal
    , npcs : IdDict NpcId Npc
    , lastWorldUpdateTrains : IdDict TrainId Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : IdDict MailId BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (SecretId LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Id UserId
            }
    , pendingOneTimePasswords :
        AssocList.Dict
            SessionId
            { requestTime : Effect.Time.Posix
            , userId : Id UserId
            , loginAttempts : Int
            , oneTimePassword : SecretId OneTimePasswordId
            }
    , invites : AssocList.Dict (SecretId InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : IdDict UserId (Nonempty BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array Duration
    , tileCountBot : Maybe TileCountBot.Model
    }


type alias Invite =
    { invitedBy : Id UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : EmailAddress
    , emailResult : EmailResult
    }


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Postmark.PostmarkSendResponse


type BackendError
    = PostmarkError EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Id UserId)


type alias BackendUserData =
    { undoHistory : List (Dict RawCellCoord Int)
    , redoHistory : List (Dict RawCellCoord Int)
    , undoCurrent : Dict RawCellCoord Int
    , mailDrafts : IdDict UserId (List MailEditor.Content)
    , cursor : Maybe Cursor
    , handColor : Colors
    , userType : BackendUserType
    , name : DisplayName
    }


type BackendUserType
    = HumanUser HumanUserData
    | BotUser


type alias HumanUserData =
    { emailAddress : EmailAddress
    , acceptedInvites : IdDict UserId ()
    , timeOfDay : TimeOfDay
    , tileHotkeys : AssocList.Dict Change.TileHotkey TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    , allowEmailNotifications : Bool
    , hyperlinksVisited : Set String
    }


type CssPixels
    = CssPixel Never


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url
    | NoOpFrontendMsg
    | TextureLoaded (Result Effect.WebGL.Texture.Error Texture)
    | LightsTextureLoaded (Result Effect.WebGL.Texture.Error Texture)
    | DepthTextureLoaded (Result Effect.WebGL.Texture.Error Texture)
    | TrainTextureLoaded (Result Effect.WebGL.Texture.Error Texture)
    | TrainLightsTextureLoaded (Result Effect.WebGL.Texture.Error Texture)
    | TrainDepthTextureLoaded (Result Effect.WebGL.Texture.Error Texture)
    | KeyUp Keyboard.RawKey
    | KeyDown Keyboard.RawKey
    | WindowResized (Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Button (Point2d Pixels Pixels)
    | MouseUp Button (Point2d Pixels Pixels)
    | MouseMove (Point2d Pixels Pixels)
    | MouseWheel { deltaY : Float, deltaMode : DeltaMode }
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | ImportedMail File
    | ImportedMail2 (Result () (List MailEditor.Content))


type ToBackend
    = ConnectToBackend (Bounds CellUnit) (Maybe LoginOrInviteToken)
    | GridChange (Nonempty ( Id EventId, Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Untrusted EmailAddress)
    | SendInviteEmailRequest (Untrusted EmailAddress)
    | PostOfficePositionRequest
    | ResetTileBotRequest
    | LoginAttemptRequest (SecretId OneTimePasswordId)


type BackendMsg
    = UserDisconnected SessionId ClientId
    | UserConnected ClientId
    | SentLoginEmail Effect.Time.Posix EmailAddress (Result Effect.Http.Error PostmarkSendResponse)
    | UpdateFromFrontend SessionId ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (SecretId InviteToken) (Result Effect.Http.Error PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix EmailAddress (Result Effect.Http.Error PostmarkSendResponse)
    | SentReportVandalismAdminEmail Effect.Time.Posix EmailAddress (Result Effect.Http.Error PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix
    | TileCountBotUpdate Effect.Time.Posix


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (Nonempty Change)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse EmailAddress
    | SendInviteEmailResponse EmailAddress
    | PostOfficePositionResponse (Maybe (Coord WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
    | LoginAttemptResponse LoginError


type LoginError
    = OneTimePasswordExpiredOrTooManyAttempts
    | WrongOneTimePassword (SecretId OneTimePasswordId)


type alias LoadingData_ =
    { grid : GridData
    , userStatus : UserStatus
    , viewBounds : Bounds CellUnit
    , trains : IdDict TrainId Train
    , mail : IdDict MailId FrontendMail
    , animals : IdDict AnimalId Animal
    , cursors : IdDict UserId Cursor
    , users : IdDict UserId FrontendUser
    , inviteTree : InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : AreTrainsAndAnimalsDisabled
    , npcs : IdDict NpcId Npc
    }
