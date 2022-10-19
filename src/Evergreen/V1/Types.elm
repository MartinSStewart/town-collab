module Evergreen.V1.Types exposing (..)

import Audio
import Browser
import Browser.Navigation
import Dict
import Duration
import EmailAddress
import Evergreen.V1.Bounds
import Evergreen.V1.Change
import Evergreen.V1.Coord
import Evergreen.V1.Cursor
import Evergreen.V1.Grid
import Evergreen.V1.LocalGrid
import Evergreen.V1.LocalModel
import Evergreen.V1.NotifyMe
import Evergreen.V1.Point2d
import Evergreen.V1.RecentChanges
import Evergreen.V1.Units
import Evergreen.V1.UrlHelper
import Evergreen.V1.User
import EverySet
import Html.Events.Extra.Mouse
import Keyboard
import Lamdera
import List.Nonempty
import Math.Vector2
import Pixels
import Quantity
import SendGrid
import Time
import Url
import WebGL
import WebGL.Texture


type ToolType
    = DragTool
    | SelectTool
    | HighlightTool (Maybe ( Evergreen.V1.User.UserId, Evergreen.V1.Coord.Coord Evergreen.V1.Units.AsciiUnit ))


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOpFrontendMsg
    | TextureLoaded (Result WebGL.Texture.Error WebGL.Texture.Texture)
    | KeyMsg Keyboard.Msg
    | KeyDown Keyboard.RawKey
    | WindowResized (Evergreen.V1.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio (Quantity.Quantity Float (Quantity.Rate Evergreen.V1.Units.WorldPixel Pixels.Pixels))
    | UserTyped String
    | TextAreaFocused
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V1.Point2d.Point2d Pixels.Pixels Evergreen.V1.Units.ScreenCoordinate)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V1.Point2d.Point2d Pixels.Pixels Evergreen.V1.Units.ScreenCoordinate)
    | MouseMove (Evergreen.V1.Point2d.Point2d Pixels.Pixels Evergreen.V1.Units.ScreenCoordinate)
    | TouchMove (Evergreen.V1.Point2d.Point2d Pixels.Pixels Evergreen.V1.Units.ScreenCoordinate)
    | ShortIntervalElapsed Time.Posix
    | VeryShortIntervalElapsed Time.Posix
    | ZoomFactorPressed Int
    | SelectToolPressed ToolType
    | UndoPressed
    | RedoPressed
    | CopyPressed
    | CutPressed
    | UnhideUserPressed Evergreen.V1.User.UserId
    | UserTagMouseEntered Evergreen.V1.User.UserId
    | UserTagMouseExited Evergreen.V1.User.UserId
    | HideForAllTogglePressed Evergreen.V1.User.UserId
    | ToggleAdminEnabledPressed
    | HideUserPressed
        { userId : Evergreen.V1.User.UserId
        , hidePoint : Evergreen.V1.Coord.Coord Evergreen.V1.Units.AsciiUnit
        }
    | AnimationFrame Time.Posix
    | PressedCancelNotifyMe
    | PressedSubmitNotifyMe Evergreen.V1.NotifyMe.Validated
    | NotifyMeModelChanged Evergreen.V1.NotifyMe.Model
    | PopSoundLoaded (Result Audio.LoadError Audio.Source)


type alias FrontendLoading =
    { key : Browser.Navigation.Key
    , windowSize : Evergreen.V1.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Quantity.Quantity Float (Quantity.Rate Evergreen.V1.Units.WorldPixel Pixels.Pixels)
    , zoomFactor : Int
    , time : Time.Posix
    , viewPoint : Evergreen.V1.Coord.Coord Evergreen.V1.Units.AsciiUnit
    , mousePosition : Evergreen.V1.Point2d.Point2d Pixels.Pixels Evergreen.V1.Units.ScreenCoordinate
    , showNotifyMe : Bool
    , notifyMeModel : Evergreen.V1.NotifyMe.Model
    , popSound : Maybe (Result Audio.LoadError Audio.Source)
    }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V1.Point2d.Point2d Pixels.Pixels Evergreen.V1.Units.ScreenCoordinate
        }
    | MouseButtonDown
        { start : Evergreen.V1.Point2d.Point2d Pixels.Pixels Evergreen.V1.Units.ScreenCoordinate
        , start_ : Evergreen.V1.Point2d.Point2d Evergreen.V1.Units.WorldPixel Evergreen.V1.Units.WorldCoordinate
        , current : Evergreen.V1.Point2d.Point2d Pixels.Pixels Evergreen.V1.Units.ScreenCoordinate
        }


