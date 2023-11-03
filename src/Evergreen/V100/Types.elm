module Evergreen.V100.Types exposing (..)

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
import Evergreen.V100.AdminPage
import Evergreen.V100.Animal
import Evergreen.V100.Audio
import Evergreen.V100.Bounds
import Evergreen.V100.Change
import Evergreen.V100.Color
import Evergreen.V100.Coord
import Evergreen.V100.Cursor
import Evergreen.V100.DisplayName
import Evergreen.V100.EmailAddress
import Evergreen.V100.Grid
import Evergreen.V100.Id
import Evergreen.V100.IdDict
import Evergreen.V100.Keyboard
import Evergreen.V100.LocalGrid
import Evergreen.V100.LocalModel
import Evergreen.V100.MailEditor
import Evergreen.V100.PersonName
import Evergreen.V100.PingData
import Evergreen.V100.Point2d
import Evergreen.V100.Postmark
import Evergreen.V100.Route
import Evergreen.V100.Shaders
import Evergreen.V100.Sound
import Evergreen.V100.Sprite
import Evergreen.V100.TextInput
import Evergreen.V100.Tile
import Evergreen.V100.TimeOfDay
import Evergreen.V100.Tool
import Evergreen.V100.Train
import Evergreen.V100.Ui
import Evergreen.V100.Units
import Evergreen.V100.Untrusted
import Evergreen.V100.User
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
    | KeyMsg Evergreen.V100.Keyboard.Msg
    | KeyDown Evergreen.V100.Keyboard.RawKey
    | WindowResized (Evergreen.V100.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V100.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V100.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V100.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V100.Sound.Sound (Result Evergreen.V100.Audio.LoadError Evergreen.V100.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V100.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V100.LocalModel.LocalModel Evergreen.V100.Change.Change Evergreen.V100.LocalGrid.LocalGrid
    , trains : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.TrainId Evergreen.V100.Train.Train
    , mail : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.MailId Evergreen.V100.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V100.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V100.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V100.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V100.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit
    , route : Evergreen.V100.Route.PageRoute
    , mousePosition : Evergreen.V100.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V100.Sound.Sound (Result Evergreen.V100.Audio.LoadError Evergreen.V100.Audio.Source)
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
    = NormalViewPoint (Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V100.Id.Id Evergreen.V100.Id.TrainId
        , startViewPoint : Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V100.Tile.TileGroup
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
    | MailEditorHover Evergreen.V100.MailEditor.Hover
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
    | AdminHover Evergreen.V100.AdminPage.Hover
    | CategoryButton Evergreen.V100.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton


type Hover
    = TileHover
        { tile : Evergreen.V100.Tile.Tile
        , userId : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
        , position : Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit
        , colors : Evergreen.V100.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V100.Id.Id Evergreen.V100.Id.TrainId
        , train : Evergreen.V100.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V100.Id.Id Evergreen.V100.Id.AnimalId
        , animal : Evergreen.V100.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V100.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V100.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V100.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit
        , current : Evergreen.V100.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit
    , tile : Evergreen.V100.Tile.Tile
    , colors : Evergreen.V100.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V100.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V100.Id.Id Evergreen.V100.Id.UserId)
    , position : Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V100.MailEditor.Model
    | AdminPage Evergreen.V100.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V100.LocalModel.LocalModel Evergreen.V100.Change.Change Evergreen.V100.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V100.Keyboard.Key
    , currentTool : Evergreen.V100.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V100.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.TrainId Evergreen.V100.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V100.LocalModel.LocalModel Evergreen.V100.Change.Change Evergreen.V100.LocalGrid.LocalGrid
    , trains : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.TrainId Evergreen.V100.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V100.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V100.Sprite.Vertex
            , background : WebGL.Mesh Evergreen.V100.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V100.Keyboard.Key
    , windowSize : Evergreen.V100.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V100.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V100.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V100.Id.Id Evergreen.V100.Id.EventId, Evergreen.V100.Change.LocalChange )
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
            , tile : Evergreen.V100.Tile.Tile
            , position : Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V100.Sound.Sound (Result Evergreen.V100.Audio.LoadError Evergreen.V100.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V100.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V100.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V100.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V100.Sprite.Vertex
    , previousTileHover : Maybe Evergreen.V100.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V100.Id.Id Evergreen.V100.Id.EventId
    , pingData : Maybe Evergreen.V100.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V100.Tile.TileGroup Evergreen.V100.Color.Colors
    , primaryColorTextInput : Evergreen.V100.TextInput.Model
    , secondaryColorTextInput : Evergreen.V100.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V100.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V100.IdDict.IdDict
            Evergreen.V100.Id.UserId
            { position : Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.UserId Evergreen.V100.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V100.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V100.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V100.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V100.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V100.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V100.Tile.Category
    , lastHotkeyChange : Maybe Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V100.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V100.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V100.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V100.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.UserId (List Evergreen.V100.MailEditor.Content)
    , cursor : Maybe Evergreen.V100.Cursor.Cursor
    , handColor : Evergreen.V100.Color.Colors
    , emailAddress : Evergreen.V100.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.UserId ()
    , name : Evergreen.V100.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    , timeOfDay : Evergreen.V100.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V100.Change.TileHotkey Evergreen.V100.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    }


type BackendError
    = PostmarkError Evergreen.V100.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V100.Id.Id Evergreen.V100.Id.UserId)


type alias Person =
    { name : Evergreen.V100.PersonName.PersonName
    , home : Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit
    , position : Evergreen.V100.Point2d.Point2d Evergreen.V100.Units.WorldUnit Evergreen.V100.Units.WorldUnit
    }


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V100.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V100.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V100.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V100.Bounds.Bounds Evergreen.V100.Units.CellUnit))
            , userId : Maybe (Evergreen.V100.Id.Id Evergreen.V100.Id.UserId)
            }
    , users : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.TrainId Evergreen.V100.Train.Train
    , animals : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.AnimalId Evergreen.V100.Animal.Animal
    , people : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.PersonId Person
    , lastWorldUpdateTrains : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.TrainId Evergreen.V100.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.MailId Evergreen.V100.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V100.Id.SecretId Evergreen.V100.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V100.Id.Id Evergreen.V100.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V100.Id.SecretId Evergreen.V100.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.UserId (List.Nonempty.Nonempty Evergreen.V100.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V100.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    }


type alias FrontendMsg =
    Evergreen.V100.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V100.Bounds.Bounds Evergreen.V100.Units.CellUnit) (Maybe Evergreen.V100.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V100.Id.Id Evergreen.V100.Id.EventId, Evergreen.V100.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V100.Untrusted.Untrusted Evergreen.V100.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V100.Untrusted.Untrusted Evergreen.V100.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V100.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V100.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V100.Id.SecretId Evergreen.V100.Route.InviteToken) (Result Effect.Http.Error Evergreen.V100.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V100.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V100.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V100.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V100.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V100.Grid.GridData
    , userStatus : Evergreen.V100.Change.UserStatus
    , viewBounds : Evergreen.V100.Bounds.Bounds Evergreen.V100.Units.CellUnit
    , trains : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.TrainId Evergreen.V100.Train.Train
    , mail : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.MailId Evergreen.V100.MailEditor.FrontendMail
    , cows : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.AnimalId Evergreen.V100.Animal.Animal
    , cursors : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.UserId Evergreen.V100.Cursor.Cursor
    , users : Evergreen.V100.IdDict.IdDict Evergreen.V100.Id.UserId Evergreen.V100.User.FrontendUser
    , inviteTree : Evergreen.V100.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V100.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V100.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V100.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V100.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V100.Coord.Coord Evergreen.V100.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
