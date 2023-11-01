module Evergreen.V95.Types exposing (..)

import Array
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
import Evergreen.V95.AdminPage
import Evergreen.V95.Animal
import Evergreen.V95.Audio
import Evergreen.V95.Bounds
import Evergreen.V95.Change
import Evergreen.V95.Color
import Evergreen.V95.Coord
import Evergreen.V95.Cursor
import Evergreen.V95.DisplayName
import Evergreen.V95.EmailAddress
import Evergreen.V95.Grid
import Evergreen.V95.Id
import Evergreen.V95.IdDict
import Evergreen.V95.Keyboard
import Evergreen.V95.LocalGrid
import Evergreen.V95.LocalModel
import Evergreen.V95.MailEditor
import Evergreen.V95.PingData
import Evergreen.V95.Point2d
import Evergreen.V95.Postmark
import Evergreen.V95.Route
import Evergreen.V95.Shaders
import Evergreen.V95.Sound
import Evergreen.V95.Sprite
import Evergreen.V95.TextInput
import Evergreen.V95.Tile
import Evergreen.V95.TimeOfDay
import Evergreen.V95.Tool
import Evergreen.V95.Train
import Evergreen.V95.Ui
import Evergreen.V95.Units
import Evergreen.V95.Untrusted
import Evergreen.V95.User
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
    | KeyMsg Evergreen.V95.Keyboard.Msg
    | KeyDown Evergreen.V95.Keyboard.RawKey
    | WindowResized (Evergreen.V95.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V95.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V95.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V95.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V95.Sound.Sound (Result Evergreen.V95.Audio.LoadError Evergreen.V95.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V95.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V95.LocalModel.LocalModel Evergreen.V95.Change.Change Evergreen.V95.LocalGrid.LocalGrid
    , trains : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.TrainId Evergreen.V95.Train.Train
    , mail : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.MailId Evergreen.V95.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V95.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V95.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V95.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V95.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit
    , route : Evergreen.V95.Route.PageRoute
    , mousePosition : Evergreen.V95.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V95.Sound.Sound (Result Evergreen.V95.Audio.LoadError Evergreen.V95.Audio.Source)
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
    = NormalViewPoint (Evergreen.V95.Point2d.Point2d Evergreen.V95.Units.WorldUnit Evergreen.V95.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V95.Id.Id Evergreen.V95.Id.TrainId
        , startViewPoint : Evergreen.V95.Point2d.Point2d Evergreen.V95.Units.WorldUnit Evergreen.V95.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V95.Tile.TileGroup
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
    | MailEditorHover Evergreen.V95.MailEditor.Hover
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
    | AdminHover Evergreen.V95.AdminPage.Hover
    | CategoryButton Evergreen.V95.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton


type Hover
    = TileHover
        { tile : Evergreen.V95.Tile.Tile
        , userId : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
        , position : Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit
        , colors : Evergreen.V95.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V95.Id.Id Evergreen.V95.Id.TrainId
        , train : Evergreen.V95.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V95.Id.Id Evergreen.V95.Id.AnimalId
        , animal : Evergreen.V95.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V95.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V95.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V95.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V95.Point2d.Point2d Evergreen.V95.Units.WorldUnit Evergreen.V95.Units.WorldUnit
        , current : Evergreen.V95.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit
    , tile : Evergreen.V95.Tile.Tile
    , colors : Evergreen.V95.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V95.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V95.Id.Id Evergreen.V95.Id.UserId)
    , position : Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V95.MailEditor.Model
    | AdminPage Evergreen.V95.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V95.LocalModel.LocalModel Evergreen.V95.Change.Change Evergreen.V95.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V95.Keyboard.Key
    , currentTool : Evergreen.V95.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V95.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.TrainId Evergreen.V95.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V95.LocalModel.LocalModel Evergreen.V95.Change.Change Evergreen.V95.LocalGrid.LocalGrid
    , trains : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.TrainId Evergreen.V95.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V95.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V95.Sprite.Vertex
            , background : WebGL.Mesh Evergreen.V95.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V95.Point2d.Point2d Evergreen.V95.Units.WorldUnit Evergreen.V95.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V95.Keyboard.Key
    , windowSize : Evergreen.V95.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V95.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V95.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V95.Id.Id Evergreen.V95.Id.EventId, Evergreen.V95.Change.LocalChange )
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
            , tile : Evergreen.V95.Tile.Tile
            , position : Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V95.Sound.Sound (Result Evergreen.V95.Audio.LoadError Evergreen.V95.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V95.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V95.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V95.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V95.Sprite.Vertex
    , previousTileHover : Maybe Evergreen.V95.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V95.Id.Id Evergreen.V95.Id.EventId
    , pingData : Maybe Evergreen.V95.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V95.Tile.TileGroup Evergreen.V95.Color.Colors
    , primaryColorTextInput : Evergreen.V95.TextInput.Model
    , secondaryColorTextInput : Evergreen.V95.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V95.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V95.IdDict.IdDict
            Evergreen.V95.Id.UserId
            { position : Evergreen.V95.Point2d.Point2d Evergreen.V95.Units.WorldUnit Evergreen.V95.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.UserId Evergreen.V95.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V95.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V95.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V95.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V95.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V95.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V95.Tile.Category
    , lastHotkeyChange : Maybe Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V95.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V95.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V95.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V95.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.UserId (List Evergreen.V95.MailEditor.Content)
    , cursor : Maybe Evergreen.V95.Cursor.Cursor
    , handColor : Evergreen.V95.Color.Colors
    , emailAddress : Evergreen.V95.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.UserId ()
    , name : Evergreen.V95.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    , timeOfDay : Evergreen.V95.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V95.Change.TileHotkey Evergreen.V95.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    }


type BackendError
    = PostmarkError Evergreen.V95.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V95.Id.Id Evergreen.V95.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V95.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V95.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V95.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V95.Bounds.Bounds Evergreen.V95.Units.CellUnit))
            , userId : Maybe (Evergreen.V95.Id.Id Evergreen.V95.Id.UserId)
            }
    , users : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.TrainId Evergreen.V95.Train.Train
    , animals : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.AnimalId Evergreen.V95.Animal.Animal
    , lastWorldUpdateTrains : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.TrainId Evergreen.V95.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.MailId Evergreen.V95.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V95.Id.SecretId Evergreen.V95.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V95.Id.Id Evergreen.V95.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V95.Id.SecretId Evergreen.V95.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.UserId (List.Nonempty.Nonempty Evergreen.V95.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V95.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    }


