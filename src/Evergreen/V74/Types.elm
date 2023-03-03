module Evergreen.V74.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V74.Animal
import Evergreen.V74.Audio
import Evergreen.V74.Bounds
import Evergreen.V74.Change
import Evergreen.V74.Color
import Evergreen.V74.Coord
import Evergreen.V74.Cursor
import Evergreen.V74.DisplayName
import Evergreen.V74.EmailAddress
import Evergreen.V74.Grid
import Evergreen.V74.Id
import Evergreen.V74.IdDict
import Evergreen.V74.Keyboard
import Evergreen.V74.LocalGrid
import Evergreen.V74.LocalModel
import Evergreen.V74.MailEditor
import Evergreen.V74.PingData
import Evergreen.V74.Point2d
import Evergreen.V74.Postmark
import Evergreen.V74.Route
import Evergreen.V74.Shaders
import Evergreen.V74.Sound
import Evergreen.V74.TextInput
import Evergreen.V74.Tile
import Evergreen.V74.Train
import Evergreen.V74.Ui
import Evergreen.V74.Units
import Evergreen.V74.Untrusted
import Evergreen.V74.User
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
    | KeyMsg Evergreen.V74.Keyboard.Msg
    | KeyDown Evergreen.V74.Keyboard.RawKey
    | WindowResized (Evergreen.V74.Coord.Coord CssPixel)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V74.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V74.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V74.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V74.Sound.Sound (Result Evergreen.V74.Audio.LoadError Evergreen.V74.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V74.LocalModel.LocalModel Evergreen.V74.Change.Change Evergreen.V74.LocalGrid.LocalGrid
    , trains : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.TrainId Evergreen.V74.Train.Train
    , mail : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.MailId Evergreen.V74.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V74.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V74.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V74.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V74.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V74.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V74.Sound.Sound (Result Evergreen.V74.Audio.LoadError Evergreen.V74.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V74.Point2d.Point2d Evergreen.V74.Units.WorldUnit Evergreen.V74.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V74.Id.Id Evergreen.V74.Id.TrainId
        , startViewPoint : Evergreen.V74.Point2d.Point2d Evergreen.V74.Units.WorldUnit Evergreen.V74.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V74.Tile.TileGroup
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
    | MailEditorHover Evergreen.V74.MailEditor.Hover
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
        { tile : Evergreen.V74.Tile.Tile
        , userId : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
        , position : Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit
        , colors : Evergreen.V74.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V74.Id.Id Evergreen.V74.Id.TrainId
        , train : Evergreen.V74.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V74.Id.Id Evergreen.V74.Id.AnimalId
        , cow : Evergreen.V74.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V74.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V74.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V74.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V74.Point2d.Point2d Evergreen.V74.Units.WorldUnit Evergreen.V74.Units.WorldUnit
        , current : Evergreen.V74.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit
    , tile : Evergreen.V74.Tile.Tile
    , colors : Evergreen.V74.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V74.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V74.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V74.Units.WorldUnit
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
    | SettingsMenu Evergreen.V74.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId)
    , position : Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit
    , linkCopied : Bool
    }


type alias UpdateMeshesData =
    { localModel : Evergreen.V74.LocalModel.LocalModel Evergreen.V74.Change.Change Evergreen.V74.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V74.Keyboard.Key
    , currentTool : Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V74.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mailEditor : Maybe Evergreen.V74.MailEditor.Model
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.TrainId Evergreen.V74.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V74.LocalModel.LocalModel Evergreen.V74.Change.Change Evergreen.V74.LocalGrid.LocalGrid
    , trains : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.TrainId Evergreen.V74.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V74.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V74.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V74.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V74.Point2d.Point2d Evergreen.V74.Units.WorldUnit Evergreen.V74.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V74.Keyboard.Key
    , windowSize : Evergreen.V74.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V74.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V74.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V74.Id.Id Evergreen.V74.Id.EventId, Evergreen.V74.Change.LocalChange )
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
            , tile : Evergreen.V74.Tile.Tile
            , position : Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V74.Sound.Sound (Result Evergreen.V74.Audio.LoadError Evergreen.V74.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V74.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V74.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V74.Tile.TileGroup
    , ui : Evergreen.V74.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V74.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V74.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V74.Id.Id Evergreen.V74.Id.EventId
    , pingData : Maybe Evergreen.V74.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V74.Tile.TileGroup Evergreen.V74.Color.Colors
    , primaryColorTextInput : Evergreen.V74.TextInput.Model
    , secondaryColorTextInput : Evergreen.V74.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V74.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V74.IdDict.IdDict
            Evergreen.V74.Id.UserId
            { position : Evergreen.V74.Point2d.Point2d Evergreen.V74.Units.WorldUnit Evergreen.V74.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.UserId Evergreen.V74.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V74.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V74.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V74.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V74.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showMap : Bool
    , showInviteTree : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V74.Shaders.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V74.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V74.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V74.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V74.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.UserId (List Evergreen.V74.MailEditor.Content)
    , cursor : Maybe Evergreen.V74.Cursor.Cursor
    , handColor : Evergreen.V74.Color.Colors
    , emailAddress : Evergreen.V74.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.UserId ()
    , name : Evergreen.V74.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V74.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V74.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V74.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V74.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V74.Bounds.Bounds Evergreen.V74.Units.CellUnit)
            , userId : Maybe (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId)
            }
    , users : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.TrainId Evergreen.V74.Train.Train
    , cows : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.AnimalId Evergreen.V74.Animal.Animal
    , lastWorldUpdateTrains : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.TrainId Evergreen.V74.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.MailId Evergreen.V74.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V74.Id.SecretId Evergreen.V74.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V74.Id.SecretId Evergreen.V74.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.UserId (List.Nonempty.Nonempty Evergreen.V74.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V74.Change.AreTrainsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V74.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V74.Bounds.Bounds Evergreen.V74.Units.CellUnit) (Maybe Evergreen.V74.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V74.Id.Id Evergreen.V74.Id.EventId, Evergreen.V74.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V74.Bounds.Bounds Evergreen.V74.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V74.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V74.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V74.Id.SecretId Evergreen.V74.Route.InviteToken) (Result Effect.Http.Error Evergreen.V74.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V74.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V74.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V74.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V74.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V74.Grid.GridData
    , userStatus : Evergreen.V74.Change.UserStatus
    , viewBounds : Evergreen.V74.Bounds.Bounds Evergreen.V74.Units.CellUnit
    , trains : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.TrainId Evergreen.V74.Train.Train
    , mail : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.MailId Evergreen.V74.MailEditor.FrontendMail
    , cows : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.AnimalId Evergreen.V74.Animal.Animal
    , cursors : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.UserId Evergreen.V74.Cursor.Cursor
    , users : Evergreen.V74.IdDict.IdDict Evergreen.V74.Id.UserId Evergreen.V74.User.FrontendUser
    , inviteTree : Evergreen.V74.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V74.Change.AreTrainsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V74.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V74.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V74.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V74.Coord.Coord Evergreen.V74.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
