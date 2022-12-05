module Evergreen.V20.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V20.Bounds
import Evergreen.V20.Change
import Evergreen.V20.Color
import Evergreen.V20.Coord
import Evergreen.V20.Grid
import Evergreen.V20.Id
import Evergreen.V20.LocalGrid
import Evergreen.V20.LocalModel
import Evergreen.V20.MailEditor
import Evergreen.V20.PingData
import Evergreen.V20.Point2d
import Evergreen.V20.Shaders
import Evergreen.V20.Sound
import Evergreen.V20.TextInput
import Evergreen.V20.Tile
import Evergreen.V20.Train
import Evergreen.V20.Units
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
    | WindowResized (Evergreen.V20.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V20.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V20.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V20.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V20.Id.Id Evergreen.V20.Id.UserId)
    | UserTagMouseEntered (Evergreen.V20.Id.Id Evergreen.V20.Id.UserId)
    | UserTagMouseExited (Evergreen.V20.Id.Id Evergreen.V20.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V20.Id.Id Evergreen.V20.Id.UserId
        , hidePoint : Evergreen.V20.Coord.Coord Evergreen.V20.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V20.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged


type alias LoadingData_ =
    { user : Evergreen.V20.Id.Id Evergreen.V20.Id.UserId
    , grid : Evergreen.V20.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V20.Id.Id Evergreen.V20.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V20.Id.Id Evergreen.V20.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V20.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V20.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V20.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V20.Bounds.Bounds Evergreen.V20.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V20.Id.Id Evergreen.V20.Id.TrainId) Evergreen.V20.Train.Train
    , mail : AssocList.Dict (Evergreen.V20.Id.Id Evergreen.V20.Id.MailId) Evergreen.V20.MailEditor.FrontendMail
    , mailEditor : Evergreen.V20.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V20.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V20.Coord.Coord Evergreen.V20.Units.WorldUnit
    , mousePosition : Evergreen.V20.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V20.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    , texture : Maybe WebGL.Texture.Texture
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V20.Point2d.Point2d Evergreen.V20.Units.WorldUnit Evergreen.V20.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V20.Id.Id Evergreen.V20.Id.TrainId
        , startViewPoint : Evergreen.V20.Point2d.Point2d Evergreen.V20.Units.WorldUnit Evergreen.V20.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V20.Tile.Tile
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V20.Coord.Coord Evergreen.V20.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V20.Id.Id Evergreen.V20.Id.TrainId
        , train : Evergreen.V20.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V20.Coord.Coord Evergreen.V20.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V20.Coord.Coord Evergreen.V20.Units.WorldUnit
        }
    | MapHover
    | MailEditorHover Evergreen.V20.MailEditor.Hover
    | PrimaryColorInput
    | SecondaryColorInput


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V20.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V20.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V20.Point2d.Point2d Evergreen.V20.Units.WorldUnit Evergreen.V20.Units.WorldUnit
        , current : Evergreen.V20.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V20.Coord.Coord Evergreen.V20.Units.WorldUnit
    , tile : Evergreen.V20.Tile.Tile
    , primaryColor : Evergreen.V20.Color.Color
    , secondaryColor : Evergreen.V20.Color.Color
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V20.LocalModel.LocalModel Evergreen.V20.Change.Change Evergreen.V20.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V20.Id.Id Evergreen.V20.Id.TrainId) Evergreen.V20.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V20.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V20.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V20.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V20.Point2d.Point2d Evergreen.V20.Units.WorldUnit Evergreen.V20.Units.WorldUnit
    , texture : WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V20.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V20.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V20.Id.Id Evergreen.V20.Id.EventId, Evergreen.V20.Change.LocalChange )
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V20.Id.Id Evergreen.V20.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V20.Id.Id Evergreen.V20.Id.UserId
            , hidePoint : Evergreen.V20.Coord.Coord Evergreen.V20.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V20.Tile.Tile
            , position : Evergreen.V20.Coord.Coord Evergreen.V20.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V20.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V20.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V20.Id.Id Evergreen.V20.Id.MailId) Evergreen.V20.MailEditor.FrontendMail
    , mailEditor : Evergreen.V20.MailEditor.Model
    , currentTile :
        Maybe
            { tile : Evergreen.V20.Tile.Tile
            , mesh : WebGL.Mesh Evergreen.V20.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V20.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V20.Tile.Tile
    , toolbarMesh : WebGL.Mesh Evergreen.V20.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V20.Tile.Tile
    , lastHouseClick : Maybe Time.Posix
    , eventIdCounter : Evergreen.V20.Id.Id Evergreen.V20.Id.EventId
    , pingData : Maybe Evergreen.V20.PingData.PingData
    , pingStartTime : Maybe Time.Posix
    , localTime : Time.Posix
    , scrollThreshold : Float
    , tileColors :
        AssocList.Dict
            Evergreen.V20.Tile.Tile
            { primaryColor : Evergreen.V20.Color.Color
            , secondaryColor : Evergreen.V20.Color.Color
            }
    , primaryColorTextInput : Evergreen.V20.TextInput.Model
    , secondaryColorTextInput : Evergreen.V20.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Time.Posix
        , sound : Evergreen.V20.Sound.Sound
        }
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V20.Id.Id Evergreen.V20.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V20.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V20.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V20.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V20.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V20.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V20.Bounds.Bounds Evergreen.V20.Units.CellUnit)
            , userId : Evergreen.V20.Id.Id Evergreen.V20.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V20.Id.Id Evergreen.V20.Id.UserId
            , hiddenUser : Evergreen.V20.Id.Id Evergreen.V20.Id.UserId
            , hidePoint : Evergreen.V20.Coord.Coord Evergreen.V20.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V20.Id.Id Evergreen.V20.Id.TrainId) Evergreen.V20.Train.Train
    , lastWorldUpdateTrains : AssocList.Dict (Evergreen.V20.Id.Id Evergreen.V20.Id.TrainId) Evergreen.V20.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V20.Id.Id Evergreen.V20.Id.MailId) Evergreen.V20.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V20.Bounds.Bounds Evergreen.V20.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V20.Id.Id Evergreen.V20.Id.EventId, Evergreen.V20.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V20.Bounds.Bounds Evergreen.V20.Units.CellUnit)
    | MailEditorToBackend Evergreen.V20.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V20.Id.Id Evergreen.V20.Id.TrainId) Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V20.Id.Id Evergreen.V20.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V20.Id.Id Evergreen.V20.Id.TrainId)
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
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V20.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V20.Id.Id Evergreen.V20.Id.TrainId) Evergreen.V20.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V20.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V20.Id.Id Evergreen.V20.Id.MailId) Evergreen.V20.MailEditor.FrontendMail)
    | PingResponse Time.Posix
