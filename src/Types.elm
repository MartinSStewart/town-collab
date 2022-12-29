module Types exposing
    ( BackendError(..)
    , BackendModel
    , BackendMsg(..)
    , BackendUserData
    , EmailEvent(..)
    , FrontendLoaded
    , FrontendLoading
    , FrontendModel
    , FrontendModel_(..)
    , FrontendMsg
    , FrontendMsg_(..)
    , Hover(..)
    , LoadingData_
    , LoadingLocalModel(..)
    , MouseButtonState(..)
    , RemovedTileParticle
    , SubmitStatus(..)
    , ToBackend(..)
    , ToFrontend(..)
    , Tool(..)
    , ToolButton(..)
    , UiHover(..)
    , ViewPoint(..)
    )

import AssocList
import Audio
import Bounds exposing (Bounds)
import Browser exposing (UrlRequest)
import Browser.Navigation
import Change exposing (Change, Cow, ServerChange)
import Color exposing (Color, Colors)
import Coord exposing (Coord, RawCellCoord)
import Cursor exposing (CursorMeshes)
import Dict exposing (Dict)
import Duration exposing (Duration)
import EmailAddress exposing (EmailAddress)
import Grid exposing (Grid, GridData)
import Html.Events.Extra.Mouse exposing (Button)
import Html.Events.Extra.Wheel
import Http
import Id exposing (CowId, EventId, Id, MailId, TrainId, UserId)
import IdDict exposing (IdDict)
import Keyboard
import Lamdera exposing (ClientId, SessionId)
import List.Nonempty exposing (Nonempty)
import LocalGrid exposing (Cursor, LocalGrid, UserStatus)
import LocalModel exposing (LocalModel)
import MailEditor exposing (BackendMail, FrontendMail, MailEditorData, Model, ShowMailEditor)
import PingData exposing (PingData)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Postmark exposing (PostmarkSendResponse)
import SendGrid
import Shaders exposing (DebrisVertex, Vertex)
import Sound exposing (Sound)
import TextInput
import Tile exposing (Tile, TileGroup)
import Time
import Train exposing (Train, TrainDiff)
import Units exposing (CellUnit, WorldUnit)
import Untrusted exposing (Untrusted)
import Url exposing (Url)
import UrlHelper exposing (ConfirmEmailKey, LoginToken, UnsubscribeEmailKey)
import WebGL
import WebGL.Texture exposing (Texture)


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Coord Pixels
    , devicePixelRatio : Maybe Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Coord WorldUnit
    , mousePosition : Point2d Pixels Pixels
    , sounds : AssocList.Dict Sound (Result Audio.LoadError Audio.Source)
    , texture : Maybe Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type LoadingLocalModel
    = LoadingLocalModel (List Change)
    | LoadedLocalModel (LocalModel Change LocalGrid) LoadingData_


type ViewPoint
    = NormalViewPoint (Point2d WorldUnit WorldUnit)
    | TrainViewPoint { trainId : Id TrainId, startViewPoint : Point2d WorldUnit WorldUnit, startTime : Time.Posix }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton TileGroup
    | TilePickerToolButton


type Tool
    = HandTool
    | TilePlacerTool { tileGroup : TileGroup, index : Int, mesh : WebGL.Mesh Vertex }
    | TilePickerTool


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : LocalModel Change LocalGrid
    , trains : AssocList.Dict (Id TrainId) Train
    , meshes : Dict RawCellCoord { foreground : WebGL.Mesh Vertex, background : WebGL.Mesh Vertex }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Point2d WorldUnit WorldUnit
    , texture : Texture
    , trainTexture : Maybe Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Coord Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Id EventId, Change.LocalChange )
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , adminEnabled : Bool
    , animationElapsedTime : Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced : Maybe { time : Time.Posix, overwroteTiles : Bool, tile : Tile, position : Coord WorldUnit }
    , sounds : AssocList.Dict Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Id MailId) FrontendMail
    , mailEditor : Model
    , currentTool : Tool
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict String TileGroup
    , toolbarMesh : WebGL.Mesh Vertex
    , loginMesh : WebGL.Mesh Vertex
    , previousTileHover : Maybe TileGroup
    , lastHouseClick : Maybe Time.Posix
    , eventIdCounter : Id EventId
    , pingData : Maybe PingData
    , pingStartTime : Maybe Time.Posix
    , localTime : Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict TileGroup Colors
    , primaryColorTextInput : TextInput.Model
    , secondaryColorTextInput : TextInput.Model
    , focus : Hover
    , music : { startTime : Time.Posix, sound : Sound }
    , previousCursorPositions : IdDict UserId { position : Point2d WorldUnit WorldUnit, time : Time.Posix }
    , handMeshes : AssocList.Dict Colors CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : TextInput.Model
    , pressedSubmitEmail : SubmitStatus EmailAddress
    }


