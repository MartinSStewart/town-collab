module Evergreen.V42.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V42.Audio
import Evergreen.V42.Bounds
import Evergreen.V42.Change
import Evergreen.V42.Color
import Evergreen.V42.Coord
import Evergreen.V42.Cursor
import Evergreen.V42.EmailAddress
import Evergreen.V42.Grid
import Evergreen.V42.Id
import Evergreen.V42.IdDict
import Evergreen.V42.Keyboard
import Evergreen.V42.LocalGrid
import Evergreen.V42.LocalModel
import Evergreen.V42.MailEditor
import Evergreen.V42.PingData
import Evergreen.V42.Point2d
import Evergreen.V42.Postmark
import Evergreen.V42.Route
import Evergreen.V42.Shaders
import Evergreen.V42.Sound
import Evergreen.V42.TextInput
import Evergreen.V42.Tile
import Evergreen.V42.Train
import Evergreen.V42.Units
import Evergreen.V42.Untrusted
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
    | KeyMsg Evergreen.V42.Keyboard.Msg
    | KeyDown Evergreen.V42.Keyboard.RawKey
    | WindowResized (Evergreen.V42.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V42.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V42.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V42.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V42.Sound.Sound (Result Evergreen.V42.Audio.LoadError Evergreen.V42.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V42.LocalModel.LocalModel Evergreen.V42.Change.Change Evergreen.V42.LocalGrid.LocalGrid
    , trains : Evergreen.V42.IdDict.IdDict Evergreen.V42.Id.TrainId Evergreen.V42.Train.Train
    , mail : AssocList.Dict (Evergreen.V42.Id.Id Evergreen.V42.Id.MailId) Evergreen.V42.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V42.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V42.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Maybe Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V42.Coord.Coord Evergreen.V42.Units.WorldUnit
    , mousePosition : Evergreen.V42.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V42.Sound.Sound (Result Evergreen.V42.Audio.LoadError Evergreen.V42.Audio.Source)
    , texture : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V42.Point2d.Point2d Evergreen.V42.Units.WorldUnit Evergreen.V42.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V42.Id.Id Evergreen.V42.Id.TrainId
        , startViewPoint : Evergreen.V42.Point2d.Point2d Evergreen.V42.Units.WorldUnit Evergreen.V42.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V42.Tile.TileGroup
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
        { tile : Evergreen.V42.Tile.Tile
        , userId : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
        , position : Evergreen.V42.Coord.Coord Evergreen.V42.Units.WorldUnit
        , colors : Evergreen.V42.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V42.Id.Id Evergreen.V42.Id.TrainId
        , train : Evergreen.V42.Train.Train
        }
    | MapHover
    | MailEditorHover Evergreen.V42.MailEditor.Hover
    | CowHover
        { cowId : Evergreen.V42.Id.Id Evergreen.V42.Id.CowId
        , cow : Evergreen.V42.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V42.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V42.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V42.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V42.Point2d.Point2d Evergreen.V42.Units.WorldUnit Evergreen.V42.Units.WorldUnit
        , current : Evergreen.V42.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V42.Coord.Coord Evergreen.V42.Units.WorldUnit
    , tile : Evergreen.V42.Tile.Tile
    , colors : Evergreen.V42.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V42.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V42.Shaders.Vertex
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
    , localModel : Evergreen.V42.LocalModel.LocalModel Evergreen.V42.Change.Change Evergreen.V42.LocalGrid.LocalGrid
    , trains : Evergreen.V42.IdDict.IdDict Evergreen.V42.Id.TrainId Evergreen.V42.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V42.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V42.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V42.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V42.Point2d.Point2d Evergreen.V42.Units.WorldUnit Evergreen.V42.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V42.Keyboard.Key
    , windowSize : Evergreen.V42.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V42.Id.Id Evergreen.V42.Id.EventId, Evergreen.V42.Change.LocalChange )
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
            , tile : Evergreen.V42.Tile.Tile
            , position : Evergreen.V42.Coord.Coord Evergreen.V42.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V42.Sound.Sound (Result Evergreen.V42.Audio.LoadError Evergreen.V42.Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V42.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mail : AssocList.Dict (Evergreen.V42.Id.Id Evergreen.V42.Id.MailId) Evergreen.V42.MailEditor.FrontendMail
    , mailEditor : Evergreen.V42.MailEditor.Model
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V42.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V42.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V42.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V42.Id.Id Evergreen.V42.Id.EventId
    , pingData : Maybe Evergreen.V42.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V42.Tile.TileGroup Evergreen.V42.Color.Colors
    , primaryColorTextInput : Evergreen.V42.TextInput.Model
    , secondaryColorTextInput : Evergreen.V42.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V42.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V42.IdDict.IdDict
            Evergreen.V42.Id.UserId
            { position : Evergreen.V42.Point2d.Point2d Evergreen.V42.Units.WorldUnit Evergreen.V42.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : AssocList.Dict Evergreen.V42.Color.Colors Evergreen.V42.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V42.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V42.EmailAddress.EmailAddress
    , showInvite : Bool
    , inviteTextInput : Evergreen.V42.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V42.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V42.Coord.Coord Evergreen.V42.Units.WorldUnit )
    , debugText : String
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V42.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V42.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V42.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V42.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V42.MailEditor.MailEditorData
    , cursor : Maybe Evergreen.V42.LocalGrid.Cursor
    , handColor : Evergreen.V42.Color.Colors
    , emailAddress : Evergreen.V42.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V42.IdDict.IdDict Evergreen.V42.Id.UserId ()
    }


type BackendError
    = PostmarkError Evergreen.V42.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V42.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V42.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V42.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V42.Bounds.Bounds Evergreen.V42.Units.CellUnit)
            , userId : Maybe (Evergreen.V42.Id.Id Evergreen.V42.Id.UserId)
            }
    , users : Evergreen.V42.IdDict.IdDict Evergreen.V42.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V42.IdDict.IdDict Evergreen.V42.Id.TrainId Evergreen.V42.Train.Train
    , cows : Evergreen.V42.IdDict.IdDict Evergreen.V42.Id.CowId Evergreen.V42.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V42.IdDict.IdDict Evergreen.V42.Id.TrainId Evergreen.V42.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : AssocList.Dict (Evergreen.V42.Id.Id Evergreen.V42.Id.MailId) Evergreen.V42.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V42.Id.SecretId Evergreen.V42.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V42.Id.Id Evergreen.V42.Id.UserId
            , requestedBy : Effect.Lamdera.SessionId
            }
    , invites : AssocList.Dict (Evergreen.V42.Id.SecretId Evergreen.V42.Route.InviteToken) Invite
    }


