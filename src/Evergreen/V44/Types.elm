module Evergreen.V44.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V44.Audio
import Evergreen.V44.Bounds
import Evergreen.V44.Change
import Evergreen.V44.Color
import Evergreen.V44.Coord
import Evergreen.V44.Cursor
import Evergreen.V44.EmailAddress
import Evergreen.V44.Grid
import Evergreen.V44.Id
import Evergreen.V44.IdDict
import Evergreen.V44.Keyboard
import Evergreen.V44.LocalGrid
import Evergreen.V44.LocalModel
import Evergreen.V44.MailEditor
import Evergreen.V44.PingData
import Evergreen.V44.Point2d
import Evergreen.V44.Postmark
import Evergreen.V44.Route
import Evergreen.V44.Shaders
import Evergreen.V44.Sound
import Evergreen.V44.TextInput
import Evergreen.V44.Tile
import Evergreen.V44.Train
import Evergreen.V44.Units
import Evergreen.V44.Untrusted
import Html.Events.Extra.Mouse
import Html.Events.Extra.Wheel
import Lamdera
import List.Nonempty
import Pixels
import Time
import Url
import WebGL


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOpFrontendMsg
    | TextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | KeyMsg Evergreen.V44.Keyboard.Msg
    | KeyDown Evergreen.V44.Keyboard.RawKey
    | WindowResized (Evergreen.V44.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V44.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V44.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V44.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V44.Sound.Sound (Result Evergreen.V44.Audio.LoadError Evergreen.V44.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V44.LocalModel.LocalModel Evergreen.V44.Change.Change Evergreen.V44.LocalGrid.LocalGrid
    , trains : Evergreen.V44.IdDict.IdDict Evergreen.V44.Id.TrainId Evergreen.V44.Train.Train
    , mail : AssocList.Dict (Evergreen.V44.Id.Id Evergreen.V44.Id.MailId) Evergreen.V44.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V44.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V44.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Maybe Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V44.Coord.Coord Evergreen.V44.Units.WorldUnit
    , mousePosition : Evergreen.V44.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V44.Sound.Sound (Result Evergreen.V44.Audio.LoadError Evergreen.V44.Audio.Source)
    , texture : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V44.Point2d.Point2d Evergreen.V44.Units.WorldUnit Evergreen.V44.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V44.Id.Id Evergreen.V44.Id.TrainId
        , startViewPoint : Evergreen.V44.Point2d.Point2d Evergreen.V44.Units.WorldUnit Evergreen.V44.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V44.Tile.TileGroup
    | TilePickerToolButton


type UiHover
    = EmailAddressTextInputHover
    | SendEmailButtonHover
    | ToolButtonHover ToolButton
    | PrimaryColorInput
    | SecondaryColorInput
    | ShowInviteUser
    | CloseInviteUser
    | SubmitInviteUser
    | InviteEmailAddressTextInput


type Hover
    = TileHover
        { tile : Evergreen.V44.Tile.Tile
        , userId : Evergreen.V44.Id.Id Evergreen.V44.Id.UserId
        , position : Evergreen.V44.Coord.Coord Evergreen.V44.Units.WorldUnit
        , colors : Evergreen.V44.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V44.Id.Id Evergreen.V44.Id.TrainId
        , train : Evergreen.V44.Train.Train
        }
    | MapHover
    | MailEditorHover Evergreen.V44.MailEditor.Hover
    | CowHover
        { cowId : Evergreen.V44.Id.Id Evergreen.V44.Id.CowId
        , cow : Evergreen.V44.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V44.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V44.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V44.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V44.Point2d.Point2d Evergreen.V44.Units.WorldUnit Evergreen.V44.Units.WorldUnit
        , current : Evergreen.V44.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V44.Coord.Coord Evergreen.V44.Units.WorldUnit
    , tile : Evergreen.V44.Tile.Tile
    , colors : Evergreen.V44.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V44.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V44.Shaders.Vertex
        }
    | TilePickerTool


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V44.LocalModel.LocalModel Evergreen.V44.Change.Change Evergreen.V44.LocalGrid.LocalGrid
    , trains : Evergreen.V44.IdDict.IdDict Evergreen.V44.Id.TrainId Evergreen.V44.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V44.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V44.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V44.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V44.Point2d.Point2d Evergreen.V44.Units.WorldUnit Evergreen.V44.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V44.Keyboard.Key
    , windowSize : Evergreen.V44.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V44.Id.Id Evergreen.V44.Id.EventId, Evergreen.V44.Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Effect.Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V44.Tile.Tile
            , position : Evergreen.V44.Coord.Coord Evergreen.V44.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V44.Sound.Sound (Result Evergreen.V44.Audio.LoadError Evergreen.V44.Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V44.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mail : AssocList.Dict (Evergreen.V44.Id.Id Evergreen.V44.Id.MailId) Evergreen.V44.MailEditor.FrontendMail
    , mailEditor : Evergreen.V44.MailEditor.Model
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V44.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V44.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V44.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V44.Id.Id Evergreen.V44.Id.EventId
    , pingData : Maybe Evergreen.V44.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V44.Tile.TileGroup Evergreen.V44.Color.Colors
    , primaryColorTextInput : Evergreen.V44.TextInput.Model
    , secondaryColorTextInput : Evergreen.V44.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V44.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V44.IdDict.IdDict
            Evergreen.V44.Id.UserId
            { position : Evergreen.V44.Point2d.Point2d Evergreen.V44.Units.WorldUnit Evergreen.V44.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : AssocList.Dict Evergreen.V44.Color.Colors Evergreen.V44.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V44.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V44.EmailAddress.EmailAddress
    , showInvite : Bool
    , inviteTextInput : Evergreen.V44.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V44.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V44.Coord.Coord Evergreen.V44.Units.WorldUnit )
    , debugText : String
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V44.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V44.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V44.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V44.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V44.MailEditor.MailEditorData
    , cursor : Maybe Evergreen.V44.LocalGrid.Cursor
    , handColor : Evergreen.V44.Color.Colors
    , emailAddress : Evergreen.V44.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V44.IdDict.IdDict Evergreen.V44.Id.UserId ()
    }


type BackendError
    = PostmarkError Evergreen.V44.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V44.Id.Id Evergreen.V44.Id.UserId)


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V44.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V44.Id.Id Evergreen.V44.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V44.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V44.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V44.Bounds.Bounds Evergreen.V44.Units.CellUnit)
            , userId : Maybe (Evergreen.V44.Id.Id Evergreen.V44.Id.UserId)
            }
    , users : Evergreen.V44.IdDict.IdDict Evergreen.V44.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V44.IdDict.IdDict Evergreen.V44.Id.TrainId Evergreen.V44.Train.Train
    , cows : Evergreen.V44.IdDict.IdDict Evergreen.V44.Id.CowId Evergreen.V44.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V44.IdDict.IdDict Evergreen.V44.Id.TrainId Evergreen.V44.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : AssocList.Dict (Evergreen.V44.Id.Id Evergreen.V44.Id.MailId) Evergreen.V44.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V44.Id.SecretId Evergreen.V44.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V44.Id.Id Evergreen.V44.Id.UserId
            , requestedBy : Effect.Lamdera.SessionId
            }
    , invites : AssocList.Dict (Evergreen.V44.Id.SecretId Evergreen.V44.Route.InviteToken) Invite
    , dummyField : Int
    }


