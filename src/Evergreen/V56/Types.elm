module Evergreen.V56.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V56.Audio
import Evergreen.V56.Bounds
import Evergreen.V56.Change
import Evergreen.V56.Color
import Evergreen.V56.Coord
import Evergreen.V56.Cursor
import Evergreen.V56.DisplayName
import Evergreen.V56.EmailAddress
import Evergreen.V56.Grid
import Evergreen.V56.Id
import Evergreen.V56.IdDict
import Evergreen.V56.Keyboard
import Evergreen.V56.LocalGrid
import Evergreen.V56.LocalModel
import Evergreen.V56.MailEditor
import Evergreen.V56.PingData
import Evergreen.V56.Point2d
import Evergreen.V56.Postmark
import Evergreen.V56.Route
import Evergreen.V56.Shaders
import Evergreen.V56.Sound
import Evergreen.V56.TextInput
import Evergreen.V56.Tile
import Evergreen.V56.Train
import Evergreen.V56.Units
import Evergreen.V56.Untrusted
import Evergreen.V56.User
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
    | KeyMsg Evergreen.V56.Keyboard.Msg
    | KeyDown Evergreen.V56.Keyboard.RawKey
    | WindowResized (Evergreen.V56.Coord.Coord CssPixel)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V56.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V56.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V56.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V56.Sound.Sound (Result Evergreen.V56.Audio.LoadError Evergreen.V56.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V56.LocalModel.LocalModel Evergreen.V56.Change.Change Evergreen.V56.LocalGrid.LocalGrid
    , trains : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.TrainId Evergreen.V56.Train.Train
    , mail : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.MailId Evergreen.V56.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V56.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V56.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V56.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V56.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V56.Coord.Coord Evergreen.V56.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V56.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V56.Sound.Sound (Result Evergreen.V56.Audio.LoadError Evergreen.V56.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V56.Point2d.Point2d Evergreen.V56.Units.WorldUnit Evergreen.V56.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V56.Id.Id Evergreen.V56.Id.TrainId
        , startViewPoint : Evergreen.V56.Point2d.Point2d Evergreen.V56.Units.WorldUnit Evergreen.V56.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V56.Tile.TileGroup
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
    | MailEditorHover Evergreen.V56.MailEditor.Hover
    | YouGotMailButton
    | ShowMapButton
    | AllowEmailNotificationsCheckbox


type Hover
    = TileHover
        { tile : Evergreen.V56.Tile.Tile
        , userId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
        , position : Evergreen.V56.Coord.Coord Evergreen.V56.Units.WorldUnit
        , colors : Evergreen.V56.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V56.Id.Id Evergreen.V56.Id.TrainId
        , train : Evergreen.V56.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V56.Id.Id Evergreen.V56.Id.CowId
        , cow : Evergreen.V56.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V56.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V56.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V56.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V56.Point2d.Point2d Evergreen.V56.Units.WorldUnit Evergreen.V56.Units.WorldUnit
        , current : Evergreen.V56.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V56.Coord.Coord Evergreen.V56.Units.WorldUnit
    , tile : Evergreen.V56.Tile.Tile
    , colors : Evergreen.V56.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V56.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V56.Shaders.Vertex
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
    | SettingsMenu Evergreen.V56.TextInput.Model
    | LoggedOutSettingsMenu


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V56.LocalModel.LocalModel Evergreen.V56.Change.Change Evergreen.V56.LocalGrid.LocalGrid
    , trains : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.TrainId Evergreen.V56.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V56.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V56.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V56.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V56.Point2d.Point2d Evergreen.V56.Units.WorldUnit Evergreen.V56.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V56.Keyboard.Key
    , windowSize : Evergreen.V56.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V56.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V56.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V56.Id.Id Evergreen.V56.Id.EventId, Evergreen.V56.Change.LocalChange )
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
            , tile : Evergreen.V56.Tile.Tile
            , position : Evergreen.V56.Coord.Coord Evergreen.V56.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V56.Sound.Sound (Result Evergreen.V56.Audio.LoadError Evergreen.V56.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V56.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V56.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V56.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V56.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V56.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V56.Id.Id Evergreen.V56.Id.EventId
    , pingData : Maybe Evergreen.V56.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V56.Tile.TileGroup Evergreen.V56.Color.Colors
    , primaryColorTextInput : Evergreen.V56.TextInput.Model
    , secondaryColorTextInput : Evergreen.V56.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V56.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V56.IdDict.IdDict
            Evergreen.V56.Id.UserId
            { position : Evergreen.V56.Point2d.Point2d Evergreen.V56.Units.WorldUnit Evergreen.V56.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.UserId Evergreen.V56.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V56.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V56.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V56.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V56.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V56.Coord.Coord Evergreen.V56.Units.WorldUnit )
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
    Evergreen.V56.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V56.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V56.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V56.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.UserId (List Evergreen.V56.MailEditor.Content)
    , cursor : Maybe Evergreen.V56.LocalGrid.Cursor
    , handColor : Evergreen.V56.Color.Colors
    , emailAddress : Evergreen.V56.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.UserId ()
    , name : Evergreen.V56.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V56.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V56.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V56.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V56.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V56.Bounds.Bounds Evergreen.V56.Units.CellUnit)
            , userId : Maybe (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
            }
    , users : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.TrainId Evergreen.V56.Train.Train
    , cows : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.CowId Evergreen.V56.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.TrainId Evergreen.V56.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.MailId Evergreen.V56.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V56.Id.SecretId Evergreen.V56.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V56.Id.SecretId Evergreen.V56.Route.InviteToken) Invite
    }


type alias FrontendMsg =
    Evergreen.V56.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V56.Bounds.Bounds Evergreen.V56.Units.CellUnit) (Maybe Evergreen.V56.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V56.Id.Id Evergreen.V56.Id.EventId, Evergreen.V56.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V56.Bounds.Bounds Evergreen.V56.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V56.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V56.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V56.Id.SecretId Evergreen.V56.Route.InviteToken) (Result Effect.Http.Error Evergreen.V56.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V56.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V56.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V56.Grid.GridData
    , userStatus : Evergreen.V56.Change.UserStatus
    , viewBounds : Evergreen.V56.Bounds.Bounds Evergreen.V56.Units.CellUnit
    , trains : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.TrainId Evergreen.V56.Train.Train
    , mail : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.MailId Evergreen.V56.MailEditor.FrontendMail
    , cows : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.CowId Evergreen.V56.Change.Cow
    , cursors : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.UserId Evergreen.V56.LocalGrid.Cursor
    , users : Evergreen.V56.IdDict.IdDict Evergreen.V56.Id.UserId Evergreen.V56.User.FrontendUser
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V56.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V56.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V56.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V56.Coord.Coord Evergreen.V56.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
