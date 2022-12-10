module Evergreen.V27.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V27.Bounds
import Evergreen.V27.Change
import Evergreen.V27.Color
import Evergreen.V27.Coord
import Evergreen.V27.Grid
import Evergreen.V27.Id
import Evergreen.V27.LocalGrid
import Evergreen.V27.LocalModel
import Evergreen.V27.MailEditor
import Evergreen.V27.PingData
import Evergreen.V27.Point2d
import Evergreen.V27.Shaders
import Evergreen.V27.Sound
import Evergreen.V27.TextInput
import Evergreen.V27.Tile
import Evergreen.V27.Train
import Evergreen.V27.Units
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
    | WindowResized (Evergreen.V27.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V27.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V27.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V27.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    | UserTagMouseEntered (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    | UserTagMouseExited (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
        , hidePoint : Evergreen.V27.Coord.Coord Evergreen.V27.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V27.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged
    | PastedText String


type alias LoadingData_ =
    { user : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , grid : Evergreen.V27.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V27.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V27.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V27.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V27.Bounds.Bounds Evergreen.V27.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.TrainId) Evergreen.V27.Train.Train
    , mail : AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.MailId) Evergreen.V27.MailEditor.FrontendMail
    , mailEditor : Evergreen.V27.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V27.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V27.Coord.Coord Evergreen.V27.Units.WorldUnit
    , mousePosition : Evergreen.V27.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V27.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    , texture : Maybe WebGL.Texture.Texture
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V27.Point2d.Point2d Evergreen.V27.Units.WorldUnit Evergreen.V27.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V27.Id.Id Evergreen.V27.Id.TrainId
        , startViewPoint : Evergreen.V27.Point2d.Point2d Evergreen.V27.Units.WorldUnit Evergreen.V27.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V27.Tile.TileGroup
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V27.Coord.Coord Evergreen.V27.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V27.Id.Id Evergreen.V27.Id.TrainId
        , train : Evergreen.V27.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V27.Coord.Coord Evergreen.V27.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V27.Coord.Coord Evergreen.V27.Units.WorldUnit
        }
    | MapHover
    | MailEditorHover Evergreen.V27.MailEditor.Hover
    | PrimaryColorInput
    | SecondaryColorInput


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V27.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V27.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V27.Point2d.Point2d Evergreen.V27.Units.WorldUnit Evergreen.V27.Units.WorldUnit
        , current : Evergreen.V27.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V27.Coord.Coord Evergreen.V27.Units.WorldUnit
    , tile : Evergreen.V27.Tile.Tile
    , primaryColor : Evergreen.V27.Color.Color
    , secondaryColor : Evergreen.V27.Color.Color
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V27.LocalModel.LocalModel Evergreen.V27.Change.Change Evergreen.V27.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.TrainId) Evergreen.V27.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V27.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V27.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V27.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V27.Point2d.Point2d Evergreen.V27.Units.WorldUnit Evergreen.V27.Units.WorldUnit
    , texture : WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V27.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V27.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V27.Id.Id Evergreen.V27.Id.EventId, Evergreen.V27.Change.LocalChange )
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
            , hidePoint : Evergreen.V27.Coord.Coord Evergreen.V27.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V27.Tile.Tile
            , position : Evergreen.V27.Coord.Coord Evergreen.V27.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V27.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V27.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.MailId) Evergreen.V27.MailEditor.FrontendMail
    , mailEditor : Evergreen.V27.MailEditor.Model
    , currentTile :
        Maybe
            { tileGroup : Evergreen.V27.Tile.TileGroup
            , index : Int
            , mesh : WebGL.Mesh Evergreen.V27.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V27.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V27.Tile.TileGroup
    , toolbarMesh : WebGL.Mesh Evergreen.V27.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V27.Tile.TileGroup
    , lastHouseClick : Maybe Time.Posix
    , eventIdCounter : Evergreen.V27.Id.Id Evergreen.V27.Id.EventId
    , pingData : Maybe Evergreen.V27.PingData.PingData
    , pingStartTime : Maybe Time.Posix
    , localTime : Time.Posix
    , scrollThreshold : Float
    , tileColors :
        AssocList.Dict
            Evergreen.V27.Tile.TileGroup
            { primaryColor : Evergreen.V27.Color.Color
            , secondaryColor : Evergreen.V27.Color.Color
            }
    , primaryColorTextInput : Evergreen.V27.TextInput.Model
    , secondaryColorTextInput : Evergreen.V27.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Time.Posix
        , sound : Evergreen.V27.Sound.Sound
        }
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V27.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V27.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V27.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V27.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V27.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V27.Bounds.Bounds Evergreen.V27.Units.CellUnit)
            , userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
            , hiddenUser : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
            , hidePoint : Evergreen.V27.Coord.Coord Evergreen.V27.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.TrainId) Evergreen.V27.Train.Train
    , lastWorldUpdateTrains : AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.TrainId) Evergreen.V27.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.MailId) Evergreen.V27.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V27.Bounds.Bounds Evergreen.V27.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V27.Id.Id Evergreen.V27.Id.EventId, Evergreen.V27.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V27.Bounds.Bounds Evergreen.V27.Units.CellUnit)
    | MailEditorToBackend Evergreen.V27.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V27.Id.Id Evergreen.V27.Id.TrainId) Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V27.Id.Id Evergreen.V27.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V27.Id.Id Evergreen.V27.Id.TrainId)
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
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V27.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.TrainId) Evergreen.V27.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V27.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.MailId) Evergreen.V27.MailEditor.FrontendMail)
    | PingResponse Time.Posix
