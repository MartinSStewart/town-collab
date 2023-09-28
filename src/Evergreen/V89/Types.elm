module Evergreen.V89.Types exposing (..)

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
import Evergreen.V89.AdminPage
import Evergreen.V89.Animal
import Evergreen.V89.Audio
import Evergreen.V89.Bounds
import Evergreen.V89.Change
import Evergreen.V89.Color
import Evergreen.V89.Coord
import Evergreen.V89.Cursor
import Evergreen.V89.DisplayName
import Evergreen.V89.EmailAddress
import Evergreen.V89.Grid
import Evergreen.V89.Id
import Evergreen.V89.IdDict
import Evergreen.V89.Keyboard
import Evergreen.V89.LocalGrid
import Evergreen.V89.LocalModel
import Evergreen.V89.MailEditor
import Evergreen.V89.PingData
import Evergreen.V89.Point2d
import Evergreen.V89.Postmark
import Evergreen.V89.Route
import Evergreen.V89.Shaders
import Evergreen.V89.Sound
import Evergreen.V89.TextInput
import Evergreen.V89.Tile
import Evergreen.V89.Tool
import Evergreen.V89.Train
import Evergreen.V89.Ui
import Evergreen.V89.Units
import Evergreen.V89.Untrusted
import Evergreen.V89.User
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
    | KeyMsg Evergreen.V89.Keyboard.Msg
    | KeyDown Evergreen.V89.Keyboard.RawKey
    | WindowResized (Evergreen.V89.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V89.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V89.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V89.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V89.Sound.Sound (Result Evergreen.V89.Audio.LoadError Evergreen.V89.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V89.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V89.LocalModel.LocalModel Evergreen.V89.Change.Change Evergreen.V89.LocalGrid.LocalGrid
    , trains : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.TrainId Evergreen.V89.Train.Train
    , mail : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.MailId Evergreen.V89.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V89.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V89.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V89.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V89.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V89.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V89.Sound.Sound (Result Evergreen.V89.Audio.LoadError Evergreen.V89.Audio.Source)
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
    = NormalViewPoint (Evergreen.V89.Point2d.Point2d Evergreen.V89.Units.WorldUnit Evergreen.V89.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V89.Id.Id Evergreen.V89.Id.TrainId
        , startViewPoint : Evergreen.V89.Point2d.Point2d Evergreen.V89.Units.WorldUnit Evergreen.V89.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V89.Tile.TileGroup
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
    | MailEditorHover Evergreen.V89.MailEditor.Hover
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
    | AdminHover Evergreen.V89.AdminPage.Hover


type Hover
    = TileHover
        { tile : Evergreen.V89.Tile.Tile
        , userId : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
        , position : Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit
        , colors : Evergreen.V89.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V89.Id.Id Evergreen.V89.Id.TrainId
        , train : Evergreen.V89.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V89.Id.Id Evergreen.V89.Id.AnimalId
        , cow : Evergreen.V89.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V89.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V89.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V89.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V89.Point2d.Point2d Evergreen.V89.Units.WorldUnit Evergreen.V89.Units.WorldUnit
        , current : Evergreen.V89.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit
    , tile : Evergreen.V89.Tile.Tile
    , colors : Evergreen.V89.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = InviteMenu
    | SettingsMenu Evergreen.V89.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V89.Id.Id Evergreen.V89.Id.UserId)
    , position : Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    }


type Page
    = MailPage Evergreen.V89.MailEditor.Model
    | AdminPage Evergreen.V89.AdminPage.Model
    | WorldPage WorldPage2


type alias UpdateMeshesData =
    { localModel : Evergreen.V89.LocalModel.LocalModel Evergreen.V89.Change.Change Evergreen.V89.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V89.Keyboard.Key
    , currentTool : Evergreen.V89.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V89.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.TrainId Evergreen.V89.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V89.LocalModel.LocalModel Evergreen.V89.Change.Change Evergreen.V89.LocalGrid.LocalGrid
    , trains : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.TrainId Evergreen.V89.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V89.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V89.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V89.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V89.Point2d.Point2d Evergreen.V89.Units.WorldUnit Evergreen.V89.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V89.Keyboard.Key
    , windowSize : Evergreen.V89.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V89.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V89.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V89.Id.Id Evergreen.V89.Id.EventId, Evergreen.V89.Change.LocalChange )
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
            , tile : Evergreen.V89.Tile.Tile
            , position : Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V89.Sound.Sound (Result Evergreen.V89.Audio.LoadError Evergreen.V89.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V89.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V89.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V89.Tile.TileGroup
    , ui : Evergreen.V89.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V89.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V89.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V89.Id.Id Evergreen.V89.Id.EventId
    , pingData : Maybe Evergreen.V89.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V89.Tile.TileGroup Evergreen.V89.Color.Colors
    , primaryColorTextInput : Evergreen.V89.TextInput.Model
    , secondaryColorTextInput : Evergreen.V89.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V89.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V89.IdDict.IdDict
            Evergreen.V89.Id.UserId
            { position : Evergreen.V89.Point2d.Point2d Evergreen.V89.Units.WorldUnit Evergreen.V89.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.UserId Evergreen.V89.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V89.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V89.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V89.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V89.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showInviteTree : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V89.Shaders.Vertex
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
    Evergreen.V89.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V89.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V89.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V89.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.UserId (List Evergreen.V89.MailEditor.Content)
    , cursor : Maybe Evergreen.V89.Cursor.Cursor
    , handColor : Evergreen.V89.Color.Colors
    , emailAddress : Evergreen.V89.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.UserId ()
    , name : Evergreen.V89.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    , timeOfDay : Evergreen.V89.Change.TimeOfDay
    }


type BackendError
    = PostmarkError Evergreen.V89.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V89.Id.Id Evergreen.V89.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V89.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V89.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V89.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V89.Bounds.Bounds Evergreen.V89.Units.CellUnit)
            , userId : Maybe (Evergreen.V89.Id.Id Evergreen.V89.Id.UserId)
            }
    , users : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.TrainId Evergreen.V89.Train.Train
    , cows : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.AnimalId Evergreen.V89.Animal.Animal
    , lastWorldUpdateTrains : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.TrainId Evergreen.V89.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.MailId Evergreen.V89.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V89.Id.SecretId Evergreen.V89.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V89.Id.Id Evergreen.V89.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V89.Id.SecretId Evergreen.V89.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.UserId (List.Nonempty.Nonempty Evergreen.V89.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V89.Change.AreTrainsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V89.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V89.Bounds.Bounds Evergreen.V89.Units.CellUnit) (Maybe Evergreen.V89.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V89.Id.Id Evergreen.V89.Id.EventId, Evergreen.V89.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V89.Bounds.Bounds Evergreen.V89.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V89.Untrusted.Untrusted Evergreen.V89.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V89.Untrusted.Untrusted Evergreen.V89.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V89.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V89.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V89.Id.SecretId Evergreen.V89.Route.InviteToken) (Result Effect.Http.Error Evergreen.V89.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V89.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V89.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V89.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V89.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V89.Grid.GridData
    , userStatus : Evergreen.V89.Change.UserStatus
    , viewBounds : Evergreen.V89.Bounds.Bounds Evergreen.V89.Units.CellUnit
    , trains : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.TrainId Evergreen.V89.Train.Train
    , mail : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.MailId Evergreen.V89.MailEditor.FrontendMail
    , cows : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.AnimalId Evergreen.V89.Animal.Animal
    , cursors : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.UserId Evergreen.V89.Cursor.Cursor
    , users : Evergreen.V89.IdDict.IdDict Evergreen.V89.Id.UserId Evergreen.V89.User.FrontendUser
    , inviteTree : Evergreen.V89.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V89.Change.AreTrainsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V89.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V89.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V89.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V89.Coord.Coord Evergreen.V89.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
