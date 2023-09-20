module Evergreen.V83.Types exposing (..)

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
import Evergreen.V83.Animal
import Evergreen.V83.Audio
import Evergreen.V83.Bounds
import Evergreen.V83.Change
import Evergreen.V83.Color
import Evergreen.V83.Coord
import Evergreen.V83.Cursor
import Evergreen.V83.DisplayName
import Evergreen.V83.EmailAddress
import Evergreen.V83.Grid
import Evergreen.V83.Id
import Evergreen.V83.IdDict
import Evergreen.V83.Keyboard
import Evergreen.V83.LocalGrid
import Evergreen.V83.LocalModel
import Evergreen.V83.MailEditor
import Evergreen.V83.PingData
import Evergreen.V83.Point2d
import Evergreen.V83.Postmark
import Evergreen.V83.Route
import Evergreen.V83.Shaders
import Evergreen.V83.Sound
import Evergreen.V83.TextInput
import Evergreen.V83.Tile
import Evergreen.V83.Tool
import Evergreen.V83.Train
import Evergreen.V83.Ui
import Evergreen.V83.Units
import Evergreen.V83.Untrusted
import Evergreen.V83.User
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
    | KeyMsg Evergreen.V83.Keyboard.Msg
    | KeyDown Evergreen.V83.Keyboard.RawKey
    | WindowResized (Evergreen.V83.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V83.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V83.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V83.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V83.Sound.Sound (Result Evergreen.V83.Audio.LoadError Evergreen.V83.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V83.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V83.LocalModel.LocalModel Evergreen.V83.Change.Change Evergreen.V83.LocalGrid.LocalGrid
    , trains : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.TrainId Evergreen.V83.Train.Train
    , mail : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.MailId Evergreen.V83.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V83.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V83.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V83.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V83.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V83.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V83.Sound.Sound (Result Evergreen.V83.Audio.LoadError Evergreen.V83.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V83.Point2d.Point2d Evergreen.V83.Units.WorldUnit Evergreen.V83.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V83.Id.Id Evergreen.V83.Id.TrainId
        , startViewPoint : Evergreen.V83.Point2d.Point2d Evergreen.V83.Units.WorldUnit Evergreen.V83.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V83.Tile.TileGroup
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
    | MailEditorHover Evergreen.V83.MailEditor.Hover
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
        { tile : Evergreen.V83.Tile.Tile
        , userId : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
        , position : Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit
        , colors : Evergreen.V83.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V83.Id.Id Evergreen.V83.Id.TrainId
        , train : Evergreen.V83.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V83.Id.Id Evergreen.V83.Id.AnimalId
        , cow : Evergreen.V83.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V83.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V83.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V83.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V83.Point2d.Point2d Evergreen.V83.Units.WorldUnit Evergreen.V83.Units.WorldUnit
        , current : Evergreen.V83.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit
    , tile : Evergreen.V83.Tile.Tile
    , colors : Evergreen.V83.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = InviteMenu
    | SettingsMenu Evergreen.V83.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V83.Id.Id Evergreen.V83.Id.UserId)
    , position : Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit
    , linkCopied : Bool
    }


type alias UpdateMeshesData =
    { localModel : Evergreen.V83.LocalModel.LocalModel Evergreen.V83.Change.Change Evergreen.V83.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V83.Keyboard.Key
    , currentTool : Evergreen.V83.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V83.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mailEditor : Maybe Evergreen.V83.MailEditor.Model
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.TrainId Evergreen.V83.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V83.LocalModel.LocalModel Evergreen.V83.Change.Change Evergreen.V83.LocalGrid.LocalGrid
    , trains : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.TrainId Evergreen.V83.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V83.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V83.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V83.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V83.Point2d.Point2d Evergreen.V83.Units.WorldUnit Evergreen.V83.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V83.Keyboard.Key
    , windowSize : Evergreen.V83.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V83.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V83.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V83.Id.Id Evergreen.V83.Id.EventId, Evergreen.V83.Change.LocalChange )
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
            , tile : Evergreen.V83.Tile.Tile
            , position : Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V83.Sound.Sound (Result Evergreen.V83.Audio.LoadError Evergreen.V83.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V83.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V83.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V83.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V83.Tile.TileGroup
    , ui : Evergreen.V83.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V83.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V83.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V83.Id.Id Evergreen.V83.Id.EventId
    , pingData : Maybe Evergreen.V83.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V83.Tile.TileGroup Evergreen.V83.Color.Colors
    , primaryColorTextInput : Evergreen.V83.TextInput.Model
    , secondaryColorTextInput : Evergreen.V83.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V83.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V83.IdDict.IdDict
            Evergreen.V83.Id.UserId
            { position : Evergreen.V83.Point2d.Point2d Evergreen.V83.Units.WorldUnit Evergreen.V83.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.UserId Evergreen.V83.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V83.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V83.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V83.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V83.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showMap : Bool
    , showInviteTree : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V83.Shaders.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V83.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V83.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V83.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V83.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.UserId (List Evergreen.V83.MailEditor.Content)
    , cursor : Maybe Evergreen.V83.Cursor.Cursor
    , handColor : Evergreen.V83.Color.Colors
    , emailAddress : Evergreen.V83.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.UserId ()
    , name : Evergreen.V83.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V83.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V83.Id.Id Evergreen.V83.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V83.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V83.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V83.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V83.Bounds.Bounds Evergreen.V83.Units.CellUnit)
            , userId : Maybe (Evergreen.V83.Id.Id Evergreen.V83.Id.UserId)
            }
    , users : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.TrainId Evergreen.V83.Train.Train
    , cows : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.AnimalId Evergreen.V83.Animal.Animal
    , lastWorldUpdateTrains : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.TrainId Evergreen.V83.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.MailId Evergreen.V83.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V83.Id.SecretId Evergreen.V83.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V83.Id.Id Evergreen.V83.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V83.Id.SecretId Evergreen.V83.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.UserId (List.Nonempty.Nonempty Evergreen.V83.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V83.Change.AreTrainsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V83.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V83.Bounds.Bounds Evergreen.V83.Units.CellUnit) (Maybe Evergreen.V83.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V83.Id.Id Evergreen.V83.Id.EventId, Evergreen.V83.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V83.Bounds.Bounds Evergreen.V83.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V83.Untrusted.Untrusted Evergreen.V83.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V83.Untrusted.Untrusted Evergreen.V83.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V83.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V83.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V83.Id.SecretId Evergreen.V83.Route.InviteToken) (Result Effect.Http.Error Evergreen.V83.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V83.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V83.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V83.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V83.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V83.Grid.GridData
    , userStatus : Evergreen.V83.Change.UserStatus
    , viewBounds : Evergreen.V83.Bounds.Bounds Evergreen.V83.Units.CellUnit
    , trains : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.TrainId Evergreen.V83.Train.Train
    , mail : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.MailId Evergreen.V83.MailEditor.FrontendMail
    , cows : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.AnimalId Evergreen.V83.Animal.Animal
    , cursors : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.UserId Evergreen.V83.Cursor.Cursor
    , users : Evergreen.V83.IdDict.IdDict Evergreen.V83.Id.UserId Evergreen.V83.User.FrontendUser
    , inviteTree : Evergreen.V83.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V83.Change.AreTrainsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V83.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V83.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V83.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V83.Coord.Coord Evergreen.V83.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast