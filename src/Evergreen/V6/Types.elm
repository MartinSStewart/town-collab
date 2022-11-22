module Evergreen.V6.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V6.Bounds
import Evergreen.V6.Change
import Evergreen.V6.Coord
import Evergreen.V6.Grid
import Evergreen.V6.Id
import Evergreen.V6.LocalGrid
import Evergreen.V6.LocalModel
import Evergreen.V6.MailEditor
import Evergreen.V6.Point2d
import Evergreen.V6.Shaders
import Evergreen.V6.Sound
import Evergreen.V6.Tile
import Evergreen.V6.Train
import Evergreen.V6.Units
import EverySet
import Html.Events.Extra.Mouse
import Html.Events.Extra.Wheel
import Keyboard
import Lamdera
import List.Nonempty
import Pixels
import SendGrid
import Time
import Url
import WebGL
import WebGL.Texture


type ToolType
    = DragTool


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOpFrontendMsg
    | TextureLoaded (Result WebGL.Texture.Error WebGL.Texture.Texture)
    | TrainTextureLoaded (Result WebGL.Texture.Error WebGL.Texture.Texture)
    | KeyMsg Keyboard.Msg
    | KeyDown Keyboard.RawKey
    | WindowResized (Evergreen.V6.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V6.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V6.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V6.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)
    | UserTagMouseEntered (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)
    | UserTagMouseExited (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)
    | HideForAllTogglePressed (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V6.Id.Id Evergreen.V6.Id.UserId
        , hidePoint : Evergreen.V6.Coord.Coord Evergreen.V6.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V6.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged


type alias LoadingData_ =
    { user : Evergreen.V6.Id.Id Evergreen.V6.Id.UserId
    , grid : Evergreen.V6.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V6.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V6.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V6.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V6.Bounds.Bounds Evergreen.V6.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V6.Id.Id Evergreen.V6.Id.TrainId) Evergreen.V6.Train.Train
    , mail : AssocList.Dict (Evergreen.V6.Id.Id Evergreen.V6.Id.MailId) Evergreen.V6.MailEditor.FrontendMail
    , mailEditor : Evergreen.V6.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V6.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V6.Coord.Coord Evergreen.V6.Units.WorldUnit
    , mousePosition : Evergreen.V6.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V6.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V6.Point2d.Point2d Evergreen.V6.Units.WorldUnit Evergreen.V6.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V6.Id.Id Evergreen.V6.Id.TrainId
        , startViewPoint : Evergreen.V6.Point2d.Point2d Evergreen.V6.Units.WorldUnit Evergreen.V6.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V6.Tile.Tile
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V6.Coord.Coord Evergreen.V6.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V6.Id.Id Evergreen.V6.Id.TrainId
        , train : Evergreen.V6.Train.Train
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V6.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V6.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V6.Point2d.Point2d Evergreen.V6.Units.WorldUnit Evergreen.V6.Units.WorldUnit
        , current : Evergreen.V6.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Maybe Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V6.Coord.Coord Evergreen.V6.Units.WorldUnit
    , tile : Evergreen.V6.Tile.Tile
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V6.LocalModel.LocalModel Evergreen.V6.Change.Change Evergreen.V6.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V6.Id.Id Evergreen.V6.Id.TrainId) Evergreen.V6.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V6.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V6.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V6.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V6.Point2d.Point2d Evergreen.V6.Units.WorldUnit Evergreen.V6.Units.WorldUnit
    , texture : Maybe WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V6.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V6.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List Evergreen.V6.Change.LocalChange
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V6.Id.Id Evergreen.V6.Id.UserId
            , hidePoint : Evergreen.V6.Coord.Coord Evergreen.V6.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V6.Tile.Tile
            , position : Evergreen.V6.Coord.Coord Evergreen.V6.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V6.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V6.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V6.Id.Id Evergreen.V6.Id.MailId) Evergreen.V6.MailEditor.FrontendMail
    , mailEditor : Evergreen.V6.MailEditor.Model
    , currentTile :
        Maybe
            { tile : Evergreen.V6.Tile.Tile
            , mesh : WebGL.Mesh Evergreen.V6.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V6.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V6.Tile.Tile
    , toolbarMesh : WebGL.Mesh Evergreen.V6.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V6.Tile.Tile
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V6.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V6.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V6.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V6.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V6.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V6.Bounds.Bounds Evergreen.V6.Units.CellUnit)
            , userId : Evergreen.V6.Id.Id Evergreen.V6.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V6.Id.Id Evergreen.V6.Id.UserId
            , hiddenUser : Evergreen.V6.Id.Id Evergreen.V6.Id.UserId
            , hidePoint : Evergreen.V6.Coord.Coord Evergreen.V6.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V6.Id.Id Evergreen.V6.Id.TrainId) Evergreen.V6.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V6.Id.Id Evergreen.V6.Id.MailId) Evergreen.V6.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V6.Bounds.Bounds Evergreen.V6.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty Evergreen.V6.Change.LocalChange)
    | ChangeViewBounds (Evergreen.V6.Bounds.Bounds Evergreen.V6.Units.CellUnit)
    | MailEditorToBackend Evergreen.V6.MailEditor.ToBackend


type BackendMsg
    = UserDisconnected Lamdera.SessionId Lamdera.ClientId
    | NotifyAdminTimeElapsed Time.Posix
    | NotifyAdminEmailSent
    | ChangeEmailSent Time.Posix EmailAddress.EmailAddress (Result SendGrid.Error ())
    | UpdateFromFrontend Lamdera.SessionId Lamdera.ClientId ToBackend Time.Posix
    | WorldUpdateTimeElapsed Time.Posix


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V6.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V6.Id.Id Evergreen.V6.Id.TrainId) Evergreen.V6.Train.Train)
    | MailEditorToFrontend Evergreen.V6.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V6.Id.Id Evergreen.V6.Id.MailId) Evergreen.V6.MailEditor.FrontendMail)
