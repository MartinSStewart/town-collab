module Evergreen.V62.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V62.Audio
import Evergreen.V62.Bounds
import Evergreen.V62.Change
import Evergreen.V62.Color
import Evergreen.V62.Coord
import Evergreen.V62.Cursor
import Evergreen.V62.DisplayName
import Evergreen.V62.EmailAddress
import Evergreen.V62.Grid
import Evergreen.V62.Id
import Evergreen.V62.IdDict
import Evergreen.V62.Keyboard
import Evergreen.V62.LocalGrid
import Evergreen.V62.LocalModel
import Evergreen.V62.MailEditor
import Evergreen.V62.PingData
import Evergreen.V62.Point2d
import Evergreen.V62.Postmark
import Evergreen.V62.Route
import Evergreen.V62.Shaders
import Evergreen.V62.Sound
import Evergreen.V62.TextInput
import Evergreen.V62.Tile
import Evergreen.V62.Train
import Evergreen.V62.Units
import Evergreen.V62.Untrusted
import Evergreen.V62.User
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
    | KeyMsg Evergreen.V62.Keyboard.Msg
    | KeyDown Evergreen.V62.Keyboard.RawKey
    | WindowResized (Evergreen.V62.Coord.Coord CssPixel)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V62.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V62.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V62.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V62.Sound.Sound (Result Evergreen.V62.Audio.LoadError Evergreen.V62.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V62.LocalModel.LocalModel Evergreen.V62.Change.Change Evergreen.V62.LocalGrid.LocalGrid
    , trains : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.TrainId Evergreen.V62.Train.Train
    , mail : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.MailId Evergreen.V62.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V62.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V62.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V62.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V62.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V62.Coord.Coord Evergreen.V62.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V62.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V62.Sound.Sound (Result Evergreen.V62.Audio.LoadError Evergreen.V62.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V62.Point2d.Point2d Evergreen.V62.Units.WorldUnit Evergreen.V62.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V62.Id.Id Evergreen.V62.Id.TrainId
        , startViewPoint : Evergreen.V62.Point2d.Point2d Evergreen.V62.Units.WorldUnit Evergreen.V62.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V62.Tile.TileGroup
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
    | MailEditorHover Evergreen.V62.MailEditor.Hover
    | YouGotMailButton
    | ShowMapButton
    | AllowEmailNotificationsCheckbox
    | ResetConnectionsButton


type Hover
    = TileHover
        { tile : Evergreen.V62.Tile.Tile
        , userId : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
        , position : Evergreen.V62.Coord.Coord Evergreen.V62.Units.WorldUnit
        , colors : Evergreen.V62.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V62.Id.Id Evergreen.V62.Id.TrainId
        , train : Evergreen.V62.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V62.Id.Id Evergreen.V62.Id.CowId
        , cow : Evergreen.V62.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V62.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V62.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V62.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V62.Point2d.Point2d Evergreen.V62.Units.WorldUnit Evergreen.V62.Units.WorldUnit
        , current : Evergreen.V62.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V62.Coord.Coord Evergreen.V62.Units.WorldUnit
    , tile : Evergreen.V62.Tile.Tile
    , colors : Evergreen.V62.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V62.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V62.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V62.Coord.Coord Evergreen.V62.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V62.Units.WorldUnit
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
    | SettingsMenu Evergreen.V62.TextInput.Model
    | LoggedOutSettingsMenu


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V62.LocalModel.LocalModel Evergreen.V62.Change.Change Evergreen.V62.LocalGrid.LocalGrid
    , trains : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.TrainId Evergreen.V62.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V62.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V62.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V62.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V62.Point2d.Point2d Evergreen.V62.Units.WorldUnit Evergreen.V62.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V62.Keyboard.Key
    , windowSize : Evergreen.V62.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V62.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V62.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V62.Id.Id Evergreen.V62.Id.EventId, Evergreen.V62.Change.LocalChange )
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
            , tile : Evergreen.V62.Tile.Tile
            , position : Evergreen.V62.Coord.Coord Evergreen.V62.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V62.Sound.Sound (Result Evergreen.V62.Audio.LoadError Evergreen.V62.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V62.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V62.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V62.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V62.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V62.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V62.Id.Id Evergreen.V62.Id.EventId
    , pingData : Maybe Evergreen.V62.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V62.Tile.TileGroup Evergreen.V62.Color.Colors
    , primaryColorTextInput : Evergreen.V62.TextInput.Model
    , secondaryColorTextInput : Evergreen.V62.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V62.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V62.IdDict.IdDict
            Evergreen.V62.Id.UserId
            { position : Evergreen.V62.Point2d.Point2d Evergreen.V62.Units.WorldUnit Evergreen.V62.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.UserId Evergreen.V62.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V62.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V62.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V62.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V62.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V62.Coord.Coord Evergreen.V62.Units.WorldUnit )
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
    Evergreen.V62.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V62.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V62.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V62.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.UserId (List Evergreen.V62.MailEditor.Content)
    , cursor : Maybe Evergreen.V62.Cursor.Cursor
    , handColor : Evergreen.V62.Color.Colors
    , emailAddress : Evergreen.V62.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.UserId ()
    , name : Evergreen.V62.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V62.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V62.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V62.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V62.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V62.Bounds.Bounds Evergreen.V62.Units.CellUnit)
            , userId : Maybe (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId)
            }
    , users : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.TrainId Evergreen.V62.Train.Train
    , cows : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.CowId Evergreen.V62.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.TrainId Evergreen.V62.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.MailId Evergreen.V62.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V62.Id.SecretId Evergreen.V62.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V62.Id.SecretId Evergreen.V62.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V62.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V62.Bounds.Bounds Evergreen.V62.Units.CellUnit) (Maybe Evergreen.V62.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V62.Id.Id Evergreen.V62.Id.EventId, Evergreen.V62.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V62.Bounds.Bounds Evergreen.V62.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V62.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V62.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V62.Id.SecretId Evergreen.V62.Route.InviteToken) (Result Effect.Http.Error Evergreen.V62.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V62.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V62.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V62.Grid.GridData
    , userStatus : Evergreen.V62.Change.UserStatus
    , viewBounds : Evergreen.V62.Bounds.Bounds Evergreen.V62.Units.CellUnit
    , trains : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.TrainId Evergreen.V62.Train.Train
    , mail : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.MailId Evergreen.V62.MailEditor.FrontendMail
    , cows : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.CowId Evergreen.V62.Change.Cow
    , cursors : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.UserId Evergreen.V62.Cursor.Cursor
    , users : Evergreen.V62.IdDict.IdDict Evergreen.V62.Id.UserId Evergreen.V62.User.FrontendUser
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V62.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V62.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V62.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V62.Coord.Coord Evergreen.V62.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
