module Evergreen.V9.Types exposing (..)

import AssocList
import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V9.Bounds
import Evergreen.V9.Change
import Evergreen.V9.Coord
import Evergreen.V9.Grid
import Evergreen.V9.Id
import Evergreen.V9.LocalGrid
import Evergreen.V9.LocalModel
import Evergreen.V9.MailEditor
import Evergreen.V9.Point2d
import Evergreen.V9.Shaders
import Evergreen.V9.Sound
import Evergreen.V9.Tile
import Evergreen.V9.Train
import Evergreen.V9.Units
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
    | WindowResized (Evergreen.V9.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V9.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V9.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V9.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    | UserTagMouseEntered (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    | UserTagMouseExited (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    | HideForAllTogglePressed (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
        , hidePoint : Evergreen.V9.Coord.Coord Evergreen.V9.Units.WorldUnit
        }
    | AnimationFrame Time.Posix
    | SoundLoaded Evergreen.V9.Sound.Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged


type alias LoadingData_ =
    { user : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    , grid : Evergreen.V9.Grid.GridData
    , hiddenUsers : EverySet.EverySet (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    , adminHiddenUsers : EverySet.EverySet (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    , undoHistory : List (Dict.Dict Evergreen.V9.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V9.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V9.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V9.Bounds.Bounds Evergreen.V9.Units.CellUnit
    , trains : AssocList.Dict (Evergreen.V9.Id.Id Evergreen.V9.Id.TrainId) Evergreen.V9.Train.Train
    , mail : AssocList.Dict (Evergreen.V9.Id.Id Evergreen.V9.Id.MailId) Evergreen.V9.MailEditor.FrontendMail
    , mailEditor : Evergreen.V9.MailEditor.MailEditorData
    }


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V9.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Time.Posix
    , viewPoint : Evergreen.V9.Coord.Coord Evergreen.V9.Units.WorldUnit
    , mousePosition : Evergreen.V9.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V9.Sound.Sound (Result Audio.LoadError Audio.Source)
    , loadingData : Maybe LoadingData_
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V9.Point2d.Point2d Evergreen.V9.Units.WorldUnit Evergreen.V9.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V9.Id.Id Evergreen.V9.Id.TrainId
        , startViewPoint : Evergreen.V9.Point2d.Point2d Evergreen.V9.Units.WorldUnit Evergreen.V9.Units.WorldUnit
        , startTime : Time.Posix
        }


type Hover
    = TileHover Evergreen.V9.Tile.Tile
    | ToolbarHover
    | PostOfficeHover
        { postOfficePosition : Evergreen.V9.Coord.Coord Evergreen.V9.Units.WorldUnit
        }
    | TrainHover
        { trainId : Evergreen.V9.Id.Id Evergreen.V9.Id.TrainId
        , train : Evergreen.V9.Train.Train
        }
    | TrainHouseHover
        { trainHousePosition : Evergreen.V9.Coord.Coord Evergreen.V9.Units.WorldUnit
        }
    | HouseHover
        { housePosition : Evergreen.V9.Coord.Coord Evergreen.V9.Units.WorldUnit
        }
    | MapHover


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V9.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V9.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V9.Point2d.Point2d Evergreen.V9.Units.WorldUnit Evergreen.V9.Units.WorldUnit
        , current : Evergreen.V9.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Time.Posix
    , position : Evergreen.V9.Coord.Coord Evergreen.V9.Units.WorldUnit
    , tile : Evergreen.V9.Tile.Tile
    }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V9.LocalModel.LocalModel Evergreen.V9.Change.Change Evergreen.V9.LocalGrid.LocalGrid
    , trains : AssocList.Dict (Evergreen.V9.Id.Id Evergreen.V9.Id.TrainId) Evergreen.V9.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V9.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V9.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V9.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V9.Point2d.Point2d Evergreen.V9.Units.WorldUnit Evergreen.V9.Units.WorldUnit
    , texture : Maybe WebGL.Texture.Texture
    , trainTexture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V9.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V9.Point2d.Point2d Pixels.Pixels Pixels.Pixels )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List Evergreen.V9.Change.LocalChange
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , startTime : Time.Posix
    , userHoverHighlighted : Maybe (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
            , hidePoint : Evergreen.V9.Coord.Coord Evergreen.V9.Units.WorldUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V9.Tile.Tile
            , position : Evergreen.V9.Coord.Coord Evergreen.V9.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V9.Sound.Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V9.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V9.Id.Id Evergreen.V9.Id.MailId) Evergreen.V9.MailEditor.FrontendMail
    , mailEditor : Evergreen.V9.MailEditor.Model
    , currentTile :
        Maybe
            { tile : Evergreen.V9.Tile.Tile
            , mesh : WebGL.Mesh Evergreen.V9.Shaders.Vertex
            }
    , lastTileRotation : List Time.Posix
    , userIdMesh : WebGL.Mesh Evergreen.V9.Shaders.Vertex
    , lastPlacementError : Maybe Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V9.Tile.Tile
    , toolbarMesh : WebGL.Mesh Evergreen.V9.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V9.Tile.Tile
    , lastHouseClick : Maybe Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V9.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V9.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V9.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V9.MailEditor.MailEditorData
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V9.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V9.Bounds.Bounds Evergreen.V9.Units.CellUnit)
            , userId : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
            }
    , users : Dict.Dict Int BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
            , hiddenUser : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
            , hidePoint : Evergreen.V9.Coord.Coord Evergreen.V9.Units.WorldUnit
            }
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    , trains : AssocList.Dict (Evergreen.V9.Id.Id Evergreen.V9.Id.TrainId) Evergreen.V9.Train.Train
    , lastWorldUpdate : Maybe Time.Posix
    , mail : AssocList.Dict (Evergreen.V9.Id.Id Evergreen.V9.Id.MailId) Evergreen.V9.MailEditor.BackendMail
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V9.Bounds.Bounds Evergreen.V9.Units.CellUnit)
    | GridChange (List.Nonempty.Nonempty Evergreen.V9.Change.LocalChange)
    | ChangeViewBounds (Evergreen.V9.Bounds.Bounds Evergreen.V9.Units.CellUnit)
    | MailEditorToBackend Evergreen.V9.MailEditor.ToBackend


type BackendMsg
    = UserDisconnected Lamdera.SessionId Lamdera.ClientId
    | NotifyAdminTimeElapsed Time.Posix
    | NotifyAdminEmailSent
    | ChangeEmailSent Time.Posix EmailAddress.EmailAddress (Result SendGrid.Error ())
    | UpdateFromFrontend Lamdera.SessionId Lamdera.ClientId ToBackend Time.Posix
    | WorldUpdateTimeElapsed Time.Posix


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V9.Change.Change)
    | UnsubscribeEmailConfirmed
    | TrainBroadcast (AssocList.Dict (Evergreen.V9.Id.Id Evergreen.V9.Id.TrainId) Evergreen.V9.Train.Train)
    | MailEditorToFrontend Evergreen.V9.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V9.Id.Id Evergreen.V9.Id.MailId) Evergreen.V9.MailEditor.FrontendMail)