type alias FrontendMsg =
    Evergreen.V95.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V95.Bounds.Bounds Evergreen.V95.Units.CellUnit) (Maybe Evergreen.V95.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V95.Id.Id Evergreen.V95.Id.EventId, Evergreen.V95.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V95.Untrusted.Untrusted Evergreen.V95.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V95.Untrusted.Untrusted Evergreen.V95.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V95.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V95.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V95.Id.SecretId Evergreen.V95.Route.InviteToken) (Result Effect.Http.Error Evergreen.V95.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V95.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V95.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V95.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V95.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V95.Grid.GridData
    , userStatus : Evergreen.V95.Change.UserStatus
    , viewBounds : Evergreen.V95.Bounds.Bounds Evergreen.V95.Units.CellUnit
    , trains : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.TrainId Evergreen.V95.Train.Train
    , mail : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.MailId Evergreen.V95.MailEditor.FrontendMail
    , cows : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.AnimalId Evergreen.V95.Animal.Animal
    , cursors : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.UserId Evergreen.V95.Cursor.Cursor
    , users : Evergreen.V95.IdDict.IdDict Evergreen.V95.Id.UserId Evergreen.V95.User.FrontendUser
    , inviteTree : Evergreen.V95.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V95.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V95.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V95.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V95.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V95.Coord.Coord Evergreen.V95.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