type alias FrontendMsg =
    Evergreen.V42.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V42.Bounds.Bounds Evergreen.V42.Units.CellUnit) (Maybe Evergreen.V42.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V42.Id.Id Evergreen.V42.Id.EventId, Evergreen.V42.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V42.Bounds.Bounds Evergreen.V42.Units.CellUnit)
    | MailEditorToBackend Evergreen.V42.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V42.Id.Id Evergreen.V42.Id.TrainId) Effect.Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V42.Id.Id Evergreen.V42.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V42.Id.Id Evergreen.V42.Id.TrainId)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V42.Untrusted.Untrusted Evergreen.V42.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V42.Untrusted.Untrusted Evergreen.V42.EmailAddress.EmailAddress)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Lamdera.ClientId Effect.Time.Posix Evergreen.V42.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V42.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V42.Id.SecretId Evergreen.V42.Route.InviteToken) (Result Effect.Http.Error Evergreen.V42.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V42.Grid.GridData
    , userStatus : Evergreen.V42.Change.UserStatus
    , viewBounds : Evergreen.V42.Bounds.Bounds Evergreen.V42.Units.CellUnit
    , trains : Evergreen.V42.IdDict.IdDict Evergreen.V42.Id.TrainId Evergreen.V42.Train.Train
    , mail : AssocList.Dict (Evergreen.V42.Id.Id Evergreen.V42.Id.MailId) Evergreen.V42.MailEditor.FrontendMail
    , cows : Evergreen.V42.IdDict.IdDict Evergreen.V42.Id.CowId Evergreen.V42.Change.Cow
    , cursors : Evergreen.V42.IdDict.IdDict Evergreen.V42.Id.UserId Evergreen.V42.LocalGrid.Cursor
    , handColors : Evergreen.V42.IdDict.IdDict Evergreen.V42.Id.UserId Evergreen.V42.Color.Colors
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V42.Change.Change)
    | UnsubscribeEmailConfirmed
    | WorldUpdateBroadcast (Evergreen.V42.IdDict.IdDict Evergreen.V42.Id.TrainId Evergreen.V42.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V42.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V42.Id.Id Evergreen.V42.Id.MailId) Evergreen.V42.MailEditor.FrontendMail)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V42.EmailAddress.EmailAddress
    | SentLoginEmailResponseDebug (Result Effect.Http.Error Evergreen.V42.Postmark.PostmarkSendResponse)
    | SendInviteEmailResponse Evergreen.V42.EmailAddress.EmailAddress
