module Evergreen.V60.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V60.Audio
import Evergreen.V60.Bounds
import Evergreen.V60.Change
import Evergreen.V60.Color
import Evergreen.V60.Coord
import Evergreen.V60.Cursor
import Evergreen.V60.DisplayName
import Evergreen.V60.EmailAddress
import Evergreen.V60.Grid
import Evergreen.V60.Id
import Evergreen.V60.IdDict
import Evergreen.V60.Keyboard
import Evergreen.V60.LocalGrid
import Evergreen.V60.LocalModel
import Evergreen.V60.MailEditor
import Evergreen.V60.PingData
import Evergreen.V60.Point2d
import Evergreen.V60.Postmark
import Evergreen.V60.Route
import Evergreen.V60.Shaders
import Evergreen.V60.Sound
import Evergreen.V60.TextInput
import Evergreen.V60.Tile
import Evergreen.V60.Train
import Evergreen.V60.Units
import Evergreen.V60.Untrusted
import Evergreen.V60.User
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
    | KeyMsg Evergreen.V60.Keyboard.Msg
    | KeyDown Evergreen.V60.Keyboard.RawKey
    | WindowResized (Evergreen.V60.Coord.Coord CssPixel)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V60.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V60.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V60.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V60.Sound.Sound (Result Evergreen.V60.Audio.LoadError Evergreen.V60.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V60.LocalModel.LocalModel Evergreen.V60.Change.Change Evergreen.V60.LocalGrid.LocalGrid
    , trains : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.TrainId Evergreen.V60.Train.Train
    , mail : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.MailId Evergreen.V60.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V60.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V60.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V60.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V60.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V60.Coord.Coord Evergreen.V60.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V60.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V60.Sound.Sound (Result Evergreen.V60.Audio.LoadError Evergreen.V60.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V60.Point2d.Point2d Evergreen.V60.Units.WorldUnit Evergreen.V60.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V60.Id.Id Evergreen.V60.Id.TrainId
        , startViewPoint : Evergreen.V60.Point2d.Point2d Evergreen.V60.Units.WorldUnit Evergreen.V60.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V60.Tile.TileGroup
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
    | MailEditorHover Evergreen.V60.MailEditor.Hover
    | YouGotMailButton
    | ShowMapButton
    | AllowEmailNotificationsCheckbox
    | ResetConnectionsButton


type Hover
    = TileHover
        { tile : Evergreen.V60.Tile.Tile
        , userId : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
        , position : Evergreen.V60.Coord.Coord Evergreen.V60.Units.WorldUnit
        , colors : Evergreen.V60.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V60.Id.Id Evergreen.V60.Id.TrainId
        , train : Evergreen.V60.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V60.Id.Id Evergreen.V60.Id.CowId
        , cow : Evergreen.V60.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V60.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V60.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V60.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V60.Point2d.Point2d Evergreen.V60.Units.WorldUnit Evergreen.V60.Units.WorldUnit
        , current : Evergreen.V60.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V60.Coord.Coord Evergreen.V60.Units.WorldUnit
    , tile : Evergreen.V60.Tile.Tile
    , colors : Evergreen.V60.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V60.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V60.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V60.Coord.Coord Evergreen.V60.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V60.Units.WorldUnit
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
    | SettingsMenu Evergreen.V60.TextInput.Model
    | LoggedOutSettingsMenu


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V60.LocalModel.LocalModel Evergreen.V60.Change.Change Evergreen.V60.LocalGrid.LocalGrid
    , trains : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.TrainId Evergreen.V60.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V60.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V60.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V60.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V60.Point2d.Point2d Evergreen.V60.Units.WorldUnit Evergreen.V60.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V60.Keyboard.Key
    , windowSize : Evergreen.V60.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V60.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V60.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V60.Id.Id Evergreen.V60.Id.EventId, Evergreen.V60.Change.LocalChange )
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
            , tile : Evergreen.V60.Tile.Tile
            , position : Evergreen.V60.Coord.Coord Evergreen.V60.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V60.Sound.Sound (Result Evergreen.V60.Audio.LoadError Evergreen.V60.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V60.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V60.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V60.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V60.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V60.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V60.Id.Id Evergreen.V60.Id.EventId
    , pingData : Maybe Evergreen.V60.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V60.Tile.TileGroup Evergreen.V60.Color.Colors
    , primaryColorTextInput : Evergreen.V60.TextInput.Model
    , secondaryColorTextInput : Evergreen.V60.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V60.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V60.IdDict.IdDict
            Evergreen.V60.Id.UserId
            { position : Evergreen.V60.Point2d.Point2d Evergreen.V60.Units.WorldUnit Evergreen.V60.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.UserId Evergreen.V60.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V60.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V60.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V60.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V60.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V60.Coord.Coord Evergreen.V60.Units.WorldUnit )
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
    Evergreen.V60.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V60.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V60.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V60.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.UserId (List Evergreen.V60.MailEditor.Content)
    , cursor : Maybe Evergreen.V60.Cursor.Cursor
    , handColor : Evergreen.V60.Color.Colors
    , emailAddress : Evergreen.V60.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.UserId ()
    , name : Evergreen.V60.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V60.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V60.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V60.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V60.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V60.Bounds.Bounds Evergreen.V60.Units.CellUnit)
            , userId : Maybe (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)
            }
    , users : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.TrainId Evergreen.V60.Train.Train
    , cows : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.CowId Evergreen.V60.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.TrainId Evergreen.V60.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.MailId Evergreen.V60.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V60.Id.SecretId Evergreen.V60.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V60.Id.SecretId Evergreen.V60.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V60.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V60.Bounds.Bounds Evergreen.V60.Units.CellUnit) (Maybe Evergreen.V60.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V60.Id.Id Evergreen.V60.Id.EventId, Evergreen.V60.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V60.Bounds.Bounds Evergreen.V60.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V60.Untrusted.Untrusted Evergreen.V60.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V60.Untrusted.Untrusted Evergreen.V60.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V60.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V60.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V60.Id.SecretId Evergreen.V60.Route.InviteToken) (Result Effect.Http.Error Evergreen.V60.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V60.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V60.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V60.Grid.GridData
    , userStatus : Evergreen.V60.Change.UserStatus
    , viewBounds : Evergreen.V60.Bounds.Bounds Evergreen.V60.Units.CellUnit
    , trains : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.TrainId Evergreen.V60.Train.Train
    , mail : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.MailId Evergreen.V60.MailEditor.FrontendMail
    , cows : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.CowId Evergreen.V60.Change.Cow
    , cursors : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.UserId Evergreen.V60.Cursor.Cursor
    , users : Evergreen.V60.IdDict.IdDict Evergreen.V60.Id.UserId Evergreen.V60.User.FrontendUser
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V60.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V60.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V60.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V60.Coord.Coord Evergreen.V60.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
