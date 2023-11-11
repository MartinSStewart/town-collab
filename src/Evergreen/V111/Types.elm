module Evergreen.V111.Types exposing (..)

import Array
import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V111.AdminPage
import Evergreen.V111.Animal
import Evergreen.V111.Audio
import Evergreen.V111.Bounds
import Evergreen.V111.Change
import Evergreen.V111.Color
import Evergreen.V111.Coord
import Evergreen.V111.Cursor
import Evergreen.V111.DisplayName
import Evergreen.V111.EmailAddress
import Evergreen.V111.Grid
import Evergreen.V111.GridCell
import Evergreen.V111.Id
import Evergreen.V111.IdDict
import Evergreen.V111.Keyboard
import Evergreen.V111.LocalGrid
import Evergreen.V111.LocalModel
import Evergreen.V111.MailEditor
import Evergreen.V111.PersonName
import Evergreen.V111.PingData
import Evergreen.V111.Point2d
import Evergreen.V111.Postmark
import Evergreen.V111.Route
import Evergreen.V111.Shaders
import Evergreen.V111.Sound
import Evergreen.V111.Sprite
import Evergreen.V111.TextInput
import Evergreen.V111.Tile
import Evergreen.V111.TileCountBot
import Evergreen.V111.TimeOfDay
import Evergreen.V111.Tool
import Evergreen.V111.Train
import Evergreen.V111.Ui
import Evergreen.V111.Units
import Evergreen.V111.Untrusted
import Evergreen.V111.User
import Html.Events.Extra.Mouse
import Html.Events.Extra.Wheel
import Lamdera
import List.Nonempty
import Pixels
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
    | LightsTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | DepthTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | SimplexLookupTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainLightsTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainDepthTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | KeyMsg Evergreen.V111.Keyboard.Msg
    | KeyDown Evergreen.V111.Keyboard.RawKey
    | WindowResized (Evergreen.V111.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V111.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V111.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V111.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V111.Sound.Sound (Result Evergreen.V111.Audio.LoadError Evergreen.V111.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V111.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V111.LocalModel.LocalModel Evergreen.V111.Change.Change Evergreen.V111.LocalGrid.LocalGrid
    , trains : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.TrainId Evergreen.V111.Train.Train
    , mail : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.MailId Evergreen.V111.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V111.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V111.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V111.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V111.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
    , route : Evergreen.V111.Route.PageRoute
    , mousePosition : Evergreen.V111.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V111.Sound.Sound (Result Evergreen.V111.Audio.LoadError Evergreen.V111.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , lightsTexture : Maybe Effect.WebGL.Texture.Texture
    , depthTexture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V111.Id.Id Evergreen.V111.Id.TrainId
        , startViewPoint : Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V111.Tile.TileGroup
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
    | MailEditorHover Evergreen.V111.MailEditor.Hover
    | YouGotMailButton
    | ShowMapButton
    | AllowEmailNotificationsCheckbox
    | UsersOnlineButton
    | CopyPositionUrlButton
    | ZoomInButton
    | ZoomOutButton
    | RotateLeftButton
    | RotateRightButton
    | AutomaticTimeOfDayButton
    | AlwaysDayTimeOfDayButton
    | AlwaysNightTimeOfDayButton
    | ShowAdminPage
    | AdminHover Evergreen.V111.AdminPage.Hover
    | CategoryButton Evergreen.V111.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton
    | OneTimePasswordInput


type Hover
    = TileHover
        { tile : Evergreen.V111.Tile.Tile
        , userId : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
        , position : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
        , colors : Evergreen.V111.Color.Colors
        , time : Effect.Time.Posix
        }
    | TrainHover
        { trainId : Evergreen.V111.Id.Id Evergreen.V111.Id.TrainId
        , train : Evergreen.V111.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V111.Id.Id Evergreen.V111.Id.AnimalId
        , animal : Evergreen.V111.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V111.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V111.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V111.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit
        , current : Evergreen.V111.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
    , tile : Evergreen.V111.Tile.Tile
    , colors : Evergreen.V111.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V111.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { change :
        Maybe
            { userId : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
            , tile : Evergreen.V111.Tile.Tile
            , position : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
            , colors : Evergreen.V111.Color.Colors
            , time : Effect.Time.Posix
            }
    , position : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V111.MailEditor.Model
    | AdminPage Evergreen.V111.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V111.LocalModel.LocalModel Evergreen.V111.Change.Change Evergreen.V111.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V111.Keyboard.Key
    , currentTool : Evergreen.V111.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V111.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.TrainId Evergreen.V111.Train.Train
    , time : Effect.Time.Posix
    }


type LoginError
    = OneTimePasswordExpiredOrTooManyAttempts
    | WrongOneTimePassword (Evergreen.V111.Id.SecretId Evergreen.V111.Id.OneTimePasswordId)


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V111.LocalModel.LocalModel Evergreen.V111.Change.Change Evergreen.V111.LocalGrid.LocalGrid
    , trains : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.TrainId Evergreen.V111.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V111.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V111.Sprite.Vertex
            , background : WebGL.Mesh Evergreen.V111.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V111.Keyboard.Key
    , windowSize : Evergreen.V111.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V111.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V111.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V111.Id.Id Evergreen.V111.Id.EventId, Evergreen.V111.Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Effect.Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V111.Tile.Tile
            , position : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V111.Sound.Sound (Result Evergreen.V111.Audio.LoadError Evergreen.V111.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V111.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V111.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V111.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V111.Sprite.Vertex
    , previousTileHover : Maybe Evergreen.V111.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V111.Id.Id Evergreen.V111.Id.EventId
    , pingData : Maybe Evergreen.V111.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V111.Tile.TileGroup Evergreen.V111.Color.Colors
    , primaryColorTextInput : Evergreen.V111.TextInput.Model
    , secondaryColorTextInput : Evergreen.V111.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V111.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V111.IdDict.IdDict
            Evergreen.V111.Id.UserId
            { position : Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.UserId Evergreen.V111.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginEmailInput : Evergreen.V111.TextInput.Model
    , oneTimePasswordInput : Evergreen.V111.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V111.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V111.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V111.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit )
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V111.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V111.Tile.Category
    , lastHotkeyChange : Maybe Time.Posix
    , loginError : Maybe LoginError
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V111.Audio.Model FrontendMsg_ FrontendModel_


type alias HumanUserData =
    { emailAddress : Evergreen.V111.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.UserId ()
    , timeOfDay : Evergreen.V111.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V111.Change.TileHotkey Evergreen.V111.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    , allowEmailNotifications : Bool
    }


type BackendUserType
    = HumanUser HumanUserData
    | BotUser


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V111.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V111.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V111.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.UserId (List Evergreen.V111.MailEditor.Content)
    , cursor : Maybe Evergreen.V111.Cursor.Cursor
    , handColor : Evergreen.V111.Color.Colors
    , userType : BackendUserType
    , name : Evergreen.V111.DisplayName.DisplayName
    }


type BackendError
    = PostmarkError Evergreen.V111.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V111.Id.Id Evergreen.V111.Id.UserId)


type alias Person =
    { name : Evergreen.V111.PersonName.PersonName
    , home : Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit
    , position : Evergreen.V111.Point2d.Point2d Evergreen.V111.Units.WorldUnit Evergreen.V111.Units.WorldUnit
    }


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V111.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V111.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V111.Grid.Grid Evergreen.V111.GridCell.BackendHistory
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V111.Bounds.Bounds Evergreen.V111.Units.CellUnit))
            , userId : Maybe (Evergreen.V111.Id.Id Evergreen.V111.Id.UserId)
            }
    , users : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.TrainId Evergreen.V111.Train.Train
    , animals : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.AnimalId Evergreen.V111.Animal.Animal
    , people : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.PersonId Person
    , lastWorldUpdateTrains : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.TrainId Evergreen.V111.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.MailId Evergreen.V111.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V111.Id.SecretId Evergreen.V111.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
            }
    , pendingOneTimePasswords :
        AssocList.Dict
            Effect.Lamdera.SessionId
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V111.Id.Id Evergreen.V111.Id.UserId
            , loginAttempts : Int
            , oneTimePassword : Evergreen.V111.Id.SecretId Evergreen.V111.Id.OneTimePasswordId
            }
    , invites : AssocList.Dict (Evergreen.V111.Id.SecretId Evergreen.V111.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.UserId (List.Nonempty.Nonempty Evergreen.V111.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V111.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    , tileCountBot : Maybe Evergreen.V111.TileCountBot.Model
    }


type alias FrontendMsg =
    Evergreen.V111.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V111.Bounds.Bounds Evergreen.V111.Units.CellUnit) (Maybe Evergreen.V111.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V111.Id.Id Evergreen.V111.Id.EventId, Evergreen.V111.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V111.Untrusted.Untrusted Evergreen.V111.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V111.Untrusted.Untrusted Evergreen.V111.EmailAddress.EmailAddress)
    | PostOfficePositionRequest
    | ResetTileBotRequest
    | LoginAttemptRequest (Evergreen.V111.Id.SecretId Evergreen.V111.Id.OneTimePasswordId)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.ClientId
    | SentLoginEmail Effect.Time.Posix Evergreen.V111.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V111.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V111.Id.SecretId Evergreen.V111.Route.InviteToken) (Result Effect.Http.Error Evergreen.V111.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V111.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V111.Postmark.PostmarkSendResponse)
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V111.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V111.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix
    | TileCountBotUpdate Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V111.Grid.GridData
    , userStatus : Evergreen.V111.Change.UserStatus
    , viewBounds : Evergreen.V111.Bounds.Bounds Evergreen.V111.Units.CellUnit
    , trains : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.TrainId Evergreen.V111.Train.Train
    , mail : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.MailId Evergreen.V111.MailEditor.FrontendMail
    , cows : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.AnimalId Evergreen.V111.Animal.Animal
    , cursors : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.UserId Evergreen.V111.Cursor.Cursor
    , users : Evergreen.V111.IdDict.IdDict Evergreen.V111.Id.UserId Evergreen.V111.User.FrontendUser
    , inviteTree : Evergreen.V111.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V111.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V111.Change.Change)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V111.EmailAddress.EmailAddress
    | SendInviteEmailResponse Evergreen.V111.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V111.Coord.Coord Evergreen.V111.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
    | LoginAttemptResponse LoginError
