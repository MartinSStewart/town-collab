module Evergreen.V48.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V48.Audio
import Evergreen.V48.Bounds
import Evergreen.V48.Change
import Evergreen.V48.Color
import Evergreen.V48.Coord
import Evergreen.V48.Cursor
import Evergreen.V48.DisplayName
import Evergreen.V48.EmailAddress
import Evergreen.V48.Grid
import Evergreen.V48.Id
import Evergreen.V48.IdDict
import Evergreen.V48.Keyboard
import Evergreen.V48.LocalGrid
import Evergreen.V48.LocalModel
import Evergreen.V48.MailEditor
import Evergreen.V48.PingData
import Evergreen.V48.Point2d
import Evergreen.V48.Postmark
import Evergreen.V48.Route
import Evergreen.V48.Shaders
import Evergreen.V48.Sound
import Evergreen.V48.TextInput
import Evergreen.V48.Tile
import Evergreen.V48.Train
import Evergreen.V48.Units
import Evergreen.V48.Untrusted
import Evergreen.V48.User
import Html.Events.Extra.Mouse
import Html.Events.Extra.Wheel
import Lamdera
import List.Nonempty
import Pixels
import Time
import Url
import WebGL


type alias UserSettings =
    { musicVolume : Int
    , soundEffectVolume : Int
    }


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOpFrontendMsg
    | TextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | KeyMsg Evergreen.V48.Keyboard.Msg
    | KeyDown Evergreen.V48.Keyboard.RawKey
    | WindowResized (Evergreen.V48.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V48.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V48.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V48.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V48.Sound.Sound (Result Evergreen.V48.Audio.LoadError Evergreen.V48.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V48.LocalModel.LocalModel Evergreen.V48.Change.Change Evergreen.V48.LocalGrid.LocalGrid
    , trains : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.TrainId Evergreen.V48.Train.Train
    , mail : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.MailId Evergreen.V48.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V48.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V48.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Maybe Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V48.Coord.Coord Evergreen.V48.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V48.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V48.Sound.Sound (Result Evergreen.V48.Audio.LoadError Evergreen.V48.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V48.Point2d.Point2d Evergreen.V48.Units.WorldUnit Evergreen.V48.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V48.Id.Id Evergreen.V48.Id.TrainId
        , startViewPoint : Evergreen.V48.Point2d.Point2d Evergreen.V48.Units.WorldUnit Evergreen.V48.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V48.Tile.TileGroup
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
    | LowerMusicVolume
    | RaiseMusicVolume
    | LowerSoundEffectVolume
    | RaiseSoundEffectVolume
    | SettingsButton
    | CloseSettings
    | DisplayNameTextInput
    | MailEditorHover Evergreen.V48.MailEditor.Hover
    | YouGotMailButton


type Hover
    = TileHover
        { tile : Evergreen.V48.Tile.Tile
        , userId : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
        , position : Evergreen.V48.Coord.Coord Evergreen.V48.Units.WorldUnit
        , colors : Evergreen.V48.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V48.Id.Id Evergreen.V48.Id.TrainId
        , train : Evergreen.V48.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V48.Id.Id Evergreen.V48.Id.CowId
        , cow : Evergreen.V48.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V48.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V48.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V48.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V48.Point2d.Point2d Evergreen.V48.Units.WorldUnit Evergreen.V48.Units.WorldUnit
        , current : Evergreen.V48.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V48.Coord.Coord Evergreen.V48.Units.WorldUnit
    , tile : Evergreen.V48.Tile.Tile
    , colors : Evergreen.V48.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V48.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V48.Shaders.Vertex
        }
    | TilePickerTool


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = InviteMenu
    | SettingsMenu Evergreen.V48.TextInput.Model
    | LoggedOutSettingsMenu


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V48.LocalModel.LocalModel Evergreen.V48.Change.Change Evergreen.V48.LocalGrid.LocalGrid
    , trains : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.TrainId Evergreen.V48.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V48.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V48.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V48.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V48.Point2d.Point2d Evergreen.V48.Units.WorldUnit Evergreen.V48.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V48.Keyboard.Key
    , windowSize : Evergreen.V48.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V48.Id.Id Evergreen.V48.Id.EventId, Evergreen.V48.Change.LocalChange )
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
            , tile : Evergreen.V48.Tile.Tile
            , position : Evergreen.V48.Coord.Coord Evergreen.V48.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V48.Sound.Sound (Result Evergreen.V48.Audio.LoadError Evergreen.V48.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V48.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V48.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V48.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V48.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V48.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V48.Id.Id Evergreen.V48.Id.EventId
    , pingData : Maybe Evergreen.V48.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V48.Tile.TileGroup Evergreen.V48.Color.Colors
    , primaryColorTextInput : Evergreen.V48.TextInput.Model
    , secondaryColorTextInput : Evergreen.V48.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V48.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V48.IdDict.IdDict
            Evergreen.V48.Id.UserId
            { position : Evergreen.V48.Point2d.Point2d Evergreen.V48.Units.WorldUnit Evergreen.V48.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : AssocList.Dict Evergreen.V48.Color.Colors Evergreen.V48.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V48.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V48.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V48.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V48.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V48.Coord.Coord Evergreen.V48.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V48.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V48.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V48.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V48.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.UserId (List Evergreen.V48.MailEditor.Content)
    , cursor : Maybe Evergreen.V48.LocalGrid.Cursor
    , handColor : Evergreen.V48.Color.Colors
    , emailAddress : Evergreen.V48.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.UserId ()
    , name : Evergreen.V48.DisplayName.DisplayName
    , sendEmailWhenReceivingALetter : Bool
    }


type BackendError
    = PostmarkError Evergreen.V48.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId)


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V48.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V48.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V48.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V48.Bounds.Bounds Evergreen.V48.Units.CellUnit)
            , userId : Maybe (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId)
            }
    , users : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.TrainId Evergreen.V48.Train.Train
    , cows : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.CowId Evergreen.V48.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.TrainId Evergreen.V48.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.MailId Evergreen.V48.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V48.Id.SecretId Evergreen.V48.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
            , requestedBy : Effect.Lamdera.SessionId
            }
    , invites : AssocList.Dict (Evergreen.V48.Id.SecretId Evergreen.V48.Route.InviteToken) Invite
    }


type alias FrontendMsg =
    Evergreen.V48.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V48.Bounds.Bounds Evergreen.V48.Units.CellUnit) (Maybe Evergreen.V48.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V48.Id.Id Evergreen.V48.Id.EventId, Evergreen.V48.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V48.Bounds.Bounds Evergreen.V48.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V48.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V48.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V48.Id.SecretId Evergreen.V48.Route.InviteToken) (Result Effect.Http.Error Evergreen.V48.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed


type alias LoadingData_ =
    { grid : Evergreen.V48.Grid.GridData
    , userStatus : Evergreen.V48.Change.UserStatus
    , viewBounds : Evergreen.V48.Bounds.Bounds Evergreen.V48.Units.CellUnit
    , trains : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.TrainId Evergreen.V48.Train.Train
    , mail : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.MailId Evergreen.V48.MailEditor.FrontendMail
    , cows : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.CowId Evergreen.V48.Change.Cow
    , cursors : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.UserId Evergreen.V48.LocalGrid.Cursor
    , users : Evergreen.V48.IdDict.IdDict Evergreen.V48.Id.UserId Evergreen.V48.User.FrontendUser
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V48.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V48.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V48.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V48.Coord.Coord Evergreen.V48.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
