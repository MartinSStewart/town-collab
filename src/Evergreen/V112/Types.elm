module Evergreen.V112.Types exposing (..)

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
import Evergreen.V112.AdminPage
import Evergreen.V112.Animal
import Evergreen.V112.Audio
import Evergreen.V112.Bounds
import Evergreen.V112.Change
import Evergreen.V112.Color
import Evergreen.V112.Coord
import Evergreen.V112.Cursor
import Evergreen.V112.DisplayName
import Evergreen.V112.EmailAddress
import Evergreen.V112.Grid
import Evergreen.V112.GridCell
import Evergreen.V112.Id
import Evergreen.V112.IdDict
import Evergreen.V112.Keyboard
import Evergreen.V112.LocalGrid
import Evergreen.V112.LocalModel
import Evergreen.V112.MailEditor
import Evergreen.V112.PersonName
import Evergreen.V112.PingData
import Evergreen.V112.Point2d
import Evergreen.V112.Postmark
import Evergreen.V112.Route
import Evergreen.V112.Shaders
import Evergreen.V112.Sound
import Evergreen.V112.Sprite
import Evergreen.V112.TextInput
import Evergreen.V112.TextInputMultiline
import Evergreen.V112.Tile
import Evergreen.V112.TileCountBot
import Evergreen.V112.TimeOfDay
import Evergreen.V112.Tool
import Evergreen.V112.Train
import Evergreen.V112.Ui
import Evergreen.V112.Units
import Evergreen.V112.Untrusted
import Evergreen.V112.User
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
    | KeyMsg Evergreen.V112.Keyboard.Msg
    | KeyDown Evergreen.V112.Keyboard.RawKey
    | WindowResized (Evergreen.V112.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V112.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V112.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V112.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V112.Sound.Sound (Result Evergreen.V112.Audio.LoadError Evergreen.V112.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V112.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V112.LocalModel.LocalModel Evergreen.V112.Change.Change Evergreen.V112.LocalGrid.LocalGrid
    , trains : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.TrainId Evergreen.V112.Train.Train
    , mail : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.MailId Evergreen.V112.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V112.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V112.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V112.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V112.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
    , route : Evergreen.V112.Route.PageRoute
    , mousePosition : Evergreen.V112.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V112.Sound.Sound (Result Evergreen.V112.Audio.LoadError Evergreen.V112.Audio.Source)
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
    = NormalViewPoint (Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V112.Id.Id Evergreen.V112.Id.TrainId
        , startViewPoint : Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V112.Tile.TileGroup
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
    | MailEditorHover Evergreen.V112.MailEditor.Hover
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
    | AdminHover Evergreen.V112.AdminPage.Hover
    | CategoryButton Evergreen.V112.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton
    | OneTimePasswordInput
    | HyperlinkInput


type Hover
    = TileHover
        { tile : Evergreen.V112.Tile.Tile
        , userId : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
        , position : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
        , colors : Evergreen.V112.Color.Colors
        , time : Effect.Time.Posix
        }
    | TrainHover
        { trainId : Evergreen.V112.Id.Id Evergreen.V112.Id.TrainId
        , train : Evergreen.V112.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V112.Id.Id Evergreen.V112.Id.AnimalId
        , animal : Evergreen.V112.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V112.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V112.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V112.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit
        , current : Evergreen.V112.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
    , tile : Evergreen.V112.Tile.Tile
    , colors : Evergreen.V112.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V112.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { change :
        Maybe
            { userId : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
            , tile : Evergreen.V112.Tile.Tile
            , position : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
            , colors : Evergreen.V112.Color.Colors
            , time : Effect.Time.Posix
            }
    , position : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V112.MailEditor.Model
    | AdminPage Evergreen.V112.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V112.LocalModel.LocalModel Evergreen.V112.Change.Change Evergreen.V112.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V112.Keyboard.Key
    , currentTool : Evergreen.V112.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V112.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.TrainId Evergreen.V112.Train.Train
    , time : Effect.Time.Posix
    }


type LoginError
    = OneTimePasswordExpiredOrTooManyAttempts
    | WrongOneTimePassword (Evergreen.V112.Id.SecretId Evergreen.V112.Id.OneTimePasswordId)


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V112.LocalModel.LocalModel Evergreen.V112.Change.Change Evergreen.V112.LocalGrid.LocalGrid
    , trains : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.TrainId Evergreen.V112.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V112.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V112.Sprite.Vertex
            , background : WebGL.Mesh Evergreen.V112.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V112.Keyboard.Key
    , windowSize : Evergreen.V112.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V112.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V112.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V112.Id.Id Evergreen.V112.Id.EventId, Evergreen.V112.Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Effect.Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V112.Tile.Tile
            , position : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V112.Sound.Sound (Result Evergreen.V112.Audio.LoadError Evergreen.V112.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V112.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V112.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V112.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V112.Sprite.Vertex
    , previousTileHover : Maybe Evergreen.V112.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V112.Id.Id Evergreen.V112.Id.EventId
    , pingData : Maybe Evergreen.V112.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V112.Tile.TileGroup Evergreen.V112.Color.Colors
    , primaryColorTextInput : Evergreen.V112.TextInput.Model
    , secondaryColorTextInput : Evergreen.V112.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V112.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V112.IdDict.IdDict
            Evergreen.V112.Id.UserId
            { position : Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.UserId Evergreen.V112.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginEmailInput : Evergreen.V112.TextInput.Model
    , oneTimePasswordInput : Evergreen.V112.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V112.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V112.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V112.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit )
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V112.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V112.Tile.Category
    , lastHotkeyChange : Maybe Time.Posix
    , loginError : Maybe LoginError
    , hyperlinkInput : Evergreen.V112.TextInputMultiline.Model
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V112.Audio.Model FrontendMsg_ FrontendModel_


type alias HumanUserData =
    { emailAddress : Evergreen.V112.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.UserId ()
    , timeOfDay : Evergreen.V112.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V112.Change.TileHotkey Evergreen.V112.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    , allowEmailNotifications : Bool
    }


type BackendUserType
    = HumanUser HumanUserData
    | BotUser


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V112.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V112.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V112.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.UserId (List Evergreen.V112.MailEditor.Content)
    , cursor : Maybe Evergreen.V112.Cursor.Cursor
    , handColor : Evergreen.V112.Color.Colors
    , userType : BackendUserType
    , name : Evergreen.V112.DisplayName.DisplayName
    }


type BackendError
    = PostmarkError Evergreen.V112.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId)


type alias Person =
    { name : Evergreen.V112.PersonName.PersonName
    , home : Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit
    , position : Evergreen.V112.Point2d.Point2d Evergreen.V112.Units.WorldUnit Evergreen.V112.Units.WorldUnit
    }


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V112.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V112.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V112.Grid.Grid Evergreen.V112.GridCell.BackendHistory
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V112.Bounds.Bounds Evergreen.V112.Units.CellUnit))
            , userId : Maybe (Evergreen.V112.Id.Id Evergreen.V112.Id.UserId)
            }
    , users : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.TrainId Evergreen.V112.Train.Train
    , animals : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.AnimalId Evergreen.V112.Animal.Animal
    , people : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.PersonId Person
    , lastWorldUpdateTrains : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.TrainId Evergreen.V112.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.MailId Evergreen.V112.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V112.Id.SecretId Evergreen.V112.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
            }
    , pendingOneTimePasswords :
        AssocList.Dict
            Effect.Lamdera.SessionId
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V112.Id.Id Evergreen.V112.Id.UserId
            , loginAttempts : Int
            , oneTimePassword : Evergreen.V112.Id.SecretId Evergreen.V112.Id.OneTimePasswordId
            }
    , invites : AssocList.Dict (Evergreen.V112.Id.SecretId Evergreen.V112.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.UserId (List.Nonempty.Nonempty Evergreen.V112.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V112.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    , tileCountBot : Maybe Evergreen.V112.TileCountBot.Model
    }


type alias FrontendMsg =
    Evergreen.V112.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V112.Bounds.Bounds Evergreen.V112.Units.CellUnit) (Maybe Evergreen.V112.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V112.Id.Id Evergreen.V112.Id.EventId, Evergreen.V112.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V112.Untrusted.Untrusted Evergreen.V112.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V112.Untrusted.Untrusted Evergreen.V112.EmailAddress.EmailAddress)
    | PostOfficePositionRequest
    | ResetTileBotRequest
    | LoginAttemptRequest (Evergreen.V112.Id.SecretId Evergreen.V112.Id.OneTimePasswordId)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.ClientId
    | SentLoginEmail Effect.Time.Posix Evergreen.V112.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V112.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V112.Id.SecretId Evergreen.V112.Route.InviteToken) (Result Effect.Http.Error Evergreen.V112.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V112.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V112.Postmark.PostmarkSendResponse)
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V112.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V112.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix
    | TileCountBotUpdate Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V112.Grid.GridData
    , userStatus : Evergreen.V112.Change.UserStatus
    , viewBounds : Evergreen.V112.Bounds.Bounds Evergreen.V112.Units.CellUnit
    , trains : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.TrainId Evergreen.V112.Train.Train
    , mail : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.MailId Evergreen.V112.MailEditor.FrontendMail
    , cows : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.AnimalId Evergreen.V112.Animal.Animal
    , cursors : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.UserId Evergreen.V112.Cursor.Cursor
    , users : Evergreen.V112.IdDict.IdDict Evergreen.V112.Id.UserId Evergreen.V112.User.FrontendUser
    , inviteTree : Evergreen.V112.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V112.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V112.Change.Change)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V112.EmailAddress.EmailAddress
    | SendInviteEmailResponse Evergreen.V112.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V112.Coord.Coord Evergreen.V112.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
    | LoginAttemptResponse LoginError