type SubmitStatus a
    = NotSubmitted { pressedSubmit : Bool }
    | Submitting
    | Submitted a


type alias RemovedTileParticle =
    { time : Time.Posix, position : Coord WorldUnit, tile : Tile, colors : Colors }


type MouseButtonState
    = MouseButtonUp { current : Point2d Pixels Pixels }
    | MouseButtonDown
        { start : Point2d Pixels Pixels
        , start_ : Point2d WorldUnit WorldUnit
        , current : Point2d Pixels Pixels
        , hover : Hover
        }


type Hover
    = ToolButtonHover ToolButton
    | ToolbarHover
    | TileHover { tile : Tile, userId : Id UserId, position : Coord WorldUnit, colors : Colors }
    | TrainHover { trainId : Id TrainId, train : Train }
    | MapHover
    | MailEditorHover MailEditor.Hover
    | PrimaryColorInput
    | SecondaryColorInput
    | CowHover { cowId : Id CowId, cow : Cow }
    | UiHover UiHover { position : Coord Pixels }


type UiHover
    = EmailAddressTextInputHover
    | SendEmailButtonHover


type alias BackendModel =
    { grid : Grid
    , userSessions : Dict SessionId { clientIds : Dict ClientId (Bounds CellUnit), userId : Id UserId }
    , users : IdDict UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Id TrainId) Train
    , cows : IdDict CowId Cow
    , lastWorldUpdateTrains : AssocList.Dict (Id TrainId) Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Id MailId) BackendMail
    , pendingLoginTokens : AssocList.Dict LoginToken { requestTime : Time.Posix, userId : Id UserId, requestedBy : SessionId }
    }


type BackendError
    = PostmarkError EmailAddress Http.Error
    | UserNotFoundWhenLoggingIn (Id UserId)


type alias BackendUserData =
    { undoHistory : List (Dict RawCellCoord Int)
    , redoHistory : List (Dict RawCellCoord Int)
    , undoCurrent : Dict RawCellCoord Int
    , mailEditor : MailEditorData
    , cursor : Maybe Cursor
    , handColor : Colors
    , emailAddress : EmailAddress
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type FrontendMsg_
    = UrlClicked UrlRequest
    | UrlChanged Url
    | NoOpFrontendMsg
    | TextureLoaded (Result WebGL.Texture.Error Texture)
    | TrainTextureLoaded (Result WebGL.Texture.Error Texture)
    | KeyMsg Keyboard.Msg
    | KeyDown Keyboard.RawKey
    | WindowResized (Coord Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Button (Point2d Pixels Pixels)
    | MouseUp Button (Point2d Pixels Pixels)
    | MouseMove (Point2d Pixels Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Time.Posix
    | SoundLoaded Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgent String


type ToBackend
    = ConnectToBackend (Bounds CellUnit) (Maybe LoginToken)
    | GridChange (Nonempty ( Id EventId, Change.LocalChange ))
    | ChangeViewBounds (Bounds CellUnit)
    | MailEditorToBackend MailEditor.ToBackend
    | TeleportHomeTrainRequest (Id TrainId) Time.Posix
    | CancelTeleportHomeTrainRequest (Id TrainId)
    | LeaveHomeTrainRequest (Id TrainId)
    | PingRequest
    | SendLoginEmailRequest (Untrusted EmailAddress)


type BackendMsg
    = UserDisconnected SessionId ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Time.Posix EmailAddress (Result Http.Error PostmarkSendResponse)
    | UpdateFromFrontend SessionId ClientId ToBackend Time.Posix
    | WorldUpdateTimeElapsed Time.Posix


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (Nonempty Change)
    | UnsubscribeEmailConfirmed
    | WorldUpdateBroadcast (AssocList.Dict (Id TrainId) TrainDiff)
    | MailEditorToFrontend MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Id MailId) FrontendMail)
    | PingResponse Time.Posix
    | SendLoginEmailResponse EmailAddress


type EmailEvent
    = UnsubscribeEmail UnsubscribeEmailKey


type alias LoadingData_ =
    { grid : GridData
    , userStatus : UserStatus
    , viewBounds : Bounds CellUnit
    , trains : AssocList.Dict (Id TrainId) Train
    , mail : AssocList.Dict (Id MailId) FrontendMail
    , cows : IdDict CowId Cow
    , cursors : IdDict UserId Cursor
    , handColors : IdDict UserId Colors
    }
