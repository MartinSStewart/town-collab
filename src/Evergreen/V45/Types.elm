module Evergreen.V45.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V45.Audio
import Evergreen.V45.Bounds
import Evergreen.V45.Change
import Evergreen.V45.Color
import Evergreen.V45.Coord
import Evergreen.V45.Cursor
import Evergreen.V45.EmailAddress
import Evergreen.V45.Grid
import Evergreen.V45.Id
import Evergreen.V45.IdDict
import Evergreen.V45.Keyboard
import Evergreen.V45.LocalGrid
import Evergreen.V45.LocalModel
import Evergreen.V45.MailEditor
import Evergreen.V45.PingData
import Evergreen.V45.Point2d
import Evergreen.V45.Postmark
import Evergreen.V45.Route
import Evergreen.V45.Shaders
import Evergreen.V45.Sound
import Evergreen.V45.TextInput
import Evergreen.V45.Tile
import Evergreen.V45.Train
import Evergreen.V45.Units
import Evergreen.V45.Untrusted
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
    | KeyMsg Evergreen.V45.Keyboard.Msg
    | KeyDown Evergreen.V45.Keyboard.RawKey
    | WindowResized (Evergreen.V45.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V45.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V45.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V45.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V45.Sound.Sound (Result Evergreen.V45.Audio.LoadError Evergreen.V45.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V45.LocalModel.LocalModel Evergreen.V45.Change.Change Evergreen.V45.LocalGrid.LocalGrid
    , trains : Evergreen.V45.IdDict.IdDict Evergreen.V45.Id.TrainId Evergreen.V45.Train.Train
    , mail : AssocList.Dict (Evergreen.V45.Id.Id Evergreen.V45.Id.MailId) Evergreen.V45.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V45.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V45.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Maybe Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V45.Coord.Coord Evergreen.V45.Units.WorldUnit
    , mousePosition : Evergreen.V45.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V45.Sound.Sound (Result Evergreen.V45.Audio.LoadError Evergreen.V45.Audio.Source)
    , texture : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V45.Point2d.Point2d Evergreen.V45.Units.WorldUnit Evergreen.V45.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V45.Id.Id Evergreen.V45.Id.TrainId
        , startViewPoint : Evergreen.V45.Point2d.Point2d Evergreen.V45.Units.WorldUnit Evergreen.V45.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V45.Tile.TileGroup
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
        { tile : Evergreen.V45.Tile.Tile
        , userId : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
        , position : Evergreen.V45.Coord.Coord Evergreen.V45.Units.WorldUnit
        , colors : Evergreen.V45.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V45.Id.Id Evergreen.V45.Id.TrainId
        , train : Evergreen.V45.Train.Train
        }
    | MapHover
    | MailEditorHover Evergreen.V45.MailEditor.Hover
    | CowHover
        { cowId : Evergreen.V45.Id.Id Evergreen.V45.Id.CowId
        , cow : Evergreen.V45.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V45.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V45.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V45.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V45.Point2d.Point2d Evergreen.V45.Units.WorldUnit Evergreen.V45.Units.WorldUnit
        , current : Evergreen.V45.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V45.Coord.Coord Evergreen.V45.Units.WorldUnit
    , tile : Evergreen.V45.Tile.Tile
    , colors : Evergreen.V45.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V45.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V45.Shaders.Vertex
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
    , localModel : Evergreen.V45.LocalModel.LocalModel Evergreen.V45.Change.Change Evergreen.V45.LocalGrid.LocalGrid
    , trains : Evergreen.V45.IdDict.IdDict Evergreen.V45.Id.TrainId Evergreen.V45.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V45.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V45.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V45.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V45.Point2d.Point2d Evergreen.V45.Units.WorldUnit Evergreen.V45.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V45.Keyboard.Key
    , windowSize : Evergreen.V45.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V45.Id.Id Evergreen.V45.Id.EventId, Evergreen.V45.Change.LocalChange )
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
            , tile : Evergreen.V45.Tile.Tile
            , position : Evergreen.V45.Coord.Coord Evergreen.V45.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V45.Sound.Sound (Result Evergreen.V45.Audio.LoadError Evergreen.V45.Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V45.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mail : AssocList.Dict (Evergreen.V45.Id.Id Evergreen.V45.Id.MailId) Evergreen.V45.MailEditor.FrontendMail
    , mailEditor : Evergreen.V45.MailEditor.Model
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V45.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V45.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V45.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V45.Id.Id Evergreen.V45.Id.EventId
    , pingData : Maybe Evergreen.V45.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V45.Tile.TileGroup Evergreen.V45.Color.Colors
    , primaryColorTextInput : Evergreen.V45.TextInput.Model
    , secondaryColorTextInput : Evergreen.V45.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V45.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V45.IdDict.IdDict
            Evergreen.V45.Id.UserId
            { position : Evergreen.V45.Point2d.Point2d Evergreen.V45.Units.WorldUnit Evergreen.V45.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : AssocList.Dict Evergreen.V45.Color.Colors Evergreen.V45.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V45.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V45.EmailAddress.EmailAddress
    , showInvite : Bool
    , inviteTextInput : Evergreen.V45.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V45.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V45.Coord.Coord Evergreen.V45.Units.WorldUnit )
    , debugText : String
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V45.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V45.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V45.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V45.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V45.MailEditor.MailEditorData
    , cursor : Maybe Evergreen.V45.LocalGrid.Cursor
    , handColor : Evergreen.V45.Color.Colors
    , emailAddress : Evergreen.V45.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V45.IdDict.IdDict Evergreen.V45.Id.UserId ()
    }


type BackendError
    = PostmarkError Evergreen.V45.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V45.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V45.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V45.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V45.Bounds.Bounds Evergreen.V45.Units.CellUnit)
            , userId : Maybe (Evergreen.V45.Id.Id Evergreen.V45.Id.UserId)
            }
    , users : Evergreen.V45.IdDict.IdDict Evergreen.V45.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V45.IdDict.IdDict Evergreen.V45.Id.TrainId Evergreen.V45.Train.Train
    , cows : Evergreen.V45.IdDict.IdDict Evergreen.V45.Id.CowId Evergreen.V45.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V45.IdDict.IdDict Evergreen.V45.Id.TrainId Evergreen.V45.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : AssocList.Dict (Evergreen.V45.Id.Id Evergreen.V45.Id.MailId) Evergreen.V45.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V45.Id.SecretId Evergreen.V45.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V45.Id.Id Evergreen.V45.Id.UserId
            , requestedBy : Effect.Lamdera.SessionId
            }
    , invites : AssocList.Dict (Evergreen.V45.Id.SecretId Evergreen.V45.Route.InviteToken) Invite
    , dummyField : Int
    }


