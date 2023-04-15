module Evergreen.V75.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V75.Animal
import Evergreen.V75.Audio
import Evergreen.V75.Bounds
import Evergreen.V75.Change
import Evergreen.V75.Color
import Evergreen.V75.Coord
import Evergreen.V75.Cursor
import Evergreen.V75.DisplayName
import Evergreen.V75.EmailAddress
import Evergreen.V75.Grid
import Evergreen.V75.Id
import Evergreen.V75.IdDict
import Evergreen.V75.Keyboard
import Evergreen.V75.LocalGrid
import Evergreen.V75.LocalModel
import Evergreen.V75.MailEditor
import Evergreen.V75.PingData
import Evergreen.V75.Point2d
import Evergreen.V75.Postmark
import Evergreen.V75.Route
import Evergreen.V75.Shaders
import Evergreen.V75.Sound
import Evergreen.V75.TextInput
import Evergreen.V75.Tile
import Evergreen.V75.Train
import Evergreen.V75.Ui
import Evergreen.V75.Units
import Evergreen.V75.Untrusted
import Evergreen.V75.User
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
    | KeyMsg Evergreen.V75.Keyboard.Msg
    | KeyDown Evergreen.V75.Keyboard.RawKey
    | WindowResized (Evergreen.V75.Coord.Coord CssPixel)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V75.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V75.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V75.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V75.Sound.Sound (Result Evergreen.V75.Audio.LoadError Evergreen.V75.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V75.LocalModel.LocalModel Evergreen.V75.Change.Change Evergreen.V75.LocalGrid.LocalGrid
    , trains : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.TrainId Evergreen.V75.Train.Train
    , mail : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.MailId Evergreen.V75.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V75.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V75.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V75.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V75.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V75.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V75.Sound.Sound (Result Evergreen.V75.Audio.LoadError Evergreen.V75.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V75.Point2d.Point2d Evergreen.V75.Units.WorldUnit Evergreen.V75.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V75.Id.Id Evergreen.V75.Id.TrainId
        , startViewPoint : Evergreen.V75.Point2d.Point2d Evergreen.V75.Units.WorldUnit Evergreen.V75.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V75.Tile.TileGroup
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
    | MailEditorHover Evergreen.V75.MailEditor.Hover
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
        { tile : Evergreen.V75.Tile.Tile
        , userId : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
        , position : Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit
        , colors : Evergreen.V75.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V75.Id.Id Evergreen.V75.Id.TrainId
        , train : Evergreen.V75.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V75.Id.Id Evergreen.V75.Id.AnimalId
        , cow : Evergreen.V75.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V75.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V75.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V75.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V75.Point2d.Point2d Evergreen.V75.Units.WorldUnit Evergreen.V75.Units.WorldUnit
        , current : Evergreen.V75.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit
    , tile : Evergreen.V75.Tile.Tile
    , colors : Evergreen.V75.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V75.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V75.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V75.Units.WorldUnit
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
    | SettingsMenu Evergreen.V75.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V75.Id.Id Evergreen.V75.Id.UserId)
    , position : Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit
    , linkCopied : Bool
    }


type alias UpdateMeshesData =
    { localModel : Evergreen.V75.LocalModel.LocalModel Evergreen.V75.Change.Change Evergreen.V75.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V75.Keyboard.Key
    , currentTool : Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V75.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mailEditor : Maybe Evergreen.V75.MailEditor.Model
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.TrainId Evergreen.V75.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V75.LocalModel.LocalModel Evergreen.V75.Change.Change Evergreen.V75.LocalGrid.LocalGrid
    , trains : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.TrainId Evergreen.V75.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V75.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V75.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V75.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V75.Point2d.Point2d Evergreen.V75.Units.WorldUnit Evergreen.V75.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V75.Keyboard.Key
    , windowSize : Evergreen.V75.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V75.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V75.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V75.Id.Id Evergreen.V75.Id.EventId, Evergreen.V75.Change.LocalChange )
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
            , tile : Evergreen.V75.Tile.Tile
            , position : Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V75.Sound.Sound (Result Evergreen.V75.Audio.LoadError Evergreen.V75.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V75.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V75.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V75.Tile.TileGroup
    , ui : Evergreen.V75.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V75.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V75.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V75.Id.Id Evergreen.V75.Id.EventId
    , pingData : Maybe Evergreen.V75.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V75.Tile.TileGroup Evergreen.V75.Color.Colors
    , primaryColorTextInput : Evergreen.V75.TextInput.Model
    , secondaryColorTextInput : Evergreen.V75.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V75.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V75.IdDict.IdDict
            Evergreen.V75.Id.UserId
            { position : Evergreen.V75.Point2d.Point2d Evergreen.V75.Units.WorldUnit Evergreen.V75.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.UserId Evergreen.V75.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V75.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V75.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V75.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V75.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showMap : Bool
    , showInviteTree : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V75.Shaders.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V75.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V75.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V75.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V75.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.UserId (List Evergreen.V75.MailEditor.Content)
    , cursor : Maybe Evergreen.V75.Cursor.Cursor
    , handColor : Evergreen.V75.Color.Colors
    , emailAddress : Evergreen.V75.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.UserId ()
    , name : Evergreen.V75.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V75.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V75.Id.Id Evergreen.V75.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V75.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V75.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V75.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V75.Bounds.Bounds Evergreen.V75.Units.CellUnit)
            , userId : Maybe (Evergreen.V75.Id.Id Evergreen.V75.Id.UserId)
            }
    , users : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.TrainId Evergreen.V75.Train.Train
    , cows : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.AnimalId Evergreen.V75.Animal.Animal
    , lastWorldUpdateTrains : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.TrainId Evergreen.V75.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.MailId Evergreen.V75.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V75.Id.SecretId Evergreen.V75.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V75.Id.Id Evergreen.V75.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V75.Id.SecretId Evergreen.V75.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.UserId (List.Nonempty.Nonempty Evergreen.V75.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V75.Change.AreTrainsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V75.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V75.Bounds.Bounds Evergreen.V75.Units.CellUnit) (Maybe Evergreen.V75.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V75.Id.Id Evergreen.V75.Id.EventId, Evergreen.V75.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V75.Bounds.Bounds Evergreen.V75.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V75.Untrusted.Untrusted Evergreen.V75.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V75.Untrusted.Untrusted Evergreen.V75.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V75.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V75.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V75.Id.SecretId Evergreen.V75.Route.InviteToken) (Result Effect.Http.Error Evergreen.V75.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V75.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V75.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V75.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V75.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V75.Grid.GridData
    , userStatus : Evergreen.V75.Change.UserStatus
    , viewBounds : Evergreen.V75.Bounds.Bounds Evergreen.V75.Units.CellUnit
    , trains : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.TrainId Evergreen.V75.Train.Train
    , mail : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.MailId Evergreen.V75.MailEditor.FrontendMail
    , cows : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.AnimalId Evergreen.V75.Animal.Animal
    , cursors : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.UserId Evergreen.V75.Cursor.Cursor
    , users : Evergreen.V75.IdDict.IdDict Evergreen.V75.Id.UserId Evergreen.V75.User.FrontendUser
    , inviteTree : Evergreen.V75.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V75.Change.AreTrainsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V75.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V75.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V75.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V75.Coord.Coord Evergreen.V75.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
