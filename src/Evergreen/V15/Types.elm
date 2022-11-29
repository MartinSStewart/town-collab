module Evergreen.V15.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V15.Bounds
import Evergreen.V15.Change
import Evergreen.V15.Coord
import Evergreen.V15.Grid
import Evergreen.V15.Id
import Evergreen.V15.LocalGrid
import Evergreen.V15.LocalModel
import Evergreen.V15.MailEditor
import Evergreen.V15.PingData
import Evergreen.V15.Point2d
import Evergreen.V15.Shaders
import Evergreen.V15.Sound
import Evergreen.V15.Tile
import Evergreen.V15.Train
import Evergreen.V15.Units
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
    | WindowResized (Evergreen.V15.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V15.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V15.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V15.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    | UserTagMouseEntered (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    | UserTagMouseExited (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
        , hidePoint : Evergreen.V15.Coord.Coord Evergreen.V15.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V15.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged


type alias LoadingData_ =
    { user : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
    , grid : Evergreen.V15.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V15.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V15.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V15.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V15.Bounds.Bounds Evergreen.V15.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V15.Id.Id Evergreen.V15.Id.TrainId) Evergreen.V15.Train.Train
    , mail : AssocList.Dict (Evergreen.V15.Id.Id Evergreen.V15.Id.MailId) Evergreen.V15.MailEditor.FrontendMail
    , mailEditor : Evergreen.V15.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V15.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V15.Coord.Coord Evergreen.V15.Units.WorldUnit
    , mousePosition : Evergreen.V15.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V15.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V15.Point2d.Point2d Evergreen.V15.Units.WorldUnit Evergreen.V15.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V15.Id.Id Evergreen.V15.Id.TrainId
        , startViewPoint : Evergreen.V15.Point2d.Point2d Evergreen.V15.Units.WorldUnit Evergreen.V15.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V15.Tile.Tile
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V15.Coord.Coord Evergreen.V15.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V15.Id.Id Evergreen.V15.Id.TrainId
        , train : Evergreen.V15.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V15.Coord.Coord Evergreen.V15.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V15.Coord.Coord Evergreen.V15.Units.WorldUnit
        }
    | MapHover


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V15.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V15.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V15.Point2d.Point2d Evergreen.V15.Units.WorldUnit Evergreen.V15.Units.WorldUnit
        , current : Evergreen.V15.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V15.Coord.Coord Evergreen.V15.Units.WorldUnit
    , tile : Evergreen.V15.Tile.Tile
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V15.LocalModel.LocalModel Evergreen.V15.Change.Change Evergreen.V15.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V15.Id.Id Evergreen.V15.Id.TrainId) Evergreen.V15.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V15.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V15.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V15.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V15.Point2d.Point2d Evergreen.V15.Units.WorldUnit Evergreen.V15.Units.WorldUnit
    , texture : Maybe WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V15.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V15.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V15.Id.Id Evergreen.V15.Id.EventId, Evergreen.V15.Change.LocalChange )
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
            , hidePoint : Evergreen.V15.Coord.Coord Evergreen.V15.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V15.Tile.Tile
            , position : Evergreen.V15.Coord.Coord Evergreen.V15.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V15.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V15.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V15.Id.Id Evergreen.V15.Id.MailId) Evergreen.V15.MailEditor.FrontendMail
    , mailEditor : Evergreen.V15.MailEditor.Model
    , currentTile :
        Maybe
            { tile : Evergreen.V15.Tile.Tile
            , mesh : WebGL.Mesh Evergreen.V15.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V15.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V15.Tile.Tile
    , toolbarMesh : WebGL.Mesh Evergreen.V15.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V15.Tile.Tile
    , lastHouseClick : Maybe Time.Posix
    , eventIdCounter : Evergreen.V15.Id.Id Evergreen.V15.Id.EventId
    , pingData : Maybe Evergreen.V15.PingData.PingData
    , pingStartTime : Maybe Time.Posix
    , localTime : Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V15.Id.Id Evergreen.V15.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V15.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V15.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V15.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V15.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V15.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V15.Bounds.Bounds Evergreen.V15.Units.CellUnit)
            , userId : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
            , hiddenUser : Evergreen.V15.Id.Id Evergreen.V15.Id.UserId
            , hidePoint : Evergreen.V15.Coord.Coord Evergreen.V15.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V15.Id.Id Evergreen.V15.Id.TrainId) Evergreen.V15.Train.Train
    , lastWorldUpdateTrains : AssocList.Dict (Evergreen.V15.Id.Id Evergreen.V15.Id.TrainId) Evergreen.V15.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V15.Id.Id Evergreen.V15.Id.MailId) Evergreen.V15.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V15.Bounds.Bounds Evergreen.V15.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V15.Id.Id Evergreen.V15.Id.EventId, Evergreen.V15.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V15.Bounds.Bounds Evergreen.V15.Units.CellUnit)
    | MailEditorToBackend Evergreen.V15.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V15.Id.Id Evergreen.V15.Id.TrainId) Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V15.Id.Id Evergreen.V15.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V15.Id.Id Evergreen.V15.Id.TrainId)
    | PingRequest


type BackendMsg
    = UserDisconnected Lamdera.SessionId Lamdera.ClientId
    | NotifyAdminTimeElapsed Time.Posix
    | NotifyAdminEmailSent
    | ChangeEmailSent Time.Posix EmailAddress.EmailAddress (Result SendGrid.Error ())
    | UpdateFromFrontend Lamdera.SessionId Lamdera.ClientId ToBackend Time.Posix
    | WorldUpdateTimeElapsed Time.Posix


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V15.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V15.Id.Id Evergreen.V15.Id.TrainId) Evergreen.V15.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V15.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V15.Id.Id Evergreen.V15.Id.MailId) Evergreen.V15.MailEditor.FrontendMail)
    | PingResponse Time.Posix
