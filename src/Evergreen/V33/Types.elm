module Evergreen.V33.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V33.Audio
import Evergreen.V33.Bounds
import Evergreen.V33.Change
import Evergreen.V33.Color
import Evergreen.V33.Coord
import Evergreen.V33.Cursor
import Evergreen.V33.EmailAddress
import Evergreen.V33.Grid
import Evergreen.V33.Id
import Evergreen.V33.IdDict
import Evergreen.V33.Keyboard
import Evergreen.V33.LocalGrid
import Evergreen.V33.LocalModel
import Evergreen.V33.MailEditor
import Evergreen.V33.PingData
import Evergreen.V33.Point2d
import Evergreen.V33.Postmark
import Evergreen.V33.Route
import Evergreen.V33.Shaders
import Evergreen.V33.Sound
import Evergreen.V33.TextInput
import Evergreen.V33.Tile
import Evergreen.V33.Train
import Evergreen.V33.Units
import Evergreen.V33.Untrusted
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
    | KeyMsg Evergreen.V33.Keyboard.Msg
    | KeyDown Evergreen.V33.Keyboard.RawKey
    | WindowResized (Evergreen.V33.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V33.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V33.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V33.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V33.Sound.Sound (Result Evergreen.V33.Audio.LoadError Evergreen.V33.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V33.LocalModel.LocalModel Evergreen.V33.Change.Change Evergreen.V33.LocalGrid.LocalGrid
    , trains : Evergreen.V33.IdDict.IdDict Evergreen.V33.Id.TrainId Evergreen.V33.Train.Train
    , mail : AssocList.Dict (Evergreen.V33.Id.Id Evergreen.V33.Id.MailId) Evergreen.V33.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V33.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V33.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Maybe Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V33.Coord.Coord Evergreen.V33.Units.WorldUnit
    , mousePosition : Evergreen.V33.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V33.Sound.Sound (Result Evergreen.V33.Audio.LoadError Evergreen.V33.Audio.Source)
    , texture : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V33.Point2d.Point2d Evergreen.V33.Units.WorldUnit Evergreen.V33.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V33.Id.Id Evergreen.V33.Id.TrainId
        , startViewPoint : Evergreen.V33.Point2d.Point2d Evergreen.V33.Units.WorldUnit Evergreen.V33.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V33.Tile.TileGroup
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
        { tile : Evergreen.V33.Tile.Tile
        , userId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
        , position : Evergreen.V33.Coord.Coord Evergreen.V33.Units.WorldUnit
        , colors : Evergreen.V33.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V33.Id.Id Evergreen.V33.Id.TrainId
        , train : Evergreen.V33.Train.Train
        }
    | MapHover
    | MailEditorHover Evergreen.V33.MailEditor.Hover
    | CowHover
        { cowId : Evergreen.V33.Id.Id Evergreen.V33.Id.CowId
        , cow : Evergreen.V33.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V33.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V33.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V33.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V33.Point2d.Point2d Evergreen.V33.Units.WorldUnit Evergreen.V33.Units.WorldUnit
        , current : Evergreen.V33.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V33.Coord.Coord Evergreen.V33.Units.WorldUnit
    , tile : Evergreen.V33.Tile.Tile
    , colors : Evergreen.V33.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V33.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V33.Shaders.Vertex
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
    , localModel : Evergreen.V33.LocalModel.LocalModel Evergreen.V33.Change.Change Evergreen.V33.LocalGrid.LocalGrid
    , trains : Evergreen.V33.IdDict.IdDict Evergreen.V33.Id.TrainId Evergreen.V33.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V33.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V33.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V33.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V33.Point2d.Point2d Evergreen.V33.Units.WorldUnit Evergreen.V33.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V33.Keyboard.Key
    , windowSize : Evergreen.V33.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V33.Id.Id Evergreen.V33.Id.EventId, Evergreen.V33.Change.LocalChange )
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
            , tile : Evergreen.V33.Tile.Tile
            , position : Evergreen.V33.Coord.Coord Evergreen.V33.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V33.Sound.Sound (Result Evergreen.V33.Audio.LoadError Evergreen.V33.Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V33.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mail : AssocList.Dict (Evergreen.V33.Id.Id Evergreen.V33.Id.MailId) Evergreen.V33.MailEditor.FrontendMail
    , mailEditor : Evergreen.V33.MailEditor.Model
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V33.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V33.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V33.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V33.Id.Id Evergreen.V33.Id.EventId
    , pingData : Maybe Evergreen.V33.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V33.Tile.TileGroup Evergreen.V33.Color.Colors
    , primaryColorTextInput : Evergreen.V33.TextInput.Model
    , secondaryColorTextInput : Evergreen.V33.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V33.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V33.IdDict.IdDict
            Evergreen.V33.Id.UserId
            { position : Evergreen.V33.Point2d.Point2d Evergreen.V33.Units.WorldUnit Evergreen.V33.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : AssocList.Dict Evergreen.V33.Color.Colors Evergreen.V33.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V33.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V33.EmailAddress.EmailAddress
    , showInvite : Bool
    , inviteTextInput : Evergreen.V33.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V33.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V33.Coord.Coord Evergreen.V33.Units.WorldUnit )
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V33.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V33.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V33.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V33.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V33.MailEditor.MailEditorData
    , cursor : Maybe Evergreen.V33.LocalGrid.Cursor
    , handColor : Evergreen.V33.Color.Colors
    , emailAddress : Evergreen.V33.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V33.IdDict.IdDict Evergreen.V33.Id.UserId ()
    }


type BackendError
    = PostmarkError Evergreen.V33.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V33.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V33.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V33.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V33.Bounds.Bounds Evergreen.V33.Units.CellUnit)
            , userId : Maybe (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
            }
    , users : Evergreen.V33.IdDict.IdDict Evergreen.V33.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V33.IdDict.IdDict Evergreen.V33.Id.TrainId Evergreen.V33.Train.Train
    , cows : Evergreen.V33.IdDict.IdDict Evergreen.V33.Id.CowId Evergreen.V33.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V33.IdDict.IdDict Evergreen.V33.Id.TrainId Evergreen.V33.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : AssocList.Dict (Evergreen.V33.Id.Id Evergreen.V33.Id.MailId) Evergreen.V33.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V33.Id.SecretId Evergreen.V33.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
            , requestedBy : Effect.Lamdera.SessionId
            }
    , invites : AssocList.Dict (Evergreen.V33.Id.SecretId Evergreen.V33.Route.InviteToken) Invite
    }


