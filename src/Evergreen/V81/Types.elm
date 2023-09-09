module Evergreen.V81.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V81.Animal
import Evergreen.V81.Audio
import Evergreen.V81.Bounds
import Evergreen.V81.Change
import Evergreen.V81.Color
import Evergreen.V81.Coord
import Evergreen.V81.Cursor
import Evergreen.V81.DisplayName
import Evergreen.V81.EmailAddress
import Evergreen.V81.Grid
import Evergreen.V81.Id
import Evergreen.V81.IdDict
import Evergreen.V81.Keyboard
import Evergreen.V81.LocalGrid
import Evergreen.V81.LocalModel
import Evergreen.V81.MailEditor
import Evergreen.V81.PingData
import Evergreen.V81.Point2d
import Evergreen.V81.Postmark
import Evergreen.V81.Route
import Evergreen.V81.Shaders
import Evergreen.V81.Sound
import Evergreen.V81.TextInput
import Evergreen.V81.Tile
import Evergreen.V81.Train
import Evergreen.V81.Ui
import Evergreen.V81.Units
import Evergreen.V81.Untrusted
import Evergreen.V81.User
import Html.Events.Extra.Mouse
import Html.Events.Extra.Wheel
import Lamdera
import List.Nonempty
import Pixels
import Quantity
import Time
import Url
import WebGL


