module Evergreen.V52.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V52.Audio
import Evergreen.V52.Bounds
import Evergreen.V52.Change
import Evergreen.V52.Color
import Evergreen.V52.Coord
import Evergreen.V52.Cursor
import Evergreen.V52.DisplayName
import Evergreen.V52.EmailAddress
import Evergreen.V52.Grid
import Evergreen.V52.Id
import Evergreen.V52.IdDict
import Evergreen.V52.Keyboard
import Evergreen.V52.LocalGrid
import Evergreen.V52.LocalModel
import Evergreen.V52.MailEditor
import Evergreen.V52.PingData
import Evergreen.V52.Point2d
import Evergreen.V52.Postmark
import Evergreen.V52.Route
import Evergreen.V52.Shaders
import Evergreen.V52.Sound
import Evergreen.V52.TextInput
import Evergreen.V52.Tile
import Evergreen.V52.Train
import Evergreen.V52.Units
import Evergreen.V52.Untrusted
import Evergreen.V52.User
import Html.Events.Extra.Mouse
import Html.Events.Extra.Wheel
import Lamdera
import List.Nonempty
import Pixels
import Time
import Url
import WebGL


type CssPixel
    = CssPixel Never


type alias UserSettings =
    { musicVolume : Int
    , soundEffectVolume : Int
    }


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOpFrontendMsg
    | TextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | SimplexLookupTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | KeyMsg Evergreen.V52.Keyboard.Msg
    | KeyDown Evergreen.V52.Keyboard.RawKey
    | WindowResized (Evergreen.V52.Coord.Coord CssPixel)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V52.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V52.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V52.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V52.Sound.Sound (Result Evergreen.V52.Audio.LoadError Evergreen.V52.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V52.LocalModel.LocalModel Evergreen.V52.Change.Change Evergreen.V52.LocalGrid.LocalGrid
    , trains : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.TrainId Evergreen.V52.Train.Train
    , mail : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.MailId Evergreen.V52.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V52.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V52.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V52.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V52.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V52.Coord.Coord Evergreen.V52.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V52.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V52.Sound.Sound (Result Evergreen.V52.Audio.LoadError Evergreen.V52.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V52.Point2d.Point2d Evergreen.V52.Units.WorldUnit Evergreen.V52.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V52.Id.Id Evergreen.V52.Id.TrainId
        , startViewPoint : Evergreen.V52.Point2d.Point2d Evergreen.V52.Units.WorldUnit Evergreen.V52.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V52.Tile.TileGroup
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
    | MailEditorHover Evergreen.V52.MailEditor.Hover
    | YouGotMailButton
    | ShowMapButton
    | AllowEmailNotificationsCheckbox


type Hover
    = TileHover
        { tile : Evergreen.V52.Tile.Tile
        , userId : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
        , position : Evergreen.V52.Coord.Coord Evergreen.V52.Units.WorldUnit
        , colors : Evergreen.V52.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V52.Id.Id Evergreen.V52.Id.TrainId
        , train : Evergreen.V52.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V52.Id.Id Evergreen.V52.Id.CowId
        , cow : Evergreen.V52.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V52.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V52.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V52.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V52.Point2d.Point2d Evergreen.V52.Units.WorldUnit Evergreen.V52.Units.WorldUnit
        , current : Evergreen.V52.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V52.Coord.Coord Evergreen.V52.Units.WorldUnit
    , tile : Evergreen.V52.Tile.Tile
    , colors : Evergreen.V52.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V52.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V52.Shaders.Vertex
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
    | SettingsMenu Evergreen.V52.TextInput.Model
    | LoggedOutSettingsMenu


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V52.LocalModel.LocalModel Evergreen.V52.Change.Change Evergreen.V52.LocalGrid.LocalGrid
    , trains : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.TrainId Evergreen.V52.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V52.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V52.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V52.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V52.Point2d.Point2d Evergreen.V52.Units.WorldUnit Evergreen.V52.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V52.Keyboard.Key
    , windowSize : Evergreen.V52.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V52.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V52.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V52.Id.Id Evergreen.V52.Id.EventId, Evergreen.V52.Change.LocalChange )
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
            , tile : Evergreen.V52.Tile.Tile
            , position : Evergreen.V52.Coord.Coord Evergreen.V52.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V52.Sound.Sound (Result Evergreen.V52.Audio.LoadError Evergreen.V52.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V52.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V52.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V52.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V52.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V52.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V52.Id.Id Evergreen.V52.Id.EventId
    , pingData : Maybe Evergreen.V52.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V52.Tile.TileGroup Evergreen.V52.Color.Colors
    , primaryColorTextInput : Evergreen.V52.TextInput.Model
    , secondaryColorTextInput : Evergreen.V52.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V52.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V52.IdDict.IdDict
            Evergreen.V52.Id.UserId
            { position : Evergreen.V52.Point2d.Point2d Evergreen.V52.Units.WorldUnit Evergreen.V52.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : AssocList.Dict Evergreen.V52.Color.Colors Evergreen.V52.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V52.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V52.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V52.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V52.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V52.Coord.Coord Evergreen.V52.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showMap : Bool
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V52.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V52.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V52.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V52.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.UserId (List Evergreen.V52.MailEditor.Content)
    , cursor : Maybe Evergreen.V52.LocalGrid.Cursor
    , handColor : Evergreen.V52.Color.Colors
    , emailAddress : Evergreen.V52.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.UserId ()
    , name : Evergreen.V52.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V52.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V52.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V52.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V52.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V52.Bounds.Bounds Evergreen.V52.Units.CellUnit)
            , userId : Maybe (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId)
            }
    , users : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.TrainId Evergreen.V52.Train.Train
    , cows : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.CowId Evergreen.V52.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.TrainId Evergreen.V52.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.MailId Evergreen.V52.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V52.Id.SecretId Evergreen.V52.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V52.Id.Id Evergreen.V52.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V52.Id.SecretId Evergreen.V52.Route.InviteToken) Invite
    }


type alias FrontendMsg =
    Evergreen.V52.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V52.Bounds.Bounds Evergreen.V52.Units.CellUnit) (Maybe Evergreen.V52.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V52.Id.Id Evergreen.V52.Id.EventId, Evergreen.V52.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V52.Bounds.Bounds Evergreen.V52.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V52.Untrusted.Untrusted Evergreen.V52.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V52.Untrusted.Untrusted Evergreen.V52.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V52.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V52.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V52.Id.SecretId Evergreen.V52.Route.InviteToken) (Result Effect.Http.Error Evergreen.V52.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V52.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V52.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V52.Grid.GridData
    , userStatus : Evergreen.V52.Change.UserStatus
    , viewBounds : Evergreen.V52.Bounds.Bounds Evergreen.V52.Units.CellUnit
    , trains : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.TrainId Evergreen.V52.Train.Train
    , mail : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.MailId Evergreen.V52.MailEditor.FrontendMail
    , cows : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.CowId Evergreen.V52.Change.Cow
    , cursors : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.UserId Evergreen.V52.LocalGrid.Cursor
    , users : Evergreen.V52.IdDict.IdDict Evergreen.V52.Id.UserId Evergreen.V52.User.FrontendUser
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V52.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V52.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V52.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V52.Coord.Coord Evergreen.V52.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
