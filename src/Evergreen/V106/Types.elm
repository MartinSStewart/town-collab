module Evergreen.V106.Types exposing (..)

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
import Evergreen.V106.AdminPage
import Evergreen.V106.Animal
import Evergreen.V106.Audio
import Evergreen.V106.Bounds
import Evergreen.V106.Change
import Evergreen.V106.Color
import Evergreen.V106.Coord
import Evergreen.V106.Cursor
import Evergreen.V106.DisplayName
import Evergreen.V106.EmailAddress
import Evergreen.V106.Grid
import Evergreen.V106.GridCell
import Evergreen.V106.Id
import Evergreen.V106.IdDict
import Evergreen.V106.Keyboard
import Evergreen.V106.LocalGrid
import Evergreen.V106.LocalModel
import Evergreen.V106.MailEditor
import Evergreen.V106.PersonName
import Evergreen.V106.PingData
import Evergreen.V106.Point2d
import Evergreen.V106.Postmark
import Evergreen.V106.Route
import Evergreen.V106.Shaders
import Evergreen.V106.Sound
import Evergreen.V106.Sprite
import Evergreen.V106.TextInput
import Evergreen.V106.Tile
import Evergreen.V106.TimeOfDay
import Evergreen.V106.Tool
import Evergreen.V106.Train
import Evergreen.V106.Ui
import Evergreen.V106.Units
import Evergreen.V106.Untrusted
import Evergreen.V106.User
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
    | KeyMsg Evergreen.V106.Keyboard.Msg
    | KeyDown Evergreen.V106.Keyboard.RawKey
    | WindowResized (Evergreen.V106.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V106.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V106.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V106.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V106.Sound.Sound (Result Evergreen.V106.Audio.LoadError Evergreen.V106.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V106.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V106.LocalModel.LocalModel Evergreen.V106.Change.Change Evergreen.V106.LocalGrid.LocalGrid
    , trains : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.TrainId Evergreen.V106.Train.Train
    , mail : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.MailId Evergreen.V106.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V106.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V106.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V106.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V106.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit
    , route : Evergreen.V106.Route.PageRoute
    , mousePosition : Evergreen.V106.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V106.Sound.Sound (Result Evergreen.V106.Audio.LoadError Evergreen.V106.Audio.Source)
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
    = NormalViewPoint (Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V106.Id.Id Evergreen.V106.Id.TrainId
        , startViewPoint : Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V106.Tile.TileGroup
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
    | MailEditorHover Evergreen.V106.MailEditor.Hover
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
    | AdminHover Evergreen.V106.AdminPage.Hover
    | CategoryButton Evergreen.V106.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton


type Hover
    = TileHover
        { tile : Evergreen.V106.Tile.Tile
        , userId : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
        , position : Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit
        , colors : Evergreen.V106.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V106.Id.Id Evergreen.V106.Id.TrainId
        , train : Evergreen.V106.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V106.Id.Id Evergreen.V106.Id.AnimalId
        , animal : Evergreen.V106.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V106.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V106.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V106.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit
        , current : Evergreen.V106.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit
    , tile : Evergreen.V106.Tile.Tile
    , colors : Evergreen.V106.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V106.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V106.Id.Id Evergreen.V106.Id.UserId)
    , position : Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V106.MailEditor.Model
    | AdminPage Evergreen.V106.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V106.LocalModel.LocalModel Evergreen.V106.Change.Change Evergreen.V106.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V106.Keyboard.Key
    , currentTool : Evergreen.V106.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V106.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.TrainId Evergreen.V106.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V106.LocalModel.LocalModel Evergreen.V106.Change.Change Evergreen.V106.LocalGrid.LocalGrid
    , trains : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.TrainId Evergreen.V106.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V106.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V106.Sprite.Vertex
            , background : WebGL.Mesh Evergreen.V106.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V106.Keyboard.Key
    , windowSize : Evergreen.V106.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V106.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V106.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V106.Id.Id Evergreen.V106.Id.EventId, Evergreen.V106.Change.LocalChange )
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
            , tile : Evergreen.V106.Tile.Tile
            , position : Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V106.Sound.Sound (Result Evergreen.V106.Audio.LoadError Evergreen.V106.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V106.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V106.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V106.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V106.Sprite.Vertex
    , previousTileHover : Maybe Evergreen.V106.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V106.Id.Id Evergreen.V106.Id.EventId
    , pingData : Maybe Evergreen.V106.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V106.Tile.TileGroup Evergreen.V106.Color.Colors
    , primaryColorTextInput : Evergreen.V106.TextInput.Model
    , secondaryColorTextInput : Evergreen.V106.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V106.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V106.IdDict.IdDict
            Evergreen.V106.Id.UserId
            { position : Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.UserId Evergreen.V106.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V106.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V106.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V106.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V106.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V106.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V106.Tile.Category
    , lastHotkeyChange : Maybe Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V106.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V106.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V106.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V106.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.UserId (List Evergreen.V106.MailEditor.Content)
    , cursor : Maybe Evergreen.V106.Cursor.Cursor
    , handColor : Evergreen.V106.Color.Colors
    , emailAddress : Evergreen.V106.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.UserId ()
    , name : Evergreen.V106.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    , timeOfDay : Evergreen.V106.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V106.Change.TileHotkey Evergreen.V106.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    }


type BackendError
    = PostmarkError Evergreen.V106.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V106.Id.Id Evergreen.V106.Id.UserId)


type alias Person =
    { name : Evergreen.V106.PersonName.PersonName
    , home : Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit
    , position : Evergreen.V106.Point2d.Point2d Evergreen.V106.Units.WorldUnit Evergreen.V106.Units.WorldUnit
    }


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V106.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V106.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V106.Grid.Grid Evergreen.V106.GridCell.BackendHistory
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V106.Bounds.Bounds Evergreen.V106.Units.CellUnit))
            , userId : Maybe (Evergreen.V106.Id.Id Evergreen.V106.Id.UserId)
            }
    , users : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.TrainId Evergreen.V106.Train.Train
    , animals : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.AnimalId Evergreen.V106.Animal.Animal
    , people : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.PersonId Person
    , lastWorldUpdateTrains : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.TrainId Evergreen.V106.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.MailId Evergreen.V106.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V106.Id.SecretId Evergreen.V106.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V106.Id.Id Evergreen.V106.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V106.Id.SecretId Evergreen.V106.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.UserId (List.Nonempty.Nonempty Evergreen.V106.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V106.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    }


