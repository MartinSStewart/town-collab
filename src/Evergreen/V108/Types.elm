module Evergreen.V108.Types exposing (..)

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
import Evergreen.V108.AdminPage
import Evergreen.V108.Animal
import Evergreen.V108.Audio
import Evergreen.V108.Bounds
import Evergreen.V108.Change
import Evergreen.V108.Color
import Evergreen.V108.Coord
import Evergreen.V108.Cursor
import Evergreen.V108.DisplayName
import Evergreen.V108.EmailAddress
import Evergreen.V108.Grid
import Evergreen.V108.GridCell
import Evergreen.V108.Id
import Evergreen.V108.IdDict
import Evergreen.V108.Keyboard
import Evergreen.V108.LocalGrid
import Evergreen.V108.LocalModel
import Evergreen.V108.MailEditor
import Evergreen.V108.PersonName
import Evergreen.V108.PingData
import Evergreen.V108.Point2d
import Evergreen.V108.Postmark
import Evergreen.V108.Route
import Evergreen.V108.Shaders
import Evergreen.V108.Sound
import Evergreen.V108.Sprite
import Evergreen.V108.TextInput
import Evergreen.V108.Tile
import Evergreen.V108.TileCountBot
import Evergreen.V108.TimeOfDay
import Evergreen.V108.Tool
import Evergreen.V108.Train
import Evergreen.V108.Ui
import Evergreen.V108.Units
import Evergreen.V108.Untrusted
import Evergreen.V108.User
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
    | KeyMsg Evergreen.V108.Keyboard.Msg
    | KeyDown Evergreen.V108.Keyboard.RawKey
    | WindowResized (Evergreen.V108.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V108.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V108.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V108.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V108.Sound.Sound (Result Evergreen.V108.Audio.LoadError Evergreen.V108.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V108.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V108.LocalModel.LocalModel Evergreen.V108.Change.Change Evergreen.V108.LocalGrid.LocalGrid
    , trains : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.TrainId Evergreen.V108.Train.Train
    , mail : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.MailId Evergreen.V108.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V108.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V108.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V108.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V108.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit
    , route : Evergreen.V108.Route.PageRoute
    , mousePosition : Evergreen.V108.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V108.Sound.Sound (Result Evergreen.V108.Audio.LoadError Evergreen.V108.Audio.Source)
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
    = NormalViewPoint (Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V108.Id.Id Evergreen.V108.Id.TrainId
        , startViewPoint : Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V108.Tile.TileGroup
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
    | MailEditorHover Evergreen.V108.MailEditor.Hover
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
    | AdminHover Evergreen.V108.AdminPage.Hover
    | CategoryButton Evergreen.V108.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton


type Hover
    = TileHover
        { tile : Evergreen.V108.Tile.Tile
        , userId : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
        , position : Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit
        , colors : Evergreen.V108.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V108.Id.Id Evergreen.V108.Id.TrainId
        , train : Evergreen.V108.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V108.Id.Id Evergreen.V108.Id.AnimalId
        , animal : Evergreen.V108.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V108.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V108.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V108.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit
        , current : Evergreen.V108.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit
    , tile : Evergreen.V108.Tile.Tile
    , colors : Evergreen.V108.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V108.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
    , position : Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V108.MailEditor.Model
    | AdminPage Evergreen.V108.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V108.LocalModel.LocalModel Evergreen.V108.Change.Change Evergreen.V108.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V108.Keyboard.Key
    , currentTool : Evergreen.V108.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V108.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.TrainId Evergreen.V108.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V108.LocalModel.LocalModel Evergreen.V108.Change.Change Evergreen.V108.LocalGrid.LocalGrid
    , trains : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.TrainId Evergreen.V108.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V108.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V108.Sprite.Vertex
            , background : WebGL.Mesh Evergreen.V108.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V108.Keyboard.Key
    , windowSize : Evergreen.V108.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V108.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V108.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V108.Id.Id Evergreen.V108.Id.EventId, Evergreen.V108.Change.LocalChange )
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
            , tile : Evergreen.V108.Tile.Tile
            , position : Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V108.Sound.Sound (Result Evergreen.V108.Audio.LoadError Evergreen.V108.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V108.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V108.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V108.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V108.Sprite.Vertex
    , previousTileHover : Maybe Evergreen.V108.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V108.Id.Id Evergreen.V108.Id.EventId
    , pingData : Maybe Evergreen.V108.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V108.Tile.TileGroup Evergreen.V108.Color.Colors
    , primaryColorTextInput : Evergreen.V108.TextInput.Model
    , secondaryColorTextInput : Evergreen.V108.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V108.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V108.IdDict.IdDict
            Evergreen.V108.Id.UserId
            { position : Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.UserId Evergreen.V108.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V108.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V108.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V108.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V108.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V108.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V108.Tile.Category
    , lastHotkeyChange : Maybe Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V108.Audio.Model FrontendMsg_ FrontendModel_


type alias HumanUserData =
    { emailAddress : Evergreen.V108.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.UserId ()
    , timeOfDay : Evergreen.V108.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V108.Change.TileHotkey Evergreen.V108.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    , allowEmailNotifications : Bool
    }


type BackendUserType
    = HumanUser HumanUserData
    | BotUser


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V108.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V108.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V108.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.UserId (List Evergreen.V108.MailEditor.Content)
    , cursor : Maybe Evergreen.V108.Cursor.Cursor
    , handColor : Evergreen.V108.Color.Colors
    , userType : BackendUserType
    , name : Evergreen.V108.DisplayName.DisplayName
    }


type BackendError
    = PostmarkError Evergreen.V108.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)


type alias Person =
    { name : Evergreen.V108.PersonName.PersonName
    , home : Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit
    , position : Evergreen.V108.Point2d.Point2d Evergreen.V108.Units.WorldUnit Evergreen.V108.Units.WorldUnit
    }


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V108.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V108.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V108.Grid.Grid Evergreen.V108.GridCell.BackendHistory
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V108.Bounds.Bounds Evergreen.V108.Units.CellUnit))
            , userId : Maybe (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)
            }
    , users : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.TrainId Evergreen.V108.Train.Train
    , animals : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.AnimalId Evergreen.V108.Animal.Animal
    , people : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.PersonId Person
    , lastWorldUpdateTrains : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.TrainId Evergreen.V108.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.MailId Evergreen.V108.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V108.Id.SecretId Evergreen.V108.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V108.Id.SecretId Evergreen.V108.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.UserId (List.Nonempty.Nonempty Evergreen.V108.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V108.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    , tileCountBot : Maybe Evergreen.V108.TileCountBot.Model
    }


