module Evergreen.V30.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V30.Bounds
import Evergreen.V30.Change
import Evergreen.V30.Color
import Evergreen.V30.Coord
import Evergreen.V30.Cursor
import Evergreen.V30.Grid
import Evergreen.V30.Id
import Evergreen.V30.IdDict
import Evergreen.V30.LocalGrid
import Evergreen.V30.LocalModel
import Evergreen.V30.MailEditor
import Evergreen.V30.PingData
import Evergreen.V30.Point2d
import Evergreen.V30.Shaders
import Evergreen.V30.Sound
import Evergreen.V30.TextInput
import Evergreen.V30.Tile
import Evergreen.V30.Train
import Evergreen.V30.Units
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
    | WindowResized (Evergreen.V30.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V30.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V30.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V30.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    | UserTagMouseEntered (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    | UserTagMouseExited (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed 
    { userId : (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    , hidePoint : (Evergreen.V30.Coord.Coord Evergreen.V30.Units.WorldUnit)
    }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V30.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgent String


type alias LoadingData_ = 
    { user : (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    , grid : Evergreen.V30.Grid.GridData
    , hiddenUsers : (EverySet.EverySet (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId))
    , adminHiddenUsers : (EverySet.EverySet (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId))
    , undoHistory : (List (Dict.Dict Evergreen.V30.Coord.RawCellCoord Int))
    , redoHistory : (List (Dict.Dict Evergreen.V30.Coord.RawCellCoord Int))
    , undoCurrent : (Dict.Dict Evergreen.V30.Coord.RawCellCoord Int)
    , viewBounds : (Evergreen.V30.Bounds.Bounds Evergreen.V30.Units.CellUnit)
    , trains : (AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.TrainId) Evergreen.V30.Train.Train)
    , mail : (AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.MailId) Evergreen.V30.MailEditor.FrontendMail)
    , mailEditor : Evergreen.V30.MailEditor.MailEditorData
    , cows : (Evergreen.V30.IdDict.IdDict Evergreen.V30.Id.CowId Evergreen.V30.Change.Cow)
    , cursors : (Evergreen.V30.IdDict.IdDict Evergreen.V30.Id.UserId Evergreen.V30.LocalGrid.Cursor)
    , handColors : (Evergreen.V30.IdDict.IdDict Evergreen.V30.Id.UserId Evergreen.V30.Color.Colors)
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V30.Change.Change)
    | LoadedLocalModel (Evergreen.V30.LocalModel.LocalModel Evergreen.V30.Change.Change Evergreen.V30.LocalGrid.LocalGrid) LoadingData_


type alias FrontendLoading = 
    { key : Browser.Navigation.Key
    , windowSize : (Evergreen.V30.Coord.Coord Pixels.Pixels)
    , devicePixelRatio : (Maybe Float)
    , zoomFactor : Int
    , time : (Maybe Time.Posix)
    , viewPoint : (Evergreen.V30.Coord.Coord Evergreen.V30.Units.WorldUnit)
    , mousePosition : (Evergreen.V30.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    , sounds : (AssocList.Dict Evergreen.V30.Sound.Sound (Result Audio.LoadError Audio.Source))
    , texture : (Maybe WebGL.Texture.Texture)
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V30.Point2d.Point2d Evergreen.V30.Units.WorldUnit Evergreen.V30.Units.WorldUnit)
    | TrainViewPoint 
    { trainId : (Evergreen.V30.Id.Id Evergreen.V30.Id.TrainId)
    , startViewPoint : (Evergreen.V30.Point2d.Point2d Evergreen.V30.Units.WorldUnit Evergreen.V30.Units.WorldUnit)
    , startTime : Time.Posix
    }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V30.Tile.TileGroup
    | TilePickerToolButton


type Hover
    = ToolButtonHover ToolButton
    | ToolbarHover
    | TileHover 
    { tile : Evergreen.V30.Tile.Tile
    , userId : (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    , position : (Evergreen.V30.Coord.Coord Evergreen.V30.Units.WorldUnit)
    , colors : Evergreen.V30.Color.Colors
    }
    | TrainHover 
    { trainId : (Evergreen.V30.Id.Id Evergreen.V30.Id.TrainId)
    , train : Evergreen.V30.Train.Train
    }
    | MapHover
    | MailEditorHover Evergreen.V30.MailEditor.Hover
    | PrimaryColorInput
    | SecondaryColorInput
    | CowHover 
    { cowId : (Evergreen.V30.Id.Id Evergreen.V30.Id.CowId)
    , cow : Evergreen.V30.Change.Cow
    }


type MouseButtonState
    = MouseButtonUp 
    { current : (Evergreen.V30.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    }
    | MouseButtonDown 
    { start : (Evergreen.V30.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    , start_ : (Evergreen.V30.Point2d.Point2d Evergreen.V30.Units.WorldUnit Evergreen.V30.Units.WorldUnit)
    , current : (Evergreen.V30.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    , hover : Hover
    }


type alias RemovedTileParticle = 
    { time : Time.Posix
    , position : (Evergreen.V30.Coord.Coord Evergreen.V30.Units.WorldUnit)
    , tile : Evergreen.V30.Tile.Tile
    , colors : Evergreen.V30.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool 
    { tileGroup : Evergreen.V30.Tile.TileGroup
    , index : Int
    , mesh : (WebGL.Mesh Evergreen.V30.Shaders.Vertex)
    }
    | TilePickerTool


type alias FrontendLoaded = 
    { key : Browser.Navigation.Key
    , localModel : (Evergreen.V30.LocalModel.LocalModel Evergreen.V30.Change.Change Evergreen.V30.LocalGrid.LocalGrid)
    , trains : (AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.TrainId) Evergreen.V30.Train.Train)
    , meshes : (Dict.Dict Evergreen.V30.Coord.RawCellCoord 
    { foreground : (WebGL.Mesh Evergreen.V30.Shaders.Vertex)
    , background : (WebGL.Mesh Evergreen.V30.Shaders.Vertex)
    })
    , viewPoint : ViewPoint
    , viewPointLastInterval : (Evergreen.V30.Point2d.Point2d Evergreen.V30.Units.WorldUnit Evergreen.V30.Units.WorldUnit)
    , texture : WebGL.Texture.Texture
    , trainTexture : (Maybe WebGL.Texture.Texture)
    , pressedKeys : (List Keyboard.Key)
    , windowSize : (Evergreen.V30.Coord.Coord Pixels.Pixels)
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : (Maybe (Time.Posix, (Evergreen.V30.Point2d.Point2d Pixels.Pixels Pixels.Pixels)))
    , mouseMiddle : MouseButtonState
    , pendingChanges : (List ((Evergreen.V30.Id.Id Evergreen.V30.Id.EventId), Evergreen.V30.Change.LocalChange))
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : (Maybe (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId))
    , highlightContextMenu : (Maybe 
    { userId : (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    , hidePoint : (Evergreen.V30.Coord.Coord Evergreen.V30.Units.WorldUnit)
    })
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced : (Maybe 
    { time : Time.Posix
    , overwroteTiles : Bool
    , tile : Evergreen.V30.Tile.Tile
    , position : (Evergreen.V30.Coord.Coord Evergreen.V30.Units.WorldUnit)
    })
    , sounds : (AssocList.Dict Evergreen.V30.Sound.Sound (Result Audio.LoadError Audio.Source))
    , removedTileParticles : (List RemovedTileParticle)
    , debrisMesh : (WebGL.Mesh Evergreen.V30.Shaders.DebrisVertex)
    , lastTrainWhistle : (Maybe Time.Posix)
    , mail : (AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.MailId) Evergreen.V30.MailEditor.FrontendMail)
    , mailEditor : Evergreen.V30.MailEditor.Model
    , currentTool : Tool
    , lastTileRotation : (List Time.Posix)
    , userIdMesh : (WebGL.Mesh Evergreen.V30.Shaders.Vertex)
    , lastPlacementError : (Maybe Time.Posix)
    , tileHotkeys : (Dict.Dict String Evergreen.V30.Tile.TileGroup)
    , toolbarMesh : (WebGL.Mesh Evergreen.V30.Shaders.Vertex)
    , previousTileHover : (Maybe Evergreen.V30.Tile.TileGroup)
    , lastHouseClick : (Maybe Time.Posix)
    , eventIdCounter : (Evergreen.V30.Id.Id Evergreen.V30.Id.EventId)
    , pingData : (Maybe Evergreen.V30.PingData.PingData)
    , pingStartTime : (Maybe Time.Posix)
    , localTime : Time.Posix
    , scrollThreshold : Float
    , tileColors : (AssocList.Dict Evergreen.V30.Tile.TileGroup Evergreen.V30.Color.Colors)
    , primaryColorTextInput : Evergreen.V30.TextInput.Model
    , secondaryColorTextInput : Evergreen.V30.TextInput.Model
    , focus : Hover
    , music : 
    { startTime : Time.Posix
    , sound : Evergreen.V30.Sound.Sound
    }
    , previousCursorPositions : (Evergreen.V30.IdDict.IdDict Evergreen.V30.Id.UserId 
    { position : (Evergreen.V30.Point2d.Point2d Evergreen.V30.Units.WorldUnit Evergreen.V30.Units.WorldUnit)
    , time : Time.Posix
    })
    , handMeshes : (AssocList.Dict Evergreen.V30.Color.Colors Evergreen.V30.Cursor.CursorMeshes)
    , hasCmdKey : Bool
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =(Audio.Model FrontendMsg_ FrontendModel_)


type alias BackendUserData = 
    { hiddenUsers : (EverySet.EverySet (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId))
    , hiddenForAll : Bool
    , undoHistory : (List (Dict.Dict Evergreen.V30.Coord.RawCellCoord Int))
    , redoHistory : (List (Dict.Dict Evergreen.V30.Coord.RawCellCoord Int))
    , undoCurrent : (Dict.Dict Evergreen.V30.Coord.RawCellCoord Int)
    , mailEditor : Evergreen.V30.MailEditor.MailEditorData
    , cursor : (Maybe Evergreen.V30.LocalGrid.Cursor)
    , handColor : Evergreen.V30.Color.Colors
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V30.Grid.Grid
    , userSessions : (Dict.Dict Lamdera.SessionId 
    { clientIds : (Dict.Dict Lamdera.ClientId (Evergreen.V30.Bounds.Bounds Evergreen.V30.Units.CellUnit))
    , userId : (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    })
    , users : (Evergreen.V30.IdDict.IdDict Evergreen.V30.Id.UserId BackendUserData)
    , usersHiddenRecently : (List 
    { reporter : (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    , hiddenUser : (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    , hidePoint : (Evergreen.V30.Coord.Coord Evergreen.V30.Units.WorldUnit)
    })
    , secretLinkCounter : Int
    , errors : (List (Time.Posix, BackendError))
    , trains : (AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.TrainId) Evergreen.V30.Train.Train)
    , cows : (Evergreen.V30.IdDict.IdDict Evergreen.V30.Id.CowId Evergreen.V30.Change.Cow)
    , lastWorldUpdateTrains : (AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.TrainId) Evergreen.V30.Train.Train)
    , lastWorldUpdate : (Maybe Time.Posix)
    , mail : (AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.MailId) Evergreen.V30.MailEditor.BackendMail)
    }


type alias FrontendMsg =(Audio.Msg FrontendMsg_)


type ToBackend
    = ConnectToBackend (Evergreen.V30.Bounds.Bounds Evergreen.V30.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty ((Evergreen.V30.Id.Id Evergreen.V30.Id.EventId), Evergreen.V30.Change.LocalChange))
    | ChangeViewBounds (Evergreen.V30.Bounds.Bounds Evergreen.V30.Units.CellUnit)
    | MailEditorToBackend Evergreen.V30.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V30.Id.Id Evergreen.V30.Id.TrainId) Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V30.Id.Id Evergreen.V30.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V30.Id.Id Evergreen.V30.Id.TrainId)
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
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V30.Change.Change)
    | UnsubscribeEmailConfirmed
    | WorldUpdateBroadcast (AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.TrainId) Evergreen.V30.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V30.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.MailId) Evergreen.V30.MailEditor.FrontendMail)
    | PingResponse Time.Posix