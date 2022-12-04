module Evergreen.V18.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V18.Bounds
import Evergreen.V18.Change
import Evergreen.V18.Color
import Evergreen.V18.Coord
import Evergreen.V18.Grid
import Evergreen.V18.Id
import Evergreen.V18.LocalGrid
import Evergreen.V18.LocalModel
import Evergreen.V18.MailEditor
import Evergreen.V18.PingData
import Evergreen.V18.Point2d
import Evergreen.V18.Shaders
import Evergreen.V18.Sound
import Evergreen.V18.TextInput
import Evergreen.V18.Tile
import Evergreen.V18.Train
import Evergreen.V18.Units
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
    | WindowResized (Evergreen.V18.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V18.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V18.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V18.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V18.Id.Id Evergreen.V18.Id.UserId)
    | UserTagMouseEntered (Evergreen.V18.Id.Id Evergreen.V18.Id.UserId)
    | UserTagMouseExited (Evergreen.V18.Id.Id Evergreen.V18.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
        , hidePoint : Evergreen.V18.Coord.Coord Evergreen.V18.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V18.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged


type alias LoadingData_ =
    { user : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
    , grid : Evergreen.V18.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V18.Id.Id Evergreen.V18.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V18.Id.Id Evergreen.V18.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V18.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V18.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V18.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V18.Bounds.Bounds Evergreen.V18.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V18.Id.Id Evergreen.V18.Id.TrainId) Evergreen.V18.Train.Train
    , mail : AssocList.Dict (Evergreen.V18.Id.Id Evergreen.V18.Id.MailId) Evergreen.V18.MailEditor.FrontendMail
    , mailEditor : Evergreen.V18.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V18.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V18.Coord.Coord Evergreen.V18.Units.WorldUnit
    , mousePosition : Evergreen.V18.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V18.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V18.Point2d.Point2d Evergreen.V18.Units.WorldUnit Evergreen.V18.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V18.Id.Id Evergreen.V18.Id.TrainId
        , startViewPoint : Evergreen.V18.Point2d.Point2d Evergreen.V18.Units.WorldUnit Evergreen.V18.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V18.Tile.Tile
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V18.Coord.Coord Evergreen.V18.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V18.Id.Id Evergreen.V18.Id.TrainId
        , train : Evergreen.V18.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V18.Coord.Coord Evergreen.V18.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V18.Coord.Coord Evergreen.V18.Units.WorldUnit
        }
    | MapHover
    | MailEditorHover Evergreen.V18.MailEditor.Hover
    | PrimaryColorInput
    | SecondaryColorInput


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V18.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V18.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V18.Point2d.Point2d Evergreen.V18.Units.WorldUnit Evergreen.V18.Units.WorldUnit
        , current : Evergreen.V18.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V18.Coord.Coord Evergreen.V18.Units.WorldUnit
    , tile : Evergreen.V18.Tile.Tile
    , primaryColor : Evergreen.V18.Color.Color
    , secondaryColor : Evergreen.V18.Color.Color
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V18.LocalModel.LocalModel Evergreen.V18.Change.Change Evergreen.V18.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V18.Id.Id Evergreen.V18.Id.TrainId) Evergreen.V18.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V18.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V18.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V18.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V18.Point2d.Point2d Evergreen.V18.Units.WorldUnit Evergreen.V18.Units.WorldUnit
    , texture : Maybe WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V18.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V18.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V18.Id.Id Evergreen.V18.Id.EventId, Evergreen.V18.Change.LocalChange )
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V18.Id.Id Evergreen.V18.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
            , hidePoint : Evergreen.V18.Coord.Coord Evergreen.V18.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V18.Tile.Tile
            , position : Evergreen.V18.Coord.Coord Evergreen.V18.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V18.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V18.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V18.Id.Id Evergreen.V18.Id.MailId) Evergreen.V18.MailEditor.FrontendMail
    , mailEditor : Evergreen.V18.MailEditor.Model
    , currentTile :
        Maybe
            { tile : Evergreen.V18.Tile.Tile
            , mesh : WebGL.Mesh Evergreen.V18.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V18.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V18.Tile.Tile
    , toolbarMesh : WebGL.Mesh Evergreen.V18.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V18.Tile.Tile
    , lastHouseClick : Maybe Time.Posix
    , eventIdCounter : Evergreen.V18.Id.Id Evergreen.V18.Id.EventId
    , pingData : Maybe Evergreen.V18.PingData.PingData
    , pingStartTime : Maybe Time.Posix
    , localTime : Time.Posix
    , scrollThreshold : Float
    , tileColors :
        AssocList.Dict
            Evergreen.V18.Tile.Tile
            { primaryColor : Evergreen.V18.Color.Color
            , secondaryColor : Evergreen.V18.Color.Color
            }
    , primaryColorTextInput : Evergreen.V18.TextInput.Model
    , secondaryColorTextInput : Evergreen.V18.TextInput.Model
    , focus : Hover
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V18.Id.Id Evergreen.V18.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V18.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V18.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V18.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V18.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V18.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V18.Bounds.Bounds Evergreen.V18.Units.CellUnit)
            , userId : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
            , hiddenUser : Evergreen.V18.Id.Id Evergreen.V18.Id.UserId
            , hidePoint : Evergreen.V18.Coord.Coord Evergreen.V18.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V18.Id.Id Evergreen.V18.Id.TrainId) Evergreen.V18.Train.Train
    , lastWorldUpdateTrains : AssocList.Dict (Evergreen.V18.Id.Id Evergreen.V18.Id.TrainId) Evergreen.V18.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V18.Id.Id Evergreen.V18.Id.MailId) Evergreen.V18.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V18.Bounds.Bounds Evergreen.V18.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V18.Id.Id Evergreen.V18.Id.EventId, Evergreen.V18.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V18.Bounds.Bounds Evergreen.V18.Units.CellUnit)
    | MailEditorToBackend Evergreen.V18.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V18.Id.Id Evergreen.V18.Id.TrainId) Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V18.Id.Id Evergreen.V18.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V18.Id.Id Evergreen.V18.Id.TrainId)
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
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V18.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V18.Id.Id Evergreen.V18.Id.TrainId) Evergreen.V18.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V18.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V18.Id.Id Evergreen.V18.Id.MailId) Evergreen.V18.MailEditor.FrontendMail)
    | PingResponse Time.Posix