type alias FrontendMsg =
    Evergreen.V33.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V33.Bounds.Bounds Evergreen.V33.Units.CellUnit) (Maybe Evergreen.V33.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V33.Id.Id Evergreen.V33.Id.EventId, Evergreen.V33.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V33.Bounds.Bounds Evergreen.V33.Units.CellUnit)
    | MailEditorToBackend Evergreen.V33.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V33.Id.Id Evergreen.V33.Id.TrainId) Effect.Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V33.Id.Id Evergreen.V33.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V33.Id.Id Evergreen.V33.Id.TrainId)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.EmailAddress.EmailAddress)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V33.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V33.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V33.Id.SecretId Evergreen.V33.Route.InviteToken) (Result Effect.Http.Error Evergreen.V33.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V33.Grid.GridData
    , userStatus : Evergreen.V33.Change.UserStatus
    , viewBounds : Evergreen.V33.Bounds.Bounds Evergreen.V33.Units.CellUnit
    , trains : Evergreen.V33.IdDict.IdDict Evergreen.V33.Id.TrainId Evergreen.V33.Train.Train
    , mail : AssocList.Dict (Evergreen.V33.Id.Id Evergreen.V33.Id.MailId) Evergreen.V33.MailEditor.FrontendMail
    , cows : Evergreen.V33.IdDict.IdDict Evergreen.V33.Id.CowId Evergreen.V33.Change.Cow
    , cursors : Evergreen.V33.IdDict.IdDict Evergreen.V33.Id.UserId Evergreen.V33.LocalGrid.Cursor
    , handColors : Evergreen.V33.IdDict.IdDict Evergreen.V33.Id.UserId Evergreen.V33.Color.Colors
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V33.Change.Change)
    | UnsubscribeEmailConfirmed
    | WorldUpdateBroadcast (Evergreen.V33.IdDict.IdDict Evergreen.V33.Id.TrainId Evergreen.V33.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V33.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V33.Id.Id Evergreen.V33.Id.MailId) Evergreen.V33.MailEditor.FrontendMail)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V33.EmailAddress.EmailAddress
    | SendInviteEmailResponse Evergreen.V33.EmailAddress.EmailAddress