type alias FrontendLoaded =
    { key : Browser.Navigation.Key
    , localModel : Evergreen.V1.LocalModel.LocalModel Evergreen.V1.Change.Change Evergreen.V1.LocalGrid.LocalGrid
    , meshes : Dict.Dict Evergreen.V1.Coord.RawCellCoord (WebGL.Mesh Evergreen.V1.Grid.Vertex)
    , cursorMesh :
        WebGL.Mesh
            { position : Math.Vector2.Vec2
            }
    , viewPoint : Evergreen.V1.Point2d.Point2d Evergreen.V1.Units.WorldPixel Evergreen.V1.Units.WorldCoordinate
    , viewPointLastInterval : Evergreen.V1.Point2d.Point2d Evergreen.V1.Units.WorldPixel Evergreen.V1.Units.WorldCoordinate
    , cursor : Evergreen.V1.Cursor.Cursor
    , texture : Maybe WebGL.Texture.Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Evergreen.V1.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Quantity.Quantity Float (Quantity.Rate Evergreen.V1.Units.WorldPixel Pixels.Pixels)
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , lastMouseLeftUp : Maybe ( Time.Posix, Evergreen.V1.Point2d.Point2d Pixels.Pixels Evergreen.V1.Units.ScreenCoordinate )
    , mouseMiddle : MouseButtonState
    , pendingChanges : List Evergreen.V1.Change.LocalChange
    , tool : ToolType
    , undoAddLast : Time.Posix
    , time : Time.Posix
    , lastTouchMove : Maybe Time.Posix
    , userHoverHighlighted : Maybe Evergreen.V1.User.UserId
    , highlightContextMenu :
        Maybe
            { userId : Evergreen.V1.User.UserId
            , hidePoint : Evergreen.V1.Coord.Coord Evergreen.V1.Units.AsciiUnit
            }
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , showNotifyMe : Bool
    , notifyMeModel : Evergreen.V1.NotifyMe.Model
    , textAreaText : String
    , popSound : Maybe (Result Audio.LoadError Audio.Source)
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { hiddenUsers : EverySet.EverySet Evergreen.V1.User.UserId
    , hiddenForAll : Bool
    , undoHistory : List (Dict.Dict Evergreen.V1.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V1.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V1.Coord.RawCellCoord Int
    }


type alias SubscribedEmail =
    { email : EmailAddress.EmailAddress
    , frequency : Evergreen.V1.NotifyMe.Frequency
    , confirmTime : Time.Posix
    , userId : Evergreen.V1.User.UserId
    , unsubscribeKey : Evergreen.V1.UrlHelper.UnsubscribeEmailKey
    }


type alias PendingEmail =
    { email : EmailAddress.EmailAddress
    , frequency : Evergreen.V1.NotifyMe.Frequency
    , creationTime : Time.Posix
    , userId : Evergreen.V1.User.UserId
    , key : Evergreen.V1.UrlHelper.ConfirmEmailKey
    }


type BackendError
    = SendGridError EmailAddress.EmailAddress SendGrid.Error


type alias BackendModel =
    { grid : Evergreen.V1.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : Dict.Dict Lamdera.ClientId (Evergreen.V1.Bounds.Bounds Evergreen.V1.Units.CellUnit)
            , userId : Evergreen.V1.User.UserId
            }
    , users : Dict.Dict Evergreen.V1.User.RawUserId BackendUserData
    , usersHiddenRecently :
        List
            { reporter : Evergreen.V1.User.UserId
            , hiddenUser : Evergreen.V1.User.UserId
            , hidePoint : Evergreen.V1.Coord.Coord Evergreen.V1.Units.AsciiUnit
            }
    , userChangesRecently : Evergreen.V1.RecentChanges.RecentChanges
    , subscribedEmails : List SubscribedEmail
    , pendingEmails : List PendingEmail
    , secretLinkCounter : Int
    , errors : List ( Time.Posix, BackendError )
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type EmailEvent
    = ConfirmationEmailConfirmed_ Evergreen.V1.UrlHelper.ConfirmEmailKey
    | UnsubscribeEmail Evergreen.V1.UrlHelper.UnsubscribeEmailKey


type ToBackend
    = ConnectToBackend (Evergreen.V1.Bounds.Bounds Evergreen.V1.Units.CellUnit) (Maybe EmailEvent)
    | GridChange (List.Nonempty.Nonempty Evergreen.V1.Change.LocalChange)
    | ChangeViewBounds (Evergreen.V1.Bounds.Bounds Evergreen.V1.Units.CellUnit)
    | NotifyMeSubmitted Evergreen.V1.NotifyMe.Validated


type BackendMsg
    = UserDisconnected Lamdera.SessionId Lamdera.ClientId
    | NotifyAdminTimeElapsed Time.Posix
    | NotifyAdminEmailSent
    | ConfirmationEmailSent Lamdera.SessionId Time.Posix (Result SendGrid.Error ())
    | ChangeEmailSent Time.Posix EmailAddress.EmailAddress (Result SendGrid.Error ())
    | UpdateFromFrontend Lamdera.SessionId Lamdera.ClientId ToBackend Time.Posix


type alias LoadingData_ =
    { user : Evergreen.V1.User.UserId
    , grid : Evergreen.V1.Grid.Grid
    , hiddenUsers : EverySet.EverySet Evergreen.V1.User.UserId
    , adminHiddenUsers : EverySet.EverySet Evergreen.V1.User.UserId
    , undoHistory : List (Dict.Dict Evergreen.V1.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V1.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V1.Coord.RawCellCoord Int
    , viewBounds : Evergreen.V1.Bounds.Bounds Evergreen.V1.Units.CellUnit
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V1.Change.Change)
    | NotifyMeEmailSent
        { isSuccessful : Bool
        }
    | NotifyMeConfirmed
    | UnsubscribeEmailConfirmed
