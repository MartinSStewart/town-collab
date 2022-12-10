module Evergreen.V26.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V26.Bounds
import Evergreen.V26.Change
import Evergreen.V26.Color
import Evergreen.V26.Coord
import Evergreen.V26.Grid
import Evergreen.V26.Id
import Evergreen.V26.LocalGrid
import Evergreen.V26.LocalModel
import Evergreen.V26.MailEditor
import Evergreen.V26.PingData
import Evergreen.V26.Point2d
import Evergreen.V26.Shaders
import Evergreen.V26.Sound
import Evergreen.V26.TextInput
import Evergreen.V26.Tile
import Evergreen.V26.Train
import Evergreen.V26.Units
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
    | WindowResized (Evergreen.V26.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V26.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V26.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V26.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    | UserTagMouseEntered (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    | UserTagMouseExited (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
        , hidePoint : Evergreen.V26.Coord.Coord Evergreen.V26.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V26.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged
    | PastedText String


type alias LoadingData_ =
    { user : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , grid : Evergreen.V26.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V26.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V26.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V26.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V26.Bounds.Bounds Evergreen.V26.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.TrainId) Evergreen.V26.Train.Train
    , mail : AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.MailId) Evergreen.V26.MailEditor.FrontendMail
    , mailEditor : Evergreen.V26.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V26.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V26.Coord.Coord Evergreen.V26.Units.WorldUnit
    , mousePosition : Evergreen.V26.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V26.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    , texture : Maybe WebGL.Texture.Texture
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V26.Point2d.Point2d Evergreen.V26.Units.WorldUnit Evergreen.V26.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V26.Id.Id Evergreen.V26.Id.TrainId
        , startViewPoint : Evergreen.V26.Point2d.Point2d Evergreen.V26.Units.WorldUnit Evergreen.V26.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V26.Tile.TileGroup
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V26.Coord.Coord Evergreen.V26.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V26.Id.Id Evergreen.V26.Id.TrainId
        , train : Evergreen.V26.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V26.Coord.Coord Evergreen.V26.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V26.Coord.Coord Evergreen.V26.Units.WorldUnit
        }
    | MapHover
    | MailEditorHover Evergreen.V26.MailEditor.Hover
    | PrimaryColorInput
    | SecondaryColorInput


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V26.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V26.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V26.Point2d.Point2d Evergreen.V26.Units.WorldUnit Evergreen.V26.Units.WorldUnit
        , current : Evergreen.V26.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V26.Coord.Coord Evergreen.V26.Units.WorldUnit
    , tile : Evergreen.V26.Tile.Tile
    , primaryColor : Evergreen.V26.Color.Color
    , secondaryColor : Evergreen.V26.Color.Color
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V26.LocalModel.LocalModel Evergreen.V26.Change.Change Evergreen.V26.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.TrainId) Evergreen.V26.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V26.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V26.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V26.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V26.Point2d.Point2d Evergreen.V26.Units.WorldUnit Evergreen.V26.Units.WorldUnit
    , texture : WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V26.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V26.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V26.Id.Id Evergreen.V26.Id.EventId, Evergreen.V26.Change.LocalChange )
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
            , hidePoint : Evergreen.V26.Coord.Coord Evergreen.V26.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V26.Tile.Tile
            , position : Evergreen.V26.Coord.Coord Evergreen.V26.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V26.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V26.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.MailId) Evergreen.V26.MailEditor.FrontendMail
    , mailEditor : Evergreen.V26.MailEditor.Model
    , currentTile :
        Maybe
            { tileGroup : Evergreen.V26.Tile.TileGroup
            , index : Int
            , mesh : WebGL.Mesh Evergreen.V26.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V26.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V26.Tile.TileGroup
    , toolbarMesh : WebGL.Mesh Evergreen.V26.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V26.Tile.TileGroup
    , lastHouseClick : Maybe Time.Posix
    , eventIdCounter : Evergreen.V26.Id.Id Evergreen.V26.Id.EventId
    , pingData : Maybe Evergreen.V26.PingData.PingData
    , pingStartTime : Maybe Time.Posix
    , localTime : Time.Posix
    , scrollThreshold : Float
    , tileColors :
        AssocList.Dict
            Evergreen.V26.Tile.TileGroup
            { primaryColor : Evergreen.V26.Color.Color
            , secondaryColor : Evergreen.V26.Color.Color
            }
    , primaryColorTextInput : Evergreen.V26.TextInput.Model
    , secondaryColorTextInput : Evergreen.V26.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Time.Posix
        , sound : Evergreen.V26.Sound.Sound
        }
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V26.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V26.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V26.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V26.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V26.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V26.Bounds.Bounds Evergreen.V26.Units.CellUnit)
            , userId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
            , hiddenUser : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
            , hidePoint : Evergreen.V26.Coord.Coord Evergreen.V26.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.TrainId) Evergreen.V26.Train.Train
    , lastWorldUpdateTrains : AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.TrainId) Evergreen.V26.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.MailId) Evergreen.V26.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V26.Bounds.Bounds Evergreen.V26.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V26.Id.Id Evergreen.V26.Id.EventId, Evergreen.V26.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V26.Bounds.Bounds Evergreen.V26.Units.CellUnit)
    | MailEditorToBackend Evergreen.V26.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V26.Id.Id Evergreen.V26.Id.TrainId) Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V26.Id.Id Evergreen.V26.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V26.Id.Id Evergreen.V26.Id.TrainId)
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
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V26.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.TrainId) Evergreen.V26.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V26.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.MailId) Evergreen.V26.MailEditor.FrontendMail)
    | PingResponse Time.Posix
