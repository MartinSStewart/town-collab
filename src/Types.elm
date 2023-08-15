module Types exposing
    ( BackendError(..)
    , BackendModel
    , BackendMsg(..)
    , BackendUserData
    , ContextMenu
    , CssPixel
    , EmailEvent(..)
    , EmailResult(..)
    , FrontendLoaded
    , FrontendLoading
    , FrontendModel
    , FrontendModel_(..)
    , FrontendMsg
    , FrontendMsg_(..)
    , Hover(..)
    , Invite
    , LoadedLocalModel_
    , LoadingData_
    , LoadingLocalModel(..)
    , LoginRequestedBy(..)
    , MouseButtonState(..)
    , RemovedTileParticle
    , SubmitStatus(..)
    , ToBackend(..)
    , ToFrontend(..)
    , Tool(..)
    , ToolButton(..)
    , TopMenu(..)
    , UiHover(..)
    , UpdateMeshesData
    , UserSettings
    , ViewPoint(..)
    )

import Animal exposing (Animal)
import AssocList
import Audio
import Bounds exposing (Bounds)
import Browser
import Change exposing (AreTrainsDisabled, BackendReport, Change, ServerChange, UserStatus)
import Color exposing (Color, Colors)
import Coord exposing (Coord, RawCellCoord)
import Cursor exposing (Cursor, CursorMeshes)
import Dict exposing (Dict)
import DisplayName exposing (DisplayName)
import Duration exposing (Duration)
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Time
import Effect.WebGL.Texture exposing (Texture)
import EmailAddress exposing (EmailAddress)
import Grid exposing (Grid, GridData)
import Html.Events.Extra.Mouse exposing (Button)
import Html.Events.Extra.Wheel
import Id exposing (AnimalId, EventId, Id, MailId, SecretId, TrainId, UserId)
import IdDict exposing (IdDict)
import Keyboard
import Lamdera
import List.Nonempty exposing (Nonempty)
import LocalGrid exposing (LocalGrid)
import LocalModel exposing (LocalModel)
import MailEditor exposing (BackendMail, FrontendMail, Model)
import PingData exposing (PingData)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Postmark exposing (PostmarkSendResponse)
import Quantity exposing (Quantity)
import Route exposing (ConfirmEmailKey, InviteToken, LoginOrInviteToken, LoginToken, UnsubscribeEmailKey)
import Shaders exposing (DebrisVertex, Vertex)
import Sound exposing (Sound)
import TextInput
import Tile exposing (Tile, TileGroup)
import Time
import Train exposing (Train, TrainDiff)
import Ui
import Units exposing (CellUnit, WorldUnit)
import Untrusted exposing (Untrusted)
import Url exposing (Url)
import User exposing (FrontendUser, InviteTree)
import WebGL


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Coord Pixels
    , cssWindowSize : Coord CssPixel
    , cssCanvasSize : Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Coord WorldUnit
    , showInbox : Bool
    , mousePosition : Point2d Pixels Pixels
    , sounds : AssocList.Dict Sound (Result Audio.LoadError Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Texture
    , simplexNoiseLookup : Maybe Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type LoadingLocalModel
    = LoadingLocalModel (List Change)
    | LoadedLocalModel LoadedLocalModel_


type alias LoadedLocalModel_ =
    { localModel : LocalModel Change LocalGrid
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


type Tool
    = HandTool
    | TilePlacerTool { tileGroup : TileGroup, index : Int, mesh : WebGL.Mesh Vertex }
    | TilePickerTool
    | TextTool (Maybe { cursorPosition : Coord WorldUnit, startColumn : Quantity Int WorldUnit })
    | ReportTool


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : LocalModel Change LocalGrid
    , trains : IdDict TrainId Train
    , meshes : Dict RawCellCoord { foreground : WebGL.Mesh Vertex, background : WebGL.Mesh Vertex }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Point2d WorldUnit WorldUnit
    , texture : Texture
    , simplexNoiseLookup : Texture
    , trainTexture : Maybe Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Coord Pixels
    , cssWindowSize : Coord CssPixel
    , cssCanvasSize : Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Id EventId, Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , adminEnabled : Bool
    , animationElapsedTime : Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced : Maybe { time : Effect.Time.Posix, overwroteTiles : Bool, tile : Tile, position : Coord WorldUnit }
    , sounds : AssocList.Dict Sound (Result Audio.LoadError Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict String TileGroup
    , ui : Ui.Element UiHover
    , uiMesh : WebGL.Mesh Vertex
    , previousTileHover : Maybe TileGroup
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
    , music : { startTime : Effect.Time.Posix, sound : Sound }
    , previousCursorPositions : IdDict UserId { position : Point2d WorldUnit WorldUnit, time : Effect.Time.Posix }
    , handMeshes : IdDict UserId CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : TextInput.Model
    , pressedSubmitEmail : SubmitStatus EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : TextInput.Model
    , inviteSubmitStatus : SubmitStatus EmailAddress
    , railToggles : List ( Time.Posix, Coord WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showMap : Bool
    , showInviteTree : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    }


type alias UpdateMeshesData =
    { localModel : LocalModel Change LocalGrid
    , pressedKeys : List Keyboard.Key
    , currentTool : Tool
    , mouseLeft : MouseButtonState
    , windowSize : Coord Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mailEditor : Maybe MailEditor.Model
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : IdDict TrainId Train
    , time : Effect.Time.Posix
    }


type alias ContextMenu =
    { userId : Maybe (Id UserId)
    , position : Coord WorldUnit
    , linkCopied : Bool
    }


type TopMenu
    = InviteMenu
    | SettingsMenu TextInput.Model
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
    = TileHover { tile : Tile, userId : Id UserId, position : Coord WorldUnit, colors : Colors }
    | TrainHover { trainId : Id TrainId, train : Train }
    | MapHover
    | CowHover { cowId : Id AnimalId, cow : Animal }
    | UiBackgroundHover
    | UiHover UiHover { position : Coord Pixels }


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
    | ResetConnectionsButton
    | UsersOnlineButton
    | CopyPositionUrlButton
    | ReportUserButton
    | ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton


type alias BackendModel =
    { grid : Grid
    , userSessions :
        Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict ClientId (Bounds CellUnit)
            , userId : Maybe (Id UserId)
            }
    , users : IdDict UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : IdDict TrainId Train
    , cows : IdDict AnimalId Animal
    , lastWorldUpdateTrains : IdDict TrainId Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : IdDict MailId BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (SecretId LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Id UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (SecretId InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : IdDict UserId (Nonempty BackendReport)
    , isGridReadOnly : Bool
    , trainsDisabled : AreTrainsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    }


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend SessionId


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
    , emailAddress : EmailAddress
    , acceptedInvites : IdDict UserId ()
    , name : DisplayName
    , allowEmailNotifications : Bool
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type CssPixel
    = CssPixel Never


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url
    | NoOpFrontendMsg
    | TextureLoaded (Result Effect.WebGL.Texture.Error Texture)
    | SimplexLookupTextureLoaded (Result Effect.WebGL.Texture.Error Texture)
    | TrainTextureLoaded (Result Effect.WebGL.Texture.Error Texture)
    | KeyMsg Keyboard.Msg
    | KeyDown Keyboard.RawKey
    | WindowResized (Coord CssPixel)
    | GotDevicePixelRatio Float
    | MouseDown Button (Point2d Pixels Pixels)
    | MouseUp Button (Point2d Pixels Pixels)
    | MouseMove (Point2d Pixels Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix


type ToBackend
    = ConnectToBackend (Bounds CellUnit) (Maybe LoginOrInviteToken)
    | GridChange (Nonempty ( Id EventId, Change.LocalChange ))
    | ChangeViewBounds (Bounds CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Untrusted EmailAddress)
    | SendInviteEmailRequest (Untrusted EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected SessionId ClientId
    | UserConnected SessionId ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix EmailAddress (Result Effect.Http.Error PostmarkSendResponse)
    | UpdateFromFrontend SessionId ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (SecretId InviteToken) (Result Effect.Http.Error PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix EmailAddress (Result Effect.Http.Error PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix EmailAddress (Result Effect.Http.Error PostmarkSendResponse)


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (Nonempty Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse EmailAddress
    | PostOfficePositionResponse (Maybe (Coord WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast


type EmailEvent
    = UnsubscribeEmail UnsubscribeEmailKey


type alias LoadingData_ =
    { grid : GridData
    , userStatus : UserStatus
    , viewBounds : Bounds CellUnit
    , trains : IdDict TrainId Train
    , mail : IdDict MailId FrontendMail
    , cows : IdDict AnimalId Animal
    , cursors : IdDict UserId Cursor
    , users : IdDict UserId FrontendUser
    , inviteTree : InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : AreTrainsDisabled
    }
