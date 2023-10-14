module Evergreen.V93.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V93.AdminPage
import Evergreen.V93.Animal
import Evergreen.V93.Audio
import Evergreen.V93.Bounds
import Evergreen.V93.Change
import Evergreen.V93.Color
import Evergreen.V93.Coord
import Evergreen.V93.Cursor
import Evergreen.V93.DisplayName
import Evergreen.V93.EmailAddress
import Evergreen.V93.Grid
import Evergreen.V93.Id
import Evergreen.V93.IdDict
import Evergreen.V93.Keyboard
import Evergreen.V93.LocalGrid
import Evergreen.V93.LocalModel
import Evergreen.V93.MailEditor
import Evergreen.V93.PingData
import Evergreen.V93.Point2d
import Evergreen.V93.Postmark
import Evergreen.V93.Route
import Evergreen.V93.Shaders
import Evergreen.V93.Sound
import Evergreen.V93.Sprite
import Evergreen.V93.TextInput
import Evergreen.V93.Tile
import Evergreen.V93.TimeOfDay
import Evergreen.V93.Tool
import Evergreen.V93.Train
import Evergreen.V93.Ui
import Evergreen.V93.Units
import Evergreen.V93.Untrusted
import Evergreen.V93.User
import Html.Events.Extra.Mouse
import Html.Events.Extra.Wheel
import Lamdera
import List.Nonempty
import Pixels
import Time
import Url
import WebGL


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
    | SimplexLookupTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainLightsTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainDepthTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | KeyMsg Evergreen.V93.Keyboard.Msg
    | KeyDown Evergreen.V93.Keyboard.RawKey
    | WindowResized (Evergreen.V93.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V93.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V93.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V93.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V93.Sound.Sound (Result Evergreen.V93.Audio.LoadError Evergreen.V93.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V93.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V93.LocalModel.LocalModel Evergreen.V93.Change.Change Evergreen.V93.LocalGrid.LocalGrid
    , trains : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.TrainId Evergreen.V93.Train.Train
    , mail : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.MailId Evergreen.V93.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V93.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V93.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V93.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V93.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit
    , route : Evergreen.V93.Route.PageRoute
    , mousePosition : Evergreen.V93.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V93.Sound.Sound (Result Evergreen.V93.Audio.LoadError Evergreen.V93.Audio.Source)
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
    = NormalViewPoint (Evergreen.V93.Point2d.Point2d Evergreen.V93.Units.WorldUnit Evergreen.V93.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V93.Id.Id Evergreen.V93.Id.TrainId
        , startViewPoint : Evergreen.V93.Point2d.Point2d Evergreen.V93.Units.WorldUnit Evergreen.V93.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V93.Tile.TileGroup
    | TilePickerToolButton
    | TextToolButton
    | ReportToolButton


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
    | MailEditorHover Evergreen.V93.MailEditor.Hover
    | YouGotMailButton
    | ShowMapButton
    | AllowEmailNotificationsCheckbox
    | UsersOnlineButton
    | CopyPositionUrlButton
    | ReportUserButton
    | ZoomInButton
    | ZoomOutButton
    | RotateLeftButton
    | RotateRightButton
    | AutomaticTimeOfDayButton
    | AlwaysDayTimeOfDayButton
    | AlwaysNightTimeOfDayButton
    | ShowAdminPage
    | AdminHover Evergreen.V93.AdminPage.Hover
    | CategoryButton Evergreen.V93.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton


type Hover
    = TileHover
        { tile : Evergreen.V93.Tile.Tile
        , userId : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
        , position : Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit
        , colors : Evergreen.V93.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V93.Id.Id Evergreen.V93.Id.TrainId
        , train : Evergreen.V93.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V93.Id.Id Evergreen.V93.Id.AnimalId
        , cow : Evergreen.V93.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V93.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V93.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V93.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V93.Point2d.Point2d Evergreen.V93.Units.WorldUnit Evergreen.V93.Units.WorldUnit
        , current : Evergreen.V93.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit
    , tile : Evergreen.V93.Tile.Tile
    , colors : Evergreen.V93.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V93.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
    , position : Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V93.MailEditor.Model
    | AdminPage Evergreen.V93.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V93.LocalModel.LocalModel Evergreen.V93.Change.Change Evergreen.V93.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V93.Keyboard.Key
    , currentTool : Evergreen.V93.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V93.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.TrainId Evergreen.V93.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V93.LocalModel.LocalModel Evergreen.V93.Change.Change Evergreen.V93.LocalGrid.LocalGrid
    , trains : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.TrainId Evergreen.V93.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V93.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V93.Sprite.Vertex
            , background : WebGL.Mesh Evergreen.V93.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V93.Point2d.Point2d Evergreen.V93.Units.WorldUnit Evergreen.V93.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V93.Keyboard.Key
    , windowSize : Evergreen.V93.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V93.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V93.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V93.Id.Id Evergreen.V93.Id.EventId, Evergreen.V93.Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Effect.Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V93.Tile.Tile
            , position : Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V93.Sound.Sound (Result Evergreen.V93.Audio.LoadError Evergreen.V93.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V93.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V93.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V93.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V93.Sprite.Vertex
    , previousTileHover : Maybe Evergreen.V93.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V93.Id.Id Evergreen.V93.Id.EventId
    , pingData : Maybe Evergreen.V93.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V93.Tile.TileGroup Evergreen.V93.Color.Colors
    , primaryColorTextInput : Evergreen.V93.TextInput.Model
    , secondaryColorTextInput : Evergreen.V93.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V93.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V93.IdDict.IdDict
            Evergreen.V93.Id.UserId
            { position : Evergreen.V93.Point2d.Point2d Evergreen.V93.Units.WorldUnit Evergreen.V93.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.UserId Evergreen.V93.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V93.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V93.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V93.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V93.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V93.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V93.Tile.Category
    , lastHotkeyChange : Maybe Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V93.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V93.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V93.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V93.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.UserId (List Evergreen.V93.MailEditor.Content)
    , cursor : Maybe Evergreen.V93.Cursor.Cursor
    , handColor : Evergreen.V93.Color.Colors
    , emailAddress : Evergreen.V93.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.UserId ()
    , name : Evergreen.V93.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    , timeOfDay : Evergreen.V93.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V93.Change.TileHotkey Evergreen.V93.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    }


type BackendError
    = PostmarkError Evergreen.V93.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V93.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V93.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V93.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V93.Bounds.Bounds Evergreen.V93.Units.CellUnit))
            , userId : Maybe (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId)
            }
    , users : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.TrainId Evergreen.V93.Train.Train
    , cows : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.AnimalId Evergreen.V93.Animal.Animal
    , lastWorldUpdateTrains : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.TrainId Evergreen.V93.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.MailId Evergreen.V93.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V93.Id.SecretId Evergreen.V93.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V93.Id.Id Evergreen.V93.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V93.Id.SecretId Evergreen.V93.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.UserId (List.Nonempty.Nonempty Evergreen.V93.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V93.Change.AreTrainsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V93.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V93.Bounds.Bounds Evergreen.V93.Units.CellUnit) (Maybe Evergreen.V93.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V93.Id.Id Evergreen.V93.Id.EventId, Evergreen.V93.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V93.Untrusted.Untrusted Evergreen.V93.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V93.Untrusted.Untrusted Evergreen.V93.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V93.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V93.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V93.Id.SecretId Evergreen.V93.Route.InviteToken) (Result Effect.Http.Error Evergreen.V93.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V93.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V93.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V93.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V93.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V93.Grid.GridData
    , userStatus : Evergreen.V93.Change.UserStatus
    , viewBounds : Evergreen.V93.Bounds.Bounds Evergreen.V93.Units.CellUnit
    , trains : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.TrainId Evergreen.V93.Train.Train
    , mail : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.MailId Evergreen.V93.MailEditor.FrontendMail
    , cows : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.AnimalId Evergreen.V93.Animal.Animal
    , cursors : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.UserId Evergreen.V93.Cursor.Cursor
    , users : Evergreen.V93.IdDict.IdDict Evergreen.V93.Id.UserId Evergreen.V93.User.FrontendUser
    , inviteTree : Evergreen.V93.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V93.Change.AreTrainsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V93.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V93.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V93.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V93.Coord.Coord Evergreen.V93.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
