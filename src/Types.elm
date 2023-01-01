module Types exposing
    ( BackendError(..)
    , BackendModel
    , BackendMsg(..)
    , BackendUserData
    , EmailEvent(..)
    , FrontendLoaded
    , FrontendLoading
    , FrontendModel
    , FrontendModel_(..)
    , FrontendMsg
    , FrontendMsg_(..)
    , Hover(..)
    , LoadedLocalModel_
    , LoadingData_
    , LoadingLocalModel(..)
    , MouseButtonState(..)
    , RemovedTileParticle
    , SubmitStatus(..)
    , ToBackend(..)
    , ToFrontend(..)
    , Tool(..)
    , ToolButton(..)
    , UiHover(..)
    , ViewPoint(..)
    )

import AssocList
import Audio
import Bounds exposing (Bounds)
import Browser
import Change exposing (Change, Cow, ServerChange, UserStatus)
import Color exposing (Color, Colors)
import Coord exposing (Coord, RawCellCoord)
import Cursor exposing (CursorMeshes)
import Dict exposing (Dict)
import Duration exposing (Duration)
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Time
import Effect.WebGL.Texture exposing (Texture)
import EmailAddress exposing (EmailAddress)
import Grid exposing (Grid, GridData)
import Html.Events.Extra.Mouse exposing (Button)
import Html.Events.Extra.Wheel
import Id exposing (CowId, EventId, Id, MailId, TrainId, UserId)
import IdDict exposing (IdDict)
import Keyboard
import Lamdera
import List.Nonempty exposing (Nonempty)
import LocalGrid exposing (Cursor, LocalGrid)
import LocalModel exposing (LocalModel)
import MailEditor exposing (BackendMail, FrontendMail, MailEditorData, Model, ShowMailEditor)
import PingData exposing (PingData)
import Pixels exposing (Pixels)
import Point2d exposing (Point2d)
import Postmark exposing (PostmarkSendResponse)
import Route exposing (ConfirmEmailKey, LoginToken, UnsubscribeEmailKey)
import SendGrid
import Shaders exposing (DebrisVertex, Vertex)
import Sound exposing (Sound)
import TextInput
import Tile exposing (Tile, TileGroup)
import Train exposing (Train, TrainDiff)
import Units exposing (CellUnit, WorldUnit)
import Untrusted exposing (Untrusted)
import Url exposing (Url)
import WebGL


type alias FrontendModel =
    Audio.Model FrontendMsg_ FrontendModel_


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Coord Pixels
    , devicePixelRatio : Maybe Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Coord WorldUnit
    , mousePosition : Point2d Pixels Pixels
    , sounds : AssocList.Dict Sound (Result Audio.LoadError Audio.Source)
    , texture : Maybe Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type LoadingLocalModel
    = LoadingLocalModel (List Change)
    | LoadedLocalModel LoadedLocalModel_


type alias LoadedLocalModel_ =
    { localModel : LocalModel Change LocalGrid
    , trains : AssocList.Dict (Id TrainId) Train
    , mail : AssocList.Dict (Id MailId) FrontendMail
    }


type ViewPoint
    = NormalViewPoint (Point2d WorldUnit WorldUnit)
    | TrainViewPoint { trainId : Id TrainId, startViewPoint : Point2d WorldUnit WorldUnit, startTime : Effect.Time.Posix }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton TileGroup
    | TilePickerToolButton


type Tool
    = HandTool
    | TilePlacerTool { tileGroup : TileGroup, index : Int, mesh : WebGL.Mesh Vertex }
    | TilePickerTool


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : LocalModel Change LocalGrid
    , trains : AssocList.Dict (Id TrainId) Train
    , meshes : Dict RawCellCoord { foreground : WebGL.Mesh Vertex, background : WebGL.Mesh Vertex }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Point2d WorldUnit WorldUnit
    , texture : Texture
    , trainTexture : Maybe Texture
    , pressedKeys : List Keyboard.Key
    , windowSize : Coord Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Id EventId, Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , adminEnabled : Bool
    , animationElapsedTime : Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced : Maybe { time : Effect.Time.Posix, overwroteTiles : Bool, tile : Tile, position : Coord WorldUnit }
    , sounds : AssocList.Dict Sound (Result Audio.LoadError Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mail : AssocList.Dict (Id MailId) FrontendMail
    , mailEditor : Model
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict String TileGroup
    , uiMesh : WebGL.Mesh Vertex
    , previousTileHover : Maybe TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Id EventId
    , pingData : Maybe PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict TileGroup Colors
    , primaryColorTextInput : TextInput.Model
    , secondaryColorTextInput : TextInput.Model
    , focus : Hover
    , music : { startTime : Effect.Time.Posix, sound : Sound }
    , previousCursorPositions : IdDict UserId { position : Point2d WorldUnit WorldUnit, time : Effect.Time.Posix }
    , handMeshes : AssocList.Dict Colors CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : TextInput.Model
    , pressedSubmitEmail : SubmitStatus EmailAddress
    }


