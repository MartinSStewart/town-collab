module Evergreen.V113.Types exposing (..)

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
import Evergreen.V113.AdminPage
import Evergreen.V113.Animal
import Evergreen.V113.Audio
import Evergreen.V113.Bounds
import Evergreen.V113.Change
import Evergreen.V113.Color
import Evergreen.V113.Coord
import Evergreen.V113.Cursor
import Evergreen.V113.DisplayName
import Evergreen.V113.EmailAddress
import Evergreen.V113.Grid
import Evergreen.V113.GridCell
import Evergreen.V113.Id
import Evergreen.V113.IdDict
import Evergreen.V113.Keyboard
import Evergreen.V113.LocalGrid
import Evergreen.V113.LocalModel
import Evergreen.V113.MailEditor
import Evergreen.V113.PersonName
import Evergreen.V113.PingData
import Evergreen.V113.Point2d
import Evergreen.V113.Postmark
import Evergreen.V113.Route
import Evergreen.V113.Shaders
import Evergreen.V113.Sound
import Evergreen.V113.Sprite
import Evergreen.V113.TextInput
import Evergreen.V113.TextInputMultiline
import Evergreen.V113.Tile
import Evergreen.V113.TileCountBot
import Evergreen.V113.TimeOfDay
import Evergreen.V113.Tool
import Evergreen.V113.Train
import Evergreen.V113.Ui
import Evergreen.V113.Units
import Evergreen.V113.Untrusted
import Evergreen.V113.User
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
    | KeyMsg Evergreen.V113.Keyboard.Msg
    | KeyDown Evergreen.V113.Keyboard.RawKey
    | WindowResized (Evergreen.V113.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V113.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V113.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V113.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V113.Sound.Sound (Result Evergreen.V113.Audio.LoadError Evergreen.V113.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V113.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V113.LocalModel.LocalModel Evergreen.V113.Change.Change Evergreen.V113.LocalGrid.LocalGrid
    , trains : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.TrainId Evergreen.V113.Train.Train
    , mail : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.MailId Evergreen.V113.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V113.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V113.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V113.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V113.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
    , route : Evergreen.V113.Route.PageRoute
    , mousePosition : Evergreen.V113.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V113.Sound.Sound (Result Evergreen.V113.Audio.LoadError Evergreen.V113.Audio.Source)
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
    = NormalViewPoint (Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V113.Id.Id Evergreen.V113.Id.TrainId
        , startViewPoint : Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V113.Tile.TileGroup
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
    | MailEditorHover Evergreen.V113.MailEditor.Hover
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
    | AdminHover Evergreen.V113.AdminPage.Hover
    | CategoryButton Evergreen.V113.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton
    | OneTimePasswordInput
    | HyperlinkInput


type Hover
    = TileHover
        { tile : Evergreen.V113.Tile.Tile
        , userId : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
        , position : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
        , colors : Evergreen.V113.Color.Colors
        , time : Effect.Time.Posix
        }
    | TrainHover
        { trainId : Evergreen.V113.Id.Id Evergreen.V113.Id.TrainId
        , train : Evergreen.V113.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V113.Id.Id Evergreen.V113.Id.AnimalId
        , animal : Evergreen.V113.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V113.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V113.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V113.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit
        , current : Evergreen.V113.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
    , tile : Evergreen.V113.Tile.Tile
    , colors : Evergreen.V113.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V113.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { change :
        Maybe
            { userId : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
            , tile : Evergreen.V113.Tile.Tile
            , position : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
            , colors : Evergreen.V113.Color.Colors
            , time : Effect.Time.Posix
            }
    , position : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V113.MailEditor.Model
    | AdminPage Evergreen.V113.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V113.LocalModel.LocalModel Evergreen.V113.Change.Change Evergreen.V113.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V113.Keyboard.Key
    , currentTool : Evergreen.V113.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V113.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.TrainId Evergreen.V113.Train.Train
    , time : Effect.Time.Posix
    }


type LoginError
    = OneTimePasswordExpiredOrTooManyAttempts
    | WrongOneTimePassword (Evergreen.V113.Id.SecretId Evergreen.V113.Id.OneTimePasswordId)


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V113.LocalModel.LocalModel Evergreen.V113.Change.Change Evergreen.V113.LocalGrid.LocalGrid
    , trains : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.TrainId Evergreen.V113.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V113.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V113.Sprite.Vertex
            , background : WebGL.Mesh Evergreen.V113.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V113.Keyboard.Key
    , windowSize : Evergreen.V113.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V113.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V113.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V113.Id.Id Evergreen.V113.Id.EventId, Evergreen.V113.Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Effect.Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V113.Tile.Tile
            , position : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V113.Sound.Sound (Result Evergreen.V113.Audio.LoadError Evergreen.V113.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V113.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V113.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V113.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V113.Sprite.Vertex
    , previousTileHover : Maybe Evergreen.V113.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V113.Id.Id Evergreen.V113.Id.EventId
    , pingData : Maybe Evergreen.V113.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V113.Tile.TileGroup Evergreen.V113.Color.Colors
    , primaryColorTextInput : Evergreen.V113.TextInput.Model
    , secondaryColorTextInput : Evergreen.V113.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V113.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V113.IdDict.IdDict
            Evergreen.V113.Id.UserId
            { position : Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.UserId Evergreen.V113.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginEmailInput : Evergreen.V113.TextInput.Model
    , oneTimePasswordInput : Evergreen.V113.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V113.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V113.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V113.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit )
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V113.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V113.Tile.Category
    , lastHotkeyChange : Maybe Time.Posix
    , loginError : Maybe LoginError
    , hyperlinkInput : Evergreen.V113.TextInputMultiline.Model
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V113.Audio.Model FrontendMsg_ FrontendModel_


type alias HumanUserData =
    { emailAddress : Evergreen.V113.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.UserId ()
    , timeOfDay : Evergreen.V113.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V113.Change.TileHotkey Evergreen.V113.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    , allowEmailNotifications : Bool
    }


type BackendUserType
    = HumanUser HumanUserData
    | BotUser


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V113.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V113.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V113.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.UserId (List Evergreen.V113.MailEditor.Content)
    , cursor : Maybe Evergreen.V113.Cursor.Cursor
    , handColor : Evergreen.V113.Color.Colors
    , userType : BackendUserType
    , name : Evergreen.V113.DisplayName.DisplayName
    }


type BackendError
    = PostmarkError Evergreen.V113.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V113.Id.Id Evergreen.V113.Id.UserId)


type alias Person =
    { name : Evergreen.V113.PersonName.PersonName
    , home : Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit
    , position : Evergreen.V113.Point2d.Point2d Evergreen.V113.Units.WorldUnit Evergreen.V113.Units.WorldUnit
    }


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V113.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V113.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V113.Grid.Grid Evergreen.V113.GridCell.BackendHistory
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V113.Bounds.Bounds Evergreen.V113.Units.CellUnit))
            , userId : Maybe (Evergreen.V113.Id.Id Evergreen.V113.Id.UserId)
            }
    , users : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.TrainId Evergreen.V113.Train.Train
    , animals : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.AnimalId Evergreen.V113.Animal.Animal
    , people : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.PersonId Person
    , lastWorldUpdateTrains : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.TrainId Evergreen.V113.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.MailId Evergreen.V113.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V113.Id.SecretId Evergreen.V113.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
            }
    , pendingOneTimePasswords :
        AssocList.Dict
            Effect.Lamdera.SessionId
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V113.Id.Id Evergreen.V113.Id.UserId
            , loginAttempts : Int
            , oneTimePassword : Evergreen.V113.Id.SecretId Evergreen.V113.Id.OneTimePasswordId
            }
    , invites : AssocList.Dict (Evergreen.V113.Id.SecretId Evergreen.V113.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.UserId (List.Nonempty.Nonempty Evergreen.V113.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V113.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    , tileCountBot : Maybe Evergreen.V113.TileCountBot.Model
    }


type alias FrontendMsg =
    Evergreen.V113.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V113.Bounds.Bounds Evergreen.V113.Units.CellUnit) (Maybe Evergreen.V113.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V113.Id.Id Evergreen.V113.Id.EventId, Evergreen.V113.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V113.Untrusted.Untrusted Evergreen.V113.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V113.Untrusted.Untrusted Evergreen.V113.EmailAddress.EmailAddress)
    | PostOfficePositionRequest
    | ResetTileBotRequest
    | LoginAttemptRequest (Evergreen.V113.Id.SecretId Evergreen.V113.Id.OneTimePasswordId)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.ClientId
    | SentLoginEmail Effect.Time.Posix Evergreen.V113.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V113.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V113.Id.SecretId Evergreen.V113.Route.InviteToken) (Result Effect.Http.Error Evergreen.V113.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V113.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V113.Postmark.PostmarkSendResponse)
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V113.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V113.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix
    | TileCountBotUpdate Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V113.Grid.GridData
    , userStatus : Evergreen.V113.Change.UserStatus
    , viewBounds : Evergreen.V113.Bounds.Bounds Evergreen.V113.Units.CellUnit
    , trains : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.TrainId Evergreen.V113.Train.Train
    , mail : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.MailId Evergreen.V113.MailEditor.FrontendMail
    , cows : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.AnimalId Evergreen.V113.Animal.Animal
    , cursors : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.UserId Evergreen.V113.Cursor.Cursor
    , users : Evergreen.V113.IdDict.IdDict Evergreen.V113.Id.UserId Evergreen.V113.User.FrontendUser
    , inviteTree : Evergreen.V113.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V113.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V113.Change.Change)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V113.EmailAddress.EmailAddress
    | SendInviteEmailResponse Evergreen.V113.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V113.Coord.Coord Evergreen.V113.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
    | LoginAttemptResponse LoginError
