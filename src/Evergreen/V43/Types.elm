module Evergreen.V43.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V43.Audio
import Evergreen.V43.Bounds
import Evergreen.V43.Change
import Evergreen.V43.Color
import Evergreen.V43.Coord
import Evergreen.V43.Cursor
import Evergreen.V43.EmailAddress
import Evergreen.V43.Grid
import Evergreen.V43.Id
import Evergreen.V43.IdDict
import Evergreen.V43.Keyboard
import Evergreen.V43.LocalGrid
import Evergreen.V43.LocalModel
import Evergreen.V43.MailEditor
import Evergreen.V43.PingData
import Evergreen.V43.Point2d
import Evergreen.V43.Postmark
import Evergreen.V43.Route
import Evergreen.V43.Shaders
import Evergreen.V43.Sound
import Evergreen.V43.TextInput
import Evergreen.V43.Tile
import Evergreen.V43.Train
import Evergreen.V43.Units
import Evergreen.V43.Untrusted
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
    | KeyMsg Evergreen.V43.Keyboard.Msg
    | KeyDown Evergreen.V43.Keyboard.RawKey
    | WindowResized (Evergreen.V43.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V43.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V43.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V43.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V43.Sound.Sound (Result Evergreen.V43.Audio.LoadError Evergreen.V43.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V43.LocalModel.LocalModel Evergreen.V43.Change.Change Evergreen.V43.LocalGrid.LocalGrid
    , trains : Evergreen.V43.IdDict.IdDict Evergreen.V43.Id.TrainId Evergreen.V43.Train.Train
    , mail : AssocList.Dict (Evergreen.V43.Id.Id Evergreen.V43.Id.MailId) Evergreen.V43.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V43.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V43.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Maybe Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V43.Coord.Coord Evergreen.V43.Units.WorldUnit
    , mousePosition : Evergreen.V43.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V43.Sound.Sound (Result Evergreen.V43.Audio.LoadError Evergreen.V43.Audio.Source)
    , texture : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V43.Point2d.Point2d Evergreen.V43.Units.WorldUnit Evergreen.V43.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V43.Id.Id Evergreen.V43.Id.TrainId
        , startViewPoint : Evergreen.V43.Point2d.Point2d Evergreen.V43.Units.WorldUnit Evergreen.V43.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V43.Tile.TileGroup
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
        { tile : Evergreen.V43.Tile.Tile
        , userId : Evergreen.V43.Id.Id Evergreen.V43.Id.UserId
        , position : Evergreen.V43.Coord.Coord Evergreen.V43.Units.WorldUnit
        , colors : Evergreen.V43.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V43.Id.Id Evergreen.V43.Id.TrainId
        , train : Evergreen.V43.Train.Train
        }
    | MapHover
    | MailEditorHover Evergreen.V43.MailEditor.Hover
    | CowHover
        { cowId : Evergreen.V43.Id.Id Evergreen.V43.Id.CowId
        , cow : Evergreen.V43.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V43.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V43.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V43.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V43.Point2d.Point2d Evergreen.V43.Units.WorldUnit Evergreen.V43.Units.WorldUnit
        , current : Evergreen.V43.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V43.Coord.Coord Evergreen.V43.Units.WorldUnit
    , tile : Evergreen.V43.Tile.Tile
    , colors : Evergreen.V43.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V43.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V43.Shaders.Vertex
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
    , localModel : Evergreen.V43.LocalModel.LocalModel Evergreen.V43.Change.Change Evergreen.V43.LocalGrid.LocalGrid
    , trains : Evergreen.V43.IdDict.IdDict Evergreen.V43.Id.TrainId Evergreen.V43.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V43.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V43.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V43.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V43.Point2d.Point2d Evergreen.V43.Units.WorldUnit Evergreen.V43.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V43.Keyboard.Key
    , windowSize : Evergreen.V43.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V43.Id.Id Evergreen.V43.Id.EventId, Evergreen.V43.Change.LocalChange )
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
            , tile : Evergreen.V43.Tile.Tile
            , position : Evergreen.V43.Coord.Coord Evergreen.V43.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V43.Sound.Sound (Result Evergreen.V43.Audio.LoadError Evergreen.V43.Audio.Source)
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V43.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mail : AssocList.Dict (Evergreen.V43.Id.Id Evergreen.V43.Id.MailId) Evergreen.V43.MailEditor.FrontendMail
    , mailEditor : Evergreen.V43.MailEditor.Model
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V43.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V43.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V43.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V43.Id.Id Evergreen.V43.Id.EventId
    , pingData : Maybe Evergreen.V43.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V43.Tile.TileGroup Evergreen.V43.Color.Colors
    , primaryColorTextInput : Evergreen.V43.TextInput.Model
    , secondaryColorTextInput : Evergreen.V43.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V43.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V43.IdDict.IdDict
            Evergreen.V43.Id.UserId
            { position : Evergreen.V43.Point2d.Point2d Evergreen.V43.Units.WorldUnit Evergreen.V43.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : AssocList.Dict Evergreen.V43.Color.Colors Evergreen.V43.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V43.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V43.EmailAddress.EmailAddress
    , showInvite : Bool
    , inviteTextInput : Evergreen.V43.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V43.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V43.Coord.Coord Evergreen.V43.Units.WorldUnit )
    , debugText : String
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V43.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V43.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V43.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V43.Coord.RawCellCoord Int
    , mailEditor : Evergreen.V43.MailEditor.MailEditorData
    , cursor : Maybe Evergreen.V43.LocalGrid.Cursor
    , handColor : Evergreen.V43.Color.Colors
    , emailAddress : Evergreen.V43.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V43.IdDict.IdDict Evergreen.V43.Id.UserId ()
    }


type BackendError
    = PostmarkError Evergreen.V43.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V43.Id.Id Evergreen.V43.Id.UserId)


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V43.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V43.Id.Id Evergreen.V43.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V43.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V43.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V43.Bounds.Bounds Evergreen.V43.Units.CellUnit)
            , userId : Maybe (Evergreen.V43.Id.Id Evergreen.V43.Id.UserId)
            }
    , users : Evergreen.V43.IdDict.IdDict Evergreen.V43.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V43.IdDict.IdDict Evergreen.V43.Id.TrainId Evergreen.V43.Train.Train
    , cows : Evergreen.V43.IdDict.IdDict Evergreen.V43.Id.CowId Evergreen.V43.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V43.IdDict.IdDict Evergreen.V43.Id.TrainId Evergreen.V43.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : AssocList.Dict (Evergreen.V43.Id.Id Evergreen.V43.Id.MailId) Evergreen.V43.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V43.Id.SecretId Evergreen.V43.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V43.Id.Id Evergreen.V43.Id.UserId
            , requestedBy : Effect.Lamdera.SessionId
            }
    , invites : AssocList.Dict (Evergreen.V43.Id.SecretId Evergreen.V43.Route.InviteToken) Invite
    }