type alias FrontendMsg =
    Evergreen.V45.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V45.Bounds.Bounds Evergreen.V45.Units.CellUnit) (Maybe Evergreen.V45.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V45.Id.Id Evergreen.V45.Id.EventId, Evergreen.V45.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V45.Bounds.Bounds Evergreen.V45.Units.CellUnit)
    | MailEditorToBackend Evergreen.V45.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V45.Id.Id Evergreen.V45.Id.TrainId) Effect.Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V45.Id.Id Evergreen.V45.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V45.Id.Id Evergreen.V45.Id.TrainId)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V45.Untrusted.Untrusted Evergreen.V45.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V45.Untrusted.Untrusted Evergreen.V45.EmailAddress.EmailAddress)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V45.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V45.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V45.Id.SecretId Evergreen.V45.Route.InviteToken) (Result Effect.Http.Error Evergreen.V45.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V45.Grid.GridData
    , userStatus : Evergreen.V45.Change.UserStatus
    , viewBounds : Evergreen.V45.Bounds.Bounds Evergreen.V45.Units.CellUnit
    , trains : Evergreen.V45.IdDict.IdDict Evergreen.V45.Id.TrainId Evergreen.V45.Train.Train
    , mail : AssocList.Dict (Evergreen.V45.Id.Id Evergreen.V45.Id.MailId) Evergreen.V45.MailEditor.FrontendMail
    , cows : Evergreen.V45.IdDict.IdDict Evergreen.V45.Id.CowId Evergreen.V45.Change.Cow
    , cursors : Evergreen.V45.IdDict.IdDict Evergreen.V45.Id.UserId Evergreen.V45.LocalGrid.Cursor
    , handColors : Evergreen.V45.IdDict.IdDict Evergreen.V45.Id.UserId Evergreen.V45.Color.Colors
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V45.Change.Change)
    | UnsubscribeEmailConfirmed
    | WorldUpdateBroadcast (Evergreen.V45.IdDict.IdDict Evergreen.V45.Id.TrainId Evergreen.V45.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V45.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V45.Id.Id Evergreen.V45.Id.MailId) Evergreen.V45.MailEditor.FrontendMail)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V45.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V45.EmailAddress.EmailAddress
