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
    , LoadingData_
    , MouseButtonState(..)
    , RemovedTileParticle
    , ToBackend(..)
    , ToFrontend(..)
    , ToolType(..)
    )

import AssocList
import Audio
import Bounds exposing (Bounds)
import Browser exposing (UrlRequest)
import Browser.Events exposing (Visibility)
import Browser.Navigation
import Change exposing (Change, ServerChange)
import Coord exposing (Coord, RawCellCoord)
import Dict exposing (Dict)
import Duration exposing (Duration)
import EmailAddress exposing (EmailAddress)
import EverySet exposing (EverySet)
import Grid exposing (Grid, GridData)
import Html.Events.Extra.Mouse exposing (Button)
import Html.Events.Extra.Wheel
import Id exposing (Id, MailId, TrainId, UserId)
import Keyboard
import Lamdera exposing (ClientId, SessionId)
import List.Nonempty exposing (Nonempty)
import LocalGrid exposing (LocalGrid)
import LocalModel exposing (LocalModel)
import MailEditor exposing (BackendMail, FrontendMail, MailEditorData, Model, ShowMailEditor)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import SendGrid
import Shaders exposing (DebrisVertex, Vertex)
import Sound exposing (Sound)
import Tile exposing (Tile)
import Time
import Train exposing (Train)
import Units exposing (CellUnit, WorldUnit)
import Url exposing (Url)
import UrlHelper exposing (ConfirmEmailKey, UnsubscribeEmailKey)
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
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Coord WorldUnit
    , mousePosition : Point2d Pixels Pixels
    , sounds : AssocList.Dict Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : LocalModel Change LocalGrid
    , trains : AssocList.Dict (Id TrainId) Train
    , meshes : Dict RawCellCoord { foreground : WebGL.Mesh Vertex, background : WebGL.Mesh Vertex }
    , viewPoint : Point2d WorldUnit WorldUnit
    , viewPointLastInterval : Point2d WorldUnit WorldUnit
    , texture : Maybe Texture
    , trainTexture : Maybe Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Coord Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Point2d Pixels Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List Change.LocalChange
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Id UserId)
    , highlightContextMenu : Maybe { userId : Id UserId, hidePoint : Coord WorldUnit }
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
    , currentTile : Maybe { tile : Tile, mesh : WebGL.Mesh Vertex }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Vertex
    , lastPlacementError : Maybe Time.Posix
    }


type alias RemovedTileParticle =
    { time : Time.Posix, position : Coord WorldUnit, tile : Tile }


type ToolType
    = DragTool


type MouseButtonState
    = MouseButtonUp { current : Point2d Pixels Pixels }
    | MouseButtonDown
        { start : Point2d Pixels Pixels
        , start_ : Point2d WorldUnit WorldUnit
        , current : Point2d Pixels Pixels
        }


type alias BackendModel =
    { grid : Grid
    , userSessions : Dict SessionId { clientIds : Dict ClientId (Bounds CellUnit), userId : Id UserId }
    , users :
        -- Key is Id UserId
        Dict Int BackendUserData
    , usersHiddenRecently : List { reporter : Id UserId, hiddenUser : Id UserId, hidePoint : Coord WorldUnit }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Id TrainId) Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Id MailId) BackendMail
    }


type BackendError
    = SendGridError EmailAddress SendGrid.Error


type alias BackendUserData =
    { hiddenUsers : EverySet (Id UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict RawCellCoord Int)
    , redoHistory : List (Dict RawCellCoord Int)
    , undoCurrent : Dict RawCellCoord Int
    , mailEditor : MailEditorData
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
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Id UserId)
    | UserTagMouseEntered (Id UserId)
    | UserTagMouseExited (Id UserId)
    | HideForAllTogglePressed (Id UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed { userId : Id UserId, hidePoint : Coord WorldUnit }
    | AnimationFrame Time.Posix
    | SoundLoaded Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged


type ToBackend
    = ConnectToBackend (Bounds CellUnit)
    | GridChange (Nonempty Change.LocalChange)
    | ChangeViewBounds (Bounds CellUnit)
    | MailEditorToBackend MailEditor.ToBackend


type BackendMsg
    = UserDisconnected SessionId ClientId
    | NotifyAdminTimeElapsed Time.Posix
    | NotifyAdminEmailSent
    | ChangeEmailSent Time.Posix EmailAddress (Result SendGrid.Error ())
    | UpdateFromFrontend SessionId ClientId ToBackend Time.Posix
    | WorldUpdateTimeElapsed Time.Posix


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (Nonempty Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Id TrainId) Train)
    | MailEditorToFrontend MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Id MailId) FrontendMail)


type EmailEvent
    = UnsubscribeEmail UnsubscribeEmailKey


type alias LoadingData_ =
    { user : Id UserId
    , grid : GridData
    , hiddenUsers : EverySet (Id UserId)
    , adminHiddenUsers : EverySet (Id UserId)
    , undoHistory : List (Dict RawCellCoord Int)
    , redoHistory : List (Dict RawCellCoord Int)
    , undoCurrent : Dict RawCellCoord Int
    , viewBounds : Bounds CellUnit
    , trains : AssocList.Dict (Id TrainId) Train
    , mail : AssocList.Dict (Id MailId) FrontendMail
    , mailEditor : MailEditorData
    }
