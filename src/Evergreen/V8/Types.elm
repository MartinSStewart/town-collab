module Evergreen.V8.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V8.Bounds
import Evergreen.V8.Change
import Evergreen.V8.Coord
import Evergreen.V8.Grid
import Evergreen.V8.Id
import Evergreen.V8.LocalGrid
import Evergreen.V8.LocalModel
import Evergreen.V8.MailEditor
import Evergreen.V8.Point2d
import Evergreen.V8.Shaders
import Evergreen.V8.Sound
import Evergreen.V8.Tile
import Evergreen.V8.Train
import Evergreen.V8.Units
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
    | WindowResized (Evergreen.V8.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V8.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V8.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V8.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)
    | UserTagMouseEntered (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)
    | UserTagMouseExited (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)
    | HideForAllTogglePressed (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V8.Id.Id Evergreen.V8.Id.UserId
        , hidePoint : Evergreen.V8.Coord.Coord Evergreen.V8.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V8.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged


type alias LoadingData_ =
    { user : Evergreen.V8.Id.Id Evergreen.V8.Id.UserId
    , grid : Evergreen.V8.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V8.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V8.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V8.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V8.Bounds.Bounds Evergreen.V8.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V8.Id.Id Evergreen.V8.Id.TrainId) Evergreen.V8.Train.Train
    , mail : AssocList.Dict (Evergreen.V8.Id.Id Evergreen.V8.Id.MailId) Evergreen.V8.MailEditor.FrontendMail
    , mailEditor : Evergreen.V8.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V8.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V8.Coord.Coord Evergreen.V8.Units.WorldUnit
    , mousePosition : Evergreen.V8.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V8.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V8.Point2d.Point2d Evergreen.V8.Units.WorldUnit Evergreen.V8.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V8.Id.Id Evergreen.V8.Id.TrainId
        , startViewPoint : Evergreen.V8.Point2d.Point2d Evergreen.V8.Units.WorldUnit Evergreen.V8.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V8.Tile.Tile
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V8.Coord.Coord Evergreen.V8.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V8.Id.Id Evergreen.V8.Id.TrainId
        , train : Evergreen.V8.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V8.Coord.Coord Evergreen.V8.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V8.Coord.Coord Evergreen.V8.Units.WorldUnit
        }
    | MapHover


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V8.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V8.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V8.Point2d.Point2d Evergreen.V8.Units.WorldUnit Evergreen.V8.Units.WorldUnit
        , current : Evergreen.V8.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V8.Coord.Coord Evergreen.V8.Units.WorldUnit
    , tile : Evergreen.V8.Tile.Tile
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V8.LocalModel.LocalModel Evergreen.V8.Change.Change Evergreen.V8.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V8.Id.Id Evergreen.V8.Id.TrainId) Evergreen.V8.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V8.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V8.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V8.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V8.Point2d.Point2d Evergreen.V8.Units.WorldUnit Evergreen.V8.Units.WorldUnit
    , texture : Maybe WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V8.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V8.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List Evergreen.V8.Change.LocalChange
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V8.Id.Id Evergreen.V8.Id.UserId
            , hidePoint : Evergreen.V8.Coord.Coord Evergreen.V8.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V8.Tile.Tile
            , position : Evergreen.V8.Coord.Coord Evergreen.V8.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V8.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V8.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V8.Id.Id Evergreen.V8.Id.MailId) Evergreen.V8.MailEditor.FrontendMail
    , mailEditor : Evergreen.V8.MailEditor.Model
    , currentTile :
        Maybe
            { tile : Evergreen.V8.Tile.Tile
            , mesh : WebGL.Mesh Evergreen.V8.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V8.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V8.Tile.Tile
    , toolbarMesh : WebGL.Mesh Evergreen.V8.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V8.Tile.Tile
    , lastHouseClick : Maybe Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V8.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V8.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V8.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V8.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V8.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V8.Bounds.Bounds Evergreen.V8.Units.CellUnit)
            , userId : Evergreen.V8.Id.Id Evergreen.V8.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V8.Id.Id Evergreen.V8.Id.UserId
            , hiddenUser : Evergreen.V8.Id.Id Evergreen.V8.Id.UserId
            , hidePoint : Evergreen.V8.Coord.Coord Evergreen.V8.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V8.Id.Id Evergreen.V8.Id.TrainId) Evergreen.V8.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V8.Id.Id Evergreen.V8.Id.MailId) Evergreen.V8.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V8.Bounds.Bounds Evergreen.V8.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty Evergreen.V8.Change.LocalChange)
    | ChangeViewBounds (Evergreen.V8.Bounds.Bounds Evergreen.V8.Units.CellUnit)
    | MailEditorToBackend Evergreen.V8.MailEditor.ToBackend


type BackendMsg
    = UserDisconnected Lamdera.SessionId Lamdera.ClientId
    | NotifyAdminTimeElapsed Time.Posix
    | NotifyAdminEmailSent
    | ChangeEmailSent Time.Posix EmailAddress.EmailAddress (Result SendGrid.Error ())
    | UpdateFromFrontend Lamdera.SessionId Lamdera.ClientId ToBackend Time.Posix
    | WorldUpdateTimeElapsed Time.Posix


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V8.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V8.Id.Id Evergreen.V8.Id.TrainId) Evergreen.V8.Train.Train)
    | MailEditorToFrontend Evergreen.V8.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V8.Id.Id Evergreen.V8.Id.MailId) Evergreen.V8.MailEditor.FrontendMail)
