module Evergreen.V91.Types exposing (..)

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
import Evergreen.V91.AdminPage
import Evergreen.V91.Animal
import Evergreen.V91.Audio
import Evergreen.V91.Bounds
import Evergreen.V91.Change
import Evergreen.V91.Color
import Evergreen.V91.Coord
import Evergreen.V91.Cursor
import Evergreen.V91.DisplayName
import Evergreen.V91.EmailAddress
import Evergreen.V91.Grid
import Evergreen.V91.Id
import Evergreen.V91.IdDict
import Evergreen.V91.Keyboard
import Evergreen.V91.LocalGrid
import Evergreen.V91.LocalModel
import Evergreen.V91.MailEditor
import Evergreen.V91.PingData
import Evergreen.V91.Point2d
import Evergreen.V91.Postmark
import Evergreen.V91.Route
import Evergreen.V91.Shaders
import Evergreen.V91.Sound
import Evergreen.V91.TextInput
import Evergreen.V91.Tile
import Evergreen.V91.Tool
import Evergreen.V91.Train
import Evergreen.V91.Ui
import Evergreen.V91.Units
import Evergreen.V91.Untrusted
import Evergreen.V91.User
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
    | KeyMsg Evergreen.V91.Keyboard.Msg
    | KeyDown Evergreen.V91.Keyboard.RawKey
    | WindowResized (Evergreen.V91.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V91.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V91.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V91.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V91.Sound.Sound (Result Evergreen.V91.Audio.LoadError Evergreen.V91.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V91.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V91.LocalModel.LocalModel Evergreen.V91.Change.Change Evergreen.V91.LocalGrid.LocalGrid
    , trains : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.TrainId Evergreen.V91.Train.Train
    , mail : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.MailId Evergreen.V91.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V91.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V91.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V91.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V91.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V91.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V91.Sound.Sound (Result Evergreen.V91.Audio.LoadError Evergreen.V91.Audio.Source)
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
    = NormalViewPoint (Evergreen.V91.Point2d.Point2d Evergreen.V91.Units.WorldUnit Evergreen.V91.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V91.Id.Id Evergreen.V91.Id.TrainId
        , startViewPoint : Evergreen.V91.Point2d.Point2d Evergreen.V91.Units.WorldUnit Evergreen.V91.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V91.Tile.TileGroup
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
    | MailEditorHover Evergreen.V91.MailEditor.Hover
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
    | AdminHover Evergreen.V91.AdminPage.Hover
    | CategoryButton Evergreen.V91.Tile.Category


type Hover
    = TileHover
        { tile : Evergreen.V91.Tile.Tile
        , userId : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
        , position : Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit
        , colors : Evergreen.V91.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V91.Id.Id Evergreen.V91.Id.TrainId
        , train : Evergreen.V91.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V91.Id.Id Evergreen.V91.Id.AnimalId
        , cow : Evergreen.V91.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V91.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V91.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V91.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V91.Point2d.Point2d Evergreen.V91.Units.WorldUnit Evergreen.V91.Units.WorldUnit
        , current : Evergreen.V91.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit
    , tile : Evergreen.V91.Tile.Tile
    , colors : Evergreen.V91.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = InviteMenu
    | SettingsMenu Evergreen.V91.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V91.Id.Id Evergreen.V91.Id.UserId)
    , position : Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    }


type Page
    = MailPage Evergreen.V91.MailEditor.Model
    | AdminPage Evergreen.V91.AdminPage.Model
    | WorldPage WorldPage2


type alias UpdateMeshesData =
    { localModel : Evergreen.V91.LocalModel.LocalModel Evergreen.V91.Change.Change Evergreen.V91.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V91.Keyboard.Key
    , currentTool : Evergreen.V91.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V91.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.TrainId Evergreen.V91.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V91.LocalModel.LocalModel Evergreen.V91.Change.Change Evergreen.V91.LocalGrid.LocalGrid
    , trains : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.TrainId Evergreen.V91.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V91.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V91.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V91.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V91.Point2d.Point2d Evergreen.V91.Units.WorldUnit Evergreen.V91.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V91.Keyboard.Key
    , windowSize : Evergreen.V91.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V91.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V91.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V91.Id.Id Evergreen.V91.Id.EventId, Evergreen.V91.Change.LocalChange )
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
            , tile : Evergreen.V91.Tile.Tile
            , position : Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V91.Sound.Sound (Result Evergreen.V91.Audio.LoadError Evergreen.V91.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V91.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V91.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V91.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V91.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V91.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V91.Id.Id Evergreen.V91.Id.EventId
    , pingData : Maybe Evergreen.V91.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V91.Tile.TileGroup Evergreen.V91.Color.Colors
    , primaryColorTextInput : Evergreen.V91.TextInput.Model
    , secondaryColorTextInput : Evergreen.V91.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V91.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V91.IdDict.IdDict
            Evergreen.V91.Id.UserId
            { position : Evergreen.V91.Point2d.Point2d Evergreen.V91.Units.WorldUnit Evergreen.V91.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.UserId Evergreen.V91.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V91.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V91.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V91.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V91.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showInviteTree : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V91.Shaders.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V91.Tile.Category
    , lastHotkeyChange : Maybe Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V91.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V91.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V91.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V91.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.UserId (List Evergreen.V91.MailEditor.Content)
    , cursor : Maybe Evergreen.V91.Cursor.Cursor
    , handColor : Evergreen.V91.Color.Colors
    , emailAddress : Evergreen.V91.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.UserId ()
    , name : Evergreen.V91.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    , timeOfDay : Evergreen.V91.Change.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V91.Change.TileHotkey Evergreen.V91.Tile.TileGroup
    }


type BackendError
    = PostmarkError Evergreen.V91.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V91.Id.Id Evergreen.V91.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V91.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V91.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V91.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V91.Bounds.Bounds Evergreen.V91.Units.CellUnit)
            , userId : Maybe (Evergreen.V91.Id.Id Evergreen.V91.Id.UserId)
            }
    , users : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.TrainId Evergreen.V91.Train.Train
    , cows : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.AnimalId Evergreen.V91.Animal.Animal
    , lastWorldUpdateTrains : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.TrainId Evergreen.V91.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.MailId Evergreen.V91.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V91.Id.SecretId Evergreen.V91.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V91.Id.SecretId Evergreen.V91.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.UserId (List.Nonempty.Nonempty Evergreen.V91.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V91.Change.AreTrainsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V91.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V91.Bounds.Bounds Evergreen.V91.Units.CellUnit) (Maybe Evergreen.V91.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V91.Id.Id Evergreen.V91.Id.EventId, Evergreen.V91.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V91.Bounds.Bounds Evergreen.V91.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V91.Untrusted.Untrusted Evergreen.V91.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V91.Untrusted.Untrusted Evergreen.V91.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V91.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V91.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V91.Id.SecretId Evergreen.V91.Route.InviteToken) (Result Effect.Http.Error Evergreen.V91.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V91.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V91.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V91.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V91.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V91.Grid.GridData
    , userStatus : Evergreen.V91.Change.UserStatus
    , viewBounds : Evergreen.V91.Bounds.Bounds Evergreen.V91.Units.CellUnit
    , trains : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.TrainId Evergreen.V91.Train.Train
    , mail : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.MailId Evergreen.V91.MailEditor.FrontendMail
    , cows : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.AnimalId Evergreen.V91.Animal.Animal
    , cursors : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.UserId Evergreen.V91.Cursor.Cursor
    , users : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.UserId Evergreen.V91.User.FrontendUser
    , inviteTree : Evergreen.V91.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V91.Change.AreTrainsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V91.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V91.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V91.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
