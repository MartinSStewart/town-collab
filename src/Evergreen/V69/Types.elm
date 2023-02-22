module Evergreen.V69.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V69.Audio
import Evergreen.V69.Bounds
import Evergreen.V69.Change
import Evergreen.V69.Color
import Evergreen.V69.Coord
import Evergreen.V69.Cursor
import Evergreen.V69.DisplayName
import Evergreen.V69.EmailAddress
import Evergreen.V69.Grid
import Evergreen.V69.Id
import Evergreen.V69.IdDict
import Evergreen.V69.Keyboard
import Evergreen.V69.LocalGrid
import Evergreen.V69.LocalModel
import Evergreen.V69.MailEditor
import Evergreen.V69.PingData
import Evergreen.V69.Point2d
import Evergreen.V69.Postmark
import Evergreen.V69.Route
import Evergreen.V69.Shaders
import Evergreen.V69.Sound
import Evergreen.V69.TextInput
import Evergreen.V69.Tile
import Evergreen.V69.Train
import Evergreen.V69.Ui
import Evergreen.V69.Units
import Evergreen.V69.Untrusted
import Evergreen.V69.User
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
    | KeyMsg Evergreen.V69.Keyboard.Msg
    | KeyDown Evergreen.V69.Keyboard.RawKey
    | WindowResized (Evergreen.V69.Coord.Coord CssPixel)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V69.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V69.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V69.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V69.Sound.Sound (Result Evergreen.V69.Audio.LoadError Evergreen.V69.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V69.LocalModel.LocalModel Evergreen.V69.Change.Change Evergreen.V69.LocalGrid.LocalGrid
    , trains : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.TrainId Evergreen.V69.Train.Train
    , mail : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.MailId Evergreen.V69.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V69.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V69.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V69.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V69.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V69.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V69.Sound.Sound (Result Evergreen.V69.Audio.LoadError Evergreen.V69.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V69.Point2d.Point2d Evergreen.V69.Units.WorldUnit Evergreen.V69.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V69.Id.Id Evergreen.V69.Id.TrainId
        , startViewPoint : Evergreen.V69.Point2d.Point2d Evergreen.V69.Units.WorldUnit Evergreen.V69.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V69.Tile.TileGroup
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
    | MailEditorHover Evergreen.V69.MailEditor.Hover
    | YouGotMailButton
    | ShowMapButton
    | AllowEmailNotificationsCheckbox
    | ResetConnectionsButton
    | UsersOnlineButton
    | CopyPositionUrlButton
    | ReportUserButton
    | ToggleIsGridReadOnlyButton


type Hover
    = TileHover
        { tile : Evergreen.V69.Tile.Tile
        , userId : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
        , position : Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit
        , colors : Evergreen.V69.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V69.Id.Id Evergreen.V69.Id.TrainId
        , train : Evergreen.V69.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V69.Id.Id Evergreen.V69.Id.CowId
        , cow : Evergreen.V69.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V69.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V69.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V69.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V69.Point2d.Point2d Evergreen.V69.Units.WorldUnit Evergreen.V69.Units.WorldUnit
        , current : Evergreen.V69.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit
    , tile : Evergreen.V69.Tile.Tile
    , colors : Evergreen.V69.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V69.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V69.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V69.Units.WorldUnit
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
    | SettingsMenu Evergreen.V69.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId)
    , position : Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit
    , linkCopied : Bool
    }


type alias UpdateMeshesData =
    { localModel : Evergreen.V69.LocalModel.LocalModel Evergreen.V69.Change.Change Evergreen.V69.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V69.Keyboard.Key
    , currentTool : Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V69.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mailEditor : Maybe Evergreen.V69.MailEditor.Model
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.TrainId Evergreen.V69.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V69.LocalModel.LocalModel Evergreen.V69.Change.Change Evergreen.V69.LocalGrid.LocalGrid
    , trains : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.TrainId Evergreen.V69.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V69.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V69.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V69.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V69.Point2d.Point2d Evergreen.V69.Units.WorldUnit Evergreen.V69.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V69.Keyboard.Key
    , windowSize : Evergreen.V69.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V69.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V69.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V69.Id.Id Evergreen.V69.Id.EventId, Evergreen.V69.Change.LocalChange )
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
            , tile : Evergreen.V69.Tile.Tile
            , position : Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V69.Sound.Sound (Result Evergreen.V69.Audio.LoadError Evergreen.V69.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V69.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V69.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V69.Tile.TileGroup
    , ui : Evergreen.V69.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V69.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V69.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V69.Id.Id Evergreen.V69.Id.EventId
    , pingData : Maybe Evergreen.V69.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V69.Tile.TileGroup Evergreen.V69.Color.Colors
    , primaryColorTextInput : Evergreen.V69.TextInput.Model
    , secondaryColorTextInput : Evergreen.V69.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V69.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V69.IdDict.IdDict
            Evergreen.V69.Id.UserId
            { position : Evergreen.V69.Point2d.Point2d Evergreen.V69.Units.WorldUnit Evergreen.V69.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.UserId Evergreen.V69.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V69.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V69.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V69.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V69.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showMap : Bool
    , showInviteTree : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V69.Shaders.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V69.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V69.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V69.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V69.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.UserId (List Evergreen.V69.MailEditor.Content)
    , cursor : Maybe Evergreen.V69.Cursor.Cursor
    , handColor : Evergreen.V69.Color.Colors
    , emailAddress : Evergreen.V69.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.UserId ()
    , name : Evergreen.V69.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V69.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V69.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V69.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V69.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V69.Bounds.Bounds Evergreen.V69.Units.CellUnit)
            , userId : Maybe (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId)
            }
    , users : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.TrainId Evergreen.V69.Train.Train
    , cows : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.CowId Evergreen.V69.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.TrainId Evergreen.V69.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.MailId Evergreen.V69.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V69.Id.SecretId Evergreen.V69.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V69.Id.SecretId Evergreen.V69.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.UserId (List.Nonempty.Nonempty Evergreen.V69.Change.BackendReport)
    , isGridReadOnly : Bool
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V69.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V69.Bounds.Bounds Evergreen.V69.Units.CellUnit) (Maybe Evergreen.V69.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V69.Id.Id Evergreen.V69.Id.EventId, Evergreen.V69.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V69.Bounds.Bounds Evergreen.V69.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V69.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V69.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V69.Id.SecretId Evergreen.V69.Route.InviteToken) (Result Effect.Http.Error Evergreen.V69.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V69.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V69.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V69.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V69.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V69.Grid.GridData
    , userStatus : Evergreen.V69.Change.UserStatus
    , viewBounds : Evergreen.V69.Bounds.Bounds Evergreen.V69.Units.CellUnit
    , trains : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.TrainId Evergreen.V69.Train.Train
    , mail : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.MailId Evergreen.V69.MailEditor.FrontendMail
    , cows : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.CowId Evergreen.V69.Change.Cow
    , cursors : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.UserId Evergreen.V69.Cursor.Cursor
    , users : Evergreen.V69.IdDict.IdDict Evergreen.V69.Id.UserId Evergreen.V69.User.FrontendUser
    , inviteTree : Evergreen.V69.User.InviteTree
    , isGridReadOnly : Bool
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V69.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V69.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V69.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V69.Coord.Coord Evergreen.V69.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
