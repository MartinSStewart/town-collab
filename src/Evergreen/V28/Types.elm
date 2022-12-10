module Evergreen.V28.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V28.Bounds
import Evergreen.V28.Change
import Evergreen.V28.Color
import Evergreen.V28.Coord
import Evergreen.V28.Grid
import Evergreen.V28.Id
import Evergreen.V28.LocalGrid
import Evergreen.V28.LocalModel
import Evergreen.V28.MailEditor
import Evergreen.V28.PingData
import Evergreen.V28.Point2d
import Evergreen.V28.Shaders
import Evergreen.V28.Sound
import Evergreen.V28.TextInput
import Evergreen.V28.Tile
import Evergreen.V28.Train
import Evergreen.V28.Units
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
    | WindowResized (Evergreen.V28.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V28.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V28.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V28.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V28.Id.Id Evergreen.V28.Id.UserId)
    | UserTagMouseEntered (Evergreen.V28.Id.Id Evergreen.V28.Id.UserId)
    | UserTagMouseExited (Evergreen.V28.Id.Id Evergreen.V28.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V28.Id.Id Evergreen.V28.Id.UserId
        , hidePoint : Evergreen.V28.Coord.Coord Evergreen.V28.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V28.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged
    | PastedText String


type alias LoadingData_ =
    { user : Evergreen.V28.Id.Id Evergreen.V28.Id.UserId
    , grid : Evergreen.V28.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V28.Id.Id Evergreen.V28.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V28.Id.Id Evergreen.V28.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V28.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V28.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V28.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V28.Bounds.Bounds Evergreen.V28.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V28.Id.Id Evergreen.V28.Id.TrainId) Evergreen.V28.Train.Train
    , mail : AssocList.Dict (Evergreen.V28.Id.Id Evergreen.V28.Id.MailId) Evergreen.V28.MailEditor.FrontendMail
    , mailEditor : Evergreen.V28.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V28.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V28.Coord.Coord Evergreen.V28.Units.WorldUnit
    , mousePosition : Evergreen.V28.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V28.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    , texture : Maybe WebGL.Texture.Texture
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V28.Point2d.Point2d Evergreen.V28.Units.WorldUnit Evergreen.V28.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V28.Id.Id Evergreen.V28.Id.TrainId
        , startViewPoint : Evergreen.V28.Point2d.Point2d Evergreen.V28.Units.WorldUnit Evergreen.V28.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V28.Tile.TileGroup
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V28.Coord.Coord Evergreen.V28.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V28.Id.Id Evergreen.V28.Id.TrainId
        , train : Evergreen.V28.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V28.Coord.Coord Evergreen.V28.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V28.Coord.Coord Evergreen.V28.Units.WorldUnit
        }
    | MapHover
    | MailEditorHover Evergreen.V28.MailEditor.Hover
    | PrimaryColorInput
    | SecondaryColorInput


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V28.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V28.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V28.Point2d.Point2d Evergreen.V28.Units.WorldUnit Evergreen.V28.Units.WorldUnit
        , current : Evergreen.V28.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V28.Coord.Coord Evergreen.V28.Units.WorldUnit
    , tile : Evergreen.V28.Tile.Tile
    , primaryColor : Evergreen.V28.Color.Color
    , secondaryColor : Evergreen.V28.Color.Color
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V28.LocalModel.LocalModel Evergreen.V28.Change.Change Evergreen.V28.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V28.Id.Id Evergreen.V28.Id.TrainId) Evergreen.V28.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V28.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V28.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V28.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V28.Point2d.Point2d Evergreen.V28.Units.WorldUnit Evergreen.V28.Units.WorldUnit
    , texture : WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V28.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V28.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V28.Id.Id Evergreen.V28.Id.EventId, Evergreen.V28.Change.LocalChange )
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V28.Id.Id Evergreen.V28.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V28.Id.Id Evergreen.V28.Id.UserId
            , hidePoint : Evergreen.V28.Coord.Coord Evergreen.V28.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V28.Tile.Tile
            , position : Evergreen.V28.Coord.Coord Evergreen.V28.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V28.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V28.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V28.Id.Id Evergreen.V28.Id.MailId) Evergreen.V28.MailEditor.FrontendMail
    , mailEditor : Evergreen.V28.MailEditor.Model
    , currentTile :
        Maybe
            { tileGroup : Evergreen.V28.Tile.TileGroup
            , index : Int
            , mesh : WebGL.Mesh Evergreen.V28.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V28.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V28.Tile.TileGroup
    , toolbarMesh : WebGL.Mesh Evergreen.V28.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V28.Tile.TileGroup
    , lastHouseClick : Maybe Time.Posix
    , eventIdCounter : Evergreen.V28.Id.Id Evergreen.V28.Id.EventId
    , pingData : Maybe Evergreen.V28.PingData.PingData
    , pingStartTime : Maybe Time.Posix
    , localTime : Time.Posix
    , scrollThreshold : Float
    , tileColors :
        AssocList.Dict
            Evergreen.V28.Tile.TileGroup
            { primaryColor : Evergreen.V28.Color.Color
            , secondaryColor : Evergreen.V28.Color.Color
            }
    , primaryColorTextInput : Evergreen.V28.TextInput.Model
    , secondaryColorTextInput : Evergreen.V28.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Time.Posix
        , sound : Evergreen.V28.Sound.Sound
        }
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V28.Id.Id Evergreen.V28.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V28.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V28.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V28.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V28.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V28.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V28.Bounds.Bounds Evergreen.V28.Units.CellUnit)
            , userId : Evergreen.V28.Id.Id Evergreen.V28.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V28.Id.Id Evergreen.V28.Id.UserId
            , hiddenUser : Evergreen.V28.Id.Id Evergreen.V28.Id.UserId
            , hidePoint : Evergreen.V28.Coord.Coord Evergreen.V28.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V28.Id.Id Evergreen.V28.Id.TrainId) Evergreen.V28.Train.Train
    , lastWorldUpdateTrains : AssocList.Dict (Evergreen.V28.Id.Id Evergreen.V28.Id.TrainId) Evergreen.V28.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V28.Id.Id Evergreen.V28.Id.MailId) Evergreen.V28.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V28.Bounds.Bounds Evergreen.V28.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V28.Id.Id Evergreen.V28.Id.EventId, Evergreen.V28.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V28.Bounds.Bounds Evergreen.V28.Units.CellUnit)
    | MailEditorToBackend Evergreen.V28.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V28.Id.Id Evergreen.V28.Id.TrainId) Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V28.Id.Id Evergreen.V28.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V28.Id.Id Evergreen.V28.Id.TrainId)
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
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V28.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V28.Id.Id Evergreen.V28.Id.TrainId) Evergreen.V28.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V28.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V28.Id.Id Evergreen.V28.Id.MailId) Evergreen.V28.MailEditor.FrontendMail)
    | PingResponse Time.Posix
