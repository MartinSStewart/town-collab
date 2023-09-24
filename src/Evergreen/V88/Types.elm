module Evergreen.V88.Types exposing (..)

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
import Evergreen.V88.AdminPage
import Evergreen.V88.Animal
import Evergreen.V88.Audio
import Evergreen.V88.Bounds
import Evergreen.V88.Change
import Evergreen.V88.Color
import Evergreen.V88.Coord
import Evergreen.V88.Cursor
import Evergreen.V88.DisplayName
import Evergreen.V88.EmailAddress
import Evergreen.V88.Grid
import Evergreen.V88.Id
import Evergreen.V88.IdDict
import Evergreen.V88.Keyboard
import Evergreen.V88.LocalGrid
import Evergreen.V88.LocalModel
import Evergreen.V88.MailEditor
import Evergreen.V88.PingData
import Evergreen.V88.Point2d
import Evergreen.V88.Postmark
import Evergreen.V88.Route
import Evergreen.V88.Shaders
import Evergreen.V88.Sound
import Evergreen.V88.TextInput
import Evergreen.V88.Tile
import Evergreen.V88.Tool
import Evergreen.V88.Train
import Evergreen.V88.Ui
import Evergreen.V88.Units
import Evergreen.V88.Untrusted
import Evergreen.V88.User
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
    | KeyMsg Evergreen.V88.Keyboard.Msg
    | KeyDown Evergreen.V88.Keyboard.RawKey
    | WindowResized (Evergreen.V88.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V88.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V88.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V88.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V88.Sound.Sound (Result Evergreen.V88.Audio.LoadError Evergreen.V88.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V88.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V88.LocalModel.LocalModel Evergreen.V88.Change.Change Evergreen.V88.LocalGrid.LocalGrid
    , trains : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.TrainId Evergreen.V88.Train.Train
    , mail : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.MailId Evergreen.V88.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V88.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V88.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V88.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V88.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V88.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V88.Sound.Sound (Result Evergreen.V88.Audio.LoadError Evergreen.V88.Audio.Source)
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
    = NormalViewPoint (Evergreen.V88.Point2d.Point2d Evergreen.V88.Units.WorldUnit Evergreen.V88.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V88.Id.Id Evergreen.V88.Id.TrainId
        , startViewPoint : Evergreen.V88.Point2d.Point2d Evergreen.V88.Units.WorldUnit Evergreen.V88.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V88.Tile.TileGroup
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
    | MailEditorHover Evergreen.V88.MailEditor.Hover
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
    | AdminHover Evergreen.V88.AdminPage.Hover


type Hover
    = TileHover
        { tile : Evergreen.V88.Tile.Tile
        , userId : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
        , position : Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit
        , colors : Evergreen.V88.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V88.Id.Id Evergreen.V88.Id.TrainId
        , train : Evergreen.V88.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V88.Id.Id Evergreen.V88.Id.AnimalId
        , cow : Evergreen.V88.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V88.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V88.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V88.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V88.Point2d.Point2d Evergreen.V88.Units.WorldUnit Evergreen.V88.Units.WorldUnit
        , current : Evergreen.V88.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit
    , tile : Evergreen.V88.Tile.Tile
    , colors : Evergreen.V88.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = InviteMenu
    | SettingsMenu Evergreen.V88.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V88.Id.Id Evergreen.V88.Id.UserId)
    , position : Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    }


type Page
    = MailPage Evergreen.V88.MailEditor.Model
    | AdminPage Evergreen.V88.AdminPage.Model
    | WorldPage WorldPage2


type alias UpdateMeshesData =
    { localModel : Evergreen.V88.LocalModel.LocalModel Evergreen.V88.Change.Change Evergreen.V88.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V88.Keyboard.Key
    , currentTool : Evergreen.V88.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V88.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.TrainId Evergreen.V88.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V88.LocalModel.LocalModel Evergreen.V88.Change.Change Evergreen.V88.LocalGrid.LocalGrid
    , trains : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.TrainId Evergreen.V88.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V88.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V88.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V88.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V88.Point2d.Point2d Evergreen.V88.Units.WorldUnit Evergreen.V88.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V88.Keyboard.Key
    , windowSize : Evergreen.V88.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V88.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V88.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V88.Id.Id Evergreen.V88.Id.EventId, Evergreen.V88.Change.LocalChange )
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
            , tile : Evergreen.V88.Tile.Tile
            , position : Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V88.Sound.Sound (Result Evergreen.V88.Audio.LoadError Evergreen.V88.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V88.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V88.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V88.Tile.TileGroup
    , ui : Evergreen.V88.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V88.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V88.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V88.Id.Id Evergreen.V88.Id.EventId
    , pingData : Maybe Evergreen.V88.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V88.Tile.TileGroup Evergreen.V88.Color.Colors
    , primaryColorTextInput : Evergreen.V88.TextInput.Model
    , secondaryColorTextInput : Evergreen.V88.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V88.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V88.IdDict.IdDict
            Evergreen.V88.Id.UserId
            { position : Evergreen.V88.Point2d.Point2d Evergreen.V88.Units.WorldUnit Evergreen.V88.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.UserId Evergreen.V88.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V88.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V88.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V88.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V88.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showInviteTree : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V88.Shaders.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V88.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V88.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V88.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V88.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.UserId (List Evergreen.V88.MailEditor.Content)
    , cursor : Maybe Evergreen.V88.Cursor.Cursor
    , handColor : Evergreen.V88.Color.Colors
    , emailAddress : Evergreen.V88.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.UserId ()
    , name : Evergreen.V88.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    , timeOfDay : Evergreen.V88.Change.TimeOfDay
    }


type BackendError
    = PostmarkError Evergreen.V88.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V88.Id.Id Evergreen.V88.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V88.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V88.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V88.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V88.Bounds.Bounds Evergreen.V88.Units.CellUnit)
            , userId : Maybe (Evergreen.V88.Id.Id Evergreen.V88.Id.UserId)
            }
    , users : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.TrainId Evergreen.V88.Train.Train
    , cows : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.AnimalId Evergreen.V88.Animal.Animal
    , lastWorldUpdateTrains : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.TrainId Evergreen.V88.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.MailId Evergreen.V88.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V88.Id.SecretId Evergreen.V88.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V88.Id.Id Evergreen.V88.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V88.Id.SecretId Evergreen.V88.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.UserId (List.Nonempty.Nonempty Evergreen.V88.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V88.Change.AreTrainsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V88.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V88.Bounds.Bounds Evergreen.V88.Units.CellUnit) (Maybe Evergreen.V88.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V88.Id.Id Evergreen.V88.Id.EventId, Evergreen.V88.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V88.Bounds.Bounds Evergreen.V88.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V88.Untrusted.Untrusted Evergreen.V88.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V88.Untrusted.Untrusted Evergreen.V88.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V88.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V88.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V88.Id.SecretId Evergreen.V88.Route.InviteToken) (Result Effect.Http.Error Evergreen.V88.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V88.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V88.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V88.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V88.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V88.Grid.GridData
    , userStatus : Evergreen.V88.Change.UserStatus
    , viewBounds : Evergreen.V88.Bounds.Bounds Evergreen.V88.Units.CellUnit
    , trains : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.TrainId Evergreen.V88.Train.Train
    , mail : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.MailId Evergreen.V88.MailEditor.FrontendMail
    , cows : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.AnimalId Evergreen.V88.Animal.Animal
    , cursors : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.UserId Evergreen.V88.Cursor.Cursor
    , users : Evergreen.V88.IdDict.IdDict Evergreen.V88.Id.UserId Evergreen.V88.User.FrontendUser
    , inviteTree : Evergreen.V88.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V88.Change.AreTrainsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V88.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V88.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V88.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V88.Coord.Coord Evergreen.V88.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
