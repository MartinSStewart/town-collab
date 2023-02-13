module Evergreen.V67.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V67.Audio
import Evergreen.V67.Bounds
import Evergreen.V67.Change
import Evergreen.V67.Color
import Evergreen.V67.Coord
import Evergreen.V67.Cursor
import Evergreen.V67.DisplayName
import Evergreen.V67.EmailAddress
import Evergreen.V67.Grid
import Evergreen.V67.Id
import Evergreen.V67.IdDict
import Evergreen.V67.Keyboard
import Evergreen.V67.LocalGrid
import Evergreen.V67.LocalModel
import Evergreen.V67.MailEditor
import Evergreen.V67.PingData
import Evergreen.V67.Point2d
import Evergreen.V67.Postmark
import Evergreen.V67.Route
import Evergreen.V67.Shaders
import Evergreen.V67.Sound
import Evergreen.V67.TextInput
import Evergreen.V67.Tile
import Evergreen.V67.Train
import Evergreen.V67.Units
import Evergreen.V67.Untrusted
import Evergreen.V67.User
import Html.Events.Extra.Mouse
import Html.Events.Extra.Wheel
import Lamdera
import List.Nonempty
import Pixels
import Quantity
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
    | KeyMsg Evergreen.V67.Keyboard.Msg
    | KeyDown Evergreen.V67.Keyboard.RawKey
    | WindowResized (Evergreen.V67.Coord.Coord CssPixel)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V67.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V67.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V67.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V67.Sound.Sound (Result Evergreen.V67.Audio.LoadError Evergreen.V67.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V67.LocalModel.LocalModel Evergreen.V67.Change.Change Evergreen.V67.LocalGrid.LocalGrid
    , trains : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.TrainId Evergreen.V67.Train.Train
    , mail : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.MailId Evergreen.V67.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V67.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V67.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V67.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V67.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V67.Coord.Coord Evergreen.V67.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V67.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V67.Sound.Sound (Result Evergreen.V67.Audio.LoadError Evergreen.V67.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V67.Point2d.Point2d Evergreen.V67.Units.WorldUnit Evergreen.V67.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V67.Id.Id Evergreen.V67.Id.TrainId
        , startViewPoint : Evergreen.V67.Point2d.Point2d Evergreen.V67.Units.WorldUnit Evergreen.V67.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V67.Tile.TileGroup
    | TilePickerToolButton
    | TextToolButton


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
    | MailEditorHover Evergreen.V67.MailEditor.Hover
    | YouGotMailButton
    | ShowMapButton
    | AllowEmailNotificationsCheckbox
    | ResetConnectionsButton
    | UsersOnlineButton


type Hover
    = TileHover
        { tile : Evergreen.V67.Tile.Tile
        , userId : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
        , position : Evergreen.V67.Coord.Coord Evergreen.V67.Units.WorldUnit
        , colors : Evergreen.V67.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V67.Id.Id Evergreen.V67.Id.TrainId
        , train : Evergreen.V67.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V67.Id.Id Evergreen.V67.Id.CowId
        , cow : Evergreen.V67.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V67.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V67.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V67.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V67.Point2d.Point2d Evergreen.V67.Units.WorldUnit Evergreen.V67.Units.WorldUnit
        , current : Evergreen.V67.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V67.Coord.Coord Evergreen.V67.Units.WorldUnit
    , tile : Evergreen.V67.Tile.Tile
    , colors : Evergreen.V67.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V67.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V67.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V67.Coord.Coord Evergreen.V67.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V67.Units.WorldUnit
            }
        )


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = InviteMenu
    | SettingsMenu Evergreen.V67.TextInput.Model
    | LoggedOutSettingsMenu


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V67.LocalModel.LocalModel Evergreen.V67.Change.Change Evergreen.V67.LocalGrid.LocalGrid
    , trains : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.TrainId Evergreen.V67.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V67.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V67.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V67.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V67.Point2d.Point2d Evergreen.V67.Units.WorldUnit Evergreen.V67.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V67.Keyboard.Key
    , windowSize : Evergreen.V67.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V67.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V67.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V67.Id.Id Evergreen.V67.Id.EventId, Evergreen.V67.Change.LocalChange )
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
            , tile : Evergreen.V67.Tile.Tile
            , position : Evergreen.V67.Coord.Coord Evergreen.V67.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V67.Sound.Sound (Result Evergreen.V67.Audio.LoadError Evergreen.V67.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V67.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V67.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V67.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V67.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V67.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V67.Id.Id Evergreen.V67.Id.EventId
    , pingData : Maybe Evergreen.V67.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V67.Tile.TileGroup Evergreen.V67.Color.Colors
    , primaryColorTextInput : Evergreen.V67.TextInput.Model
    , secondaryColorTextInput : Evergreen.V67.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V67.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V67.IdDict.IdDict
            Evergreen.V67.Id.UserId
            { position : Evergreen.V67.Point2d.Point2d Evergreen.V67.Units.WorldUnit Evergreen.V67.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.UserId Evergreen.V67.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V67.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V67.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V67.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V67.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V67.Coord.Coord Evergreen.V67.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showMap : Bool
    , showInviteTree : Bool
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V67.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V67.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V67.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V67.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.UserId (List Evergreen.V67.MailEditor.Content)
    , cursor : Maybe Evergreen.V67.Cursor.Cursor
    , handColor : Evergreen.V67.Color.Colors
    , emailAddress : Evergreen.V67.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.UserId ()
    , name : Evergreen.V67.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V67.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V67.Id.Id Evergreen.V67.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V67.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V67.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V67.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V67.Bounds.Bounds Evergreen.V67.Units.CellUnit)
            , userId : Maybe (Evergreen.V67.Id.Id Evergreen.V67.Id.UserId)
            }
    , users : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.TrainId Evergreen.V67.Train.Train
    , cows : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.CowId Evergreen.V67.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.TrainId Evergreen.V67.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.MailId Evergreen.V67.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V67.Id.SecretId Evergreen.V67.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V67.Id.Id Evergreen.V67.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V67.Id.SecretId Evergreen.V67.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V67.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V67.Bounds.Bounds Evergreen.V67.Units.CellUnit) (Maybe Evergreen.V67.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V67.Id.Id Evergreen.V67.Id.EventId, Evergreen.V67.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V67.Bounds.Bounds Evergreen.V67.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V67.Untrusted.Untrusted Evergreen.V67.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V67.Untrusted.Untrusted Evergreen.V67.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V67.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V67.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V67.Id.SecretId Evergreen.V67.Route.InviteToken) (Result Effect.Http.Error Evergreen.V67.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V67.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V67.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V67.Grid.GridData
    , userStatus : Evergreen.V67.Change.UserStatus
    , viewBounds : Evergreen.V67.Bounds.Bounds Evergreen.V67.Units.CellUnit
    , trains : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.TrainId Evergreen.V67.Train.Train
    , mail : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.MailId Evergreen.V67.MailEditor.FrontendMail
    , cows : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.CowId Evergreen.V67.Change.Cow
    , cursors : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.UserId Evergreen.V67.Cursor.Cursor
    , users : Evergreen.V67.IdDict.IdDict Evergreen.V67.Id.UserId Evergreen.V67.User.FrontendUser
    , inviteTree : Evergreen.V67.User.InviteTree
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V67.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V67.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V67.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V67.Coord.Coord Evergreen.V67.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
