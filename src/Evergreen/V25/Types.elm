module Evergreen.V25.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V25.Bounds
import Evergreen.V25.Change
import Evergreen.V25.Color
import Evergreen.V25.Coord
import Evergreen.V25.Grid
import Evergreen.V25.Id
import Evergreen.V25.LocalGrid
import Evergreen.V25.LocalModel
import Evergreen.V25.MailEditor
import Evergreen.V25.PingData
import Evergreen.V25.Point2d
import Evergreen.V25.Shaders
import Evergreen.V25.Sound
import Evergreen.V25.TextInput
import Evergreen.V25.Tile
import Evergreen.V25.Train
import Evergreen.V25.Units
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
    | WindowResized (Evergreen.V25.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V25.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V25.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V25.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    | UserTagMouseEntered (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    | UserTagMouseExited (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
        , hidePoint : Evergreen.V25.Coord.Coord Evergreen.V25.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V25.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged
    | PastedText String


type alias LoadingData_ =
    { user : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    , grid : Evergreen.V25.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V25.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V25.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V25.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V25.Bounds.Bounds Evergreen.V25.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V25.Id.Id Evergreen.V25.Id.TrainId) Evergreen.V25.Train.Train
    , mail : AssocList.Dict (Evergreen.V25.Id.Id Evergreen.V25.Id.MailId) Evergreen.V25.MailEditor.FrontendMail
    , mailEditor : Evergreen.V25.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V25.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V25.Coord.Coord Evergreen.V25.Units.WorldUnit
    , mousePosition : Evergreen.V25.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V25.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    , texture : Maybe WebGL.Texture.Texture
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V25.Point2d.Point2d Evergreen.V25.Units.WorldUnit Evergreen.V25.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V25.Id.Id Evergreen.V25.Id.TrainId
        , startViewPoint : Evergreen.V25.Point2d.Point2d Evergreen.V25.Units.WorldUnit Evergreen.V25.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V25.Tile.TileGroup
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V25.Coord.Coord Evergreen.V25.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V25.Id.Id Evergreen.V25.Id.TrainId
        , train : Evergreen.V25.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V25.Coord.Coord Evergreen.V25.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V25.Coord.Coord Evergreen.V25.Units.WorldUnit
        }
    | MapHover
    | MailEditorHover Evergreen.V25.MailEditor.Hover
    | PrimaryColorInput
    | SecondaryColorInput


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V25.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V25.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V25.Point2d.Point2d Evergreen.V25.Units.WorldUnit Evergreen.V25.Units.WorldUnit
        , current : Evergreen.V25.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V25.Coord.Coord Evergreen.V25.Units.WorldUnit
    , tile : Evergreen.V25.Tile.Tile
    , primaryColor : Evergreen.V25.Color.Color
    , secondaryColor : Evergreen.V25.Color.Color
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V25.LocalModel.LocalModel Evergreen.V25.Change.Change Evergreen.V25.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V25.Id.Id Evergreen.V25.Id.TrainId) Evergreen.V25.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V25.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V25.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V25.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V25.Point2d.Point2d Evergreen.V25.Units.WorldUnit Evergreen.V25.Units.WorldUnit
    , texture : WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V25.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V25.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V25.Id.Id Evergreen.V25.Id.EventId, Evergreen.V25.Change.LocalChange )
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
            , hidePoint : Evergreen.V25.Coord.Coord Evergreen.V25.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V25.Tile.Tile
            , position : Evergreen.V25.Coord.Coord Evergreen.V25.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V25.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V25.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V25.Id.Id Evergreen.V25.Id.MailId) Evergreen.V25.MailEditor.FrontendMail
    , mailEditor : Evergreen.V25.MailEditor.Model
    , currentTile :
        Maybe
            { tileGroup : Evergreen.V25.Tile.TileGroup
            , index : Int
            , mesh : WebGL.Mesh Evergreen.V25.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V25.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V25.Tile.TileGroup
    , toolbarMesh : WebGL.Mesh Evergreen.V25.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V25.Tile.TileGroup
    , lastHouseClick : Maybe Time.Posix
    , eventIdCounter : Evergreen.V25.Id.Id Evergreen.V25.Id.EventId
    , pingData : Maybe Evergreen.V25.PingData.PingData
    , pingStartTime : Maybe Time.Posix
    , localTime : Time.Posix
    , scrollThreshold : Float
    , tileColors :
        AssocList.Dict
            Evergreen.V25.Tile.TileGroup
            { primaryColor : Evergreen.V25.Color.Color
            , secondaryColor : Evergreen.V25.Color.Color
            }
    , primaryColorTextInput : Evergreen.V25.TextInput.Model
    , secondaryColorTextInput : Evergreen.V25.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Time.Posix
        , sound : Evergreen.V25.Sound.Sound
        }
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V25.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V25.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V25.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V25.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V25.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V25.Bounds.Bounds Evergreen.V25.Units.CellUnit)
            , userId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
            , hiddenUser : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
            , hidePoint : Evergreen.V25.Coord.Coord Evergreen.V25.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V25.Id.Id Evergreen.V25.Id.TrainId) Evergreen.V25.Train.Train
    , lastWorldUpdateTrains : AssocList.Dict (Evergreen.V25.Id.Id Evergreen.V25.Id.TrainId) Evergreen.V25.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V25.Id.Id Evergreen.V25.Id.MailId) Evergreen.V25.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V25.Bounds.Bounds Evergreen.V25.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V25.Id.Id Evergreen.V25.Id.EventId, Evergreen.V25.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V25.Bounds.Bounds Evergreen.V25.Units.CellUnit)
    | MailEditorToBackend Evergreen.V25.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V25.Id.Id Evergreen.V25.Id.TrainId) Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V25.Id.Id Evergreen.V25.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V25.Id.Id Evergreen.V25.Id.TrainId)
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
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V25.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V25.Id.Id Evergreen.V25.Id.TrainId) Evergreen.V25.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V25.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V25.Id.Id Evergreen.V25.Id.MailId) Evergreen.V25.MailEditor.FrontendMail)
    | PingResponse Time.Posix
