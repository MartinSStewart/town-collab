module Evergreen.V10.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V10.Bounds
import Evergreen.V10.Change
import Evergreen.V10.Coord
import Evergreen.V10.Grid
import Evergreen.V10.Id
import Evergreen.V10.LocalGrid
import Evergreen.V10.LocalModel
import Evergreen.V10.MailEditor
import Evergreen.V10.Point2d
import Evergreen.V10.Shaders
import Evergreen.V10.Sound
import Evergreen.V10.Tile
import Evergreen.V10.Train
import Evergreen.V10.Units
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
    | WindowResized (Evergreen.V10.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V10.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V10.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V10.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V10.Id.Id Evergreen.V10.Id.UserId)
    | UserTagMouseEntered (Evergreen.V10.Id.Id Evergreen.V10.Id.UserId)
    | UserTagMouseExited (Evergreen.V10.Id.Id Evergreen.V10.Id.UserId)
    | HideForAllTogglePressed (Evergreen.V10.Id.Id Evergreen.V10.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V10.Id.Id Evergreen.V10.Id.UserId
        , hidePoint : Evergreen.V10.Coord.Coord Evergreen.V10.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V10.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged


type alias LoadingData_ =
    { user : Evergreen.V10.Id.Id Evergreen.V10.Id.UserId
    , grid : Evergreen.V10.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V10.Id.Id Evergreen.V10.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V10.Id.Id Evergreen.V10.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V10.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V10.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V10.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V10.Bounds.Bounds Evergreen.V10.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V10.Id.Id Evergreen.V10.Id.TrainId) Evergreen.V10.Train.Train
    , mail : AssocList.Dict (Evergreen.V10.Id.Id Evergreen.V10.Id.MailId) Evergreen.V10.MailEditor.FrontendMail
    , mailEditor : Evergreen.V10.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V10.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V10.Coord.Coord Evergreen.V10.Units.WorldUnit
    , mousePosition : Evergreen.V10.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V10.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V10.Point2d.Point2d Evergreen.V10.Units.WorldUnit Evergreen.V10.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V10.Id.Id Evergreen.V10.Id.TrainId
        , startViewPoint : Evergreen.V10.Point2d.Point2d Evergreen.V10.Units.WorldUnit Evergreen.V10.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V10.Tile.Tile
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V10.Coord.Coord Evergreen.V10.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V10.Id.Id Evergreen.V10.Id.TrainId
        , train : Evergreen.V10.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V10.Coord.Coord Evergreen.V10.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V10.Coord.Coord Evergreen.V10.Units.WorldUnit
        }
    | MapHover


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V10.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V10.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V10.Point2d.Point2d Evergreen.V10.Units.WorldUnit Evergreen.V10.Units.WorldUnit
        , current : Evergreen.V10.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V10.Coord.Coord Evergreen.V10.Units.WorldUnit
    , tile : Evergreen.V10.Tile.Tile
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V10.LocalModel.LocalModel Evergreen.V10.Change.Change Evergreen.V10.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V10.Id.Id Evergreen.V10.Id.TrainId) Evergreen.V10.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V10.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V10.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V10.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V10.Point2d.Point2d Evergreen.V10.Units.WorldUnit Evergreen.V10.Units.WorldUnit
    , texture : Maybe WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V10.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V10.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List Evergreen.V10.Change.LocalChange
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V10.Id.Id Evergreen.V10.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V10.Id.Id Evergreen.V10.Id.UserId
            , hidePoint : Evergreen.V10.Coord.Coord Evergreen.V10.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V10.Tile.Tile
            , position : Evergreen.V10.Coord.Coord Evergreen.V10.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V10.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V10.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V10.Id.Id Evergreen.V10.Id.MailId) Evergreen.V10.MailEditor.FrontendMail
    , mailEditor : Evergreen.V10.MailEditor.Model
    , currentTile :
        Maybe
            { tile : Evergreen.V10.Tile.Tile
            , mesh : WebGL.Mesh Evergreen.V10.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V10.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V10.Tile.Tile
    , toolbarMesh : WebGL.Mesh Evergreen.V10.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V10.Tile.Tile
    , lastHouseClick : Maybe Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V10.Id.Id Evergreen.V10.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V10.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V10.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V10.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V10.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V10.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V10.Bounds.Bounds Evergreen.V10.Units.CellUnit)
            , userId : Evergreen.V10.Id.Id Evergreen.V10.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V10.Id.Id Evergreen.V10.Id.UserId
            , hiddenUser : Evergreen.V10.Id.Id Evergreen.V10.Id.UserId
            , hidePoint : Evergreen.V10.Coord.Coord Evergreen.V10.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V10.Id.Id Evergreen.V10.Id.TrainId) Evergreen.V10.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V10.Id.Id Evergreen.V10.Id.MailId) Evergreen.V10.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V10.Bounds.Bounds Evergreen.V10.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty Evergreen.V10.Change.LocalChange)
    | ChangeViewBounds (Evergreen.V10.Bounds.Bounds Evergreen.V10.Units.CellUnit)
    | MailEditorToBackend Evergreen.V10.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V10.Id.Id Evergreen.V10.Id.TrainId)
    | CancelTeleportHomeTrainRequest (Evergreen.V10.Id.Id Evergreen.V10.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V10.Id.Id Evergreen.V10.Id.TrainId)


type BackendMsg
    = UserDisconnected Lamdera.SessionId Lamdera.ClientId
    | NotifyAdminTimeElapsed Time.Posix
    | NotifyAdminEmailSent
    | ChangeEmailSent Time.Posix EmailAddress.EmailAddress (Result SendGrid.Error ())
    | UpdateFromFrontend Lamdera.SessionId Lamdera.ClientId ToBackend Time.Posix
    | WorldUpdateTimeElapsed Time.Posix


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V10.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V10.Id.Id Evergreen.V10.Id.TrainId) Evergreen.V10.Train.Train)
    | MailEditorToFrontend Evergreen.V10.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V10.Id.Id Evergreen.V10.Id.MailId) Evergreen.V10.MailEditor.FrontendMail)
