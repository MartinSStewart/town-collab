module Evergreen.V59.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V59.Audio
import Evergreen.V59.Bounds
import Evergreen.V59.Change
import Evergreen.V59.Color
import Evergreen.V59.Coord
import Evergreen.V59.Cursor
import Evergreen.V59.DisplayName
import Evergreen.V59.EmailAddress
import Evergreen.V59.Grid
import Evergreen.V59.Id
import Evergreen.V59.IdDict
import Evergreen.V59.Keyboard
import Evergreen.V59.LocalGrid
import Evergreen.V59.LocalModel
import Evergreen.V59.MailEditor
import Evergreen.V59.PingData
import Evergreen.V59.Point2d
import Evergreen.V59.Postmark
import Evergreen.V59.Route
import Evergreen.V59.Shaders
import Evergreen.V59.Sound
import Evergreen.V59.TextInput
import Evergreen.V59.Tile
import Evergreen.V59.Train
import Evergreen.V59.Units
import Evergreen.V59.Untrusted
import Evergreen.V59.User
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
    | KeyMsg Evergreen.V59.Keyboard.Msg
    | KeyDown Evergreen.V59.Keyboard.RawKey
    | WindowResized (Evergreen.V59.Coord.Coord CssPixel)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V59.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V59.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V59.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V59.Sound.Sound (Result Evergreen.V59.Audio.LoadError Evergreen.V59.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V59.LocalModel.LocalModel Evergreen.V59.Change.Change Evergreen.V59.LocalGrid.LocalGrid
    , trains : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.TrainId Evergreen.V59.Train.Train
    , mail : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.MailId Evergreen.V59.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V59.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V59.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V59.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V59.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V59.Coord.Coord Evergreen.V59.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V59.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V59.Sound.Sound (Result Evergreen.V59.Audio.LoadError Evergreen.V59.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V59.Point2d.Point2d Evergreen.V59.Units.WorldUnit Evergreen.V59.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V59.Id.Id Evergreen.V59.Id.TrainId
        , startViewPoint : Evergreen.V59.Point2d.Point2d Evergreen.V59.Units.WorldUnit Evergreen.V59.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V59.Tile.TileGroup
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
    | MailEditorHover Evergreen.V59.MailEditor.Hover
    | YouGotMailButton
    | ShowMapButton
    | AllowEmailNotificationsCheckbox
    | ResetConnectionsButton


type Hover
    = TileHover
        { tile : Evergreen.V59.Tile.Tile
        , userId : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
        , position : Evergreen.V59.Coord.Coord Evergreen.V59.Units.WorldUnit
        , colors : Evergreen.V59.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V59.Id.Id Evergreen.V59.Id.TrainId
        , train : Evergreen.V59.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V59.Id.Id Evergreen.V59.Id.CowId
        , cow : Evergreen.V59.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V59.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V59.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V59.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V59.Point2d.Point2d Evergreen.V59.Units.WorldUnit Evergreen.V59.Units.WorldUnit
        , current : Evergreen.V59.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V59.Coord.Coord Evergreen.V59.Units.WorldUnit
    , tile : Evergreen.V59.Tile.Tile
    , colors : Evergreen.V59.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V59.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V59.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V59.Coord.Coord Evergreen.V59.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V59.Units.WorldUnit
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
    | SettingsMenu Evergreen.V59.TextInput.Model
    | LoggedOutSettingsMenu


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V59.LocalModel.LocalModel Evergreen.V59.Change.Change Evergreen.V59.LocalGrid.LocalGrid
    , trains : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.TrainId Evergreen.V59.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V59.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V59.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V59.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V59.Point2d.Point2d Evergreen.V59.Units.WorldUnit Evergreen.V59.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V59.Keyboard.Key
    , windowSize : Evergreen.V59.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V59.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V59.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V59.Id.Id Evergreen.V59.Id.EventId, Evergreen.V59.Change.LocalChange )
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
            , tile : Evergreen.V59.Tile.Tile
            , position : Evergreen.V59.Coord.Coord Evergreen.V59.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V59.Sound.Sound (Result Evergreen.V59.Audio.LoadError Evergreen.V59.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V59.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V59.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V59.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V59.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V59.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V59.Id.Id Evergreen.V59.Id.EventId
    , pingData : Maybe Evergreen.V59.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V59.Tile.TileGroup Evergreen.V59.Color.Colors
    , primaryColorTextInput : Evergreen.V59.TextInput.Model
    , secondaryColorTextInput : Evergreen.V59.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V59.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V59.IdDict.IdDict
            Evergreen.V59.Id.UserId
            { position : Evergreen.V59.Point2d.Point2d Evergreen.V59.Units.WorldUnit Evergreen.V59.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.UserId Evergreen.V59.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V59.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V59.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V59.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V59.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V59.Coord.Coord Evergreen.V59.Units.WorldUnit )
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
    Evergreen.V59.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V59.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V59.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V59.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.UserId (List Evergreen.V59.MailEditor.Content)
    , cursor : Maybe Evergreen.V59.Cursor.Cursor
    , handColor : Evergreen.V59.Color.Colors
    , emailAddress : Evergreen.V59.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.UserId ()
    , name : Evergreen.V59.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V59.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V59.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V59.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V59.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V59.Bounds.Bounds Evergreen.V59.Units.CellUnit)
            , userId : Maybe (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId)
            }
    , users : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.TrainId Evergreen.V59.Train.Train
    , cows : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.CowId Evergreen.V59.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.TrainId Evergreen.V59.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.MailId Evergreen.V59.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V59.Id.SecretId Evergreen.V59.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V59.Id.Id Evergreen.V59.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V59.Id.SecretId Evergreen.V59.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V59.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V59.Bounds.Bounds Evergreen.V59.Units.CellUnit) (Maybe Evergreen.V59.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V59.Id.Id Evergreen.V59.Id.EventId, Evergreen.V59.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V59.Bounds.Bounds Evergreen.V59.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V59.Untrusted.Untrusted Evergreen.V59.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V59.Untrusted.Untrusted Evergreen.V59.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V59.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V59.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V59.Id.SecretId Evergreen.V59.Route.InviteToken) (Result Effect.Http.Error Evergreen.V59.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V59.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V59.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V59.Grid.GridData
    , userStatus : Evergreen.V59.Change.UserStatus
    , viewBounds : Evergreen.V59.Bounds.Bounds Evergreen.V59.Units.CellUnit
    , trains : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.TrainId Evergreen.V59.Train.Train
    , mail : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.MailId Evergreen.V59.MailEditor.FrontendMail
    , cows : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.CowId Evergreen.V59.Change.Cow
    , cursors : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.UserId Evergreen.V59.Cursor.Cursor
    , users : Evergreen.V59.IdDict.IdDict Evergreen.V59.Id.UserId Evergreen.V59.User.FrontendUser
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V59.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V59.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V59.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V59.Coord.Coord Evergreen.V59.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
