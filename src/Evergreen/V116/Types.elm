module Evergreen.V116.Types exposing (..)

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
import Evergreen.V116.AdminPage
import Evergreen.V116.Animal
import Evergreen.V116.Audio
import Evergreen.V116.Bounds
import Evergreen.V116.Change
import Evergreen.V116.Color
import Evergreen.V116.Coord
import Evergreen.V116.Cursor
import Evergreen.V116.DisplayName
import Evergreen.V116.EmailAddress
import Evergreen.V116.Grid
import Evergreen.V116.GridCell
import Evergreen.V116.Id
import Evergreen.V116.IdDict
import Evergreen.V116.Keyboard
import Evergreen.V116.LocalGrid
import Evergreen.V116.LocalModel
import Evergreen.V116.MailEditor
import Evergreen.V116.PersonName
import Evergreen.V116.PingData
import Evergreen.V116.Point2d
import Evergreen.V116.Postmark
import Evergreen.V116.Route
import Evergreen.V116.Shaders
import Evergreen.V116.Sound
import Evergreen.V116.Sprite
import Evergreen.V116.TextInput
import Evergreen.V116.TextInputMultiline
import Evergreen.V116.Tile
import Evergreen.V116.TileCountBot
import Evergreen.V116.TimeOfDay
import Evergreen.V116.Tool
import Evergreen.V116.Train
import Evergreen.V116.Ui
import Evergreen.V116.Units
import Evergreen.V116.Untrusted
import Evergreen.V116.User
import Html.Events.Extra.Mouse
import Html.Events.Extra.Wheel
import Lamdera
import List.Nonempty
import Pixels
import Set
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
    | KeyMsg Evergreen.V116.Keyboard.Msg
    | KeyDown Evergreen.V116.Keyboard.RawKey
    | WindowResized (Evergreen.V116.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V116.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V116.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V116.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V116.Sound.Sound (Result Evergreen.V116.Audio.LoadError Evergreen.V116.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V116.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V116.LocalModel.LocalModel Evergreen.V116.Change.Change Evergreen.V116.LocalGrid.LocalGrid
    , trains : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.TrainId Evergreen.V116.Train.Train
    , mail : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.MailId Evergreen.V116.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V116.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V116.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V116.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V116.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
    , route : Evergreen.V116.Route.PageRoute
    , mousePosition : Evergreen.V116.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V116.Sound.Sound (Result Evergreen.V116.Audio.LoadError Evergreen.V116.Audio.Source)
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
    = NormalViewPoint (Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V116.Id.Id Evergreen.V116.Id.TrainId
        , startViewPoint : Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V116.Tile.TileGroup
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
    | MailEditorHover Evergreen.V116.MailEditor.Hover
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
    | AdminHover Evergreen.V116.AdminPage.Hover
    | CategoryButton Evergreen.V116.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton
    | OneTimePasswordInput
    | HyperlinkInput


type Hover
    = TileHover
        { tile : Evergreen.V116.Tile.Tile
        , userId : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
        , position : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
        , colors : Evergreen.V116.Color.Colors
        , time : Effect.Time.Posix
        }
    | TrainHover
        { trainId : Evergreen.V116.Id.Id Evergreen.V116.Id.TrainId
        , train : Evergreen.V116.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V116.Id.Id Evergreen.V116.Id.AnimalId
        , animal : Evergreen.V116.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V116.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V116.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V116.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit
        , current : Evergreen.V116.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
    , tile : Evergreen.V116.Tile.Tile
    , colors : Evergreen.V116.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V116.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { change :
        Maybe
            { userId : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
            , tile : Evergreen.V116.Tile.Tile
            , position : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
            , colors : Evergreen.V116.Color.Colors
            , time : Effect.Time.Posix
            }
    , position : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V116.MailEditor.Model
    | AdminPage Evergreen.V116.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V116.LocalModel.LocalModel Evergreen.V116.Change.Change Evergreen.V116.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V116.Keyboard.Key
    , currentTool : Evergreen.V116.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V116.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.TrainId Evergreen.V116.Train.Train
    , time : Effect.Time.Posix
    }


type LoginError
    = OneTimePasswordExpiredOrTooManyAttempts
    | WrongOneTimePassword (Evergreen.V116.Id.SecretId Evergreen.V116.Id.OneTimePasswordId)


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V116.LocalModel.LocalModel Evergreen.V116.Change.Change Evergreen.V116.LocalGrid.LocalGrid
    , trains : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.TrainId Evergreen.V116.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V116.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V116.Sprite.Vertex
            , background : WebGL.Mesh Evergreen.V116.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V116.Keyboard.Key
    , windowSize : Evergreen.V116.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V116.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V116.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V116.Id.Id Evergreen.V116.Id.EventId, Evergreen.V116.Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Effect.Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V116.Tile.Tile
            , position : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V116.Sound.Sound (Result Evergreen.V116.Audio.LoadError Evergreen.V116.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V116.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V116.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V116.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V116.Sprite.Vertex
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V116.Id.Id Evergreen.V116.Id.EventId
    , pingData : Maybe Evergreen.V116.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V116.Tile.TileGroup Evergreen.V116.Color.Colors
    , primaryColorTextInput : Evergreen.V116.TextInput.Model
    , secondaryColorTextInput : Evergreen.V116.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V116.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V116.IdDict.IdDict
            Evergreen.V116.Id.UserId
            { position : Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.UserId Evergreen.V116.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginEmailInput : Evergreen.V116.TextInput.Model
    , oneTimePasswordInput : Evergreen.V116.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V116.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V116.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V116.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit )
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V116.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V116.Tile.Category
    , lastHotkeyChange : Maybe Time.Posix
    , loginError : Maybe LoginError
    , hyperlinkInput : Evergreen.V116.TextInputMultiline.Model
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V116.Audio.Model FrontendMsg_ FrontendModel_


type alias HumanUserData =
    { emailAddress : Evergreen.V116.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.UserId ()
    , timeOfDay : Evergreen.V116.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V116.Change.TileHotkey Evergreen.V116.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    , allowEmailNotifications : Bool
    , hyperlinksVisited : Set.Set String
    }


type BackendUserType
    = HumanUser HumanUserData
    | BotUser


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V116.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V116.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V116.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.UserId (List Evergreen.V116.MailEditor.Content)
    , cursor : Maybe Evergreen.V116.Cursor.Cursor
    , handColor : Evergreen.V116.Color.Colors
    , userType : BackendUserType
    , name : Evergreen.V116.DisplayName.DisplayName
    }


type BackendError
    = PostmarkError Evergreen.V116.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)


type alias Person =
    { name : Evergreen.V116.PersonName.PersonName
    , home : Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit
    , position : Evergreen.V116.Point2d.Point2d Evergreen.V116.Units.WorldUnit Evergreen.V116.Units.WorldUnit
    }


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V116.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V116.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V116.Grid.Grid Evergreen.V116.GridCell.BackendHistory
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V116.Bounds.Bounds Evergreen.V116.Units.CellUnit))
            , userId : Maybe (Evergreen.V116.Id.Id Evergreen.V116.Id.UserId)
            }
    , users : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.TrainId Evergreen.V116.Train.Train
    , animals : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.AnimalId Evergreen.V116.Animal.Animal
    , people : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.PersonId Person
    , lastWorldUpdateTrains : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.TrainId Evergreen.V116.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.MailId Evergreen.V116.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V116.Id.SecretId Evergreen.V116.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
            }
    , pendingOneTimePasswords :
        AssocList.Dict
            Effect.Lamdera.SessionId
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V116.Id.Id Evergreen.V116.Id.UserId
            , loginAttempts : Int
            , oneTimePassword : Evergreen.V116.Id.SecretId Evergreen.V116.Id.OneTimePasswordId
            }
    , invites : AssocList.Dict (Evergreen.V116.Id.SecretId Evergreen.V116.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.UserId (List.Nonempty.Nonempty Evergreen.V116.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V116.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    , tileCountBot : Maybe Evergreen.V116.TileCountBot.Model
    }


type alias FrontendMsg =
    Evergreen.V116.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V116.Bounds.Bounds Evergreen.V116.Units.CellUnit) (Maybe Evergreen.V116.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V116.Id.Id Evergreen.V116.Id.EventId, Evergreen.V116.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V116.Untrusted.Untrusted Evergreen.V116.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V116.Untrusted.Untrusted Evergreen.V116.EmailAddress.EmailAddress)
    | PostOfficePositionRequest
    | ResetTileBotRequest
    | LoginAttemptRequest (Evergreen.V116.Id.SecretId Evergreen.V116.Id.OneTimePasswordId)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.ClientId
    | SentLoginEmail Effect.Time.Posix Evergreen.V116.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V116.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V116.Id.SecretId Evergreen.V116.Route.InviteToken) (Result Effect.Http.Error Evergreen.V116.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V116.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V116.Postmark.PostmarkSendResponse)
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V116.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V116.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix
    | TileCountBotUpdate Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V116.Grid.GridData
    , userStatus : Evergreen.V116.Change.UserStatus
    , viewBounds : Evergreen.V116.Bounds.Bounds Evergreen.V116.Units.CellUnit
    , trains : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.TrainId Evergreen.V116.Train.Train
    , mail : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.MailId Evergreen.V116.MailEditor.FrontendMail
    , cows : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.AnimalId Evergreen.V116.Animal.Animal
    , cursors : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.UserId Evergreen.V116.Cursor.Cursor
    , users : Evergreen.V116.IdDict.IdDict Evergreen.V116.Id.UserId Evergreen.V116.User.FrontendUser
    , inviteTree : Evergreen.V116.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V116.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V116.Change.Change)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V116.EmailAddress.EmailAddress
    | SendInviteEmailResponse Evergreen.V116.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V116.Coord.Coord Evergreen.V116.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
    | LoginAttemptResponse LoginError
