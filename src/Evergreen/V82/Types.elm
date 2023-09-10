module Evergreen.V82.Types exposing (..)

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
import Evergreen.V82.Animal
import Evergreen.V82.Audio
import Evergreen.V82.Bounds
import Evergreen.V82.Change
import Evergreen.V82.Color
import Evergreen.V82.Coord
import Evergreen.V82.Cursor
import Evergreen.V82.DisplayName
import Evergreen.V82.EmailAddress
import Evergreen.V82.Grid
import Evergreen.V82.Id
import Evergreen.V82.IdDict
import Evergreen.V82.Keyboard
import Evergreen.V82.LocalGrid
import Evergreen.V82.LocalModel
import Evergreen.V82.MailEditor
import Evergreen.V82.PingData
import Evergreen.V82.Point2d
import Evergreen.V82.Postmark
import Evergreen.V82.Route
import Evergreen.V82.Shaders
import Evergreen.V82.Sound
import Evergreen.V82.TextInput
import Evergreen.V82.Tile
import Evergreen.V82.Tool
import Evergreen.V82.Train
import Evergreen.V82.Ui
import Evergreen.V82.Units
import Evergreen.V82.Untrusted
import Evergreen.V82.User
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
    | KeyMsg Evergreen.V82.Keyboard.Msg
    | KeyDown Evergreen.V82.Keyboard.RawKey
    | WindowResized (Evergreen.V82.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V82.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V82.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V82.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V82.Sound.Sound (Result Evergreen.V82.Audio.LoadError Evergreen.V82.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V82.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V82.LocalModel.LocalModel Evergreen.V82.Change.Change Evergreen.V82.LocalGrid.LocalGrid
    , trains : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.TrainId Evergreen.V82.Train.Train
    , mail : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.MailId Evergreen.V82.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V82.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V82.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V82.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V82.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V82.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V82.Sound.Sound (Result Evergreen.V82.Audio.LoadError Evergreen.V82.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V82.Point2d.Point2d Evergreen.V82.Units.WorldUnit Evergreen.V82.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V82.Id.Id Evergreen.V82.Id.TrainId
        , startViewPoint : Evergreen.V82.Point2d.Point2d Evergreen.V82.Units.WorldUnit Evergreen.V82.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V82.Tile.TileGroup
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
    | MailEditorHover Evergreen.V82.MailEditor.Hover
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
        { tile : Evergreen.V82.Tile.Tile
        , userId : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
        , position : Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit
        , colors : Evergreen.V82.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V82.Id.Id Evergreen.V82.Id.TrainId
        , train : Evergreen.V82.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V82.Id.Id Evergreen.V82.Id.AnimalId
        , cow : Evergreen.V82.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V82.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V82.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V82.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V82.Point2d.Point2d Evergreen.V82.Units.WorldUnit Evergreen.V82.Units.WorldUnit
        , current : Evergreen.V82.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit
    , tile : Evergreen.V82.Tile.Tile
    , colors : Evergreen.V82.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = InviteMenu
    | SettingsMenu Evergreen.V82.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V82.Id.Id Evergreen.V82.Id.UserId)
    , position : Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit
    , linkCopied : Bool
    }


type alias UpdateMeshesData =
    { localModel : Evergreen.V82.LocalModel.LocalModel Evergreen.V82.Change.Change Evergreen.V82.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V82.Keyboard.Key
    , currentTool : Evergreen.V82.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V82.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mailEditor : Maybe Evergreen.V82.MailEditor.Model
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.TrainId Evergreen.V82.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V82.LocalModel.LocalModel Evergreen.V82.Change.Change Evergreen.V82.LocalGrid.LocalGrid
    , trains : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.TrainId Evergreen.V82.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V82.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V82.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V82.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V82.Point2d.Point2d Evergreen.V82.Units.WorldUnit Evergreen.V82.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V82.Keyboard.Key
    , windowSize : Evergreen.V82.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V82.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V82.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V82.Id.Id Evergreen.V82.Id.EventId, Evergreen.V82.Change.LocalChange )
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
            , tile : Evergreen.V82.Tile.Tile
            , position : Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V82.Sound.Sound (Result Evergreen.V82.Audio.LoadError Evergreen.V82.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V82.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V82.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V82.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V82.Tile.TileGroup
    , ui : Evergreen.V82.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V82.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V82.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V82.Id.Id Evergreen.V82.Id.EventId
    , pingData : Maybe Evergreen.V82.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V82.Tile.TileGroup Evergreen.V82.Color.Colors
    , primaryColorTextInput : Evergreen.V82.TextInput.Model
    , secondaryColorTextInput : Evergreen.V82.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V82.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V82.IdDict.IdDict
            Evergreen.V82.Id.UserId
            { position : Evergreen.V82.Point2d.Point2d Evergreen.V82.Units.WorldUnit Evergreen.V82.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.UserId Evergreen.V82.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V82.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V82.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V82.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V82.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showMap : Bool
    , showInviteTree : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V82.Shaders.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V82.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V82.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V82.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V82.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.UserId (List Evergreen.V82.MailEditor.Content)
    , cursor : Maybe Evergreen.V82.Cursor.Cursor
    , handColor : Evergreen.V82.Color.Colors
    , emailAddress : Evergreen.V82.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.UserId ()
    , name : Evergreen.V82.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V82.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V82.Id.Id Evergreen.V82.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V82.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V82.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V82.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V82.Bounds.Bounds Evergreen.V82.Units.CellUnit)
            , userId : Maybe (Evergreen.V82.Id.Id Evergreen.V82.Id.UserId)
            }
    , users : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.TrainId Evergreen.V82.Train.Train
    , cows : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.AnimalId Evergreen.V82.Animal.Animal
    , lastWorldUpdateTrains : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.TrainId Evergreen.V82.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.MailId Evergreen.V82.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V82.Id.SecretId Evergreen.V82.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V82.Id.Id Evergreen.V82.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V82.Id.SecretId Evergreen.V82.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.UserId (List.Nonempty.Nonempty Evergreen.V82.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V82.Change.AreTrainsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V82.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V82.Bounds.Bounds Evergreen.V82.Units.CellUnit) (Maybe Evergreen.V82.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V82.Id.Id Evergreen.V82.Id.EventId, Evergreen.V82.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V82.Bounds.Bounds Evergreen.V82.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V82.Untrusted.Untrusted Evergreen.V82.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V82.Untrusted.Untrusted Evergreen.V82.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V82.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V82.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V82.Id.SecretId Evergreen.V82.Route.InviteToken) (Result Effect.Http.Error Evergreen.V82.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V82.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V82.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V82.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V82.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V82.Grid.GridData
    , userStatus : Evergreen.V82.Change.UserStatus
    , viewBounds : Evergreen.V82.Bounds.Bounds Evergreen.V82.Units.CellUnit
    , trains : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.TrainId Evergreen.V82.Train.Train
    , mail : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.MailId Evergreen.V82.MailEditor.FrontendMail
    , cows : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.AnimalId Evergreen.V82.Animal.Animal
    , cursors : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.UserId Evergreen.V82.Cursor.Cursor
    , users : Evergreen.V82.IdDict.IdDict Evergreen.V82.Id.UserId Evergreen.V82.User.FrontendUser
    , inviteTree : Evergreen.V82.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V82.Change.AreTrainsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V82.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V82.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V82.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V82.Coord.Coord Evergreen.V82.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
