module Evergreen.V24.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V24.Bounds
import Evergreen.V24.Change
import Evergreen.V24.Color
import Evergreen.V24.Coord
import Evergreen.V24.Grid
import Evergreen.V24.Id
import Evergreen.V24.LocalGrid
import Evergreen.V24.LocalModel
import Evergreen.V24.MailEditor
import Evergreen.V24.PingData
import Evergreen.V24.Point2d
import Evergreen.V24.Shaders
import Evergreen.V24.Sound
import Evergreen.V24.TextInput
import Evergreen.V24.Tile
import Evergreen.V24.Train
import Evergreen.V24.Units
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
    | WindowResized (Evergreen.V24.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V24.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V24.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V24.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    | UserTagMouseEntered (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    | UserTagMouseExited (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
        , hidePoint : Evergreen.V24.Coord.Coord Evergreen.V24.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V24.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged
    | PastedText String


type alias LoadingData_ =
    { user : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
    , grid : Evergreen.V24.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V24.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V24.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V24.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V24.Bounds.Bounds Evergreen.V24.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V24.Id.Id Evergreen.V24.Id.TrainId) Evergreen.V24.Train.Train
    , mail : AssocList.Dict (Evergreen.V24.Id.Id Evergreen.V24.Id.MailId) Evergreen.V24.MailEditor.FrontendMail
    , mailEditor : Evergreen.V24.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V24.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V24.Coord.Coord Evergreen.V24.Units.WorldUnit
    , mousePosition : Evergreen.V24.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V24.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    , texture : Maybe WebGL.Texture.Texture
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V24.Point2d.Point2d Evergreen.V24.Units.WorldUnit Evergreen.V24.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V24.Id.Id Evergreen.V24.Id.TrainId
        , startViewPoint : Evergreen.V24.Point2d.Point2d Evergreen.V24.Units.WorldUnit Evergreen.V24.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V24.Tile.TileGroup
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V24.Coord.Coord Evergreen.V24.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V24.Id.Id Evergreen.V24.Id.TrainId
        , train : Evergreen.V24.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V24.Coord.Coord Evergreen.V24.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V24.Coord.Coord Evergreen.V24.Units.WorldUnit
        }
    | MapHover
    | MailEditorHover Evergreen.V24.MailEditor.Hover
    | PrimaryColorInput
    | SecondaryColorInput


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V24.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V24.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V24.Point2d.Point2d Evergreen.V24.Units.WorldUnit Evergreen.V24.Units.WorldUnit
        , current : Evergreen.V24.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V24.Coord.Coord Evergreen.V24.Units.WorldUnit
    , tile : Evergreen.V24.Tile.Tile
    , primaryColor : Evergreen.V24.Color.Color
    , secondaryColor : Evergreen.V24.Color.Color
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V24.LocalModel.LocalModel Evergreen.V24.Change.Change Evergreen.V24.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V24.Id.Id Evergreen.V24.Id.TrainId) Evergreen.V24.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V24.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V24.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V24.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V24.Point2d.Point2d Evergreen.V24.Units.WorldUnit Evergreen.V24.Units.WorldUnit
    , texture : WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V24.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V24.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V24.Id.Id Evergreen.V24.Id.EventId, Evergreen.V24.Change.LocalChange )
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
            , hidePoint : Evergreen.V24.Coord.Coord Evergreen.V24.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V24.Tile.Tile
            , position : Evergreen.V24.Coord.Coord Evergreen.V24.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V24.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V24.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V24.Id.Id Evergreen.V24.Id.MailId) Evergreen.V24.MailEditor.FrontendMail
    , mailEditor : Evergreen.V24.MailEditor.Model
    , currentTile :
        Maybe
            { tileGroup : Evergreen.V24.Tile.TileGroup
            , index : Int
            , mesh : WebGL.Mesh Evergreen.V24.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V24.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V24.Tile.TileGroup
    , toolbarMesh : WebGL.Mesh Evergreen.V24.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V24.Tile.TileGroup
    , lastHouseClick : Maybe Time.Posix
    , eventIdCounter : Evergreen.V24.Id.Id Evergreen.V24.Id.EventId
    , pingData : Maybe Evergreen.V24.PingData.PingData
    , pingStartTime : Maybe Time.Posix
    , localTime : Time.Posix
    , scrollThreshold : Float
    , tileColors :
        AssocList.Dict
            Evergreen.V24.Tile.TileGroup
            { primaryColor : Evergreen.V24.Color.Color
            , secondaryColor : Evergreen.V24.Color.Color
            }
    , primaryColorTextInput : Evergreen.V24.TextInput.Model
    , secondaryColorTextInput : Evergreen.V24.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Time.Posix
        , sound : Evergreen.V24.Sound.Sound
        }
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V24.Id.Id Evergreen.V24.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V24.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V24.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V24.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V24.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V24.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V24.Bounds.Bounds Evergreen.V24.Units.CellUnit)
            , userId : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
            , hiddenUser : Evergreen.V24.Id.Id Evergreen.V24.Id.UserId
            , hidePoint : Evergreen.V24.Coord.Coord Evergreen.V24.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V24.Id.Id Evergreen.V24.Id.TrainId) Evergreen.V24.Train.Train
    , lastWorldUpdateTrains : AssocList.Dict (Evergreen.V24.Id.Id Evergreen.V24.Id.TrainId) Evergreen.V24.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V24.Id.Id Evergreen.V24.Id.MailId) Evergreen.V24.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V24.Bounds.Bounds Evergreen.V24.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V24.Id.Id Evergreen.V24.Id.EventId, Evergreen.V24.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V24.Bounds.Bounds Evergreen.V24.Units.CellUnit)
    | MailEditorToBackend Evergreen.V24.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V24.Id.Id Evergreen.V24.Id.TrainId) Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V24.Id.Id Evergreen.V24.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V24.Id.Id Evergreen.V24.Id.TrainId)
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
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V24.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V24.Id.Id Evergreen.V24.Id.TrainId) Evergreen.V24.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V24.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V24.Id.Id Evergreen.V24.Id.MailId) Evergreen.V24.MailEditor.FrontendMail)
    | PingResponse Time.Posix
