module Evergreen.V76.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V76.Animal
import Evergreen.V76.Audio
import Evergreen.V76.Bounds
import Evergreen.V76.Change
import Evergreen.V76.Color
import Evergreen.V76.Coord
import Evergreen.V76.Cursor
import Evergreen.V76.DisplayName
import Evergreen.V76.EmailAddress
import Evergreen.V76.Grid
import Evergreen.V76.Id
import Evergreen.V76.IdDict
import Evergreen.V76.Keyboard
import Evergreen.V76.LocalGrid
import Evergreen.V76.LocalModel
import Evergreen.V76.MailEditor
import Evergreen.V76.PingData
import Evergreen.V76.Point2d
import Evergreen.V76.Postmark
import Evergreen.V76.Route
import Evergreen.V76.Shaders
import Evergreen.V76.Sound
import Evergreen.V76.TextInput
import Evergreen.V76.Tile
import Evergreen.V76.Train
import Evergreen.V76.Ui
import Evergreen.V76.Units
import Evergreen.V76.Untrusted
import Evergreen.V76.User
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
    | KeyMsg Evergreen.V76.Keyboard.Msg
    | KeyDown Evergreen.V76.Keyboard.RawKey
    | WindowResized (Evergreen.V76.Coord.Coord CssPixel)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V76.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V76.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V76.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V76.Sound.Sound (Result Evergreen.V76.Audio.LoadError Evergreen.V76.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V76.LocalModel.LocalModel Evergreen.V76.Change.Change Evergreen.V76.LocalGrid.LocalGrid
    , trains : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.TrainId Evergreen.V76.Train.Train
    , mail : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.MailId Evergreen.V76.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V76.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V76.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V76.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V76.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V76.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V76.Sound.Sound (Result Evergreen.V76.Audio.LoadError Evergreen.V76.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V76.Point2d.Point2d Evergreen.V76.Units.WorldUnit Evergreen.V76.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V76.Id.Id Evergreen.V76.Id.TrainId
        , startViewPoint : Evergreen.V76.Point2d.Point2d Evergreen.V76.Units.WorldUnit Evergreen.V76.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V76.Tile.TileGroup
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
    | MailEditorHover Evergreen.V76.MailEditor.Hover
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
        { tile : Evergreen.V76.Tile.Tile
        , userId : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
        , position : Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit
        , colors : Evergreen.V76.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V76.Id.Id Evergreen.V76.Id.TrainId
        , train : Evergreen.V76.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V76.Id.Id Evergreen.V76.Id.AnimalId
        , cow : Evergreen.V76.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V76.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V76.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V76.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V76.Point2d.Point2d Evergreen.V76.Units.WorldUnit Evergreen.V76.Units.WorldUnit
        , current : Evergreen.V76.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit
    , tile : Evergreen.V76.Tile.Tile
    , colors : Evergreen.V76.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V76.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V76.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V76.Units.WorldUnit
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
    | SettingsMenu Evergreen.V76.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { userId : Maybe (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
    , position : Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit
    , linkCopied : Bool
    }


type alias UpdateMeshesData =
    { localModel : Evergreen.V76.LocalModel.LocalModel Evergreen.V76.Change.Change Evergreen.V76.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V76.Keyboard.Key
    , currentTool : Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V76.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mailEditor : Maybe Evergreen.V76.MailEditor.Model
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.TrainId Evergreen.V76.Train.Train
    , time : Effect.Time.Posix
    }


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V76.LocalModel.LocalModel Evergreen.V76.Change.Change Evergreen.V76.LocalGrid.LocalGrid
    , trains : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.TrainId Evergreen.V76.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V76.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V76.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V76.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V76.Point2d.Point2d Evergreen.V76.Units.WorldUnit Evergreen.V76.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V76.Keyboard.Key
    , windowSize : Evergreen.V76.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V76.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V76.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V76.Id.Id Evergreen.V76.Id.EventId, Evergreen.V76.Change.LocalChange )
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
            , tile : Evergreen.V76.Tile.Tile
            , position : Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V76.Sound.Sound (Result Evergreen.V76.Audio.LoadError Evergreen.V76.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V76.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V76.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V76.Tile.TileGroup
    , ui : Evergreen.V76.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V76.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V76.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V76.Id.Id Evergreen.V76.Id.EventId
    , pingData : Maybe Evergreen.V76.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V76.Tile.TileGroup Evergreen.V76.Color.Colors
    , primaryColorTextInput : Evergreen.V76.TextInput.Model
    , secondaryColorTextInput : Evergreen.V76.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V76.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V76.IdDict.IdDict
            Evergreen.V76.Id.UserId
            { position : Evergreen.V76.Point2d.Point2d Evergreen.V76.Units.WorldUnit Evergreen.V76.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.UserId Evergreen.V76.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V76.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V76.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V76.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V76.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showMap : Bool
    , showInviteTree : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V76.Shaders.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V76.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V76.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V76.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V76.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.UserId (List Evergreen.V76.MailEditor.Content)
    , cursor : Maybe Evergreen.V76.Cursor.Cursor
    , handColor : Evergreen.V76.Color.Colors
    , emailAddress : Evergreen.V76.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.UserId ()
    , name : Evergreen.V76.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V76.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V76.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V76.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V76.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V76.Bounds.Bounds Evergreen.V76.Units.CellUnit)
            , userId : Maybe (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)
            }
    , users : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.TrainId Evergreen.V76.Train.Train
    , cows : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.AnimalId Evergreen.V76.Animal.Animal
    , lastWorldUpdateTrains : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.TrainId Evergreen.V76.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.MailId Evergreen.V76.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V76.Id.SecretId Evergreen.V76.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V76.Id.SecretId Evergreen.V76.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.UserId (List.Nonempty.Nonempty Evergreen.V76.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V76.Change.AreTrainsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    }


type alias FrontendMsg =
    Evergreen.V76.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V76.Bounds.Bounds Evergreen.V76.Units.CellUnit) (Maybe Evergreen.V76.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V76.Id.Id Evergreen.V76.Id.EventId, Evergreen.V76.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V76.Bounds.Bounds Evergreen.V76.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V76.Untrusted.Untrusted Evergreen.V76.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V76.Untrusted.Untrusted Evergreen.V76.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V76.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V76.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V76.Id.SecretId Evergreen.V76.Route.InviteToken) (Result Effect.Http.Error Evergreen.V76.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V76.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V76.Postmark.PostmarkSendResponse)
    | RegenerateCache Effect.Time.Posix
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V76.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V76.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V76.Grid.GridData
    , userStatus : Evergreen.V76.Change.UserStatus
    , viewBounds : Evergreen.V76.Bounds.Bounds Evergreen.V76.Units.CellUnit
    , trains : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.TrainId Evergreen.V76.Train.Train
    , mail : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.MailId Evergreen.V76.MailEditor.FrontendMail
    , cows : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.AnimalId Evergreen.V76.Animal.Animal
    , cursors : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.UserId Evergreen.V76.Cursor.Cursor
    , users : Evergreen.V76.IdDict.IdDict Evergreen.V76.Id.UserId Evergreen.V76.User.FrontendUser
    , inviteTree : Evergreen.V76.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V76.Change.AreTrainsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V76.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V76.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V76.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V76.Coord.Coord Evergreen.V76.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
