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
import Browser.Navigation
import Change exposing (Change, ServerChange)
import Coord exposing (Coord, RawCellCoord)
import Cursor exposing (Cursor)
import Dict exposing (Dict)
import Duration exposing (Duration)
import EmailAddress exposing (EmailAddress)
import EverySet exposing (EverySet)
import Grid exposing (Grid)
import Html.Events.Extra.Mouse exposing (Button)
import Keyboard
import Lamdera exposing (ClientId, SessionId)
import List.Nonempty exposing (Nonempty)
import LocalGrid exposing (LocalGrid)
import LocalModel exposing (LocalModel)
import Math.Vector2 exposing (Vec2)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import SendGrid
import Shaders exposing (DebrisVertex)
import Sound exposing (Sound)
import Tile exposing (Tile)
import Time
import Train exposing (Train)
import Units exposing (CellUnit, WorldUnit)
import Url exposing (Url)
import UrlHelper exposing (ConfirmEmailKey, UnsubscribeEmailKey)
import User exposing (RawUserId, UserId)
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
    , trains : List Train
    , meshes : Dict RawCellCoord (WebGL.Mesh Grid.Vertex)
    , cursorMesh : WebGL.Mesh { position : Vec2 }
    , viewPoint : Point2d WorldUnit WorldUnit
    , viewPointLastInterval : Point2d WorldUnit WorldUnit
    , cursor : Cursor
    , texture : Maybe Texture
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
    , lastTouchMove : Maybe Time.Posix
    , userHoverHighlighted : Maybe UserId
    , highlightContextMenu : Maybe { userId : UserId, hidePoint : Coord WorldUnit }
    , adminEnabled : Bool
    , animationElapsedTime : Duration
    , ignoreNextUrlChanged : Bool
    , textAreaText : String
    , lastTilePlaced : Maybe { time : Time.Posix, overwroteTiles : Bool }
    , sounds : AssocList.Dict Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh DebrisVertex
    }


type alias RemovedTileParticle =
    { time : Time.Posix, position : Coord WorldUnit, tile : Tile }


type ToolType
    = DragTool
    | SelectTool
    | HighlightTool (Maybe ( UserId, Coord WorldUnit ))


type MouseButtonState
    = MouseButtonUp { current : Point2d Pixels Pixels }
    | MouseButtonDown
        { start : Point2d Pixels Pixels
        , start_ : Point2d WorldUnit WorldUnit
        , current : Point2d Pixels Pixels
        }


type alias BackendModel =
    { grid : Grid
    , userSessions : Dict SessionId { clientIds : Dict ClientId (Bounds CellUnit), userId : UserId }
    , users : Dict RawUserId BackendUserData
    , usersHiddenRecently : List { reporter : UserId, hiddenUser : UserId, hidePoint : Coord WorldUnit }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : List Train
    , lastWorldUpdate : Maybe Time.Posix
    }


type BackendError
    = SendGridError EmailAddress SendGrid.Error


type alias BackendUserData =
    { hiddenUsers : EverySet UserId
    , hiddenForAll : Bool
    , undoHistory : List (Dict RawCellCoord Int)
    , redoHistory : List (Dict RawCellCoord Int)
    , undoCurrent : Dict RawCellCoord Int
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type FrontendMsg_
    = UrlClicked UrlRequest
    | UrlChanged Url
    | NoOpFrontendMsg
    | TextureLoaded (Result WebGL.Texture.Error Texture)
    | KeyMsg Keyboard.Msg
    | KeyDown Keyboard.RawKey
    | WindowResized (Coord Pixels)
    | GotDevicePixelRatio Float
    | UserTyped String
    | TextAreaFocused
    | MouseDown Button (Point2d Pixels Pixels)
    | MouseUp Button (Point2d Pixels Pixels)
    | MouseMove (Point2d Pixels Pixels)
    | TouchMove (Point2d Pixels Pixels)
    | ShortIntervalElapsed Time.Posix
    | VeryShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed UserId
    | UserTagMouseEntered UserId
    | UserTagMouseExited UserId
    | HideForAllTogglePressed UserId
    | ToggleAdminEnabledPressed
    | HideUserPressed { userId : UserId, hidePoint : Coord WorldUnit }
    | AnimationFrame Time.Posix
    | SoundLoaded Sound (Result Audio.LoadError Audio.Source)


type ToBackend
    = ConnectToBackend (Bounds CellUnit)
    | GridChange (Nonempty Change.LocalChange)
    | ChangeViewBounds (Bounds CellUnit)


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
    | TrainUpdate (List Train)


type EmailEvent
    = UnsubscribeEmail UnsubscribeEmailKey


type alias LoadingData_ =
    { user : UserId
    , grid : Grid
    , hiddenUsers : EverySet UserId
    , adminHiddenUsers : EverySet UserId
    , undoHistory : List (Dict RawCellCoord Int)
    , redoHistory : List (Dict RawCellCoord Int)
    , undoCurrent : Dict RawCellCoord Int
    , viewBounds : Bounds CellUnit
    , trains : List Train
    }
