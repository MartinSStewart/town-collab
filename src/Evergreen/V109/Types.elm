module Evergreen.V109.Types exposing (..)

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
import Evergreen.V109.AdminPage
import Evergreen.V109.Animal
import Evergreen.V109.Audio
import Evergreen.V109.Bounds
import Evergreen.V109.Change
import Evergreen.V109.Color
import Evergreen.V109.Coord
import Evergreen.V109.Cursor
import Evergreen.V109.DisplayName
import Evergreen.V109.EmailAddress
import Evergreen.V109.Grid
import Evergreen.V109.GridCell
import Evergreen.V109.Id
import Evergreen.V109.IdDict
import Evergreen.V109.Keyboard
import Evergreen.V109.LocalGrid
import Evergreen.V109.LocalModel
import Evergreen.V109.MailEditor
import Evergreen.V109.PersonName
import Evergreen.V109.PingData
import Evergreen.V109.Point2d
import Evergreen.V109.Postmark
import Evergreen.V109.Route
import Evergreen.V109.Shaders
import Evergreen.V109.Sound
import Evergreen.V109.Sprite
import Evergreen.V109.TextInput
import Evergreen.V109.Tile
import Evergreen.V109.TileCountBot
import Evergreen.V109.TimeOfDay
import Evergreen.V109.Tool
import Evergreen.V109.Train
import Evergreen.V109.Ui
import Evergreen.V109.Units
import Evergreen.V109.Untrusted
import Evergreen.V109.User
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
    | KeyMsg Evergreen.V109.Keyboard.Msg
    | KeyDown Evergreen.V109.Keyboard.RawKey
    | WindowResized (Evergreen.V109.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V109.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V109.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V109.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V109.Sound.Sound (Result Evergreen.V109.Audio.LoadError Evergreen.V109.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V109.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V109.LocalModel.LocalModel Evergreen.V109.Change.Change Evergreen.V109.LocalGrid.LocalGrid
    , trains : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.TrainId Evergreen.V109.Train.Train
    , mail : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.MailId Evergreen.V109.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V109.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V109.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V109.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V109.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit
    , route : Evergreen.V109.Route.PageRoute
    , mousePosition : Evergreen.V109.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V109.Sound.Sound (Result Evergreen.V109.Audio.LoadError Evergreen.V109.Audio.Source)
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
    = NormalViewPoint (Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V109.Id.Id Evergreen.V109.Id.TrainId
        , startViewPoint : Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V109.Tile.TileGroup
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
    | MailEditorHover Evergreen.V109.MailEditor.Hover
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
    | AdminHover Evergreen.V109.AdminPage.Hover
    | CategoryButton Evergreen.V109.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton
    | OneTimePasswordInput


type Hover
    = TileHover
        { tile : Evergreen.V109.Tile.Tile
        , userId : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
        , position : Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit
        , colors : Evergreen.V109.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V109.Id.Id Evergreen.V109.Id.TrainId
        , train : Evergreen.V109.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V109.Id.Id Evergreen.V109.Id.AnimalId
        , animal : Evergreen.V109.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V109.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V109.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V109.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit
        , current : Evergreen.V109.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit
    , tile : Evergreen.V109.Tile.Tile
    , colors : Evergreen.V109.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V109.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
    , position : Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V109.MailEditor.Model
    | AdminPage Evergreen.V109.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V109.LocalModel.LocalModel Evergreen.V109.Change.Change Evergreen.V109.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V109.Keyboard.Key
    , currentTool : Evergreen.V109.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V109.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.TrainId Evergreen.V109.Train.Train
    , time : Effect.Time.Posix
    }


type LoginError
    = OneTimePasswordExpiredOrTooManyAttempts
    | WrongOneTimePassword (Evergreen.V109.Id.SecretId Evergreen.V109.Id.OneTimePasswordId)


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V109.LocalModel.LocalModel Evergreen.V109.Change.Change Evergreen.V109.LocalGrid.LocalGrid
    , trains : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.TrainId Evergreen.V109.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V109.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V109.Sprite.Vertex
            , background : WebGL.Mesh Evergreen.V109.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V109.Keyboard.Key
    , windowSize : Evergreen.V109.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V109.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V109.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V109.Id.Id Evergreen.V109.Id.EventId, Evergreen.V109.Change.LocalChange )
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
            , tile : Evergreen.V109.Tile.Tile
            , position : Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V109.Sound.Sound (Result Evergreen.V109.Audio.LoadError Evergreen.V109.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V109.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V109.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V109.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V109.Sprite.Vertex
    , previousTileHover : Maybe Evergreen.V109.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V109.Id.Id Evergreen.V109.Id.EventId
    , pingData : Maybe Evergreen.V109.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V109.Tile.TileGroup Evergreen.V109.Color.Colors
    , primaryColorTextInput : Evergreen.V109.TextInput.Model
    , secondaryColorTextInput : Evergreen.V109.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V109.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V109.IdDict.IdDict
            Evergreen.V109.Id.UserId
            { position : Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.UserId Evergreen.V109.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginEmailInput : Evergreen.V109.TextInput.Model
    , oneTimePasswordInput : Evergreen.V109.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V109.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V109.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V109.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V109.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V109.Tile.Category
    , lastHotkeyChange : Maybe Time.Posix
    , loginError : Maybe LoginError
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V109.Audio.Model FrontendMsg_ FrontendModel_


type alias HumanUserData =
    { emailAddress : Evergreen.V109.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.UserId ()
    , timeOfDay : Evergreen.V109.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V109.Change.TileHotkey Evergreen.V109.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    , allowEmailNotifications : Bool
    }


type BackendUserType
    = HumanUser HumanUserData
    | BotUser


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V109.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V109.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V109.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.UserId (List Evergreen.V109.MailEditor.Content)
    , cursor : Maybe Evergreen.V109.Cursor.Cursor
    , handColor : Evergreen.V109.Color.Colors
    , userType : BackendUserType
    , name : Evergreen.V109.DisplayName.DisplayName
    }


type BackendError
    = PostmarkError Evergreen.V109.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)


type alias Person =
    { name : Evergreen.V109.PersonName.PersonName
    , home : Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit
    , position : Evergreen.V109.Point2d.Point2d Evergreen.V109.Units.WorldUnit Evergreen.V109.Units.WorldUnit
    }


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V109.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V109.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V109.Grid.Grid Evergreen.V109.GridCell.BackendHistory
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V109.Bounds.Bounds Evergreen.V109.Units.CellUnit))
            , userId : Maybe (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)
            }
    , users : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.TrainId Evergreen.V109.Train.Train
    , animals : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.AnimalId Evergreen.V109.Animal.Animal
    , people : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.PersonId Person
    , lastWorldUpdateTrains : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.TrainId Evergreen.V109.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.MailId Evergreen.V109.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V109.Id.SecretId Evergreen.V109.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , pendingOneTimePasswords :
        AssocList.Dict
            Effect.Lamdera.SessionId
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
            , loginAttempts : Int
            , oneTimePassword : Evergreen.V109.Id.SecretId Evergreen.V109.Id.OneTimePasswordId
            }
    , invites : AssocList.Dict (Evergreen.V109.Id.SecretId Evergreen.V109.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.UserId (List.Nonempty.Nonempty Evergreen.V109.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V109.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    , tileCountBot : Maybe Evergreen.V109.TileCountBot.Model
    }


type alias FrontendMsg =
    Evergreen.V109.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V109.Bounds.Bounds Evergreen.V109.Units.CellUnit) (Maybe Evergreen.V109.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V109.Id.Id Evergreen.V109.Id.EventId, Evergreen.V109.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V109.Untrusted.Untrusted Evergreen.V109.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V109.Untrusted.Untrusted Evergreen.V109.EmailAddress.EmailAddress)
    | PostOfficePositionRequest
    | ResetTileBotRequest
    | LoginAttemptRequest (Evergreen.V109.Id.SecretId Evergreen.V109.Id.OneTimePasswordId)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V109.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V109.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V109.Id.SecretId Evergreen.V109.Route.InviteToken) (Result Effect.Http.Error Evergreen.V109.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V109.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V109.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V109.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V109.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix
    | TileCountBotUpdate Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V109.Grid.GridData
    , userStatus : Evergreen.V109.Change.UserStatus
    , viewBounds : Evergreen.V109.Bounds.Bounds Evergreen.V109.Units.CellUnit
    , trains : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.TrainId Evergreen.V109.Train.Train
    , mail : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.MailId Evergreen.V109.MailEditor.FrontendMail
    , cows : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.AnimalId Evergreen.V109.Animal.Animal
    , cursors : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.UserId Evergreen.V109.Cursor.Cursor
    , users : Evergreen.V109.IdDict.IdDict Evergreen.V109.Id.UserId Evergreen.V109.User.FrontendUser
    , inviteTree : Evergreen.V109.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V109.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V109.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V109.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V109.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V109.Coord.Coord Evergreen.V109.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
    | LoginAttemptResponse LoginError