type CssPixels
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
    | KeyMsg Evergreen.V81.Keyboard.Msg
    | KeyDown Evergreen.V81.Keyboard.RawKey
    | WindowResized (Evergreen.V81.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V81.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V81.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V81.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V81.Sound.Sound (Result Evergreen.V81.Audio.LoadError Evergreen.V81.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V81.LocalModel.LocalModel Evergreen.V81.Change.Change Evergreen.V81.LocalGrid.LocalGrid
    , trains : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.TrainId Evergreen.V81.Train.Train
    , mail : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.MailId Evergreen.V81.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V81.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V81.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V81.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V81.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V81.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V81.Sound.Sound (Result Evergreen.V81.Audio.LoadError Evergreen.V81.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V81.Point2d.Point2d Evergreen.V81.Units.WorldUnit Evergreen.V81.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V81.Id.Id Evergreen.V81.Id.TrainId
        , startViewPoint : Evergreen.V81.Point2d.Point2d Evergreen.V81.Units.WorldUnit Evergreen.V81.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V81.Tile.TileGroup
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
    | MailEditorHover Evergreen.V81.MailEditor.Hover
    | YouGotMailButton
    | ShowMapButton
    | AllowEmailNotificationsCheckbox
    | ResetConnectionsButton
    | UsersOnlineButton
    | CopyPositionUrlButton
    | ReportUserButton
    | ToggleIsGridReadOnlyButton
    | ToggleTrainsDisabledButton
    | ZoomInButton
    | ZoomOutButton
    | RotateLeftButton
    | RotateRightButton


type Hover
    = TileHover
        { tile : Evergreen.V81.Tile.Tile
        , userId : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
        , position : Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit
        , colors : Evergreen.V81.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V81.Id.Id Evergreen.V81.Id.TrainId
        , train : Evergreen.V81.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V81.Id.Id Evergreen.V81.Id.AnimalId
        , cow : Evergreen.V81.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V81.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V81.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V81.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V81.Point2d.Point2d Evergreen.V81.Units.WorldUnit Evergreen.V81.Units.WorldUnit
        , current : Evergreen.V81.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit
    , tile : Evergreen.V81.Tile.Tile
    , colors : Evergreen.V81.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V81.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V81.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V81.Units.WorldUnit
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
    | SettingsMenu Evergreen.V81.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V81.Id.Id Evergreen.V81.Id.UserId)
    , position : Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit
    , linkCopied : Bool
    }


type alias UpdateMeshesData =
    { localModel : Evergreen.V81.LocalModel.LocalModel Evergreen.V81.Change.Change Evergreen.V81.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V81.Keyboard.Key
    , currentTool : Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V81.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mailEditor : Maybe Evergreen.V81.MailEditor.Model
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.TrainId Evergreen.V81.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V81.LocalModel.LocalModel Evergreen.V81.Change.Change Evergreen.V81.LocalGrid.LocalGrid
    , trains : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.TrainId Evergreen.V81.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V81.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V81.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V81.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V81.Point2d.Point2d Evergreen.V81.Units.WorldUnit Evergreen.V81.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V81.Keyboard.Key
    , windowSize : Evergreen.V81.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V81.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V81.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V81.Id.Id Evergreen.V81.Id.EventId, Evergreen.V81.Change.LocalChange )
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
            , tile : Evergreen.V81.Tile.Tile
            , position : Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V81.Sound.Sound (Result Evergreen.V81.Audio.LoadError Evergreen.V81.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V81.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V81.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V81.Tile.TileGroup
    , ui : Evergreen.V81.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V81.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V81.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V81.Id.Id Evergreen.V81.Id.EventId
    , pingData : Maybe Evergreen.V81.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V81.Tile.TileGroup Evergreen.V81.Color.Colors
    , primaryColorTextInput : Evergreen.V81.TextInput.Model
    , secondaryColorTextInput : Evergreen.V81.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V81.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V81.IdDict.IdDict
            Evergreen.V81.Id.UserId
            { position : Evergreen.V81.Point2d.Point2d Evergreen.V81.Units.WorldUnit Evergreen.V81.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.UserId Evergreen.V81.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V81.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V81.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V81.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V81.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showMap : Bool
    , showInviteTree : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V81.Shaders.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V81.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V81.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V81.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V81.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.UserId (List Evergreen.V81.MailEditor.Content)
    , cursor : Maybe Evergreen.V81.Cursor.Cursor
    , handColor : Evergreen.V81.Color.Colors
    , emailAddress : Evergreen.V81.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.UserId ()
    , name : Evergreen.V81.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V81.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V81.Id.Id Evergreen.V81.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V81.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V81.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V81.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V81.Bounds.Bounds Evergreen.V81.Units.CellUnit)
            , userId : Maybe (Evergreen.V81.Id.Id Evergreen.V81.Id.UserId)
            }
    , users : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.TrainId Evergreen.V81.Train.Train
    , cows : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.AnimalId Evergreen.V81.Animal.Animal
    , lastWorldUpdateTrains : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.TrainId Evergreen.V81.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.MailId Evergreen.V81.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V81.Id.SecretId Evergreen.V81.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V81.Id.Id Evergreen.V81.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V81.Id.SecretId Evergreen.V81.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.UserId (List.Nonempty.Nonempty Evergreen.V81.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V81.Change.AreTrainsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V81.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V81.Bounds.Bounds Evergreen.V81.Units.CellUnit) (Maybe Evergreen.V81.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V81.Id.Id Evergreen.V81.Id.EventId, Evergreen.V81.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V81.Bounds.Bounds Evergreen.V81.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V81.Untrusted.Untrusted Evergreen.V81.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V81.Untrusted.Untrusted Evergreen.V81.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V81.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V81.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V81.Id.SecretId Evergreen.V81.Route.InviteToken) (Result Effect.Http.Error Evergreen.V81.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V81.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V81.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V81.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V81.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V81.Grid.GridData
    , userStatus : Evergreen.V81.Change.UserStatus
    , viewBounds : Evergreen.V81.Bounds.Bounds Evergreen.V81.Units.CellUnit
    , trains : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.TrainId Evergreen.V81.Train.Train
    , mail : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.MailId Evergreen.V81.MailEditor.FrontendMail
    , cows : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.AnimalId Evergreen.V81.Animal.Animal
    , cursors : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.UserId Evergreen.V81.Cursor.Cursor
    , users : Evergreen.V81.IdDict.IdDict Evergreen.V81.Id.UserId Evergreen.V81.User.FrontendUser
    , inviteTree : Evergreen.V81.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V81.Change.AreTrainsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V81.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V81.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V81.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V81.Coord.Coord Evergreen.V81.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