type alias FrontendMsg =
    Evergreen.V108.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V108.Bounds.Bounds Evergreen.V108.Units.CellUnit) (Maybe Evergreen.V108.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V108.Id.Id Evergreen.V108.Id.EventId, Evergreen.V108.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V108.Untrusted.Untrusted Evergreen.V108.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V108.Untrusted.Untrusted Evergreen.V108.EmailAddress.EmailAddress)
    | PostOfficePositionRequest
    | ResetTileBotRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V108.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V108.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V108.Id.SecretId Evergreen.V108.Route.InviteToken) (Result Effect.Http.Error Evergreen.V108.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V108.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V108.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V108.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V108.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix
    | TileCountBotUpdate Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V108.Grid.GridData
    , userStatus : Evergreen.V108.Change.UserStatus
    , viewBounds : Evergreen.V108.Bounds.Bounds Evergreen.V108.Units.CellUnit
    , trains : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.TrainId Evergreen.V108.Train.Train
    , mail : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.MailId Evergreen.V108.MailEditor.FrontendMail
    , cows : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.AnimalId Evergreen.V108.Animal.Animal
    , cursors : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.UserId Evergreen.V108.Cursor.Cursor
    , users : Evergreen.V108.IdDict.IdDict Evergreen.V108.Id.UserId Evergreen.V108.User.FrontendUser
    , inviteTree : Evergreen.V108.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V108.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V108.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V108.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V108.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V108.Coord.Coord Evergreen.V108.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