type alias FrontendMsg =
    Evergreen.V106.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V106.Bounds.Bounds Evergreen.V106.Units.CellUnit) (Maybe Evergreen.V106.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V106.Id.Id Evergreen.V106.Id.EventId, Evergreen.V106.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V106.Untrusted.Untrusted Evergreen.V106.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V106.Untrusted.Untrusted Evergreen.V106.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V106.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V106.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V106.Id.SecretId Evergreen.V106.Route.InviteToken) (Result Effect.Http.Error Evergreen.V106.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V106.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V106.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V106.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V106.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V106.Grid.GridData
    , userStatus : Evergreen.V106.Change.UserStatus
    , viewBounds : Evergreen.V106.Bounds.Bounds Evergreen.V106.Units.CellUnit
    , trains : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.TrainId Evergreen.V106.Train.Train
    , mail : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.MailId Evergreen.V106.MailEditor.FrontendMail
    , cows : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.AnimalId Evergreen.V106.Animal.Animal
    , cursors : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.UserId Evergreen.V106.Cursor.Cursor
    , users : Evergreen.V106.IdDict.IdDict Evergreen.V106.Id.UserId Evergreen.V106.User.FrontendUser
    , inviteTree : Evergreen.V106.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V106.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V106.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V106.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V106.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V106.Coord.Coord Evergreen.V106.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