type alias FrontendMsg =
    Evergreen.V43.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V43.Bounds.Bounds Evergreen.V43.Units.CellUnit) (Maybe Evergreen.V43.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V43.Id.Id Evergreen.V43.Id.EventId, Evergreen.V43.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V43.Bounds.Bounds Evergreen.V43.Units.CellUnit)
    | MailEditorToBackend Evergreen.V43.MailEditor.ToBackend
    | TeleportHomeTrainRequest (Evergreen.V43.Id.Id Evergreen.V43.Id.TrainId) Effect.Time.Posix
    | CancelTeleportHomeTrainRequest (Evergreen.V43.Id.Id Evergreen.V43.Id.TrainId)
    | LeaveHomeTrainRequest (Evergreen.V43.Id.Id Evergreen.V43.Id.TrainId)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V43.Untrusted.Untrusted Evergreen.V43.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V43.Untrusted.Untrusted Evergreen.V43.EmailAddress.EmailAddress)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Lamdera.ClientId Effect.Time.Posix Evergreen.V43.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V43.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V43.Id.SecretId Evergreen.V43.Route.InviteToken) (Result Effect.Http.Error Evergreen.V43.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V43.Grid.GridData
    , userStatus : Evergreen.V43.Change.UserStatus
    , viewBounds : Evergreen.V43.Bounds.Bounds Evergreen.V43.Units.CellUnit
    , trains : Evergreen.V43.IdDict.IdDict Evergreen.V43.Id.TrainId Evergreen.V43.Train.Train
    , mail : AssocList.Dict (Evergreen.V43.Id.Id Evergreen.V43.Id.MailId) Evergreen.V43.MailEditor.FrontendMail
    , cows : Evergreen.V43.IdDict.IdDict Evergreen.V43.Id.CowId Evergreen.V43.Change.Cow
    , cursors : Evergreen.V43.IdDict.IdDict Evergreen.V43.Id.UserId Evergreen.V43.LocalGrid.Cursor
    , handColors : Evergreen.V43.IdDict.IdDict Evergreen.V43.Id.UserId Evergreen.V43.Color.Colors
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V43.Change.Change)
    | UnsubscribeEmailConfirmed
    | WorldUpdateBroadcast (Evergreen.V43.IdDict.IdDict Evergreen.V43.Id.TrainId Evergreen.V43.Train.TrainDiff)
    | MailEditorToFrontend Evergreen.V43.MailEditor.ToFrontend
    | MailBroadcast (AssocList.Dict (Evergreen.V43.Id.Id Evergreen.V43.Id.MailId) Evergreen.V43.MailEditor.FrontendMail)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V43.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V43.EmailAddress.EmailAddress
