module Evergreen.V97.Types exposing (..)

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
import Evergreen.V97.AdminPage
import Evergreen.V97.Animal
import Evergreen.V97.Audio
import Evergreen.V97.Bounds
import Evergreen.V97.Change
import Evergreen.V97.Color
import Evergreen.V97.Coord
import Evergreen.V97.Cursor
import Evergreen.V97.DisplayName
import Evergreen.V97.EmailAddress
import Evergreen.V97.Grid
import Evergreen.V97.Id
import Evergreen.V97.IdDict
import Evergreen.V97.Keyboard
import Evergreen.V97.LocalGrid
import Evergreen.V97.LocalModel
import Evergreen.V97.MailEditor
import Evergreen.V97.PingData
import Evergreen.V97.Point2d
import Evergreen.V97.Postmark
import Evergreen.V97.Route
import Evergreen.V97.Shaders
import Evergreen.V97.Sound
import Evergreen.V97.Sprite
import Evergreen.V97.TextInput
import Evergreen.V97.Tile
import Evergreen.V97.TimeOfDay
import Evergreen.V97.Tool
import Evergreen.V97.Train
import Evergreen.V97.Ui
import Evergreen.V97.Units
import Evergreen.V97.Untrusted
import Evergreen.V97.User
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
    | KeyMsg Evergreen.V97.Keyboard.Msg
    | KeyDown Evergreen.V97.Keyboard.RawKey
    | WindowResized (Evergreen.V97.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V97.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V97.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V97.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V97.Sound.Sound (Result Evergreen.V97.Audio.LoadError Evergreen.V97.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V97.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V97.LocalModel.LocalModel Evergreen.V97.Change.Change Evergreen.V97.LocalGrid.LocalGrid
    , trains : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.TrainId Evergreen.V97.Train.Train
    , mail : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.MailId Evergreen.V97.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V97.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V97.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V97.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V97.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit
    , route : Evergreen.V97.Route.PageRoute
    , mousePosition : Evergreen.V97.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V97.Sound.Sound (Result Evergreen.V97.Audio.LoadError Evergreen.V97.Audio.Source)
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
    = NormalViewPoint (Evergreen.V97.Point2d.Point2d Evergreen.V97.Units.WorldUnit Evergreen.V97.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V97.Id.Id Evergreen.V97.Id.TrainId
        , startViewPoint : Evergreen.V97.Point2d.Point2d Evergreen.V97.Units.WorldUnit Evergreen.V97.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V97.Tile.TileGroup
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
    | MailEditorHover Evergreen.V97.MailEditor.Hover
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
    | AdminHover Evergreen.V97.AdminPage.Hover
    | CategoryButton Evergreen.V97.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton


type Hover
    = TileHover
        { tile : Evergreen.V97.Tile.Tile
        , userId : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
        , position : Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit
        , colors : Evergreen.V97.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V97.Id.Id Evergreen.V97.Id.TrainId
        , train : Evergreen.V97.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V97.Id.Id Evergreen.V97.Id.AnimalId
        , animal : Evergreen.V97.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V97.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V97.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V97.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V97.Point2d.Point2d Evergreen.V97.Units.WorldUnit Evergreen.V97.Units.WorldUnit
        , current : Evergreen.V97.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit
    , tile : Evergreen.V97.Tile.Tile
    , colors : Evergreen.V97.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V97.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
    , position : Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V97.MailEditor.Model
    | AdminPage Evergreen.V97.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V97.LocalModel.LocalModel Evergreen.V97.Change.Change Evergreen.V97.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V97.Keyboard.Key
    , currentTool : Evergreen.V97.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V97.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.TrainId Evergreen.V97.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V97.LocalModel.LocalModel Evergreen.V97.Change.Change Evergreen.V97.LocalGrid.LocalGrid
    , trains : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.TrainId Evergreen.V97.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V97.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V97.Sprite.Vertex
            , background : WebGL.Mesh Evergreen.V97.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V97.Point2d.Point2d Evergreen.V97.Units.WorldUnit Evergreen.V97.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V97.Keyboard.Key
    , windowSize : Evergreen.V97.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V97.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V97.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V97.Id.Id Evergreen.V97.Id.EventId, Evergreen.V97.Change.LocalChange )
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
            , tile : Evergreen.V97.Tile.Tile
            , position : Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V97.Sound.Sound (Result Evergreen.V97.Audio.LoadError Evergreen.V97.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V97.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V97.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V97.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V97.Sprite.Vertex
    , previousTileHover : Maybe Evergreen.V97.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V97.Id.Id Evergreen.V97.Id.EventId
    , pingData : Maybe Evergreen.V97.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V97.Tile.TileGroup Evergreen.V97.Color.Colors
    , primaryColorTextInput : Evergreen.V97.TextInput.Model
    , secondaryColorTextInput : Evergreen.V97.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V97.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V97.IdDict.IdDict
            Evergreen.V97.Id.UserId
            { position : Evergreen.V97.Point2d.Point2d Evergreen.V97.Units.WorldUnit Evergreen.V97.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.UserId Evergreen.V97.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V97.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V97.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V97.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V97.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V97.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V97.Tile.Category
    , lastHotkeyChange : Maybe Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V97.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V97.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V97.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V97.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.UserId (List Evergreen.V97.MailEditor.Content)
    , cursor : Maybe Evergreen.V97.Cursor.Cursor
    , handColor : Evergreen.V97.Color.Colors
    , emailAddress : Evergreen.V97.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.UserId ()
    , name : Evergreen.V97.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    , timeOfDay : Evergreen.V97.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V97.Change.TileHotkey Evergreen.V97.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    }


type BackendError
    = PostmarkError Evergreen.V97.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V97.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V97.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V97.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V97.Bounds.Bounds Evergreen.V97.Units.CellUnit))
            , userId : Maybe (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)
            }
    , users : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.TrainId Evergreen.V97.Train.Train
    , animals : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.AnimalId Evergreen.V97.Animal.Animal
    , lastWorldUpdateTrains : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.TrainId Evergreen.V97.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.MailId Evergreen.V97.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V97.Id.SecretId Evergreen.V97.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V97.Id.SecretId Evergreen.V97.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.UserId (List.Nonempty.Nonempty Evergreen.V97.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V97.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    }


type alias FrontendMsg =
    Evergreen.V97.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V97.Bounds.Bounds Evergreen.V97.Units.CellUnit) (Maybe Evergreen.V97.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V97.Id.Id Evergreen.V97.Id.EventId, Evergreen.V97.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V97.Untrusted.Untrusted Evergreen.V97.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V97.Untrusted.Untrusted Evergreen.V97.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V97.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V97.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V97.Id.SecretId Evergreen.V97.Route.InviteToken) (Result Effect.Http.Error Evergreen.V97.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V97.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V97.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V97.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V97.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V97.Grid.GridData
    , userStatus : Evergreen.V97.Change.UserStatus
    , viewBounds : Evergreen.V97.Bounds.Bounds Evergreen.V97.Units.CellUnit
    , trains : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.TrainId Evergreen.V97.Train.Train
    , mail : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.MailId Evergreen.V97.MailEditor.FrontendMail
    , cows : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.AnimalId Evergreen.V97.Animal.Animal
    , cursors : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.UserId Evergreen.V97.Cursor.Cursor
    , users : Evergreen.V97.IdDict.IdDict Evergreen.V97.Id.UserId Evergreen.V97.User.FrontendUser
    , inviteTree : Evergreen.V97.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V97.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V97.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V97.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V97.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V97.Coord.Coord Evergreen.V97.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
