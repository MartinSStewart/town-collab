module Evergreen.V99.Types exposing (..)

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
import Evergreen.V99.AdminPage
import Evergreen.V99.Animal
import Evergreen.V99.Audio
import Evergreen.V99.Bounds
import Evergreen.V99.Change
import Evergreen.V99.Color
import Evergreen.V99.Coord
import Evergreen.V99.Cursor
import Evergreen.V99.DisplayName
import Evergreen.V99.EmailAddress
import Evergreen.V99.Grid
import Evergreen.V99.Id
import Evergreen.V99.IdDict
import Evergreen.V99.Keyboard
import Evergreen.V99.LocalGrid
import Evergreen.V99.LocalModel
import Evergreen.V99.MailEditor
import Evergreen.V99.PersonName
import Evergreen.V99.PingData
import Evergreen.V99.Point2d
import Evergreen.V99.Postmark
import Evergreen.V99.Route
import Evergreen.V99.Shaders
import Evergreen.V99.Sound
import Evergreen.V99.Sprite
import Evergreen.V99.TextInput
import Evergreen.V99.Tile
import Evergreen.V99.TimeOfDay
import Evergreen.V99.Tool
import Evergreen.V99.Train
import Evergreen.V99.Ui
import Evergreen.V99.Units
import Evergreen.V99.Untrusted
import Evergreen.V99.User
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
    | KeyMsg Evergreen.V99.Keyboard.Msg
    | KeyDown Evergreen.V99.Keyboard.RawKey
    | WindowResized (Evergreen.V99.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V99.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V99.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V99.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V99.Sound.Sound (Result Evergreen.V99.Audio.LoadError Evergreen.V99.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V99.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V99.LocalModel.LocalModel Evergreen.V99.Change.Change Evergreen.V99.LocalGrid.LocalGrid
    , trains : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.TrainId Evergreen.V99.Train.Train
    , mail : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.MailId Evergreen.V99.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V99.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V99.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V99.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V99.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit
    , route : Evergreen.V99.Route.PageRoute
    , mousePosition : Evergreen.V99.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V99.Sound.Sound (Result Evergreen.V99.Audio.LoadError Evergreen.V99.Audio.Source)
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
    = NormalViewPoint (Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V99.Id.Id Evergreen.V99.Id.TrainId
        , startViewPoint : Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V99.Tile.TileGroup
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
    | MailEditorHover Evergreen.V99.MailEditor.Hover
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
    | AdminHover Evergreen.V99.AdminPage.Hover
    | CategoryButton Evergreen.V99.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton


type Hover
    = TileHover
        { tile : Evergreen.V99.Tile.Tile
        , userId : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
        , position : Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit
        , colors : Evergreen.V99.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V99.Id.Id Evergreen.V99.Id.TrainId
        , train : Evergreen.V99.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V99.Id.Id Evergreen.V99.Id.AnimalId
        , animal : Evergreen.V99.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V99.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V99.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V99.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit
        , current : Evergreen.V99.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit
    , tile : Evergreen.V99.Tile.Tile
    , colors : Evergreen.V99.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V99.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V99.Id.Id Evergreen.V99.Id.UserId)
    , position : Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V99.MailEditor.Model
    | AdminPage Evergreen.V99.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V99.LocalModel.LocalModel Evergreen.V99.Change.Change Evergreen.V99.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V99.Keyboard.Key
    , currentTool : Evergreen.V99.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V99.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.TrainId Evergreen.V99.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V99.LocalModel.LocalModel Evergreen.V99.Change.Change Evergreen.V99.LocalGrid.LocalGrid
    , trains : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.TrainId Evergreen.V99.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V99.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V99.Sprite.Vertex
            , background : WebGL.Mesh Evergreen.V99.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V99.Keyboard.Key
    , windowSize : Evergreen.V99.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V99.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V99.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V99.Id.Id Evergreen.V99.Id.EventId, Evergreen.V99.Change.LocalChange )
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
            , tile : Evergreen.V99.Tile.Tile
            , position : Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V99.Sound.Sound (Result Evergreen.V99.Audio.LoadError Evergreen.V99.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V99.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V99.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V99.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V99.Sprite.Vertex
    , previousTileHover : Maybe Evergreen.V99.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V99.Id.Id Evergreen.V99.Id.EventId
    , pingData : Maybe Evergreen.V99.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V99.Tile.TileGroup Evergreen.V99.Color.Colors
    , primaryColorTextInput : Evergreen.V99.TextInput.Model
    , secondaryColorTextInput : Evergreen.V99.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V99.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V99.IdDict.IdDict
            Evergreen.V99.Id.UserId
            { position : Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.UserId Evergreen.V99.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V99.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V99.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V99.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V99.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V99.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V99.Tile.Category
    , lastHotkeyChange : Maybe Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V99.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V99.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V99.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V99.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.UserId (List Evergreen.V99.MailEditor.Content)
    , cursor : Maybe Evergreen.V99.Cursor.Cursor
    , handColor : Evergreen.V99.Color.Colors
    , emailAddress : Evergreen.V99.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.UserId ()
    , name : Evergreen.V99.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    , timeOfDay : Evergreen.V99.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V99.Change.TileHotkey Evergreen.V99.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    }


type BackendError
    = PostmarkError Evergreen.V99.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V99.Id.Id Evergreen.V99.Id.UserId)


type alias Person =
    { name : Evergreen.V99.PersonName.PersonName
    , home : Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit
    , position : Evergreen.V99.Point2d.Point2d Evergreen.V99.Units.WorldUnit Evergreen.V99.Units.WorldUnit
    }


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V99.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V99.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V99.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V99.Bounds.Bounds Evergreen.V99.Units.CellUnit))
            , userId : Maybe (Evergreen.V99.Id.Id Evergreen.V99.Id.UserId)
            }
    , users : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.TrainId Evergreen.V99.Train.Train
    , animals : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.AnimalId Evergreen.V99.Animal.Animal
    , people : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.PersonId Person
    , lastWorldUpdateTrains : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.TrainId Evergreen.V99.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.MailId Evergreen.V99.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V99.Id.SecretId Evergreen.V99.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V99.Id.Id Evergreen.V99.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V99.Id.SecretId Evergreen.V99.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.UserId (List.Nonempty.Nonempty Evergreen.V99.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V99.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    }


type alias FrontendMsg =
    Evergreen.V99.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V99.Bounds.Bounds Evergreen.V99.Units.CellUnit) (Maybe Evergreen.V99.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V99.Id.Id Evergreen.V99.Id.EventId, Evergreen.V99.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V99.Untrusted.Untrusted Evergreen.V99.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V99.Untrusted.Untrusted Evergreen.V99.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V99.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V99.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V99.Id.SecretId Evergreen.V99.Route.InviteToken) (Result Effect.Http.Error Evergreen.V99.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V99.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V99.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V99.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V99.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V99.Grid.GridData
    , userStatus : Evergreen.V99.Change.UserStatus
    , viewBounds : Evergreen.V99.Bounds.Bounds Evergreen.V99.Units.CellUnit
    , trains : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.TrainId Evergreen.V99.Train.Train
    , mail : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.MailId Evergreen.V99.MailEditor.FrontendMail
    , cows : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.AnimalId Evergreen.V99.Animal.Animal
    , cursors : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.UserId Evergreen.V99.Cursor.Cursor
    , users : Evergreen.V99.IdDict.IdDict Evergreen.V99.Id.UserId Evergreen.V99.User.FrontendUser
    , inviteTree : Evergreen.V99.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V99.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V99.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V99.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V99.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V99.Coord.Coord Evergreen.V99.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
