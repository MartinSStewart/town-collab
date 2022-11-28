module Evergreen.V11.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V11.Bounds
import Evergreen.V11.Change
import Evergreen.V11.Coord
import Evergreen.V11.Grid
import Evergreen.V11.Id
import Evergreen.V11.LocalGrid
import Evergreen.V11.LocalModel
import Evergreen.V11.MailEditor
import Evergreen.V11.Point2d
import Evergreen.V11.Shaders
import Evergreen.V11.Sound
import Evergreen.V11.Tile
import Evergreen.V11.Train
import Evergreen.V11.Units
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
    | WindowResized (Evergreen.V11.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V11.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V11.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V11.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V11.Id.Id Evergreen.V11.Id.UserId)
    | UserTagMouseEntered (Evergreen.V11.Id.Id Evergreen.V11.Id.UserId)
    | UserTagMouseExited (Evergreen.V11.Id.Id Evergreen.V11.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V11.Id.Id Evergreen.V11.Id.UserId
        , hidePoint : Evergreen.V11.Coord.Coord Evergreen.V11.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V11.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged


type alias LoadingData_ =
    { user : Evergreen.V11.Id.Id Evergreen.V11.Id.UserId
    , grid : Evergreen.V11.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V11.Id.Id Evergreen.V11.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V11.Id.Id Evergreen.V11.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V11.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V11.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V11.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V11.Bounds.Bounds Evergreen.V11.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V11.Id.Id Evergreen.V11.Id.TrainId) Evergreen.V11.Train.Train
    , mail : AssocList.Dict (Evergreen.V11.Id.Id Evergreen.V11.Id.MailId) Evergreen.V11.MailEditor.FrontendMail
    , mailEditor : Evergreen.V11.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V11.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V11.Coord.Coord Evergreen.V11.Units.WorldUnit
    , mousePosition : Evergreen.V11.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V11.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V11.Point2d.Point2d Evergreen.V11.Units.WorldUnit Evergreen.V11.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V11.Id.Id Evergreen.V11.Id.TrainId
        , startViewPoint : Evergreen.V11.Point2d.Point2d Evergreen.V11.Units.WorldUnit Evergreen.V11.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V11.Tile.Tile
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V11.Coord.Coord Evergreen.V11.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V11.Id.Id Evergreen.V11.Id.TrainId
        , train : Evergreen.V11.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V11.Coord.Coord Evergreen.V11.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V11.Coord.Coord Evergreen.V11.Units.WorldUnit
        }
    | MapHover


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V11.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V11.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V11.Point2d.Point2d Evergreen.V11.Units.WorldUnit Evergreen.V11.Units.WorldUnit
        , current : Evergreen.V11.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V11.Coord.Coord Evergreen.V11.Units.WorldUnit
    , tile : Evergreen.V11.Tile.Tile
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V11.LocalModel.LocalModel Evergreen.V11.Change.Change Evergreen.V11.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V11.Id.Id Evergreen.V11.Id.TrainId) Evergreen.V11.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V11.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V11.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V11.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V11.Point2d.Point2d Evergreen.V11.Units.WorldUnit Evergreen.V11.Units.WorldUnit
    , texture : Maybe WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V11.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V11.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V11.Id.Id Evergreen.V11.Id.EventId, Evergreen.V11.Change.LocalChange )
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V11.Id.Id Evergreen.V11.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V11.Id.Id Evergreen.V11.Id.UserId
            , hidePoint : Evergreen.V11.Coord.Coord Evergreen.V11.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V11.Tile.Tile
            , position : Evergreen.V11.Coord.Coord Evergreen.V11.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V11.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V11.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V11.Id.Id Evergreen.V11.Id.MailId) Evergreen.V11.MailEditor.FrontendMail
    , mailEditor : Evergreen.V11.MailEditor.Model
    , currentTile :
        Maybe
            { tile : Evergreen.V11.Tile.Tile
            , mesh : WebGL.Mesh Evergreen.V11.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V11.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V11.Tile.Tile
    , toolbarMesh : WebGL.Mesh Evergreen.V11.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V11.Tile.Tile
    , lastHouseClick : Maybe Time.Posix
    , eventIdCounter : Evergreen.V11.Id.Id Evergreen.V11.Id.EventId
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V11.Id.Id Evergreen.V11.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V11.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V11.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V11.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V11.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V11.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V11.Bounds.Bounds Evergreen.V11.Units.CellUnit)
            , userId : Evergreen.V11.Id.Id Evergreen.V11.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V11.Id.Id Evergreen.V11.Id.UserId
            , hiddenUser : Evergreen.V11.Id.Id Evergreen.V11.Id.UserId
            , hidePoint : Evergreen.V11.Coord.Coord Evergreen.V11.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V11.Id.Id Evergreen.V11.Id.TrainId) Evergreen.V11.Train.Train
    , lastWorldUpdateTrains : AssocList.Dict (Evergreen.V11.Id.Id Evergreen.V11.Id.TrainId) Evergreen.V11.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V11.Id.Id Evergreen.V11.Id.MailId) Evergreen.V11.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V11.Bounds.Bounds Evergreen.V11.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V11.Id.Id Evergreen.V11.Id.EventId, Evergreen.V11.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V11.Bounds.Bounds Evergreen.V11.Units.CellUnit)
    | MailEditorToBackend Evergreen.V11.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V11.Id.Id Evergreen.V11.Id.TrainId)
    | CancelTeleportHomeTrainRequest (Evergreen.V11.Id.Id Evergreen.V11.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V11.Id.Id Evergreen.V11.Id.TrainId)


type BackendMsg
    = UserDisconnected Lamdera.SessionId Lamdera.ClientId
    | NotifyAdminTimeElapsed Time.Posix
    | NotifyAdminEmailSent
    | ChangeEmailSent Time.Posix EmailAddress.EmailAddress (Result SendGrid.Error ())
    | UpdateFromFrontend Lamdera.SessionId Lamdera.ClientId ToBackend Time.Posix
    | WorldUpdateTimeElapsed Time.Posix


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V11.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V11.Id.Id Evergreen.V11.Id.TrainId) Evergreen.V11.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V11.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V11.Id.Id Evergreen.V11.Id.MailId) Evergreen.V11.MailEditor.FrontendMail)
