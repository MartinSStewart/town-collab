module Evergreen.V23.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V23.Bounds
import Evergreen.V23.Change
import Evergreen.V23.Color
import Evergreen.V23.Coord
import Evergreen.V23.Grid
import Evergreen.V23.Id
import Evergreen.V23.LocalGrid
import Evergreen.V23.LocalModel
import Evergreen.V23.MailEditor
import Evergreen.V23.PingData
import Evergreen.V23.Point2d
import Evergreen.V23.Shaders
import Evergreen.V23.Sound
import Evergreen.V23.TextInput
import Evergreen.V23.Tile
import Evergreen.V23.Train
import Evergreen.V23.Units
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
    | WindowResized (Evergreen.V23.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V23.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V23.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V23.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    | UserTagMouseEntered (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    | UserTagMouseExited (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
        , hidePoint : Evergreen.V23.Coord.Coord Evergreen.V23.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V23.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged
    | PastedText String


type alias LoadingData_ =
    { user : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
    , grid : Evergreen.V23.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V23.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V23.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V23.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V23.Bounds.Bounds Evergreen.V23.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V23.Id.Id Evergreen.V23.Id.TrainId) Evergreen.V23.Train.Train
    , mail : AssocList.Dict (Evergreen.V23.Id.Id Evergreen.V23.Id.MailId) Evergreen.V23.MailEditor.FrontendMail
    , mailEditor : Evergreen.V23.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V23.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V23.Coord.Coord Evergreen.V23.Units.WorldUnit
    , mousePosition : Evergreen.V23.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V23.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    , texture : Maybe WebGL.Texture.Texture
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V23.Point2d.Point2d Evergreen.V23.Units.WorldUnit Evergreen.V23.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V23.Id.Id Evergreen.V23.Id.TrainId
        , startViewPoint : Evergreen.V23.Point2d.Point2d Evergreen.V23.Units.WorldUnit Evergreen.V23.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V23.Tile.TileGroup
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V23.Coord.Coord Evergreen.V23.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V23.Id.Id Evergreen.V23.Id.TrainId
        , train : Evergreen.V23.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V23.Coord.Coord Evergreen.V23.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V23.Coord.Coord Evergreen.V23.Units.WorldUnit
        }
    | MapHover
    | MailEditorHover Evergreen.V23.MailEditor.Hover
    | PrimaryColorInput
    | SecondaryColorInput


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V23.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V23.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V23.Point2d.Point2d Evergreen.V23.Units.WorldUnit Evergreen.V23.Units.WorldUnit
        , current : Evergreen.V23.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V23.Coord.Coord Evergreen.V23.Units.WorldUnit
    , tile : Evergreen.V23.Tile.Tile
    , primaryColor : Evergreen.V23.Color.Color
    , secondaryColor : Evergreen.V23.Color.Color
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V23.LocalModel.LocalModel Evergreen.V23.Change.Change Evergreen.V23.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V23.Id.Id Evergreen.V23.Id.TrainId) Evergreen.V23.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V23.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V23.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V23.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V23.Point2d.Point2d Evergreen.V23.Units.WorldUnit Evergreen.V23.Units.WorldUnit
    , texture : WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V23.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V23.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V23.Id.Id Evergreen.V23.Id.EventId, Evergreen.V23.Change.LocalChange )
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
            , hidePoint : Evergreen.V23.Coord.Coord Evergreen.V23.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V23.Tile.Tile
            , position : Evergreen.V23.Coord.Coord Evergreen.V23.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V23.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V23.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V23.Id.Id Evergreen.V23.Id.MailId) Evergreen.V23.MailEditor.FrontendMail
    , mailEditor : Evergreen.V23.MailEditor.Model
    , currentTile :
        Maybe
            { tileGroup : Evergreen.V23.Tile.TileGroup
            , index : Int
            , mesh : WebGL.Mesh Evergreen.V23.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V23.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V23.Tile.TileGroup
    , toolbarMesh : WebGL.Mesh Evergreen.V23.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V23.Tile.TileGroup
    , lastHouseClick : Maybe Time.Posix
    , eventIdCounter : Evergreen.V23.Id.Id Evergreen.V23.Id.EventId
    , pingData : Maybe Evergreen.V23.PingData.PingData
    , pingStartTime : Maybe Time.Posix
    , localTime : Time.Posix
    , scrollThreshold : Float
    , tileColors :
        AssocList.Dict
            Evergreen.V23.Tile.TileGroup
            { primaryColor : Evergreen.V23.Color.Color
            , secondaryColor : Evergreen.V23.Color.Color
            }
    , primaryColorTextInput : Evergreen.V23.TextInput.Model
    , secondaryColorTextInput : Evergreen.V23.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Time.Posix
        , sound : Evergreen.V23.Sound.Sound
        }
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V23.Id.Id Evergreen.V23.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V23.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V23.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V23.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V23.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V23.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V23.Bounds.Bounds Evergreen.V23.Units.CellUnit)
            , userId : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
            , hiddenUser : Evergreen.V23.Id.Id Evergreen.V23.Id.UserId
            , hidePoint : Evergreen.V23.Coord.Coord Evergreen.V23.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V23.Id.Id Evergreen.V23.Id.TrainId) Evergreen.V23.Train.Train
    , lastWorldUpdateTrains : AssocList.Dict (Evergreen.V23.Id.Id Evergreen.V23.Id.TrainId) Evergreen.V23.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V23.Id.Id Evergreen.V23.Id.MailId) Evergreen.V23.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V23.Bounds.Bounds Evergreen.V23.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V23.Id.Id Evergreen.V23.Id.EventId, Evergreen.V23.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V23.Bounds.Bounds Evergreen.V23.Units.CellUnit)
    | MailEditorToBackend Evergreen.V23.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V23.Id.Id Evergreen.V23.Id.TrainId) Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V23.Id.Id Evergreen.V23.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V23.Id.Id Evergreen.V23.Id.TrainId)
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
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V23.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V23.Id.Id Evergreen.V23.Id.TrainId) Evergreen.V23.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V23.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V23.Id.Id Evergreen.V23.Id.MailId) Evergreen.V23.MailEditor.FrontendMail)
    | PingResponse Time.Posix
