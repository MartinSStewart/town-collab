module Evergreen.V29.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V29.Bounds
import Evergreen.V29.Change
import Evergreen.V29.Color
import Evergreen.V29.Coord
import Evergreen.V29.Grid
import Evergreen.V29.Id
import Evergreen.V29.IdDict
import Evergreen.V29.LocalGrid
import Evergreen.V29.LocalModel
import Evergreen.V29.MailEditor
import Evergreen.V29.PingData
import Evergreen.V29.Point2d
import Evergreen.V29.Shaders
import Evergreen.V29.Sound
import Evergreen.V29.TextInput
import Evergreen.V29.Tile
import Evergreen.V29.Train
import Evergreen.V29.Units
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
    | WindowResized (Evergreen.V29.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V29.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V29.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V29.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    | UserTagMouseEntered (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    | UserTagMouseExited (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
        , hidePoint : Evergreen.V29.Coord.Coord Evergreen.V29.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V29.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged
    | PastedText String


type alias LoadingData_ =
    { user : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , grid : Evergreen.V29.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V29.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V29.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V29.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V29.Bounds.Bounds Evergreen.V29.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.TrainId) Evergreen.V29.Train.Train
    , mail : AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.MailId) Evergreen.V29.MailEditor.FrontendMail
    , mailEditor : Evergreen.V29.MailEditor.MailEditorData
    , cows : Evergreen.V29.IdDict.IdDict Evergreen.V29.Id.CowId Evergreen.V29.Change.Cow
    , cursors : Evergreen.V29.IdDict.IdDict Evergreen.V29.Id.UserId Evergreen.V29.LocalGrid.Cursor
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V29.Change.Change)
    | LoadedLocalModel (Evergreen.V29.LocalModel.LocalModel Evergreen.V29.Change.Change Evergreen.V29.LocalGrid.LocalGrid) LoadingData_


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V29.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Maybe Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V29.Coord.Coord Evergreen.V29.Units.WorldUnit
    , mousePosition : Evergreen.V29.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V29.Sound.Sound (Result Audio.LoadError Audio.Source)
    , texture : Maybe WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V29.Point2d.Point2d Evergreen.V29.Units.WorldUnit Evergreen.V29.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V29.Id.Id Evergreen.V29.Id.TrainId
        , startViewPoint : Evergreen.V29.Point2d.Point2d Evergreen.V29.Units.WorldUnit Evergreen.V29.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V29.Tile.TileGroup
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V29.Coord.Coord Evergreen.V29.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V29.Id.Id Evergreen.V29.Id.TrainId
        , train : Evergreen.V29.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V29.Coord.Coord Evergreen.V29.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V29.Coord.Coord Evergreen.V29.Units.WorldUnit
        }
    | MapHover
    | MailEditorHover Evergreen.V29.MailEditor.Hover
    | PrimaryColorInput
    | SecondaryColorInput
    | CowHover
        { cowId : Evergreen.V29.Id.Id Evergreen.V29.Id.CowId
        , cow : Evergreen.V29.Change.Cow
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V29.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V29.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V29.Point2d.Point2d Evergreen.V29.Units.WorldUnit Evergreen.V29.Units.WorldUnit
        , current : Evergreen.V29.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V29.Coord.Coord Evergreen.V29.Units.WorldUnit
    , tile : Evergreen.V29.Tile.Tile
    , primaryColor : Evergreen.V29.Color.Color
    , secondaryColor : Evergreen.V29.Color.Color
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V29.LocalModel.LocalModel Evergreen.V29.Change.Change Evergreen.V29.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.TrainId) Evergreen.V29.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V29.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V29.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V29.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V29.Point2d.Point2d Evergreen.V29.Units.WorldUnit Evergreen.V29.Units.WorldUnit
    , texture : WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V29.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V29.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V29.Id.Id Evergreen.V29.Id.EventId, Evergreen.V29.Change.LocalChange )
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
            , hidePoint : Evergreen.V29.Coord.Coord Evergreen.V29.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V29.Tile.Tile
            , position : Evergreen.V29.Coord.Coord Evergreen.V29.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V29.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V29.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.MailId) Evergreen.V29.MailEditor.FrontendMail
    , mailEditor : Evergreen.V29.MailEditor.Model
    , currentTile :
        Maybe
            { tileGroup : Evergreen.V29.Tile.TileGroup
            , index : Int
            , mesh : WebGL.Mesh Evergreen.V29.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V29.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V29.Tile.TileGroup
    , toolbarMesh : WebGL.Mesh Evergreen.V29.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V29.Tile.TileGroup
    , lastHouseClick : Maybe Time.Posix
    , eventIdCounter : Evergreen.V29.Id.Id Evergreen.V29.Id.EventId
    , pingData : Maybe Evergreen.V29.PingData.PingData
    , pingStartTime : Maybe Time.Posix
    , localTime : Time.Posix
    , scrollThreshold : Float
    , tileColors :
        AssocList.Dict
            Evergreen.V29.Tile.TileGroup
            { primaryColor : Evergreen.V29.Color.Color
            , secondaryColor : Evergreen.V29.Color.Color
            }
    , primaryColorTextInput : Evergreen.V29.TextInput.Model
    , secondaryColorTextInput : Evergreen.V29.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Time.Posix
        , sound : Evergreen.V29.Sound.Sound
        }
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V29.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V29.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V29.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V29.MailEditor.MailEditorData
    , cursor : Maybe Evergreen.V29.LocalGrid.Cursor
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V29.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V29.Bounds.Bounds Evergreen.V29.Units.CellUnit)
            , userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
            }
    , users : Evergreen.V29.IdDict.IdDict Evergreen.V29.Id.UserId BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
            , hiddenUser : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
            , hidePoint : Evergreen.V29.Coord.Coord Evergreen.V29.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.TrainId) Evergreen.V29.Train.Train
    , cows : Evergreen.V29.IdDict.IdDict Evergreen.V29.Id.CowId Evergreen.V29.Change.Cow
    , lastWorldUpdateTrains : AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.TrainId) Evergreen.V29.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.MailId) Evergreen.V29.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V29.Bounds.Bounds Evergreen.V29.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V29.Id.Id Evergreen.V29.Id.EventId, Evergreen.V29.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V29.Bounds.Bounds Evergreen.V29.Units.CellUnit)
    | MailEditorToBackend Evergreen.V29.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V29.Id.Id Evergreen.V29.Id.TrainId) Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V29.Id.Id Evergreen.V29.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V29.Id.Id Evergreen.V29.Id.TrainId)
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
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V29.Change.Change)
    | UnsubscribeEmailConfirmed
    | WorldUpdateBroadcast (AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.TrainId) Evergreen.V29.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V29.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.MailId) Evergreen.V29.MailEditor.FrontendMail)
    | PingResponse Time.Posix
