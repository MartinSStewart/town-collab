module Evergreen.V14.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V14.Bounds
import Evergreen.V14.Change
import Evergreen.V14.Coord
import Evergreen.V14.Grid
import Evergreen.V14.Id
import Evergreen.V14.LocalGrid
import Evergreen.V14.LocalModel
import Evergreen.V14.MailEditor
import Evergreen.V14.PingData
import Evergreen.V14.Point2d
import Evergreen.V14.Shaders
import Evergreen.V14.Sound
import Evergreen.V14.Tile
import Evergreen.V14.Train
import Evergreen.V14.Units
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
    | WindowResized (Evergreen.V14.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V14.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V14.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V14.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    | UserTagMouseEntered (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    | UserTagMouseExited (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
        , hidePoint : Evergreen.V14.Coord.Coord Evergreen.V14.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V14.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged


type alias LoadingData_ =
    { user : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
    , grid : Evergreen.V14.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V14.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V14.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V14.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V14.Bounds.Bounds Evergreen.V14.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V14.Id.Id Evergreen.V14.Id.TrainId) Evergreen.V14.Train.Train
    , mail : AssocList.Dict (Evergreen.V14.Id.Id Evergreen.V14.Id.MailId) Evergreen.V14.MailEditor.FrontendMail
    , mailEditor : Evergreen.V14.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V14.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V14.Coord.Coord Evergreen.V14.Units.WorldUnit
    , mousePosition : Evergreen.V14.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V14.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V14.Point2d.Point2d Evergreen.V14.Units.WorldUnit Evergreen.V14.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V14.Id.Id Evergreen.V14.Id.TrainId
        , startViewPoint : Evergreen.V14.Point2d.Point2d Evergreen.V14.Units.WorldUnit Evergreen.V14.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V14.Tile.Tile
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V14.Coord.Coord Evergreen.V14.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V14.Id.Id Evergreen.V14.Id.TrainId
        , train : Evergreen.V14.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V14.Coord.Coord Evergreen.V14.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V14.Coord.Coord Evergreen.V14.Units.WorldUnit
        }
    | MapHover


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V14.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V14.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V14.Point2d.Point2d Evergreen.V14.Units.WorldUnit Evergreen.V14.Units.WorldUnit
        , current : Evergreen.V14.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V14.Coord.Coord Evergreen.V14.Units.WorldUnit
    , tile : Evergreen.V14.Tile.Tile
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V14.LocalModel.LocalModel Evergreen.V14.Change.Change Evergreen.V14.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V14.Id.Id Evergreen.V14.Id.TrainId) Evergreen.V14.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V14.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V14.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V14.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V14.Point2d.Point2d Evergreen.V14.Units.WorldUnit Evergreen.V14.Units.WorldUnit
    , texture : Maybe WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V14.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V14.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V14.Id.Id Evergreen.V14.Id.EventId, Evergreen.V14.Change.LocalChange )
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
            , hidePoint : Evergreen.V14.Coord.Coord Evergreen.V14.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V14.Tile.Tile
            , position : Evergreen.V14.Coord.Coord Evergreen.V14.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V14.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V14.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V14.Id.Id Evergreen.V14.Id.MailId) Evergreen.V14.MailEditor.FrontendMail
    , mailEditor : Evergreen.V14.MailEditor.Model
    , currentTile :
        Maybe
            { tile : Evergreen.V14.Tile.Tile
            , mesh : WebGL.Mesh Evergreen.V14.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V14.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V14.Tile.Tile
    , toolbarMesh : WebGL.Mesh Evergreen.V14.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V14.Tile.Tile
    , lastHouseClick : Maybe Time.Posix
    , eventIdCounter : Evergreen.V14.Id.Id Evergreen.V14.Id.EventId
    , pingData : Maybe Evergreen.V14.PingData.PingData
    , pingStartTime : Maybe Time.Posix
    , localTime : Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V14.Id.Id Evergreen.V14.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V14.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V14.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V14.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V14.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V14.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V14.Bounds.Bounds Evergreen.V14.Units.CellUnit)
            , userId : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
            , hiddenUser : Evergreen.V14.Id.Id Evergreen.V14.Id.UserId
            , hidePoint : Evergreen.V14.Coord.Coord Evergreen.V14.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V14.Id.Id Evergreen.V14.Id.TrainId) Evergreen.V14.Train.Train
    , lastWorldUpdateTrains : AssocList.Dict (Evergreen.V14.Id.Id Evergreen.V14.Id.TrainId) Evergreen.V14.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V14.Id.Id Evergreen.V14.Id.MailId) Evergreen.V14.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V14.Bounds.Bounds Evergreen.V14.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V14.Id.Id Evergreen.V14.Id.EventId, Evergreen.V14.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V14.Bounds.Bounds Evergreen.V14.Units.CellUnit)
    | MailEditorToBackend Evergreen.V14.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V14.Id.Id Evergreen.V14.Id.TrainId) Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V14.Id.Id Evergreen.V14.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V14.Id.Id Evergreen.V14.Id.TrainId)
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
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V14.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V14.Id.Id Evergreen.V14.Id.TrainId) Evergreen.V14.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V14.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V14.Id.Id Evergreen.V14.Id.MailId) Evergreen.V14.MailEditor.FrontendMail)
    | PingResponse Time.Posix
