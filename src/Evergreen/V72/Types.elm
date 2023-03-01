module Evergreen.V72.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V72.Audio
import Evergreen.V72.Bounds
import Evergreen.V72.Change
import Evergreen.V72.Color
import Evergreen.V72.Coord
import Evergreen.V72.Cursor
import Evergreen.V72.DisplayName
import Evergreen.V72.EmailAddress
import Evergreen.V72.Grid
import Evergreen.V72.Id
import Evergreen.V72.IdDict
import Evergreen.V72.Keyboard
import Evergreen.V72.LocalGrid
import Evergreen.V72.LocalModel
import Evergreen.V72.MailEditor
import Evergreen.V72.PingData
import Evergreen.V72.Point2d
import Evergreen.V72.Postmark
import Evergreen.V72.Route
import Evergreen.V72.Shaders
import Evergreen.V72.Sound
import Evergreen.V72.TextInput
import Evergreen.V72.Tile
import Evergreen.V72.Train
import Evergreen.V72.Ui
import Evergreen.V72.Units
import Evergreen.V72.Untrusted
import Evergreen.V72.User
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
    | KeyMsg Evergreen.V72.Keyboard.Msg
    | KeyDown Evergreen.V72.Keyboard.RawKey
    | WindowResized (Evergreen.V72.Coord.Coord CssPixel)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V72.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V72.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V72.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V72.Sound.Sound (Result Evergreen.V72.Audio.LoadError Evergreen.V72.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V72.LocalModel.LocalModel Evergreen.V72.Change.Change Evergreen.V72.LocalGrid.LocalGrid
    , trains : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.TrainId Evergreen.V72.Train.Train
    , mail : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.MailId Evergreen.V72.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V72.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V72.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V72.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V72.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V72.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V72.Sound.Sound (Result Evergreen.V72.Audio.LoadError Evergreen.V72.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V72.Point2d.Point2d Evergreen.V72.Units.WorldUnit Evergreen.V72.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V72.Id.Id Evergreen.V72.Id.TrainId
        , startViewPoint : Evergreen.V72.Point2d.Point2d Evergreen.V72.Units.WorldUnit Evergreen.V72.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V72.Tile.TileGroup
    | TilePickerToolButton
    | TextToolButton
    | ReportToolButton


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
    | MailEditorHover Evergreen.V72.MailEditor.Hover
    | YouGotMailButton
    | ShowMapButton
    | AllowEmailNotificationsCheckbox
    | ResetConnectionsButton
    | UsersOnlineButton
    | CopyPositionUrlButton
    | ReportUserButton
    | ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton


type Hover
    = TileHover
        { tile : Evergreen.V72.Tile.Tile
        , userId : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
        , position : Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit
        , colors : Evergreen.V72.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V72.Id.Id Evergreen.V72.Id.TrainId
        , train : Evergreen.V72.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V72.Id.Id Evergreen.V72.Id.CowId
        , cow : Evergreen.V72.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V72.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V72.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V72.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V72.Point2d.Point2d Evergreen.V72.Units.WorldUnit Evergreen.V72.Units.WorldUnit
        , current : Evergreen.V72.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit
    , tile : Evergreen.V72.Tile.Tile
    , colors : Evergreen.V72.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V72.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V72.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V72.Units.WorldUnit
            }
        )
    | ReportTool


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = InviteMenu
    | SettingsMenu Evergreen.V72.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V72.Id.Id Evergreen.V72.Id.UserId)
    , position : Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit
    , linkCopied : Bool
    }


type alias UpdateMeshesData =
    { localModel : Evergreen.V72.LocalModel.LocalModel Evergreen.V72.Change.Change Evergreen.V72.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V72.Keyboard.Key
    , currentTool : Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V72.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mailEditor : Maybe Evergreen.V72.MailEditor.Model
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.TrainId Evergreen.V72.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V72.LocalModel.LocalModel Evergreen.V72.Change.Change Evergreen.V72.LocalGrid.LocalGrid
    , trains : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.TrainId Evergreen.V72.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V72.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V72.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V72.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V72.Point2d.Point2d Evergreen.V72.Units.WorldUnit Evergreen.V72.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V72.Keyboard.Key
    , windowSize : Evergreen.V72.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V72.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V72.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V72.Id.Id Evergreen.V72.Id.EventId, Evergreen.V72.Change.LocalChange )
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
            , tile : Evergreen.V72.Tile.Tile
            , position : Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V72.Sound.Sound (Result Evergreen.V72.Audio.LoadError Evergreen.V72.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V72.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V72.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V72.Tile.TileGroup
    , ui : Evergreen.V72.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V72.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V72.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V72.Id.Id Evergreen.V72.Id.EventId
    , pingData : Maybe Evergreen.V72.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V72.Tile.TileGroup Evergreen.V72.Color.Colors
    , primaryColorTextInput : Evergreen.V72.TextInput.Model
    , secondaryColorTextInput : Evergreen.V72.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V72.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V72.IdDict.IdDict
            Evergreen.V72.Id.UserId
            { position : Evergreen.V72.Point2d.Point2d Evergreen.V72.Units.WorldUnit Evergreen.V72.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.UserId Evergreen.V72.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V72.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V72.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V72.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V72.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showMap : Bool
    , showInviteTree : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V72.Shaders.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V72.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V72.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V72.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V72.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.UserId (List Evergreen.V72.MailEditor.Content)
    , cursor : Maybe Evergreen.V72.Cursor.Cursor
    , handColor : Evergreen.V72.Color.Colors
    , emailAddress : Evergreen.V72.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.UserId ()
    , name : Evergreen.V72.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V72.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V72.Id.Id Evergreen.V72.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V72.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V72.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V72.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V72.Bounds.Bounds Evergreen.V72.Units.CellUnit)
            , userId : Maybe (Evergreen.V72.Id.Id Evergreen.V72.Id.UserId)
            }
    , users : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.TrainId Evergreen.V72.Train.Train
    , cows : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.CowId Evergreen.V72.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.TrainId Evergreen.V72.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.MailId Evergreen.V72.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V72.Id.SecretId Evergreen.V72.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V72.Id.Id Evergreen.V72.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V72.Id.SecretId Evergreen.V72.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.UserId (List.Nonempty.Nonempty Evergreen.V72.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V72.Change.AreTrainsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V72.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V72.Bounds.Bounds Evergreen.V72.Units.CellUnit) (Maybe Evergreen.V72.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V72.Id.Id Evergreen.V72.Id.EventId, Evergreen.V72.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V72.Bounds.Bounds Evergreen.V72.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V72.Untrusted.Untrusted Evergreen.V72.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V72.Untrusted.Untrusted Evergreen.V72.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V72.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V72.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V72.Id.SecretId Evergreen.V72.Route.InviteToken) (Result Effect.Http.Error Evergreen.V72.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V72.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V72.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V72.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V72.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V72.Grid.GridData
    , userStatus : Evergreen.V72.Change.UserStatus
    , viewBounds : Evergreen.V72.Bounds.Bounds Evergreen.V72.Units.CellUnit
    , trains : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.TrainId Evergreen.V72.Train.Train
    , mail : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.MailId Evergreen.V72.MailEditor.FrontendMail
    , cows : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.CowId Evergreen.V72.Change.Cow
    , cursors : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.UserId Evergreen.V72.Cursor.Cursor
    , users : Evergreen.V72.IdDict.IdDict Evergreen.V72.Id.UserId Evergreen.V72.User.FrontendUser
    , inviteTree : Evergreen.V72.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V72.Change.AreTrainsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V72.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V72.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V72.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V72.Coord.Coord Evergreen.V72.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
