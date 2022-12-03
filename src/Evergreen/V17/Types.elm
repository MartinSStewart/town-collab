module Evergreen.V17.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V17.Bounds
import Evergreen.V17.Change
import Evergreen.V17.Color
import Evergreen.V17.Coord
import Evergreen.V17.Grid
import Evergreen.V17.Id
import Evergreen.V17.LocalGrid
import Evergreen.V17.LocalModel
import Evergreen.V17.MailEditor
import Evergreen.V17.PingData
import Evergreen.V17.Point2d
import Evergreen.V17.Shaders
import Evergreen.V17.Sound
import Evergreen.V17.Tile
import Evergreen.V17.Train
import Evergreen.V17.Units
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
    | WindowResized (Evergreen.V17.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V17.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V17.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V17.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    | UserTagMouseEntered (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    | UserTagMouseExited (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed 
    { userId : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    , hidePoint : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.WorldUnit)
    }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V17.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged


type alias LoadingData_ = 
    { user : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    , grid : Evergreen.V17.Grid.GridData
    , hiddenUsers : (EverySet.EverySet (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId))
    , adminHiddenUsers : (EverySet.EverySet (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId))
    , undoHistory : (List (Dict.Dict Evergreen.V17.Coord.RawCellCoord Int))
    , redoHistory : (List (Dict.Dict Evergreen.V17.Coord.RawCellCoord Int))
    , undoCurrent : (Dict.Dict Evergreen.V17.Coord.RawCellCoord Int)
    , viewBounds : (Evergreen.V17.Bounds.Bounds Evergreen.V17.Units.CellUnit)
    , trains : (AssocList.Dict (Evergreen.V17.Id.Id Evergreen.V17.Id.TrainId) Evergreen.V17.Train.Train)
    , mail : (AssocList.Dict (Evergreen.V17.Id.Id Evergreen.V17.Id.MailId) Evergreen.V17.MailEditor.FrontendMail)
    , mailEditor : Evergreen.V17.MailEditor.MailEditorData
    }


type alias FrontendLoading = 
    { key : Browser.Navigation.Key
    , windowSize : (Evergreen.V17.Coord.Coord Pixels.Pixels)
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : (Maybe Time.Posix)
    , viewPoint : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.WorldUnit)
    , mousePosition : (Evergreen.V17.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    , sounds : (AssocList.Dict Evergreen.V17.Sound.Sound (Result Audio.LoadError Audio.Source))
    , loadingData : (Maybe LoadingData_)
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V17.Point2d.Point2d Evergreen.V17.Units.WorldUnit Evergreen.V17.Units.WorldUnit)
    | TrainViewPoint 
    { trainId : (Evergreen.V17.Id.Id Evergreen.V17.Id.TrainId)
    , startViewPoint : (Evergreen.V17.Point2d.Point2d Evergreen.V17.Units.WorldUnit Evergreen.V17.Units.WorldUnit)
    , startTime : Time.Posix
    }


type Hover
    = TileHover Evergreen.V17.Tile.Tile
    | ToolbarHover
    | PostOfficeHover 
    { postOfficePosition : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.WorldUnit)
    }
    | TrainHover 
    { trainId : (Evergreen.V17.Id.Id Evergreen.V17.Id.TrainId)
    , train : Evergreen.V17.Train.Train
    }
    | TrainHouseHover 
    { trainHousePosition : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.WorldUnit)
    }
    | HouseHover 
    { housePosition : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.WorldUnit)
    }
    | MapHover
    | MailEditorHover Evergreen.V17.MailEditor.Hover


