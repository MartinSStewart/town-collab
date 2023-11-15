module Evergreen.V114.Types exposing (..)

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
import Evergreen.V114.AdminPage
import Evergreen.V114.Animal
import Evergreen.V114.Audio
import Evergreen.V114.Bounds
import Evergreen.V114.Change
import Evergreen.V114.Color
import Evergreen.V114.Coord
import Evergreen.V114.Cursor
import Evergreen.V114.DisplayName
import Evergreen.V114.EmailAddress
import Evergreen.V114.Grid
import Evergreen.V114.GridCell
import Evergreen.V114.Id
import Evergreen.V114.IdDict
import Evergreen.V114.Keyboard
import Evergreen.V114.LocalGrid
import Evergreen.V114.LocalModel
import Evergreen.V114.MailEditor
import Evergreen.V114.PersonName
import Evergreen.V114.PingData
import Evergreen.V114.Point2d
import Evergreen.V114.Postmark
import Evergreen.V114.Route
import Evergreen.V114.Shaders
import Evergreen.V114.Sound
import Evergreen.V114.Sprite
import Evergreen.V114.TextInput
import Evergreen.V114.TextInputMultiline
import Evergreen.V114.Tile
import Evergreen.V114.TileCountBot
import Evergreen.V114.TimeOfDay
import Evergreen.V114.Tool
import Evergreen.V114.Train
import Evergreen.V114.Ui
import Evergreen.V114.Units
import Evergreen.V114.Untrusted
import Evergreen.V114.User
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
    | KeyMsg Evergreen.V114.Keyboard.Msg
    | KeyDown Evergreen.V114.Keyboard.RawKey
    | WindowResized (Evergreen.V114.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V114.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V114.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V114.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V114.Sound.Sound (Result Evergreen.V114.Audio.LoadError Evergreen.V114.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V114.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V114.LocalModel.LocalModel Evergreen.V114.Change.Change Evergreen.V114.LocalGrid.LocalGrid
    , trains : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.TrainId Evergreen.V114.Train.Train
    , mail : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.MailId Evergreen.V114.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V114.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V114.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V114.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V114.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit
    , route : Evergreen.V114.Route.PageRoute
    , mousePosition : Evergreen.V114.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V114.Sound.Sound (Result Evergreen.V114.Audio.LoadError Evergreen.V114.Audio.Source)
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
    = NormalViewPoint (Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V114.Id.Id Evergreen.V114.Id.TrainId
        , startViewPoint : Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V114.Tile.TileGroup
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
    | MailEditorHover Evergreen.V114.MailEditor.Hover
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
    | AdminHover Evergreen.V114.AdminPage.Hover
    | CategoryButton Evergreen.V114.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton
    | OneTimePasswordInput
    | HyperlinkInput


type Hover
    = TileHover
        { tile : Evergreen.V114.Tile.Tile
        , userId : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
        , position : Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit
        , colors : Evergreen.V114.Color.Colors
        , time : Effect.Time.Posix
        }
    | TrainHover
        { trainId : Evergreen.V114.Id.Id Evergreen.V114.Id.TrainId
        , train : Evergreen.V114.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V114.Id.Id Evergreen.V114.Id.AnimalId
        , animal : Evergreen.V114.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V114.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V114.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V114.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit
        , current : Evergreen.V114.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit
    , tile : Evergreen.V114.Tile.Tile
    , colors : Evergreen.V114.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V114.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { change :
        Maybe
            { userId : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
            , tile : Evergreen.V114.Tile.Tile
            , position : Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit
            , colors : Evergreen.V114.Color.Colors
            , time : Effect.Time.Posix
            }
    , position : Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V114.MailEditor.Model
    | AdminPage Evergreen.V114.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V114.LocalModel.LocalModel Evergreen.V114.Change.Change Evergreen.V114.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V114.Keyboard.Key
    , currentTool : Evergreen.V114.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V114.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.TrainId Evergreen.V114.Train.Train
    , time : Effect.Time.Posix
    }


type LoginError
    = OneTimePasswordExpiredOrTooManyAttempts
    | WrongOneTimePassword (Evergreen.V114.Id.SecretId Evergreen.V114.Id.OneTimePasswordId)


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V114.LocalModel.LocalModel Evergreen.V114.Change.Change Evergreen.V114.LocalGrid.LocalGrid
    , trains : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.TrainId Evergreen.V114.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V114.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V114.Sprite.Vertex
            , background : WebGL.Mesh Evergreen.V114.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V114.Keyboard.Key
    , windowSize : Evergreen.V114.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V114.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V114.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V114.Id.Id Evergreen.V114.Id.EventId, Evergreen.V114.Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Effect.Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V114.Tile.Tile
            , position : Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V114.Sound.Sound (Result Evergreen.V114.Audio.LoadError Evergreen.V114.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V114.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V114.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V114.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V114.Sprite.Vertex
    , previousTileHover : Maybe Evergreen.V114.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V114.Id.Id Evergreen.V114.Id.EventId
    , pingData : Maybe Evergreen.V114.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V114.Tile.TileGroup Evergreen.V114.Color.Colors
    , primaryColorTextInput : Evergreen.V114.TextInput.Model
    , secondaryColorTextInput : Evergreen.V114.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V114.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V114.IdDict.IdDict
            Evergreen.V114.Id.UserId
            { position : Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.UserId Evergreen.V114.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginEmailInput : Evergreen.V114.TextInput.Model
    , oneTimePasswordInput : Evergreen.V114.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V114.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V114.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V114.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit )
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V114.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V114.Tile.Category
    , lastHotkeyChange : Maybe Time.Posix
    , loginError : Maybe LoginError
    , hyperlinkInput : Evergreen.V114.TextInputMultiline.Model
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V114.Audio.Model FrontendMsg_ FrontendModel_


type alias HumanUserData =
    { emailAddress : Evergreen.V114.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.UserId ()
    , timeOfDay : Evergreen.V114.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V114.Change.TileHotkey Evergreen.V114.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    , allowEmailNotifications : Bool
    }


type BackendUserType
    = HumanUser HumanUserData
    | BotUser


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V114.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V114.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V114.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.UserId (List Evergreen.V114.MailEditor.Content)
    , cursor : Maybe Evergreen.V114.Cursor.Cursor
    , handColor : Evergreen.V114.Color.Colors
    , userType : BackendUserType
    , name : Evergreen.V114.DisplayName.DisplayName
    }


type BackendError
    = PostmarkError Evergreen.V114.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)


type alias Person =
    { name : Evergreen.V114.PersonName.PersonName
    , home : Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit
    , position : Evergreen.V114.Point2d.Point2d Evergreen.V114.Units.WorldUnit Evergreen.V114.Units.WorldUnit
    }


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V114.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V114.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V114.Grid.Grid Evergreen.V114.GridCell.BackendHistory
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V114.Bounds.Bounds Evergreen.V114.Units.CellUnit))
            , userId : Maybe (Evergreen.V114.Id.Id Evergreen.V114.Id.UserId)
            }
    , users : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.TrainId Evergreen.V114.Train.Train
    , animals : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.AnimalId Evergreen.V114.Animal.Animal
    , people : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.PersonId Person
    , lastWorldUpdateTrains : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.TrainId Evergreen.V114.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.MailId Evergreen.V114.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V114.Id.SecretId Evergreen.V114.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
            }
    , pendingOneTimePasswords :
        AssocList.Dict
            Effect.Lamdera.SessionId
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V114.Id.Id Evergreen.V114.Id.UserId
            , loginAttempts : Int
            , oneTimePassword : Evergreen.V114.Id.SecretId Evergreen.V114.Id.OneTimePasswordId
            }
    , invites : AssocList.Dict (Evergreen.V114.Id.SecretId Evergreen.V114.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.UserId (List.Nonempty.Nonempty Evergreen.V114.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V114.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    , tileCountBot : Maybe Evergreen.V114.TileCountBot.Model
    }


type alias FrontendMsg =
    Evergreen.V114.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V114.Bounds.Bounds Evergreen.V114.Units.CellUnit) (Maybe Evergreen.V114.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V114.Id.Id Evergreen.V114.Id.EventId, Evergreen.V114.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V114.Untrusted.Untrusted Evergreen.V114.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V114.Untrusted.Untrusted Evergreen.V114.EmailAddress.EmailAddress)
    | PostOfficePositionRequest
    | ResetTileBotRequest
    | LoginAttemptRequest (Evergreen.V114.Id.SecretId Evergreen.V114.Id.OneTimePasswordId)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.ClientId
    | SentLoginEmail Effect.Time.Posix Evergreen.V114.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V114.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V114.Id.SecretId Evergreen.V114.Route.InviteToken) (Result Effect.Http.Error Evergreen.V114.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V114.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V114.Postmark.PostmarkSendResponse)
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V114.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V114.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix
    | TileCountBotUpdate Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V114.Grid.GridData
    , userStatus : Evergreen.V114.Change.UserStatus
    , viewBounds : Evergreen.V114.Bounds.Bounds Evergreen.V114.Units.CellUnit
    , trains : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.TrainId Evergreen.V114.Train.Train
    , mail : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.MailId Evergreen.V114.MailEditor.FrontendMail
    , cows : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.AnimalId Evergreen.V114.Animal.Animal
    , cursors : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.UserId Evergreen.V114.Cursor.Cursor
    , users : Evergreen.V114.IdDict.IdDict Evergreen.V114.Id.UserId Evergreen.V114.User.FrontendUser
    , inviteTree : Evergreen.V114.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V114.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V114.Change.Change)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V114.EmailAddress.EmailAddress
    | SendInviteEmailResponse Evergreen.V114.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V114.Coord.Coord Evergreen.V114.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
    | LoginAttemptResponse LoginError
