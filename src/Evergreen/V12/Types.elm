module Evergreen.V12.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V12.Bounds
import Evergreen.V12.Change
import Evergreen.V12.Coord
import Evergreen.V12.Grid
import Evergreen.V12.Id
import Evergreen.V12.LocalGrid
import Evergreen.V12.LocalModel
import Evergreen.V12.MailEditor
import Evergreen.V12.PingData
import Evergreen.V12.Point2d
import Evergreen.V12.Shaders
import Evergreen.V12.Sound
import Evergreen.V12.Tile
import Evergreen.V12.Train
import Evergreen.V12.Units
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
    | WindowResized (Evergreen.V12.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V12.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V12.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V12.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    | UserTagMouseEntered (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    | UserTagMouseExited (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
        , hidePoint : Evergreen.V12.Coord.Coord Evergreen.V12.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V12.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged


type alias LoadingData_ =
    { user : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    , grid : Evergreen.V12.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V12.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V12.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V12.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V12.Bounds.Bounds Evergreen.V12.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V12.Id.Id Evergreen.V12.Id.TrainId) Evergreen.V12.Train.Train
    , mail : AssocList.Dict (Evergreen.V12.Id.Id Evergreen.V12.Id.MailId) Evergreen.V12.MailEditor.FrontendMail
    , mailEditor : Evergreen.V12.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V12.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V12.Coord.Coord Evergreen.V12.Units.WorldUnit
    , mousePosition : Evergreen.V12.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V12.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V12.Point2d.Point2d Evergreen.V12.Units.WorldUnit Evergreen.V12.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V12.Id.Id Evergreen.V12.Id.TrainId
        , startViewPoint : Evergreen.V12.Point2d.Point2d Evergreen.V12.Units.WorldUnit Evergreen.V12.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V12.Tile.Tile
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V12.Coord.Coord Evergreen.V12.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V12.Id.Id Evergreen.V12.Id.TrainId
        , train : Evergreen.V12.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V12.Coord.Coord Evergreen.V12.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V12.Coord.Coord Evergreen.V12.Units.WorldUnit
        }
    | MapHover


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V12.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V12.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V12.Point2d.Point2d Evergreen.V12.Units.WorldUnit Evergreen.V12.Units.WorldUnit
        , current : Evergreen.V12.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V12.Coord.Coord Evergreen.V12.Units.WorldUnit
    , tile : Evergreen.V12.Tile.Tile
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V12.LocalModel.LocalModel Evergreen.V12.Change.Change Evergreen.V12.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V12.Id.Id Evergreen.V12.Id.TrainId) Evergreen.V12.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V12.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V12.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V12.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V12.Point2d.Point2d Evergreen.V12.Units.WorldUnit Evergreen.V12.Units.WorldUnit
    , texture : Maybe WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V12.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V12.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V12.Id.Id Evergreen.V12.Id.EventId, Evergreen.V12.Change.LocalChange )
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
            , hidePoint : Evergreen.V12.Coord.Coord Evergreen.V12.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V12.Tile.Tile
            , position : Evergreen.V12.Coord.Coord Evergreen.V12.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V12.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V12.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V12.Id.Id Evergreen.V12.Id.MailId) Evergreen.V12.MailEditor.FrontendMail
    , mailEditor : Evergreen.V12.MailEditor.Model
    , currentTile :
        Maybe
            { tile : Evergreen.V12.Tile.Tile
            , mesh : WebGL.Mesh Evergreen.V12.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V12.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V12.Tile.Tile
    , toolbarMesh : WebGL.Mesh Evergreen.V12.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V12.Tile.Tile
    , lastHouseClick : Maybe Time.Posix
    , eventIdCounter : Evergreen.V12.Id.Id Evergreen.V12.Id.EventId
    , pingData : Maybe Evergreen.V12.PingData.PingData
    , pingStartTime : Maybe Time.Posix
    , localTime : Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V12.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V12.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V12.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V12.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V12.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V12.Bounds.Bounds Evergreen.V12.Units.CellUnit)
            , userId : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
            , hiddenUser : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
            , hidePoint : Evergreen.V12.Coord.Coord Evergreen.V12.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V12.Id.Id Evergreen.V12.Id.TrainId) Evergreen.V12.Train.Train
    , lastWorldUpdateTrains : AssocList.Dict (Evergreen.V12.Id.Id Evergreen.V12.Id.TrainId) Evergreen.V12.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V12.Id.Id Evergreen.V12.Id.MailId) Evergreen.V12.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V12.Bounds.Bounds Evergreen.V12.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V12.Id.Id Evergreen.V12.Id.EventId, Evergreen.V12.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V12.Bounds.Bounds Evergreen.V12.Units.CellUnit)
    | MailEditorToBackend Evergreen.V12.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V12.Id.Id Evergreen.V12.Id.TrainId)
    | CancelTeleportHomeTrainRequest (Evergreen.V12.Id.Id Evergreen.V12.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V12.Id.Id Evergreen.V12.Id.TrainId)
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
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V12.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V12.Id.Id Evergreen.V12.Id.TrainId) Evergreen.V12.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V12.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V12.Id.Id Evergreen.V12.Id.MailId) Evergreen.V12.MailEditor.FrontendMail)
    | PingResponse Time.Posix
