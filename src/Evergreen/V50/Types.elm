module Evergreen.V50.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V50.Audio
import Evergreen.V50.Bounds
import Evergreen.V50.Change
import Evergreen.V50.Color
import Evergreen.V50.Coord
import Evergreen.V50.Cursor
import Evergreen.V50.DisplayName
import Evergreen.V50.EmailAddress
import Evergreen.V50.Grid
import Evergreen.V50.Id
import Evergreen.V50.IdDict
import Evergreen.V50.Keyboard
import Evergreen.V50.LocalGrid
import Evergreen.V50.LocalModel
import Evergreen.V50.MailEditor
import Evergreen.V50.PingData
import Evergreen.V50.Point2d
import Evergreen.V50.Postmark
import Evergreen.V50.Route
import Evergreen.V50.Shaders
import Evergreen.V50.Sound
import Evergreen.V50.TextInput
import Evergreen.V50.Tile
import Evergreen.V50.Train
import Evergreen.V50.Units
import Evergreen.V50.Untrusted
import Evergreen.V50.User
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
    | KeyMsg Evergreen.V50.Keyboard.Msg
    | KeyDown Evergreen.V50.Keyboard.RawKey
    | WindowResized (Evergreen.V50.Coord.Coord CssPixel)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V50.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V50.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V50.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V50.Sound.Sound (Result Evergreen.V50.Audio.LoadError Evergreen.V50.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V50.LocalModel.LocalModel Evergreen.V50.Change.Change Evergreen.V50.LocalGrid.LocalGrid
    , trains : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.TrainId Evergreen.V50.Train.Train
    , mail : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.MailId Evergreen.V50.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V50.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V50.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V50.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V50.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V50.Coord.Coord Evergreen.V50.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V50.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V50.Sound.Sound (Result Evergreen.V50.Audio.LoadError Evergreen.V50.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V50.Point2d.Point2d Evergreen.V50.Units.WorldUnit Evergreen.V50.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V50.Id.Id Evergreen.V50.Id.TrainId
        , startViewPoint : Evergreen.V50.Point2d.Point2d Evergreen.V50.Units.WorldUnit Evergreen.V50.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V50.Tile.TileGroup
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
    | MailEditorHover Evergreen.V50.MailEditor.Hover
    | YouGotMailButton
    | ShowMapButton
    | AllowEmailNotificationsCheckbox


type Hover
    = TileHover
        { tile : Evergreen.V50.Tile.Tile
        , userId : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
        , position : Evergreen.V50.Coord.Coord Evergreen.V50.Units.WorldUnit
        , colors : Evergreen.V50.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V50.Id.Id Evergreen.V50.Id.TrainId
        , train : Evergreen.V50.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V50.Id.Id Evergreen.V50.Id.CowId
        , cow : Evergreen.V50.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V50.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V50.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V50.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V50.Point2d.Point2d Evergreen.V50.Units.WorldUnit Evergreen.V50.Units.WorldUnit
        , current : Evergreen.V50.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V50.Coord.Coord Evergreen.V50.Units.WorldUnit
    , tile : Evergreen.V50.Tile.Tile
    , colors : Evergreen.V50.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V50.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V50.Shaders.Vertex
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
    | SettingsMenu Evergreen.V50.TextInput.Model
    | LoggedOutSettingsMenu


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V50.LocalModel.LocalModel Evergreen.V50.Change.Change Evergreen.V50.LocalGrid.LocalGrid
    , trains : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.TrainId Evergreen.V50.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V50.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V50.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V50.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V50.Point2d.Point2d Evergreen.V50.Units.WorldUnit Evergreen.V50.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V50.Keyboard.Key
    , windowSize : Evergreen.V50.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V50.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V50.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V50.Id.Id Evergreen.V50.Id.EventId, Evergreen.V50.Change.LocalChange )
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
            , tile : Evergreen.V50.Tile.Tile
            , position : Evergreen.V50.Coord.Coord Evergreen.V50.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V50.Sound.Sound (Result Evergreen.V50.Audio.LoadError Evergreen.V50.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V50.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V50.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V50.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V50.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V50.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V50.Id.Id Evergreen.V50.Id.EventId
    , pingData : Maybe Evergreen.V50.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V50.Tile.TileGroup Evergreen.V50.Color.Colors
    , primaryColorTextInput : Evergreen.V50.TextInput.Model
    , secondaryColorTextInput : Evergreen.V50.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V50.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V50.IdDict.IdDict
            Evergreen.V50.Id.UserId
            { position : Evergreen.V50.Point2d.Point2d Evergreen.V50.Units.WorldUnit Evergreen.V50.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : AssocList.Dict Evergreen.V50.Color.Colors Evergreen.V50.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V50.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V50.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V50.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V50.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V50.Coord.Coord Evergreen.V50.Units.WorldUnit )
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
    Evergreen.V50.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V50.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V50.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V50.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.UserId (List Evergreen.V50.MailEditor.Content)
    , cursor : Maybe Evergreen.V50.LocalGrid.Cursor
    , handColor : Evergreen.V50.Color.Colors
    , emailAddress : Evergreen.V50.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.UserId ()
    , name : Evergreen.V50.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V50.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId)


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V50.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V50.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V50.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V50.Bounds.Bounds Evergreen.V50.Units.CellUnit)
            , userId : Maybe (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId)
            }
    , users : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.TrainId Evergreen.V50.Train.Train
    , cows : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.CowId Evergreen.V50.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.TrainId Evergreen.V50.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.MailId Evergreen.V50.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V50.Id.SecretId Evergreen.V50.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
            , requestedBy : Effect.Lamdera.SessionId
            }
    , invites : AssocList.Dict (Evergreen.V50.Id.SecretId Evergreen.V50.Route.InviteToken) Invite
    }


type alias FrontendMsg =
    Evergreen.V50.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V50.Bounds.Bounds Evergreen.V50.Units.CellUnit) (Maybe Evergreen.V50.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V50.Id.Id Evergreen.V50.Id.EventId, Evergreen.V50.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V50.Bounds.Bounds Evergreen.V50.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V50.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V50.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V50.Id.SecretId Evergreen.V50.Route.InviteToken) (Result Effect.Http.Error Evergreen.V50.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed


type alias LoadingData_ =
    { grid : Evergreen.V50.Grid.GridData
    , userStatus : Evergreen.V50.Change.UserStatus
    , viewBounds : Evergreen.V50.Bounds.Bounds Evergreen.V50.Units.CellUnit
    , trains : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.TrainId Evergreen.V50.Train.Train
    , mail : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.MailId Evergreen.V50.MailEditor.FrontendMail
    , cows : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.CowId Evergreen.V50.Change.Cow
    , cursors : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.UserId Evergreen.V50.LocalGrid.Cursor
    , users : Evergreen.V50.IdDict.IdDict Evergreen.V50.Id.UserId Evergreen.V50.User.FrontendUser
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V50.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V50.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V50.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V50.Coord.Coord Evergreen.V50.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
