module Evergreen.V77.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V77.Animal
import Evergreen.V77.Audio
import Evergreen.V77.Bounds
import Evergreen.V77.Change
import Evergreen.V77.Color
import Evergreen.V77.Coord
import Evergreen.V77.Cursor
import Evergreen.V77.DisplayName
import Evergreen.V77.EmailAddress
import Evergreen.V77.Grid
import Evergreen.V77.Id
import Evergreen.V77.IdDict
import Evergreen.V77.Keyboard
import Evergreen.V77.LocalGrid
import Evergreen.V77.LocalModel
import Evergreen.V77.MailEditor
import Evergreen.V77.PingData
import Evergreen.V77.Point2d
import Evergreen.V77.Postmark
import Evergreen.V77.Route
import Evergreen.V77.Shaders
import Evergreen.V77.Sound
import Evergreen.V77.TextInput
import Evergreen.V77.Tile
import Evergreen.V77.Train
import Evergreen.V77.Ui
import Evergreen.V77.Units
import Evergreen.V77.Untrusted
import Evergreen.V77.User
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
    | KeyMsg Evergreen.V77.Keyboard.Msg
    | KeyDown Evergreen.V77.Keyboard.RawKey
    | WindowResized (Evergreen.V77.Coord.Coord CssPixel)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V77.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V77.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V77.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V77.Sound.Sound (Result Evergreen.V77.Audio.LoadError Evergreen.V77.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V77.LocalModel.LocalModel Evergreen.V77.Change.Change Evergreen.V77.LocalGrid.LocalGrid
    , trains : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.TrainId Evergreen.V77.Train.Train
    , mail : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.MailId Evergreen.V77.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V77.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V77.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V77.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V77.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V77.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V77.Sound.Sound (Result Evergreen.V77.Audio.LoadError Evergreen.V77.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V77.Point2d.Point2d Evergreen.V77.Units.WorldUnit Evergreen.V77.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V77.Id.Id Evergreen.V77.Id.TrainId
        , startViewPoint : Evergreen.V77.Point2d.Point2d Evergreen.V77.Units.WorldUnit Evergreen.V77.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V77.Tile.TileGroup
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
    | MailEditorHover Evergreen.V77.MailEditor.Hover
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
        { tile : Evergreen.V77.Tile.Tile
        , userId : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
        , position : Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit
        , colors : Evergreen.V77.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V77.Id.Id Evergreen.V77.Id.TrainId
        , train : Evergreen.V77.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V77.Id.Id Evergreen.V77.Id.AnimalId
        , cow : Evergreen.V77.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V77.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V77.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V77.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V77.Point2d.Point2d Evergreen.V77.Units.WorldUnit Evergreen.V77.Units.WorldUnit
        , current : Evergreen.V77.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit
    , tile : Evergreen.V77.Tile.Tile
    , colors : Evergreen.V77.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V77.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V77.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V77.Units.WorldUnit
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
    | SettingsMenu Evergreen.V77.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
    , position : Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit
    , linkCopied : Bool
    }


type alias UpdateMeshesData =
    { localModel : Evergreen.V77.LocalModel.LocalModel Evergreen.V77.Change.Change Evergreen.V77.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V77.Keyboard.Key
    , currentTool : Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V77.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mailEditor : Maybe Evergreen.V77.MailEditor.Model
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.TrainId Evergreen.V77.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V77.LocalModel.LocalModel Evergreen.V77.Change.Change Evergreen.V77.LocalGrid.LocalGrid
    , trains : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.TrainId Evergreen.V77.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V77.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V77.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V77.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V77.Point2d.Point2d Evergreen.V77.Units.WorldUnit Evergreen.V77.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V77.Keyboard.Key
    , windowSize : Evergreen.V77.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V77.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V77.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V77.Id.Id Evergreen.V77.Id.EventId, Evergreen.V77.Change.LocalChange )
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
            , tile : Evergreen.V77.Tile.Tile
            , position : Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V77.Sound.Sound (Result Evergreen.V77.Audio.LoadError Evergreen.V77.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V77.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V77.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V77.Tile.TileGroup
    , ui : Evergreen.V77.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V77.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V77.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V77.Id.Id Evergreen.V77.Id.EventId
    , pingData : Maybe Evergreen.V77.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V77.Tile.TileGroup Evergreen.V77.Color.Colors
    , primaryColorTextInput : Evergreen.V77.TextInput.Model
    , secondaryColorTextInput : Evergreen.V77.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V77.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V77.IdDict.IdDict
            Evergreen.V77.Id.UserId
            { position : Evergreen.V77.Point2d.Point2d Evergreen.V77.Units.WorldUnit Evergreen.V77.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.UserId Evergreen.V77.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V77.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V77.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V77.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V77.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showMap : Bool
    , showInviteTree : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V77.Shaders.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V77.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V77.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V77.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V77.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.UserId (List Evergreen.V77.MailEditor.Content)
    , cursor : Maybe Evergreen.V77.Cursor.Cursor
    , handColor : Evergreen.V77.Color.Colors
    , emailAddress : Evergreen.V77.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.UserId ()
    , name : Evergreen.V77.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V77.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V77.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V77.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V77.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V77.Bounds.Bounds Evergreen.V77.Units.CellUnit)
            , userId : Maybe (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId)
            }
    , users : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.TrainId Evergreen.V77.Train.Train
    , cows : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.AnimalId Evergreen.V77.Animal.Animal
    , lastWorldUpdateTrains : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.TrainId Evergreen.V77.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.MailId Evergreen.V77.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V77.Id.SecretId Evergreen.V77.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V77.Id.Id Evergreen.V77.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V77.Id.SecretId Evergreen.V77.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.UserId (List.Nonempty.Nonempty Evergreen.V77.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V77.Change.AreTrainsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V77.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V77.Bounds.Bounds Evergreen.V77.Units.CellUnit) (Maybe Evergreen.V77.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V77.Id.Id Evergreen.V77.Id.EventId, Evergreen.V77.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V77.Bounds.Bounds Evergreen.V77.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V77.Untrusted.Untrusted Evergreen.V77.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V77.Untrusted.Untrusted Evergreen.V77.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V77.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V77.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V77.Id.SecretId Evergreen.V77.Route.InviteToken) (Result Effect.Http.Error Evergreen.V77.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V77.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V77.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V77.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V77.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V77.Grid.GridData
    , userStatus : Evergreen.V77.Change.UserStatus
    , viewBounds : Evergreen.V77.Bounds.Bounds Evergreen.V77.Units.CellUnit
    , trains : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.TrainId Evergreen.V77.Train.Train
    , mail : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.MailId Evergreen.V77.MailEditor.FrontendMail
    , cows : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.AnimalId Evergreen.V77.Animal.Animal
    , cursors : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.UserId Evergreen.V77.Cursor.Cursor
    , users : Evergreen.V77.IdDict.IdDict Evergreen.V77.Id.UserId Evergreen.V77.User.FrontendUser
    , inviteTree : Evergreen.V77.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V77.Change.AreTrainsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V77.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V77.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V77.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V77.Coord.Coord Evergreen.V77.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
