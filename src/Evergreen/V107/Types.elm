module Evergreen.V107.Types exposing (..)

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
import Evergreen.V107.AdminPage
import Evergreen.V107.Animal
import Evergreen.V107.Audio
import Evergreen.V107.Bounds
import Evergreen.V107.Change
import Evergreen.V107.Color
import Evergreen.V107.Coord
import Evergreen.V107.Cursor
import Evergreen.V107.DisplayName
import Evergreen.V107.EmailAddress
import Evergreen.V107.Grid
import Evergreen.V107.GridCell
import Evergreen.V107.Id
import Evergreen.V107.IdDict
import Evergreen.V107.Keyboard
import Evergreen.V107.LocalGrid
import Evergreen.V107.LocalModel
import Evergreen.V107.MailEditor
import Evergreen.V107.PersonName
import Evergreen.V107.PingData
import Evergreen.V107.Point2d
import Evergreen.V107.Postmark
import Evergreen.V107.Route
import Evergreen.V107.Shaders
import Evergreen.V107.Sound
import Evergreen.V107.Sprite
import Evergreen.V107.TextInput
import Evergreen.V107.Tile
import Evergreen.V107.TileCountBot
import Evergreen.V107.TimeOfDay
import Evergreen.V107.Tool
import Evergreen.V107.Train
import Evergreen.V107.Ui
import Evergreen.V107.Units
import Evergreen.V107.Untrusted
import Evergreen.V107.User
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
    | KeyMsg Evergreen.V107.Keyboard.Msg
    | KeyDown Evergreen.V107.Keyboard.RawKey
    | WindowResized (Evergreen.V107.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V107.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V107.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V107.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V107.Sound.Sound (Result Evergreen.V107.Audio.LoadError Evergreen.V107.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V107.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V107.LocalModel.LocalModel Evergreen.V107.Change.Change Evergreen.V107.LocalGrid.LocalGrid
    , trains : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.TrainId Evergreen.V107.Train.Train
    , mail : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.MailId Evergreen.V107.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V107.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V107.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V107.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V107.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit
    , route : Evergreen.V107.Route.PageRoute
    , mousePosition : Evergreen.V107.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V107.Sound.Sound (Result Evergreen.V107.Audio.LoadError Evergreen.V107.Audio.Source)
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
    = NormalViewPoint (Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V107.Id.Id Evergreen.V107.Id.TrainId
        , startViewPoint : Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V107.Tile.TileGroup
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
    | MailEditorHover Evergreen.V107.MailEditor.Hover
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
    | AdminHover Evergreen.V107.AdminPage.Hover
    | CategoryButton Evergreen.V107.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton


type Hover
    = TileHover
        { tile : Evergreen.V107.Tile.Tile
        , userId : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
        , position : Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit
        , colors : Evergreen.V107.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V107.Id.Id Evergreen.V107.Id.TrainId
        , train : Evergreen.V107.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V107.Id.Id Evergreen.V107.Id.AnimalId
        , animal : Evergreen.V107.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V107.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V107.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V107.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit
        , current : Evergreen.V107.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit
    , tile : Evergreen.V107.Tile.Tile
    , colors : Evergreen.V107.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V107.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V107.Id.Id Evergreen.V107.Id.UserId)
    , position : Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V107.MailEditor.Model
    | AdminPage Evergreen.V107.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V107.LocalModel.LocalModel Evergreen.V107.Change.Change Evergreen.V107.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V107.Keyboard.Key
    , currentTool : Evergreen.V107.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V107.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.TrainId Evergreen.V107.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V107.LocalModel.LocalModel Evergreen.V107.Change.Change Evergreen.V107.LocalGrid.LocalGrid
    , trains : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.TrainId Evergreen.V107.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V107.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V107.Sprite.Vertex
            , background : WebGL.Mesh Evergreen.V107.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V107.Keyboard.Key
    , windowSize : Evergreen.V107.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V107.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V107.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V107.Id.Id Evergreen.V107.Id.EventId, Evergreen.V107.Change.LocalChange )
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
            , tile : Evergreen.V107.Tile.Tile
            , position : Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V107.Sound.Sound (Result Evergreen.V107.Audio.LoadError Evergreen.V107.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V107.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V107.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V107.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V107.Sprite.Vertex
    , previousTileHover : Maybe Evergreen.V107.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V107.Id.Id Evergreen.V107.Id.EventId
    , pingData : Maybe Evergreen.V107.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V107.Tile.TileGroup Evergreen.V107.Color.Colors
    , primaryColorTextInput : Evergreen.V107.TextInput.Model
    , secondaryColorTextInput : Evergreen.V107.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V107.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V107.IdDict.IdDict
            Evergreen.V107.Id.UserId
            { position : Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.UserId Evergreen.V107.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V107.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V107.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V107.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V107.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V107.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V107.Tile.Category
    , lastHotkeyChange : Maybe Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V107.Audio.Model FrontendMsg_ FrontendModel_


type alias HumanUserData =
    { emailAddress : Evergreen.V107.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.UserId ()
    , timeOfDay : Evergreen.V107.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V107.Change.TileHotkey Evergreen.V107.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    , allowEmailNotifications : Bool
    }


type BackendUserType
    = HumanUser HumanUserData
    | BotUser


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V107.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V107.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V107.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.UserId (List Evergreen.V107.MailEditor.Content)
    , cursor : Maybe Evergreen.V107.Cursor.Cursor
    , handColor : Evergreen.V107.Color.Colors
    , userType : BackendUserType
    , name : Evergreen.V107.DisplayName.DisplayName
    }


type BackendError
    = PostmarkError Evergreen.V107.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V107.Id.Id Evergreen.V107.Id.UserId)


type alias Person =
    { name : Evergreen.V107.PersonName.PersonName
    , home : Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit
    , position : Evergreen.V107.Point2d.Point2d Evergreen.V107.Units.WorldUnit Evergreen.V107.Units.WorldUnit
    }


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V107.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V107.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V107.Grid.Grid Evergreen.V107.GridCell.BackendHistory
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V107.Bounds.Bounds Evergreen.V107.Units.CellUnit))
            , userId : Maybe (Evergreen.V107.Id.Id Evergreen.V107.Id.UserId)
            }
    , users : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.TrainId Evergreen.V107.Train.Train
    , animals : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.AnimalId Evergreen.V107.Animal.Animal
    , people : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.PersonId Person
    , lastWorldUpdateTrains : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.TrainId Evergreen.V107.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.MailId Evergreen.V107.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V107.Id.SecretId Evergreen.V107.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V107.Id.Id Evergreen.V107.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V107.Id.SecretId Evergreen.V107.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.UserId (List.Nonempty.Nonempty Evergreen.V107.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V107.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    , tileCountBot : Maybe Evergreen.V107.TileCountBot.Model
    }