type alias FrontendMsg =
    Evergreen.V44.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V44.Bounds.Bounds Evergreen.V44.Units.CellUnit) (Maybe Evergreen.V44.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V44.Id.Id Evergreen.V44.Id.EventId, Evergreen.V44.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V44.Bounds.Bounds Evergreen.V44.Units.CellUnit)
    | MailEditorToBackend Evergreen.V44.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V44.Id.Id Evergreen.V44.Id.TrainId) Effect.Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V44.Id.Id Evergreen.V44.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V44.Id.Id Evergreen.V44.Id.TrainId)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V44.Untrusted.Untrusted Evergreen.V44.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V44.Untrusted.Untrusted Evergreen.V44.EmailAddress.EmailAddress)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Lamdera.ClientId Effect.Time.Posix Evergreen.V44.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V44.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V44.Id.SecretId Evergreen.V44.Route.InviteToken) (Result Effect.Http.Error Evergreen.V44.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V44.Grid.GridData
    , userStatus : Evergreen.V44.Change.UserStatus
    , viewBounds : Evergreen.V44.Bounds.Bounds Evergreen.V44.Units.CellUnit
    , trains : Evergreen.V44.IdDict.IdDict Evergreen.V44.Id.TrainId Evergreen.V44.Train.Train
    , mail : AssocList.Dict (Evergreen.V44.Id.Id Evergreen.V44.Id.MailId) Evergreen.V44.MailEditor.FrontendMail
    , cows : Evergreen.V44.IdDict.IdDict Evergreen.V44.Id.CowId Evergreen.V44.Change.Cow
    , cursors : Evergreen.V44.IdDict.IdDict Evergreen.V44.Id.UserId Evergreen.V44.LocalGrid.Cursor
    , handColors : Evergreen.V44.IdDict.IdDict Evergreen.V44.Id.UserId Evergreen.V44.Color.Colors
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V44.Change.Change)
    | UnsubscribeEmailConfirmed
    | WorldUpdateBroadcast (Evergreen.V44.IdDict.IdDict Evergreen.V44.Id.TrainId Evergreen.V44.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V44.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V44.Id.Id Evergreen.V44.Id.MailId) Evergreen.V44.MailEditor.FrontendMail)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V44.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V44.EmailAddress.EmailAddress
