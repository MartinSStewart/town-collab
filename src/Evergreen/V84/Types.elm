module Evergreen.V84.Types exposing (..)

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
import Evergreen.V84.Animal
import Evergreen.V84.Audio
import Evergreen.V84.Bounds
import Evergreen.V84.Change
import Evergreen.V84.Color
import Evergreen.V84.Coord
import Evergreen.V84.Cursor
import Evergreen.V84.DisplayName
import Evergreen.V84.EmailAddress
import Evergreen.V84.Grid
import Evergreen.V84.Id
import Evergreen.V84.IdDict
import Evergreen.V84.Keyboard
import Evergreen.V84.LocalGrid
import Evergreen.V84.LocalModel
import Evergreen.V84.MailEditor
import Evergreen.V84.PingData
import Evergreen.V84.Point2d
import Evergreen.V84.Postmark
import Evergreen.V84.Route
import Evergreen.V84.Shaders
import Evergreen.V84.Sound
import Evergreen.V84.TextInput
import Evergreen.V84.Tile
import Evergreen.V84.Tool
import Evergreen.V84.Train
import Evergreen.V84.Ui
import Evergreen.V84.Units
import Evergreen.V84.Untrusted
import Evergreen.V84.User
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
    | SimplexLookupTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | KeyMsg Evergreen.V84.Keyboard.Msg
    | KeyDown Evergreen.V84.Keyboard.RawKey
    | WindowResized (Evergreen.V84.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V84.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V84.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V84.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V84.Sound.Sound (Result Evergreen.V84.Audio.LoadError Evergreen.V84.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V84.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V84.LocalModel.LocalModel Evergreen.V84.Change.Change Evergreen.V84.LocalGrid.LocalGrid
    , trains : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.TrainId Evergreen.V84.Train.Train
    , mail : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.MailId Evergreen.V84.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V84.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V84.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V84.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V84.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V84.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V84.Sound.Sound (Result Evergreen.V84.Audio.LoadError Evergreen.V84.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V84.Point2d.Point2d Evergreen.V84.Units.WorldUnit Evergreen.V84.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V84.Id.Id Evergreen.V84.Id.TrainId
        , startViewPoint : Evergreen.V84.Point2d.Point2d Evergreen.V84.Units.WorldUnit Evergreen.V84.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V84.Tile.TileGroup
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
    | MailEditorHover Evergreen.V84.MailEditor.Hover
    | YouGotMailButton
    | ShowMapButton
    | AllowEmailNotificationsCheckbox
    | ResetConnectionsButton
    | UsersOnlineButton
    | CopyPositionUrlButton
    | ReportUserButton
    | ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ZoomInButton
    | ZoomOutButton
    | RotateLeftButton
    | RotateRightButton


type Hover
    = TileHover
        { tile : Evergreen.V84.Tile.Tile
        , userId : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
        , position : Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit
        , colors : Evergreen.V84.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V84.Id.Id Evergreen.V84.Id.TrainId
        , train : Evergreen.V84.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V84.Id.Id Evergreen.V84.Id.AnimalId
        , cow : Evergreen.V84.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V84.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V84.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V84.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V84.Point2d.Point2d Evergreen.V84.Units.WorldUnit Evergreen.V84.Units.WorldUnit
        , current : Evergreen.V84.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit
    , tile : Evergreen.V84.Tile.Tile
    , colors : Evergreen.V84.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = InviteMenu
    | SettingsMenu Evergreen.V84.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V84.Id.Id Evergreen.V84.Id.UserId)
    , position : Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit
    , linkCopied : Bool
    }


type alias UpdateMeshesData =
    { localModel : Evergreen.V84.LocalModel.LocalModel Evergreen.V84.Change.Change Evergreen.V84.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V84.Keyboard.Key
    , currentTool : Evergreen.V84.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V84.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mailEditor : Maybe Evergreen.V84.MailEditor.Model
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.TrainId Evergreen.V84.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V84.LocalModel.LocalModel Evergreen.V84.Change.Change Evergreen.V84.LocalGrid.LocalGrid
    , trains : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.TrainId Evergreen.V84.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V84.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V84.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V84.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V84.Point2d.Point2d Evergreen.V84.Units.WorldUnit Evergreen.V84.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V84.Keyboard.Key
    , windowSize : Evergreen.V84.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V84.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V84.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V84.Id.Id Evergreen.V84.Id.EventId, Evergreen.V84.Change.LocalChange )
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
            , tile : Evergreen.V84.Tile.Tile
            , position : Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V84.Sound.Sound (Result Evergreen.V84.Audio.LoadError Evergreen.V84.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V84.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V84.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V84.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V84.Tile.TileGroup
    , ui : Evergreen.V84.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V84.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V84.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V84.Id.Id Evergreen.V84.Id.EventId
    , pingData : Maybe Evergreen.V84.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V84.Tile.TileGroup Evergreen.V84.Color.Colors
    , primaryColorTextInput : Evergreen.V84.TextInput.Model
    , secondaryColorTextInput : Evergreen.V84.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V84.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V84.IdDict.IdDict
            Evergreen.V84.Id.UserId
            { position : Evergreen.V84.Point2d.Point2d Evergreen.V84.Units.WorldUnit Evergreen.V84.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.UserId Evergreen.V84.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V84.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V84.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V84.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V84.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showMap : Bool
    , showInviteTree : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V84.Shaders.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V84.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V84.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V84.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V84.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.UserId (List Evergreen.V84.MailEditor.Content)
    , cursor : Maybe Evergreen.V84.Cursor.Cursor
    , handColor : Evergreen.V84.Color.Colors
    , emailAddress : Evergreen.V84.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.UserId ()
    , name : Evergreen.V84.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V84.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V84.Id.Id Evergreen.V84.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V84.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V84.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V84.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V84.Bounds.Bounds Evergreen.V84.Units.CellUnit)
            , userId : Maybe (Evergreen.V84.Id.Id Evergreen.V84.Id.UserId)
            }
    , users : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.TrainId Evergreen.V84.Train.Train
    , cows : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.AnimalId Evergreen.V84.Animal.Animal
    , lastWorldUpdateTrains : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.TrainId Evergreen.V84.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.MailId Evergreen.V84.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V84.Id.SecretId Evergreen.V84.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V84.Id.Id Evergreen.V84.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V84.Id.SecretId Evergreen.V84.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.UserId (List.Nonempty.Nonempty Evergreen.V84.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V84.Change.AreTrainsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V84.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V84.Bounds.Bounds Evergreen.V84.Units.CellUnit) (Maybe Evergreen.V84.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V84.Id.Id Evergreen.V84.Id.EventId, Evergreen.V84.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V84.Bounds.Bounds Evergreen.V84.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V84.Untrusted.Untrusted Evergreen.V84.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V84.Untrusted.Untrusted Evergreen.V84.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V84.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V84.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V84.Id.SecretId Evergreen.V84.Route.InviteToken) (Result Effect.Http.Error Evergreen.V84.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V84.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V84.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V84.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V84.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V84.Grid.GridData
    , userStatus : Evergreen.V84.Change.UserStatus
    , viewBounds : Evergreen.V84.Bounds.Bounds Evergreen.V84.Units.CellUnit
    , trains : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.TrainId Evergreen.V84.Train.Train
    , mail : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.MailId Evergreen.V84.MailEditor.FrontendMail
    , cows : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.AnimalId Evergreen.V84.Animal.Animal
    , cursors : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.UserId Evergreen.V84.Cursor.Cursor
    , users : Evergreen.V84.IdDict.IdDict Evergreen.V84.Id.UserId Evergreen.V84.User.FrontendUser
    , inviteTree : Evergreen.V84.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V84.Change.AreTrainsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V84.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V84.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V84.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V84.Coord.Coord Evergreen.V84.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
