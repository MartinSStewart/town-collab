module Evergreen.V49.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V49.Audio
import Evergreen.V49.Bounds
import Evergreen.V49.Change
import Evergreen.V49.Color
import Evergreen.V49.Coord
import Evergreen.V49.Cursor
import Evergreen.V49.DisplayName
import Evergreen.V49.EmailAddress
import Evergreen.V49.Grid
import Evergreen.V49.Id
import Evergreen.V49.IdDict
import Evergreen.V49.Keyboard
import Evergreen.V49.LocalGrid
import Evergreen.V49.LocalModel
import Evergreen.V49.MailEditor
import Evergreen.V49.PingData
import Evergreen.V49.Point2d
import Evergreen.V49.Postmark
import Evergreen.V49.Route
import Evergreen.V49.Shaders
import Evergreen.V49.Sound
import Evergreen.V49.TextInput
import Evergreen.V49.Tile
import Evergreen.V49.Train
import Evergreen.V49.Units
import Evergreen.V49.Untrusted
import Evergreen.V49.User
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
    | KeyMsg Evergreen.V49.Keyboard.Msg
    | KeyDown Evergreen.V49.Keyboard.RawKey
    | WindowResized (Evergreen.V49.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V49.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V49.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V49.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V49.Sound.Sound (Result Evergreen.V49.Audio.LoadError Evergreen.V49.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V49.LocalModel.LocalModel Evergreen.V49.Change.Change Evergreen.V49.LocalGrid.LocalGrid
    , trains : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.TrainId Evergreen.V49.Train.Train
    , mail : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.MailId Evergreen.V49.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V49.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V49.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Maybe Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V49.Coord.Coord Evergreen.V49.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V49.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V49.Sound.Sound (Result Evergreen.V49.Audio.LoadError Evergreen.V49.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V49.Point2d.Point2d Evergreen.V49.Units.WorldUnit Evergreen.V49.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V49.Id.Id Evergreen.V49.Id.TrainId
        , startViewPoint : Evergreen.V49.Point2d.Point2d Evergreen.V49.Units.WorldUnit Evergreen.V49.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V49.Tile.TileGroup
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
    | MailEditorHover Evergreen.V49.MailEditor.Hover
    | YouGotMailButton


type Hover
    = TileHover
        { tile : Evergreen.V49.Tile.Tile
        , userId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
        , position : Evergreen.V49.Coord.Coord Evergreen.V49.Units.WorldUnit
        , colors : Evergreen.V49.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V49.Id.Id Evergreen.V49.Id.TrainId
        , train : Evergreen.V49.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V49.Id.Id Evergreen.V49.Id.CowId
        , cow : Evergreen.V49.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V49.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V49.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V49.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V49.Point2d.Point2d Evergreen.V49.Units.WorldUnit Evergreen.V49.Units.WorldUnit
        , current : Evergreen.V49.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V49.Coord.Coord Evergreen.V49.Units.WorldUnit
    , tile : Evergreen.V49.Tile.Tile
    , colors : Evergreen.V49.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V49.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V49.Shaders.Vertex
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
    | SettingsMenu Evergreen.V49.TextInput.Model
    | LoggedOutSettingsMenu


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V49.LocalModel.LocalModel Evergreen.V49.Change.Change Evergreen.V49.LocalGrid.LocalGrid
    , trains : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.TrainId Evergreen.V49.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V49.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V49.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V49.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V49.Point2d.Point2d Evergreen.V49.Units.WorldUnit Evergreen.V49.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V49.Keyboard.Key
    , windowSize : Evergreen.V49.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V49.Id.Id Evergreen.V49.Id.EventId, Evergreen.V49.Change.LocalChange )
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
            , tile : Evergreen.V49.Tile.Tile
            , position : Evergreen.V49.Coord.Coord Evergreen.V49.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V49.Sound.Sound (Result Evergreen.V49.Audio.LoadError Evergreen.V49.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V49.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V49.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V49.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V49.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V49.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V49.Id.Id Evergreen.V49.Id.EventId
    , pingData : Maybe Evergreen.V49.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V49.Tile.TileGroup Evergreen.V49.Color.Colors
    , primaryColorTextInput : Evergreen.V49.TextInput.Model
    , secondaryColorTextInput : Evergreen.V49.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V49.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V49.IdDict.IdDict
            Evergreen.V49.Id.UserId
            { position : Evergreen.V49.Point2d.Point2d Evergreen.V49.Units.WorldUnit Evergreen.V49.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : AssocList.Dict Evergreen.V49.Color.Colors Evergreen.V49.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V49.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V49.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V49.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V49.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V49.Coord.Coord Evergreen.V49.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V49.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V49.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V49.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V49.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.UserId (List Evergreen.V49.MailEditor.Content)
    , cursor : Maybe Evergreen.V49.LocalGrid.Cursor
    , handColor : Evergreen.V49.Color.Colors
    , emailAddress : Evergreen.V49.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.UserId ()
    , name : Evergreen.V49.DisplayName.DisplayName
    , sendEmailWhenReceivingALetter : Bool
    }


type BackendError
    = PostmarkError Evergreen.V49.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V49.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V49.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V49.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V49.Bounds.Bounds Evergreen.V49.Units.CellUnit)
            , userId : Maybe (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
            }
    , users : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.TrainId Evergreen.V49.Train.Train
    , cows : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.CowId Evergreen.V49.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.TrainId Evergreen.V49.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.MailId Evergreen.V49.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V49.Id.SecretId Evergreen.V49.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
            , requestedBy : Effect.Lamdera.SessionId
            }
    , invites : AssocList.Dict (Evergreen.V49.Id.SecretId Evergreen.V49.Route.InviteToken) Invite
    }


type alias FrontendMsg =
    Evergreen.V49.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V49.Bounds.Bounds Evergreen.V49.Units.CellUnit) (Maybe Evergreen.V49.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V49.Id.Id Evergreen.V49.Id.EventId, Evergreen.V49.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V49.Bounds.Bounds Evergreen.V49.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V49.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V49.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V49.Id.SecretId Evergreen.V49.Route.InviteToken) (Result Effect.Http.Error Evergreen.V49.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed


type alias LoadingData_ =
    { grid : Evergreen.V49.Grid.GridData
    , userStatus : Evergreen.V49.Change.UserStatus
    , viewBounds : Evergreen.V49.Bounds.Bounds Evergreen.V49.Units.CellUnit
    , trains : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.TrainId Evergreen.V49.Train.Train
    , mail : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.MailId Evergreen.V49.MailEditor.FrontendMail
    , cows : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.CowId Evergreen.V49.Change.Cow
    , cursors : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.UserId Evergreen.V49.LocalGrid.Cursor
    , users : Evergreen.V49.IdDict.IdDict Evergreen.V49.Id.UserId Evergreen.V49.User.FrontendUser
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V49.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V49.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V49.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V49.Coord.Coord Evergreen.V49.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
