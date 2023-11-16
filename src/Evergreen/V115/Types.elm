module Evergreen.V115.Types exposing (..)

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
import Evergreen.V115.AdminPage
import Evergreen.V115.Animal
import Evergreen.V115.Audio
import Evergreen.V115.Bounds
import Evergreen.V115.Change
import Evergreen.V115.Color
import Evergreen.V115.Coord
import Evergreen.V115.Cursor
import Evergreen.V115.DisplayName
import Evergreen.V115.EmailAddress
import Evergreen.V115.Grid
import Evergreen.V115.GridCell
import Evergreen.V115.Id
import Evergreen.V115.IdDict
import Evergreen.V115.Keyboard
import Evergreen.V115.LocalGrid
import Evergreen.V115.LocalModel
import Evergreen.V115.MailEditor
import Evergreen.V115.PersonName
import Evergreen.V115.PingData
import Evergreen.V115.Point2d
import Evergreen.V115.Postmark
import Evergreen.V115.Route
import Evergreen.V115.Shaders
import Evergreen.V115.Sound
import Evergreen.V115.Sprite
import Evergreen.V115.TextInput
import Evergreen.V115.TextInputMultiline
import Evergreen.V115.Tile
import Evergreen.V115.TileCountBot
import Evergreen.V115.TimeOfDay
import Evergreen.V115.Tool
import Evergreen.V115.Train
import Evergreen.V115.Ui
import Evergreen.V115.Units
import Evergreen.V115.Untrusted
import Evergreen.V115.User
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
    | KeyMsg Evergreen.V115.Keyboard.Msg
    | KeyDown Evergreen.V115.Keyboard.RawKey
    | WindowResized (Evergreen.V115.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V115.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V115.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V115.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V115.Sound.Sound (Result Evergreen.V115.Audio.LoadError Evergreen.V115.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V115.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V115.LocalModel.LocalModel Evergreen.V115.Change.Change Evergreen.V115.LocalGrid.LocalGrid
    , trains : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.TrainId Evergreen.V115.Train.Train
    , mail : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.MailId Evergreen.V115.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V115.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V115.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V115.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V115.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
    , route : Evergreen.V115.Route.PageRoute
    , mousePosition : Evergreen.V115.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V115.Sound.Sound (Result Evergreen.V115.Audio.LoadError Evergreen.V115.Audio.Source)
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
    = NormalViewPoint (Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V115.Id.Id Evergreen.V115.Id.TrainId
        , startViewPoint : Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V115.Tile.TileGroup
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
    | MailEditorHover Evergreen.V115.MailEditor.Hover
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
    | AdminHover Evergreen.V115.AdminPage.Hover
    | CategoryButton Evergreen.V115.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton
    | OneTimePasswordInput
    | HyperlinkInput


type Hover
    = TileHover
        { tile : Evergreen.V115.Tile.Tile
        , userId : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
        , position : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
        , colors : Evergreen.V115.Color.Colors
        , time : Effect.Time.Posix
        }
    | TrainHover
        { trainId : Evergreen.V115.Id.Id Evergreen.V115.Id.TrainId
        , train : Evergreen.V115.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V115.Id.Id Evergreen.V115.Id.AnimalId
        , animal : Evergreen.V115.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V115.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V115.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V115.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit
        , current : Evergreen.V115.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
    , tile : Evergreen.V115.Tile.Tile
    , colors : Evergreen.V115.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V115.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { change :
        Maybe
            { userId : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
            , tile : Evergreen.V115.Tile.Tile
            , position : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
            , colors : Evergreen.V115.Color.Colors
            , time : Effect.Time.Posix
            }
    , position : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V115.MailEditor.Model
    | AdminPage Evergreen.V115.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V115.LocalModel.LocalModel Evergreen.V115.Change.Change Evergreen.V115.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V115.Keyboard.Key
    , currentTool : Evergreen.V115.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V115.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.TrainId Evergreen.V115.Train.Train
    , time : Effect.Time.Posix
    }


type LoginError
    = OneTimePasswordExpiredOrTooManyAttempts
    | WrongOneTimePassword (Evergreen.V115.Id.SecretId Evergreen.V115.Id.OneTimePasswordId)


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V115.LocalModel.LocalModel Evergreen.V115.Change.Change Evergreen.V115.LocalGrid.LocalGrid
    , trains : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.TrainId Evergreen.V115.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V115.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V115.Sprite.Vertex
            , background : WebGL.Mesh Evergreen.V115.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V115.Keyboard.Key
    , windowSize : Evergreen.V115.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V115.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V115.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V115.Id.Id Evergreen.V115.Id.EventId, Evergreen.V115.Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Effect.Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V115.Tile.Tile
            , position : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V115.Sound.Sound (Result Evergreen.V115.Audio.LoadError Evergreen.V115.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V115.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V115.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V115.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V115.Sprite.Vertex
    , previousTileHover : Maybe Evergreen.V115.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V115.Id.Id Evergreen.V115.Id.EventId
    , pingData : Maybe Evergreen.V115.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V115.Tile.TileGroup Evergreen.V115.Color.Colors
    , primaryColorTextInput : Evergreen.V115.TextInput.Model
    , secondaryColorTextInput : Evergreen.V115.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V115.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V115.IdDict.IdDict
            Evergreen.V115.Id.UserId
            { position : Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.UserId Evergreen.V115.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginEmailInput : Evergreen.V115.TextInput.Model
    , oneTimePasswordInput : Evergreen.V115.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V115.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V115.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V115.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit )
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V115.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V115.Tile.Category
    , lastHotkeyChange : Maybe Time.Posix
    , loginError : Maybe LoginError
    , hyperlinkInput : Evergreen.V115.TextInputMultiline.Model
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V115.Audio.Model FrontendMsg_ FrontendModel_


type alias HumanUserData =
    { emailAddress : Evergreen.V115.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.UserId ()
    , timeOfDay : Evergreen.V115.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V115.Change.TileHotkey Evergreen.V115.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    , allowEmailNotifications : Bool
    }


type BackendUserType
    = HumanUser HumanUserData
    | BotUser


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V115.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V115.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V115.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.UserId (List Evergreen.V115.MailEditor.Content)
    , cursor : Maybe Evergreen.V115.Cursor.Cursor
    , handColor : Evergreen.V115.Color.Colors
    , userType : BackendUserType
    , name : Evergreen.V115.DisplayName.DisplayName
    }


type BackendError
    = PostmarkError Evergreen.V115.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)


type alias Person =
    { name : Evergreen.V115.PersonName.PersonName
    , home : Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit
    , position : Evergreen.V115.Point2d.Point2d Evergreen.V115.Units.WorldUnit Evergreen.V115.Units.WorldUnit
    }


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V115.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V115.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V115.Grid.Grid Evergreen.V115.GridCell.BackendHistory
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V115.Bounds.Bounds Evergreen.V115.Units.CellUnit))
            , userId : Maybe (Evergreen.V115.Id.Id Evergreen.V115.Id.UserId)
            }
    , users : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.TrainId Evergreen.V115.Train.Train
    , animals : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.AnimalId Evergreen.V115.Animal.Animal
    , people : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.PersonId Person
    , lastWorldUpdateTrains : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.TrainId Evergreen.V115.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.MailId Evergreen.V115.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V115.Id.SecretId Evergreen.V115.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
            }
    , pendingOneTimePasswords :
        AssocList.Dict
            Effect.Lamdera.SessionId
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V115.Id.Id Evergreen.V115.Id.UserId
            , loginAttempts : Int
            , oneTimePassword : Evergreen.V115.Id.SecretId Evergreen.V115.Id.OneTimePasswordId
            }
    , invites : AssocList.Dict (Evergreen.V115.Id.SecretId Evergreen.V115.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.UserId (List.Nonempty.Nonempty Evergreen.V115.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V115.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    , tileCountBot : Maybe Evergreen.V115.TileCountBot.Model
    }


type alias FrontendMsg =
    Evergreen.V115.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V115.Bounds.Bounds Evergreen.V115.Units.CellUnit) (Maybe Evergreen.V115.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V115.Id.Id Evergreen.V115.Id.EventId, Evergreen.V115.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V115.Untrusted.Untrusted Evergreen.V115.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V115.Untrusted.Untrusted Evergreen.V115.EmailAddress.EmailAddress)
    | PostOfficePositionRequest
    | ResetTileBotRequest
    | LoginAttemptRequest (Evergreen.V115.Id.SecretId Evergreen.V115.Id.OneTimePasswordId)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.ClientId
    | SentLoginEmail Effect.Time.Posix Evergreen.V115.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V115.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V115.Id.SecretId Evergreen.V115.Route.InviteToken) (Result Effect.Http.Error Evergreen.V115.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V115.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V115.Postmark.PostmarkSendResponse)
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V115.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V115.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix
    | TileCountBotUpdate Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V115.Grid.GridData
    , userStatus : Evergreen.V115.Change.UserStatus
    , viewBounds : Evergreen.V115.Bounds.Bounds Evergreen.V115.Units.CellUnit
    , trains : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.TrainId Evergreen.V115.Train.Train
    , mail : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.MailId Evergreen.V115.MailEditor.FrontendMail
    , cows : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.AnimalId Evergreen.V115.Animal.Animal
    , cursors : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.UserId Evergreen.V115.Cursor.Cursor
    , users : Evergreen.V115.IdDict.IdDict Evergreen.V115.Id.UserId Evergreen.V115.User.FrontendUser
    , inviteTree : Evergreen.V115.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V115.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V115.Change.Change)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V115.EmailAddress.EmailAddress
    | SendInviteEmailResponse Evergreen.V115.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V115.Coord.Coord Evergreen.V115.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
    | LoginAttemptResponse LoginError
