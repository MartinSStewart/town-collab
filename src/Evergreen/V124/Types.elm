module Evergreen.V124.Types exposing (..)

import Array
import AssocList
import AssocSet
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.File
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL
import Effect.WebGL.Texture
import Evergreen.V124.AdminPage
import Evergreen.V124.Animal
import Evergreen.V124.Audio
import Evergreen.V124.Bounds
import Evergreen.V124.Change
import Evergreen.V124.Color
import Evergreen.V124.Coord
import Evergreen.V124.Cursor
import Evergreen.V124.DisplayName
import Evergreen.V124.EmailAddress
import Evergreen.V124.Grid
import Evergreen.V124.GridCell
import Evergreen.V124.Id
import Evergreen.V124.IdDict
import Evergreen.V124.Keyboard
import Evergreen.V124.LocalGrid
import Evergreen.V124.LocalModel
import Evergreen.V124.MailEditor
import Evergreen.V124.PersonName
import Evergreen.V124.PingData
import Evergreen.V124.Point2d
import Evergreen.V124.Postmark
import Evergreen.V124.Route
import Evergreen.V124.Shaders
import Evergreen.V124.Sound
import Evergreen.V124.Sprite
import Evergreen.V124.TextInput
import Evergreen.V124.TextInputMultiline
import Evergreen.V124.Tile
import Evergreen.V124.TileCountBot
import Evergreen.V124.TimeOfDay
import Evergreen.V124.Tool
import Evergreen.V124.Train
import Evergreen.V124.Ui
import Evergreen.V124.Units
import Evergreen.V124.Untrusted
import Evergreen.V124.User
import Html.Events.Extra.Mouse
import Html.Events.Extra.Wheel
import Lamdera
import List.Nonempty
import Pixels
import Set
import Time
import Url


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
    | TrainTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainLightsTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainDepthTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | KeyUp Evergreen.V124.Keyboard.RawKey
    | KeyDown Evergreen.V124.Keyboard.RawKey
    | WindowResized (Evergreen.V124.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V124.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V124.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V124.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V124.Sound.Sound (Result Evergreen.V124.Audio.LoadError Evergreen.V124.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V124.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V124.LocalModel.LocalModel Evergreen.V124.Change.Change Evergreen.V124.LocalGrid.LocalGrid
    , trains : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.TrainId Evergreen.V124.Train.Train
    , mail : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.MailId Evergreen.V124.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V124.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V124.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V124.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V124.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
    , route : Evergreen.V124.Route.PageRoute
    , mousePosition : Evergreen.V124.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V124.Sound.Sound (Result Evergreen.V124.Audio.LoadError Evergreen.V124.Audio.Source)
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
    = NormalViewPoint (Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V124.Id.Id Evergreen.V124.Id.TrainId
        , startViewPoint : Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V124.Tile.TileGroup
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
    | MailEditorHover Evergreen.V124.MailEditor.Hover
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
    | AdminHover Evergreen.V124.AdminPage.Hover
    | CategoryButton Evergreen.V124.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit)
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
        { tile : Evergreen.V124.Tile.Tile
        , userId : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
        , position : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
        , colors : Evergreen.V124.Color.Colors
        , time : Effect.Time.Posix
        }
    | TrainHover
        { trainId : Evergreen.V124.Id.Id Evergreen.V124.Id.TrainId
        , train : Evergreen.V124.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V124.Id.Id Evergreen.V124.Id.AnimalId
        , animal : Evergreen.V124.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V124.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V124.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V124.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit
        , current : Evergreen.V124.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
    , tile : Evergreen.V124.Tile.Tile
    , colors : Evergreen.V124.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V124.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { change :
        Maybe
            { userId : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
            , tile : Evergreen.V124.Tile.Tile
            , position : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
            , colors : Evergreen.V124.Color.Colors
            , time : Effect.Time.Posix
            }
    , position : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V124.MailEditor.Model
    | AdminPage Evergreen.V124.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V124.LocalModel.LocalModel Evergreen.V124.Change.Change Evergreen.V124.LocalGrid.LocalGrid
    , pressedKeys : AssocSet.Set Evergreen.V124.Keyboard.Key
    , currentTool : Evergreen.V124.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V124.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.TrainId Evergreen.V124.Train.Train
    , time : Effect.Time.Posix
    }


type LoginError
    = OneTimePasswordExpiredOrTooManyAttempts
    | WrongOneTimePassword (Evergreen.V124.Id.SecretId Evergreen.V124.Id.OneTimePasswordId)


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V124.LocalModel.LocalModel Evergreen.V124.Change.Change Evergreen.V124.LocalGrid.LocalGrid
    , trains : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.TrainId Evergreen.V124.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V124.Coord.RawCellCoord
            { foreground : Effect.WebGL.Mesh Evergreen.V124.Sprite.Vertex
            , background : Effect.WebGL.Mesh Evergreen.V124.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : AssocSet.Set Evergreen.V124.Keyboard.Key
    , windowSize : Evergreen.V124.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V124.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V124.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V124.Id.Id Evergreen.V124.Id.EventId, Evergreen.V124.Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Effect.Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V124.Tile.Tile
            , position : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V124.Sound.Sound (Result Evergreen.V124.Audio.LoadError Evergreen.V124.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : Effect.WebGL.Mesh Evergreen.V124.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V124.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V124.Ui.Element UiHover
    , uiMesh : Effect.WebGL.Mesh Evergreen.V124.Sprite.Vertex
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V124.Id.Id Evergreen.V124.Id.EventId
    , pingData : Maybe Evergreen.V124.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V124.Tile.TileGroup Evergreen.V124.Color.Colors
    , primaryColorTextInput : Evergreen.V124.TextInput.Model
    , secondaryColorTextInput : Evergreen.V124.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V124.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V124.IdDict.IdDict
            Evergreen.V124.Id.UserId
            { position : Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.UserId Evergreen.V124.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginEmailInput : Evergreen.V124.TextInput.Model
    , oneTimePasswordInput : Evergreen.V124.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V124.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V124.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V124.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit )
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : Effect.WebGL.Mesh Evergreen.V124.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V124.Tile.Category
    , tileCategoryPageIndex : AssocList.Dict Evergreen.V124.Tile.Category Int
    , lastHotkeyChange : Maybe Time.Posix
    , loginError : Maybe LoginError
    , hyperlinkInput : Evergreen.V124.TextInputMultiline.Model
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V124.Audio.Model FrontendMsg_ FrontendModel_


type alias HumanUserData =
    { emailAddress : Evergreen.V124.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.UserId ()
    , timeOfDay : Evergreen.V124.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V124.Change.TileHotkey Evergreen.V124.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    , allowEmailNotifications : Bool
    , hyperlinksVisited : Set.Set String
    }


type BackendUserType
    = HumanUser HumanUserData
    | BotUser


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V124.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V124.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V124.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.UserId (List Evergreen.V124.MailEditor.Content)
    , cursor : Maybe Evergreen.V124.Cursor.Cursor
    , handColor : Evergreen.V124.Color.Colors
    , userType : BackendUserType
    , name : Evergreen.V124.DisplayName.DisplayName
    }


type BackendError
    = PostmarkError Evergreen.V124.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)


type alias Person =
    { name : Evergreen.V124.PersonName.PersonName
    , home : Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit
    , position : Evergreen.V124.Point2d.Point2d Evergreen.V124.Units.WorldUnit Evergreen.V124.Units.WorldUnit
    }


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V124.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V124.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V124.Grid.Grid Evergreen.V124.GridCell.BackendHistory
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V124.Bounds.Bounds Evergreen.V124.Units.CellUnit))
            , userId : Maybe (Evergreen.V124.Id.Id Evergreen.V124.Id.UserId)
            }
    , users : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.TrainId Evergreen.V124.Train.Train
    , animals : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.AnimalId Evergreen.V124.Animal.Animal
    , people : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.PersonId Person
    , lastWorldUpdateTrains : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.TrainId Evergreen.V124.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.MailId Evergreen.V124.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V124.Id.SecretId Evergreen.V124.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
            }
    , pendingOneTimePasswords :
        AssocList.Dict
            Effect.Lamdera.SessionId
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V124.Id.Id Evergreen.V124.Id.UserId
            , loginAttempts : Int
            , oneTimePassword : Evergreen.V124.Id.SecretId Evergreen.V124.Id.OneTimePasswordId
            }
    , invites : AssocList.Dict (Evergreen.V124.Id.SecretId Evergreen.V124.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.UserId (List.Nonempty.Nonempty Evergreen.V124.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V124.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    , tileCountBot : Maybe Evergreen.V124.TileCountBot.Model
    }


type alias FrontendMsg =
    Evergreen.V124.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V124.Bounds.Bounds Evergreen.V124.Units.CellUnit) (Maybe Evergreen.V124.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V124.Id.Id Evergreen.V124.Id.EventId, Evergreen.V124.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V124.Untrusted.Untrusted Evergreen.V124.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V124.Untrusted.Untrusted Evergreen.V124.EmailAddress.EmailAddress)
    | PostOfficePositionRequest
    | ResetTileBotRequest
    | LoginAttemptRequest (Evergreen.V124.Id.SecretId Evergreen.V124.Id.OneTimePasswordId)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.ClientId
    | SentLoginEmail Effect.Time.Posix Evergreen.V124.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V124.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V124.Id.SecretId Evergreen.V124.Route.InviteToken) (Result Effect.Http.Error Evergreen.V124.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V124.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V124.Postmark.PostmarkSendResponse)
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V124.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V124.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix
    | TileCountBotUpdate Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V124.Grid.GridData
    , userStatus : Evergreen.V124.Change.UserStatus
    , viewBounds : Evergreen.V124.Bounds.Bounds Evergreen.V124.Units.CellUnit
    , trains : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.TrainId Evergreen.V124.Train.Train
    , mail : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.MailId Evergreen.V124.MailEditor.FrontendMail
    , cows : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.AnimalId Evergreen.V124.Animal.Animal
    , cursors : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.UserId Evergreen.V124.Cursor.Cursor
    , users : Evergreen.V124.IdDict.IdDict Evergreen.V124.Id.UserId Evergreen.V124.User.FrontendUser
    , inviteTree : Evergreen.V124.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V124.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V124.Change.Change)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V124.EmailAddress.EmailAddress
    | SendInviteEmailResponse Evergreen.V124.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V124.Coord.Coord Evergreen.V124.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
    | LoginAttemptResponse LoginError
