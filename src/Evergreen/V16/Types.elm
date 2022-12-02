module Evergreen.V16.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V16.Bounds
import Evergreen.V16.Change
import Evergreen.V16.Coord
import Evergreen.V16.Grid
import Evergreen.V16.Id
import Evergreen.V16.LocalGrid
import Evergreen.V16.LocalModel
import Evergreen.V16.MailEditor
import Evergreen.V16.PingData
import Evergreen.V16.Point2d
import Evergreen.V16.Shaders
import Evergreen.V16.Sound
import Evergreen.V16.Tile
import Evergreen.V16.Train
import Evergreen.V16.Units
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
    | WindowResized (Evergreen.V16.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V16.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V16.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V16.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    | UserTagMouseEntered (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    | UserTagMouseExited (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
        , hidePoint : Evergreen.V16.Coord.Coord Evergreen.V16.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V16.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged


type alias LoadingData_ =
    { user : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    , grid : Evergreen.V16.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V16.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V16.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V16.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V16.Bounds.Bounds Evergreen.V16.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V16.Id.Id Evergreen.V16.Id.TrainId) Evergreen.V16.Train.Train
    , mail : AssocList.Dict (Evergreen.V16.Id.Id Evergreen.V16.Id.MailId) Evergreen.V16.MailEditor.FrontendMail
    , mailEditor : Evergreen.V16.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V16.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V16.Coord.Coord Evergreen.V16.Units.WorldUnit
    , mousePosition : Evergreen.V16.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V16.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V16.Point2d.Point2d Evergreen.V16.Units.WorldUnit Evergreen.V16.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V16.Id.Id Evergreen.V16.Id.TrainId
        , startViewPoint : Evergreen.V16.Point2d.Point2d Evergreen.V16.Units.WorldUnit Evergreen.V16.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V16.Tile.Tile
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V16.Coord.Coord Evergreen.V16.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V16.Id.Id Evergreen.V16.Id.TrainId
        , train : Evergreen.V16.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V16.Coord.Coord Evergreen.V16.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V16.Coord.Coord Evergreen.V16.Units.WorldUnit
        }
    | MapHover


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V16.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V16.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V16.Point2d.Point2d Evergreen.V16.Units.WorldUnit Evergreen.V16.Units.WorldUnit
        , current : Evergreen.V16.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V16.Coord.Coord Evergreen.V16.Units.WorldUnit
    , tile : Evergreen.V16.Tile.Tile
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V16.LocalModel.LocalModel Evergreen.V16.Change.Change Evergreen.V16.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V16.Id.Id Evergreen.V16.Id.TrainId) Evergreen.V16.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V16.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V16.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V16.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V16.Point2d.Point2d Evergreen.V16.Units.WorldUnit Evergreen.V16.Units.WorldUnit
    , texture : Maybe WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V16.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V16.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V16.Id.Id Evergreen.V16.Id.EventId, Evergreen.V16.Change.LocalChange )
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
            , hidePoint : Evergreen.V16.Coord.Coord Evergreen.V16.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V16.Tile.Tile
            , position : Evergreen.V16.Coord.Coord Evergreen.V16.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V16.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V16.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V16.Id.Id Evergreen.V16.Id.MailId) Evergreen.V16.MailEditor.FrontendMail
    , mailEditor : Evergreen.V16.MailEditor.Model
    , currentTile :
        Maybe
            { tile : Evergreen.V16.Tile.Tile
            , mesh : WebGL.Mesh Evergreen.V16.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V16.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V16.Tile.Tile
    , toolbarMesh : WebGL.Mesh Evergreen.V16.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V16.Tile.Tile
    , lastHouseClick : Maybe Time.Posix
    , eventIdCounter : Evergreen.V16.Id.Id Evergreen.V16.Id.EventId
    , pingData : Maybe Evergreen.V16.PingData.PingData
    , pingStartTime : Maybe Time.Posix
    , localTime : Time.Posix
    , scrollThreshold : Float
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V16.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V16.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V16.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V16.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V16.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V16.Bounds.Bounds Evergreen.V16.Units.CellUnit)
            , userId : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
            , hiddenUser : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
            , hidePoint : Evergreen.V16.Coord.Coord Evergreen.V16.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V16.Id.Id Evergreen.V16.Id.TrainId) Evergreen.V16.Train.Train
    , lastWorldUpdateTrains : AssocList.Dict (Evergreen.V16.Id.Id Evergreen.V16.Id.TrainId) Evergreen.V16.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V16.Id.Id Evergreen.V16.Id.MailId) Evergreen.V16.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V16.Bounds.Bounds Evergreen.V16.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V16.Id.Id Evergreen.V16.Id.EventId, Evergreen.V16.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V16.Bounds.Bounds Evergreen.V16.Units.CellUnit)
    | MailEditorToBackend Evergreen.V16.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V16.Id.Id Evergreen.V16.Id.TrainId) Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V16.Id.Id Evergreen.V16.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V16.Id.Id Evergreen.V16.Id.TrainId)
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
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V16.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V16.Id.Id Evergreen.V16.Id.TrainId) Evergreen.V16.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V16.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V16.Id.Id Evergreen.V16.Id.MailId) Evergreen.V16.MailEditor.FrontendMail)
    | PingResponse Time.Posix
