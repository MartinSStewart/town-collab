module Evergreen.V123.Types exposing (..)

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
import Evergreen.V123.AdminPage
import Evergreen.V123.Animal
import Evergreen.V123.Audio
import Evergreen.V123.Bounds
import Evergreen.V123.Change
import Evergreen.V123.Color
import Evergreen.V123.Coord
import Evergreen.V123.Cursor
import Evergreen.V123.DisplayName
import Evergreen.V123.EmailAddress
import Evergreen.V123.Grid
import Evergreen.V123.GridCell
import Evergreen.V123.Id
import Evergreen.V123.IdDict
import Evergreen.V123.Keyboard
import Evergreen.V123.LocalGrid
import Evergreen.V123.LocalModel
import Evergreen.V123.MailEditor
import Evergreen.V123.PersonName
import Evergreen.V123.PingData
import Evergreen.V123.Point2d
import Evergreen.V123.Postmark
import Evergreen.V123.Route
import Evergreen.V123.Shaders
import Evergreen.V123.Sound
import Evergreen.V123.Sprite
import Evergreen.V123.TextInput
import Evergreen.V123.TextInputMultiline
import Evergreen.V123.Tile
import Evergreen.V123.TileCountBot
import Evergreen.V123.TimeOfDay
import Evergreen.V123.Tool
import Evergreen.V123.Train
import Evergreen.V123.Ui
import Evergreen.V123.Units
import Evergreen.V123.Untrusted
import Evergreen.V123.User
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
    | KeyMsg Evergreen.V123.Keyboard.Msg
    | KeyDown Evergreen.V123.Keyboard.RawKey
    | WindowResized (Evergreen.V123.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V123.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V123.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V123.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V123.Sound.Sound (Result Evergreen.V123.Audio.LoadError Evergreen.V123.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | GotWebGlFix
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V123.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V123.LocalModel.LocalModel Evergreen.V123.Change.Change Evergreen.V123.LocalGrid.LocalGrid
    , trains : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.TrainId Evergreen.V123.Train.Train
    , mail : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.MailId Evergreen.V123.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V123.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V123.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V123.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V123.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
    , route : Evergreen.V123.Route.PageRoute
    , mousePosition : Evergreen.V123.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V123.Sound.Sound (Result Evergreen.V123.Audio.LoadError Evergreen.V123.Audio.Source)
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
    = NormalViewPoint (Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V123.Id.Id Evergreen.V123.Id.TrainId
        , startViewPoint : Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V123.Tile.TileGroup
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
    | MailEditorHover Evergreen.V123.MailEditor.Hover
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
    | AdminHover Evergreen.V123.AdminPage.Hover
    | CategoryButton Evergreen.V123.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton
    | OneTimePasswordInput
    | HyperlinkInput
    | CategoryNextPageButton
    | CategoryPreviousPageButton


type Hover
    = TileHover
        { tile : Evergreen.V123.Tile.Tile
        , userId : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
        , position : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
        , colors : Evergreen.V123.Color.Colors
        , time : Effect.Time.Posix
        }
    | TrainHover
        { trainId : Evergreen.V123.Id.Id Evergreen.V123.Id.TrainId
        , train : Evergreen.V123.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V123.Id.Id Evergreen.V123.Id.AnimalId
        , animal : Evergreen.V123.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V123.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V123.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V123.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit
        , current : Evergreen.V123.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
    , tile : Evergreen.V123.Tile.Tile
    , colors : Evergreen.V123.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V123.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { change :
        Maybe
            { userId : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
            , tile : Evergreen.V123.Tile.Tile
            , position : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
            , colors : Evergreen.V123.Color.Colors
            , time : Effect.Time.Posix
            }
    , position : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V123.MailEditor.Model
    | AdminPage Evergreen.V123.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V123.LocalModel.LocalModel Evergreen.V123.Change.Change Evergreen.V123.LocalGrid.LocalGrid
    , pressedKeys : List Evergreen.V123.Keyboard.Key
    , currentTool : Evergreen.V123.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V123.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.TrainId Evergreen.V123.Train.Train
    , time : Effect.Time.Posix
    }


type LoginError
    = OneTimePasswordExpiredOrTooManyAttempts
    | WrongOneTimePassword (Evergreen.V123.Id.SecretId Evergreen.V123.Id.OneTimePasswordId)


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V123.LocalModel.LocalModel Evergreen.V123.Change.Change Evergreen.V123.LocalGrid.LocalGrid
    , trains : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.TrainId Evergreen.V123.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V123.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V123.Sprite.Vertex
            , background : WebGL.Mesh Evergreen.V123.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V123.Keyboard.Key
    , windowSize : Evergreen.V123.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V123.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V123.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V123.Id.Id Evergreen.V123.Id.EventId, Evergreen.V123.Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Effect.Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V123.Tile.Tile
            , position : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V123.Sound.Sound (Result Evergreen.V123.Audio.LoadError Evergreen.V123.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V123.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V123.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V123.Ui.Element UiHover
    , uiMesh : WebGL.Mesh Evergreen.V123.Sprite.Vertex
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V123.Id.Id Evergreen.V123.Id.EventId
    , pingData : Maybe Evergreen.V123.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V123.Tile.TileGroup Evergreen.V123.Color.Colors
    , primaryColorTextInput : Evergreen.V123.TextInput.Model
    , secondaryColorTextInput : Evergreen.V123.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V123.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V123.IdDict.IdDict
            Evergreen.V123.Id.UserId
            { position : Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.UserId Evergreen.V123.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginEmailInput : Evergreen.V123.TextInput.Model
    , oneTimePasswordInput : Evergreen.V123.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V123.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V123.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V123.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit )
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : WebGL.Mesh Evergreen.V123.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V123.Tile.Category
    , tileCategoryPageIndex : AssocList.Dict Evergreen.V123.Tile.Category Int
    , lastHotkeyChange : Maybe Time.Posix
    , loginError : Maybe LoginError
    , hyperlinkInput : Evergreen.V123.TextInputMultiline.Model
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V123.Audio.Model FrontendMsg_ FrontendModel_


type alias HumanUserData =
    { emailAddress : Evergreen.V123.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.UserId ()
    , timeOfDay : Evergreen.V123.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V123.Change.TileHotkey Evergreen.V123.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    , allowEmailNotifications : Bool
    , hyperlinksVisited : Set.Set String
    }


type BackendUserType
    = HumanUser HumanUserData
    | BotUser


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V123.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V123.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V123.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.UserId (List Evergreen.V123.MailEditor.Content)
    , cursor : Maybe Evergreen.V123.Cursor.Cursor
    , handColor : Evergreen.V123.Color.Colors
    , userType : BackendUserType
    , name : Evergreen.V123.DisplayName.DisplayName
    }


type BackendError
    = PostmarkError Evergreen.V123.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V123.Id.Id Evergreen.V123.Id.UserId)


type alias Person =
    { name : Evergreen.V123.PersonName.PersonName
    , home : Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit
    , position : Evergreen.V123.Point2d.Point2d Evergreen.V123.Units.WorldUnit Evergreen.V123.Units.WorldUnit
    }


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V123.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V123.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V123.Grid.Grid Evergreen.V123.GridCell.BackendHistory
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V123.Bounds.Bounds Evergreen.V123.Units.CellUnit))
            , userId : Maybe (Evergreen.V123.Id.Id Evergreen.V123.Id.UserId)
            }
    , users : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.TrainId Evergreen.V123.Train.Train
    , animals : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.AnimalId Evergreen.V123.Animal.Animal
    , people : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.PersonId Person
    , lastWorldUpdateTrains : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.TrainId Evergreen.V123.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.MailId Evergreen.V123.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V123.Id.SecretId Evergreen.V123.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
            }
    , pendingOneTimePasswords :
        AssocList.Dict
            Effect.Lamdera.SessionId
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V123.Id.Id Evergreen.V123.Id.UserId
            , loginAttempts : Int
            , oneTimePassword : Evergreen.V123.Id.SecretId Evergreen.V123.Id.OneTimePasswordId
            }
    , invites : AssocList.Dict (Evergreen.V123.Id.SecretId Evergreen.V123.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.UserId (List.Nonempty.Nonempty Evergreen.V123.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V123.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    , tileCountBot : Maybe Evergreen.V123.TileCountBot.Model
    }


type alias FrontendMsg =
    Evergreen.V123.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V123.Bounds.Bounds Evergreen.V123.Units.CellUnit) (Maybe Evergreen.V123.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V123.Id.Id Evergreen.V123.Id.EventId, Evergreen.V123.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V123.Untrusted.Untrusted Evergreen.V123.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V123.Untrusted.Untrusted Evergreen.V123.EmailAddress.EmailAddress)
    | PostOfficePositionRequest
    | ResetTileBotRequest
    | LoginAttemptRequest (Evergreen.V123.Id.SecretId Evergreen.V123.Id.OneTimePasswordId)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.ClientId
    | SentLoginEmail Effect.Time.Posix Evergreen.V123.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V123.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V123.Id.SecretId Evergreen.V123.Route.InviteToken) (Result Effect.Http.Error Evergreen.V123.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V123.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V123.Postmark.PostmarkSendResponse)
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V123.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V123.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix
    | TileCountBotUpdate Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V123.Grid.GridData
    , userStatus : Evergreen.V123.Change.UserStatus
    , viewBounds : Evergreen.V123.Bounds.Bounds Evergreen.V123.Units.CellUnit
    , trains : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.TrainId Evergreen.V123.Train.Train
    , mail : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.MailId Evergreen.V123.MailEditor.FrontendMail
    , cows : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.AnimalId Evergreen.V123.Animal.Animal
    , cursors : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.UserId Evergreen.V123.Cursor.Cursor
    , users : Evergreen.V123.IdDict.IdDict Evergreen.V123.Id.UserId Evergreen.V123.User.FrontendUser
    , inviteTree : Evergreen.V123.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V123.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V123.Change.Change)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V123.EmailAddress.EmailAddress
    | SendInviteEmailResponse Evergreen.V123.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V123.Coord.Coord Evergreen.V123.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
    | LoginAttemptResponse LoginError
