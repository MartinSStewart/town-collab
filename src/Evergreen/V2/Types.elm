module Evergreen.V2.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V2.Bounds
import Evergreen.V2.Change
import Evergreen.V2.Coord
import Evergreen.V2.Grid
import Evergreen.V2.Id
import Evergreen.V2.LocalGrid
import Evergreen.V2.LocalModel
import Evergreen.V2.MailEditor
import Evergreen.V2.Point2d
import Evergreen.V2.Shaders
import Evergreen.V2.Sound
import Evergreen.V2.Tile
import Evergreen.V2.Train
import Evergreen.V2.Units
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
    | WindowResized (Evergreen.V2.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V2.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V2.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V2.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V2.Id.Id Evergreen.V2.Id.UserId)
    | UserTagMouseEntered (Evergreen.V2.Id.Id Evergreen.V2.Id.UserId)
    | UserTagMouseExited (Evergreen.V2.Id.Id Evergreen.V2.Id.UserId)
    | HideForAllTogglePressed (Evergreen.V2.Id.Id Evergreen.V2.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V2.Id.Id Evergreen.V2.Id.UserId
        , hidePoint : Evergreen.V2.Coord.Coord Evergreen.V2.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V2.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged


type alias LoadingData_ =
    { user : Evergreen.V2.Id.Id Evergreen.V2.Id.UserId
    , grid : Evergreen.V2.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V2.Id.Id Evergreen.V2.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V2.Id.Id Evergreen.V2.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V2.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V2.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V2.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V2.Bounds.Bounds Evergreen.V2.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V2.Id.Id Evergreen.V2.Id.TrainId) Evergreen.V2.Train.Train
    , mail : AssocList.Dict (Evergreen.V2.Id.Id Evergreen.V2.Id.MailId) Evergreen.V2.MailEditor.FrontendMail
    , mailEditor : Evergreen.V2.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V2.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V2.Coord.Coord Evergreen.V2.Units.WorldUnit
    , mousePosition : Evergreen.V2.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V2.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V2.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V2.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V2.Point2d.Point2d Evergreen.V2.Units.WorldUnit Evergreen.V2.Units.WorldUnit
        , current : Evergreen.V2.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V2.Coord.Coord Evergreen.V2.Units.WorldUnit
    , tile : Evergreen.V2.Tile.Tile
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V2.LocalModel.LocalModel Evergreen.V2.Change.Change Evergreen.V2.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V2.Id.Id Evergreen.V2.Id.TrainId) Evergreen.V2.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V2.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V2.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V2.Shaders.Vertex
            }
    , viewPoint : Evergreen.V2.Point2d.Point2d Evergreen.V2.Units.WorldUnit Evergreen.V2.Units.WorldUnit
    , viewPointLastInterval : Evergreen.V2.Point2d.Point2d Evergreen.V2.Units.WorldUnit Evergreen.V2.Units.WorldUnit
    , texture : Maybe WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V2.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V2.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List Evergreen.V2.Change.LocalChange
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V2.Id.Id Evergreen.V2.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V2.Id.Id Evergreen.V2.Id.UserId
            , hidePoint : Evergreen.V2.Coord.Coord Evergreen.V2.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V2.Tile.Tile
            , position : Evergreen.V2.Coord.Coord Evergreen.V2.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V2.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V2.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V2.Id.Id Evergreen.V2.Id.MailId) Evergreen.V2.MailEditor.FrontendMail
    , mailEditor : Evergreen.V2.MailEditor.Model
    , currentTile :
        Maybe
            { tile : Evergreen.V2.Tile.Tile
            , mesh : WebGL.Mesh Evergreen.V2.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V2.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V2.Id.Id Evergreen.V2.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V2.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V2.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V2.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V2.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V2.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V2.Bounds.Bounds Evergreen.V2.Units.CellUnit)
            , userId : Evergreen.V2.Id.Id Evergreen.V2.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V2.Id.Id Evergreen.V2.Id.UserId
            , hiddenUser : Evergreen.V2.Id.Id Evergreen.V2.Id.UserId
            , hidePoint : Evergreen.V2.Coord.Coord Evergreen.V2.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V2.Id.Id Evergreen.V2.Id.TrainId) Evergreen.V2.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V2.Id.Id Evergreen.V2.Id.MailId) Evergreen.V2.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V2.Bounds.Bounds Evergreen.V2.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty Evergreen.V2.Change.LocalChange)
    | ChangeViewBounds (Evergreen.V2.Bounds.Bounds Evergreen.V2.Units.CellUnit)
    | MailEditorToBackend Evergreen.V2.MailEditor.ToBackend


type BackendMsg
    = UserDisconnected Lamdera.SessionId Lamdera.ClientId
    | NotifyAdminTimeElapsed Time.Posix
    | NotifyAdminEmailSent
    | ChangeEmailSent Time.Posix EmailAddress.EmailAddress (Result SendGrid.Error ())
    | UpdateFromFrontend Lamdera.SessionId Lamdera.ClientId ToBackend Time.Posix
    | WorldUpdateTimeElapsed Time.Posix


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V2.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V2.Id.Id Evergreen.V2.Id.TrainId) Evergreen.V2.Train.Train)
    | MailEditorToFrontend Evergreen.V2.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V2.Id.Id Evergreen.V2.Id.MailId) Evergreen.V2.MailEditor.FrontendMail)