type MouseButtonState
    = MouseButtonUp 
    { current : (Evergreen.V17.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    }
    | MouseButtonDown 
    { start : (Evergreen.V17.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    , start_ : (Evergreen.V17.Point2d.Point2d Evergreen.V17.Units.WorldUnit Evergreen.V17.Units.WorldUnit)
    , current : (Evergreen.V17.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    , hover : Hover
    }


type alias RemovedTileParticle = 
    { time : Time.Posix
    , position : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.WorldUnit)
    , tile : Evergreen.V17.Tile.Tile
    }


type alias FrontendLoaded = 
    { key : Browser.Navigation.Key
    , localModel : (Evergreen.V17.LocalModel.LocalModel Evergreen.V17.Change.Change Evergreen.V17.LocalGrid.LocalGrid)
    , trains : (AssocList.Dict (Evergreen.V17.Id.Id Evergreen.V17.Id.TrainId) Evergreen.V17.Train.Train)
    , meshes : (Dict.Dict Evergreen.V17.Coord.RawCellCoord 
    { foreground : (WebGL.Mesh Evergreen.V17.Shaders.Vertex)
    , background : (WebGL.Mesh Evergreen.V17.Shaders.Vertex)
    })
    , viewPoint : ViewPoint
    , viewPointLastInterval : (Evergreen.V17.Point2d.Point2d Evergreen.V17.Units.WorldUnit Evergreen.V17.Units.WorldUnit)
    , texture : (Maybe WebGL.Texture.Texture)
    , trainTexture : (Maybe WebGL.Texture.Texture)
    , pressedKeys : (List Keyboard.Key)
    , windowSize : (Evergreen.V17.Coord.Coord Pixels.Pixels)
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : (Maybe (Time.Posix, (Evergreen.V17.Point2d.Point2d Pixels.Pixels Pixels.Pixels)))
    , mouseMiddle : MouseButtonState
    , pendingChanges : (List ((Evergreen.V17.Id.Id Evergreen.V17.Id.EventId), Evergreen.V17.Change.LocalChange))
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : (Maybe (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId))
    , highlightContextMenu : (Maybe 
    { userId : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    , hidePoint : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.WorldUnit)
    })
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced : (Maybe 
    { time : Time.Posix
    , overwroteTiles : Bool
    , tile : Evergreen.V17.Tile.Tile
    , position : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.WorldUnit)
    })
    , sounds : (AssocList.Dict Evergreen.V17.Sound.Sound (Result Audio.LoadError Audio.Source))
    , removedTileParticles : (List RemovedTileParticle)
    , debrisMesh : (WebGL.Mesh Evergreen.V17.Shaders.DebrisVertex)
    , lastTrainWhistle : (Maybe Time.Posix)
    , mail : (AssocList.Dict (Evergreen.V17.Id.Id Evergreen.V17.Id.MailId) Evergreen.V17.MailEditor.FrontendMail)
    , mailEditor : Evergreen.V17.MailEditor.Model
    , currentTile : (Maybe 
    { tile : Evergreen.V17.Tile.Tile
    , mesh : (WebGL.Mesh Evergreen.V17.Shaders.Vertex)
    })
    , lastTileRotation : (List Time.Posix)
    , userIdMesh : (WebGL.Mesh Evergreen.V17.Shaders.Vertex)
    , lastPlacementError : (Maybe Time.Posix)
    , tileHotkeys : (Dict.Dict String Evergreen.V17.Tile.Tile)
    , toolbarMesh : (WebGL.Mesh Evergreen.V17.Shaders.Vertex)
    , previousTileHover : (Maybe Evergreen.V17.Tile.Tile)
    , lastHouseClick : (Maybe Time.Posix)
    , eventIdCounter : (Evergreen.V17.Id.Id Evergreen.V17.Id.EventId)
    , pingData : (Maybe Evergreen.V17.PingData.PingData)
    , pingStartTime : (Maybe Time.Posix)
    , localTime : Time.Posix
    , scrollThreshold : Float
    , tileColors : (AssocList.Dict Evergreen.V17.Tile.Tile 
    { primaryColor : Evergreen.V17.Color.Color
    , secondaryColor : Evergreen.V17.Color.Color
    })
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =(Audio.Model FrontendMsg_ FrontendModel_)


type alias BackendUserData = 
    { hiddenUsers : (EverySet.EverySet (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId))
    , hiddenForAll : Bool
    , undoHistory : (List (Dict.Dict Evergreen.V17.Coord.RawCellCoord Int))
    , redoHistory : (List (Dict.Dict Evergreen.V17.Coord.RawCellCoord Int))
    , undoCurrent : (Dict.Dict Evergreen.V17.Coord.RawCellCoord Int)
    , mailEditor : Evergreen.V17.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V17.Grid.Grid
    , userSessions : (Dict.Dict Lamdera.SessionId 
    { clientIds : (Dict.Dict Lamdera.ClientId (Evergreen.V17.Bounds.Bounds Evergreen.V17.Units.CellUnit))
    , userId : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    })
    , users : (Dict.Dict Int BackendUserData)
    , usersHiddenRecently : (List 
    { reporter : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    , hiddenUser : (Evergreen.V17.Id.Id Evergreen.V17.Id.UserId)
    , hidePoint : (Evergreen.V17.Coord.Coord Evergreen.V17.Units.WorldUnit)
    })
    , secretLinkCounter : Int
    , errors : (List (Time.Posix, BackendError))
    , trains : (AssocList.Dict (Evergreen.V17.Id.Id Evergreen.V17.Id.TrainId) Evergreen.V17.Train.Train)
    , lastWorldUpdateTrains : (AssocList.Dict (Evergreen.V17.Id.Id Evergreen.V17.Id.TrainId) Evergreen.V17.Train.Train)
    , lastWorldUpdate : (Maybe Time.Posix)
    , mail : (AssocList.Dict (Evergreen.V17.Id.Id Evergreen.V17.Id.MailId) Evergreen.V17.MailEditor.BackendMail)
    }


type alias FrontendMsg =(Audio.Msg FrontendMsg_)


type ToBackend
    = ConnectToBackend (Evergreen.V17.Bounds.Bounds Evergreen.V17.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty ((Evergreen.V17.Id.Id Evergreen.V17.Id.EventId), Evergreen.V17.Change.LocalChange))
    | ChangeViewBounds (Evergreen.V17.Bounds.Bounds Evergreen.V17.Units.CellUnit)
    | MailEditorToBackend Evergreen.V17.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V17.Id.Id Evergreen.V17.Id.TrainId) Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V17.Id.Id Evergreen.V17.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V17.Id.Id Evergreen.V17.Id.TrainId)
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
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V17.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V17.Id.Id Evergreen.V17.Id.TrainId) Evergreen.V17.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V17.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V17.Id.Id Evergreen.V17.Id.MailId) Evergreen.V17.MailEditor.FrontendMail)
    | PingResponse Time.Posix