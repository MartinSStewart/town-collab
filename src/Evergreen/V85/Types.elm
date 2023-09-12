module Evergreen.V85.Types exposing (..)

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
import Evergreen.V85.Animal
import Evergreen.V85.Audio
import Evergreen.V85.Bounds
import Evergreen.V85.Change
import Evergreen.V85.Color
import Evergreen.V85.Coord
import Evergreen.V85.Cursor
import Evergreen.V85.DisplayName
import Evergreen.V85.EmailAddress
import Evergreen.V85.Grid
import Evergreen.V85.Id
import Evergreen.V85.IdDict
import Evergreen.V85.Keyboard
import Evergreen.V85.LocalGrid
import Evergreen.V85.LocalModel
import Evergreen.V85.MailEditor
import Evergreen.V85.PingData
import Evergreen.V85.Point2d
import Evergreen.V85.Postmark
import Evergreen.V85.Route
import Evergreen.V85.Shaders
import Evergreen.V85.Sound
import Evergreen.V85.TextInput
import Evergreen.V85.Tile
import Evergreen.V85.Tool
import Evergreen.V85.Train
import Evergreen.V85.Ui
import Evergreen.V85.Units
import Evergreen.V85.Untrusted
import Evergreen.V85.User
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
    | KeyMsg Evergreen.V85.Keyboard.Msg
    | KeyDown Evergreen.V85.Keyboard.RawKey
    | WindowResized (Evergreen.V85.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V85.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V85.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V85.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V85.Sound.Sound (Result Evergreen.V85.Audio.LoadError Evergreen.V85.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V85.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V85.LocalModel.LocalModel Evergreen.V85.Change.Change Evergreen.V85.LocalGrid.LocalGrid
    , trains : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.TrainId Evergreen.V85.Train.Train
    , mail : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.MailId Evergreen.V85.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V85.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V85.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V85.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V85.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V85.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V85.Sound.Sound (Result Evergreen.V85.Audio.LoadError Evergreen.V85.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V85.Point2d.Point2d Evergreen.V85.Units.WorldUnit Evergreen.V85.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V85.Id.Id Evergreen.V85.Id.TrainId
        , startViewPoint : Evergreen.V85.Point2d.Point2d Evergreen.V85.Units.WorldUnit Evergreen.V85.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V85.Tile.TileGroup
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
    | MailEditorHover Evergreen.V85.MailEditor.Hover
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
        { tile : Evergreen.V85.Tile.Tile
        , userId : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
        , position : Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit
        , colors : Evergreen.V85.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V85.Id.Id Evergreen.V85.Id.TrainId
        , train : Evergreen.V85.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V85.Id.Id Evergreen.V85.Id.AnimalId
        , cow : Evergreen.V85.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V85.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V85.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V85.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V85.Point2d.Point2d Evergreen.V85.Units.WorldUnit Evergreen.V85.Units.WorldUnit
        , current : Evergreen.V85.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit
    , tile : Evergreen.V85.Tile.Tile
    , colors : Evergreen.V85.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = InviteMenu
    | SettingsMenu Evergreen.V85.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V85.Id.Id Evergreen.V85.Id.UserId)
    , position : Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit
    , linkCopied : Bool
    }


type alias UpdateMeshesData =
    { localModel : Evergreen.V85.LocalModel.LocalModel Evergreen.V85.Change.Change Evergreen.V85.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V85.Keyboard.Key
    , currentTool : Evergreen.V85.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V85.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mailEditor : Maybe Evergreen.V85.MailEditor.Model
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.TrainId Evergreen.V85.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V85.LocalModel.LocalModel Evergreen.V85.Change.Change Evergreen.V85.LocalGrid.LocalGrid
    , trains : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.TrainId Evergreen.V85.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V85.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V85.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V85.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V85.Point2d.Point2d Evergreen.V85.Units.WorldUnit Evergreen.V85.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V85.Keyboard.Key
    , windowSize : Evergreen.V85.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V85.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V85.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V85.Id.Id Evergreen.V85.Id.EventId, Evergreen.V85.Change.LocalChange )
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
            , tile : Evergreen.V85.Tile.Tile
            , position : Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V85.Sound.Sound (Result Evergreen.V85.Audio.LoadError Evergreen.V85.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V85.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V85.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V85.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V85.Tile.TileGroup
    , ui : Evergreen.V85.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V85.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V85.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V85.Id.Id Evergreen.V85.Id.EventId
    , pingData : Maybe Evergreen.V85.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V85.Tile.TileGroup Evergreen.V85.Color.Colors
    , primaryColorTextInput : Evergreen.V85.TextInput.Model
    , secondaryColorTextInput : Evergreen.V85.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V85.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V85.IdDict.IdDict
            Evergreen.V85.Id.UserId
            { position : Evergreen.V85.Point2d.Point2d Evergreen.V85.Units.WorldUnit Evergreen.V85.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.UserId Evergreen.V85.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V85.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V85.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V85.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V85.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showMap : Bool
    , showInviteTree : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V85.Shaders.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V85.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V85.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V85.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V85.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.UserId (List Evergreen.V85.MailEditor.Content)
    , cursor : Maybe Evergreen.V85.Cursor.Cursor
    , handColor : Evergreen.V85.Color.Colors
    , emailAddress : Evergreen.V85.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.UserId ()
    , name : Evergreen.V85.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V85.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V85.Id.Id Evergreen.V85.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V85.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V85.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V85.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V85.Bounds.Bounds Evergreen.V85.Units.CellUnit)
            , userId : Maybe (Evergreen.V85.Id.Id Evergreen.V85.Id.UserId)
            }
    , users : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.TrainId Evergreen.V85.Train.Train
    , cows : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.AnimalId Evergreen.V85.Animal.Animal
    , lastWorldUpdateTrains : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.TrainId Evergreen.V85.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.MailId Evergreen.V85.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V85.Id.SecretId Evergreen.V85.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V85.Id.Id Evergreen.V85.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V85.Id.SecretId Evergreen.V85.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.UserId (List.Nonempty.Nonempty Evergreen.V85.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V85.Change.AreTrainsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V85.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V85.Bounds.Bounds Evergreen.V85.Units.CellUnit) (Maybe Evergreen.V85.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V85.Id.Id Evergreen.V85.Id.EventId, Evergreen.V85.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V85.Bounds.Bounds Evergreen.V85.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V85.Untrusted.Untrusted Evergreen.V85.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V85.Untrusted.Untrusted Evergreen.V85.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V85.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V85.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V85.Id.SecretId Evergreen.V85.Route.InviteToken) (Result Effect.Http.Error Evergreen.V85.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V85.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V85.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V85.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V85.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V85.Grid.GridData
    , userStatus : Evergreen.V85.Change.UserStatus
    , viewBounds : Evergreen.V85.Bounds.Bounds Evergreen.V85.Units.CellUnit
    , trains : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.TrainId Evergreen.V85.Train.Train
    , mail : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.MailId Evergreen.V85.MailEditor.FrontendMail
    , cows : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.AnimalId Evergreen.V85.Animal.Animal
    , cursors : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.UserId Evergreen.V85.Cursor.Cursor
    , users : Evergreen.V85.IdDict.IdDict Evergreen.V85.Id.UserId Evergreen.V85.User.FrontendUser
    , inviteTree : Evergreen.V85.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V85.Change.AreTrainsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V85.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V85.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V85.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V85.Coord.Coord Evergreen.V85.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