type SubmitStatus a
    = NotSubmitted { pressedSubmit : Bool }
    | Submitting
    | Submitted a


type alias RemovedTileParticle =
    { time : Effect.Time.Posix, position : Coord WorldUnit, tile : Tile, colors : Colors }


type MouseButtonState
    = MouseButtonUp { current : Point2d Pixels Pixels }
    | MouseButtonDown
        { start : Point2d Pixels Pixels
        , start_ : Point2d WorldUnit WorldUnit
        , current : Point2d Pixels Pixels
        , hover : Hover
        }


type Hover
    = TileHover { tile : Tile, userId : Id UserId, position : Coord WorldUnit, colors : Colors }
    | TrainHover { trainId : Id TrainId, train : Train }
    | MapHover
    | MailEditorHover MailEditor.Hover
    | CowHover { cowId : Id CowId, cow : Cow }
    | UiBackgroundHover
    | UiHover UiHover { position : Coord Pixels }


type UiHover
    = EmailAddressTextInputHover
    | SendEmailButtonHover
    | ToolButtonHover ToolButton
    | PrimaryColorInput
    | SecondaryColorInput


type alias BackendModel =
    { grid : Grid
    , userSessions :
        Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict ClientId (Bounds CellUnit)
            , userId : Maybe (Id UserId)
            }
    , users : IdDict UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : AssocList.Dict (Id TrainId) Train
    , cows : IdDict CowId Cow
    , lastWorldUpdateTrains : AssocList.Dict (Id TrainId) Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : AssocList.Dict (Id MailId) BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            LoginToken
            { requestTime : Effect.Time.Posix
            , userId : Id UserId
            , requestedBy : SessionId
            }
    }


type BackendError
    = PostmarkError EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Id UserId)


type alias BackendUserData =
    { undoHistory : List (Dict RawCellCoord Int)
    , redoHistory : List (Dict RawCellCoord Int)
    , undoCurrent : Dict RawCellCoord Int
    , mailEditor : MailEditorData
    , cursor : Maybe Cursor
    , handColor : Colors
    , emailAddress : EmailAddress
    }


type alias FrontendMsg =
    Audio.Msg FrontendMsg_


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url
    | NoOpFrontendMsg
    | TextureLoaded (Result Effect.WebGL.Texture.Error Texture)
    | TrainTextureLoaded (Result Effect.WebGL.Texture.Error Texture)
    | KeyMsg Keyboard.Msg
    | KeyDown Keyboard.RawKey
    | WindowResized (Coord Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Button (Point2d Pixels Pixels)
    | MouseUp Button (Point2d Pixels Pixels)
    | MouseMove (Point2d Pixels Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Sound (Result Audio.LoadError Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgent String


type ToBackend
    = ConnectToBackend (Bounds CellUnit) (Maybe LoginToken)
    | GridChange (Nonempty ( Id EventId, Change.LocalChange ))
    | ChangeViewBounds (Bounds CellUnit)
    | MailEditorToBackend MailEditor.ToBackend
    | TeleportHomeTrainRequest (Id TrainId) Effect.Time.Posix
    | CancelTeleportHomeTrainRequest (Id TrainId)
    | LeaveHomeTrainRequest (Id TrainId)
    | PingRequest
    | SendLoginEmailRequest (Untrusted EmailAddress)


type BackendMsg
    = UserDisconnected SessionId ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix EmailAddress (Result Effect.Http.Error PostmarkSendResponse)
    | UpdateFromFrontend SessionId ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (Nonempty Change)
    | UnsubscribeEmailConfirmed
    | WorldUpdateBroadcast (AssocList.Dict (Id TrainId) TrainDiff)
    | MailEditorToFrontend MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Id MailId) FrontendMail)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse EmailAddress


type EmailEvent
    = UnsubscribeEmail UnsubscribeEmailKey


type alias LoadingData_ =
    { grid : GridData
    , userStatus : UserStatus
    , viewBounds : Bounds CellUnit
    , trains : AssocList.Dict (Id TrainId) Train
    , mail : AssocList.Dict (Id MailId) FrontendMail
    , cows : IdDict CowId Cow
    , cursors : IdDict UserId Cursor
    , handColors : IdDict UserId Colors
    }