type alias FrontendMsg =
    Evergreen.V107.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V107.Bounds.Bounds Evergreen.V107.Units.CellUnit) (Maybe Evergreen.V107.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V107.Id.Id Evergreen.V107.Id.EventId, Evergreen.V107.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V107.Untrusted.Untrusted Evergreen.V107.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V107.Untrusted.Untrusted Evergreen.V107.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V107.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V107.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V107.Id.SecretId Evergreen.V107.Route.InviteToken) (Result Effect.Http.Error Evergreen.V107.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V107.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V107.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V107.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V107.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix
    | TileCountBotUpdate Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V107.Grid.GridData
    , userStatus : Evergreen.V107.Change.UserStatus
    , viewBounds : Evergreen.V107.Bounds.Bounds Evergreen.V107.Units.CellUnit
    , trains : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.TrainId Evergreen.V107.Train.Train
    , mail : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.MailId Evergreen.V107.MailEditor.FrontendMail
    , cows : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.AnimalId Evergreen.V107.Animal.Animal
    , cursors : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.UserId Evergreen.V107.Cursor.Cursor
    , users : Evergreen.V107.IdDict.IdDict Evergreen.V107.Id.UserId Evergreen.V107.User.FrontendUser
    , inviteTree : Evergreen.V107.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V107.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V107.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V107.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V107.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V107.Coord.Coord Evergreen.V107.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
