module Evergreen.V125.Types exposing (..)

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
import Evergreen.V125.AdminPage
import Evergreen.V125.Animal
import Evergreen.V125.Audio
import Evergreen.V125.Bounds
import Evergreen.V125.Change
import Evergreen.V125.Color
import Evergreen.V125.Coord
import Evergreen.V125.Cursor
import Evergreen.V125.DisplayName
import Evergreen.V125.EmailAddress
import Evergreen.V125.Grid
import Evergreen.V125.GridCell
import Evergreen.V125.Id
import Evergreen.V125.IdDict
import Evergreen.V125.Keyboard
import Evergreen.V125.LocalGrid
import Evergreen.V125.LocalModel
import Evergreen.V125.MailEditor
import Evergreen.V125.PersonName
import Evergreen.V125.PingData
import Evergreen.V125.Point2d
import Evergreen.V125.Postmark
import Evergreen.V125.Route
import Evergreen.V125.Shaders
import Evergreen.V125.Sound
import Evergreen.V125.Sprite
import Evergreen.V125.TextInput
import Evergreen.V125.TextInputMultiline
import Evergreen.V125.Tile
import Evergreen.V125.TileCountBot
import Evergreen.V125.TimeOfDay
import Evergreen.V125.Tool
import Evergreen.V125.Train
import Evergreen.V125.Ui
import Evergreen.V125.Units
import Evergreen.V125.Untrusted
import Evergreen.V125.User
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
    | KeyUp Evergreen.V125.Keyboard.RawKey
    | KeyDown Evergreen.V125.Keyboard.RawKey
    | WindowResized (Evergreen.V125.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V125.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V125.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V125.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V125.Sound.Sound (Result Evergreen.V125.Audio.LoadError Evergreen.V125.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V125.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V125.LocalModel.LocalModel Evergreen.V125.Change.Change Evergreen.V125.LocalGrid.LocalGrid
    , trains : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.TrainId Evergreen.V125.Train.Train
    , mail : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.MailId Evergreen.V125.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V125.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V125.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V125.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V125.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
    , route : Evergreen.V125.Route.PageRoute
    , mousePosition : Evergreen.V125.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V125.Sound.Sound (Result Evergreen.V125.Audio.LoadError Evergreen.V125.Audio.Source)
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
    = NormalViewPoint (Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V125.Id.Id Evergreen.V125.Id.TrainId
        , startViewPoint : Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V125.Tile.TileGroup
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
    | MailEditorHover Evergreen.V125.MailEditor.Hover
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
    | AdminHover Evergreen.V125.AdminPage.Hover
    | CategoryButton Evergreen.V125.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit)
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
        { tile : Evergreen.V125.Tile.Tile
        , userId : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
        , position : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
        , colors : Evergreen.V125.Color.Colors
        , time : Effect.Time.Posix
        }
    | TrainHover
        { trainId : Evergreen.V125.Id.Id Evergreen.V125.Id.TrainId
        , train : Evergreen.V125.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V125.Id.Id Evergreen.V125.Id.AnimalId
        , animal : Evergreen.V125.Animal.Animal
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V125.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V125.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V125.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit
        , current : Evergreen.V125.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
    , tile : Evergreen.V125.Tile.Tile
    , colors : Evergreen.V125.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V125.TextInput.Model
    | LoggedOutSettingsMenu


type alias ContextMenu =
    { change :
        Maybe
            { userId : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
            , tile : Evergreen.V125.Tile.Tile
            , position : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
            , colors : Evergreen.V125.Color.Colors
            , time : Effect.Time.Posix
            }
    , position : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
    , linkCopied : Bool
    }


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V125.MailEditor.Model
    | AdminPage Evergreen.V125.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V125.LocalModel.LocalModel Evergreen.V125.Change.Change Evergreen.V125.LocalGrid.LocalGrid
    , pressedKeys : AssocSet.Set Evergreen.V125.Keyboard.Key
    , currentTool : Evergreen.V125.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V125.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , trains : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.TrainId Evergreen.V125.Train.Train
    , time : Effect.Time.Posix
    }


type LoginError
    = OneTimePasswordExpiredOrTooManyAttempts
    | WrongOneTimePassword (Evergreen.V125.Id.SecretId Evergreen.V125.Id.OneTimePasswordId)


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V125.LocalModel.LocalModel Evergreen.V125.Change.Change Evergreen.V125.LocalGrid.LocalGrid
    , trains : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.TrainId Evergreen.V125.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V125.Coord.RawCellCoord
            { foreground : Effect.WebGL.Mesh Evergreen.V125.Sprite.Vertex
            , background : Effect.WebGL.Mesh Evergreen.V125.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : AssocSet.Set Evergreen.V125.Keyboard.Key
    , windowSize : Evergreen.V125.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V125.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V125.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V125.Id.Id Evergreen.V125.Id.EventId, Evergreen.V125.Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Effect.Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V125.Tile.Tile
            , position : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V125.Sound.Sound (Result Evergreen.V125.Audio.LoadError Evergreen.V125.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : Effect.WebGL.Mesh Evergreen.V125.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V125.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V125.Ui.Element UiHover
    , uiMesh : Effect.WebGL.Mesh Evergreen.V125.Sprite.Vertex
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V125.Id.Id Evergreen.V125.Id.EventId
    , pingData : Maybe Evergreen.V125.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V125.Tile.TileGroup Evergreen.V125.Color.Colors
    , primaryColorTextInput : Evergreen.V125.TextInput.Model
    , secondaryColorTextInput : Evergreen.V125.TextInput.Model
    , previousFocus : Maybe UiHover
    , focus : Maybe UiHover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V125.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V125.IdDict.IdDict
            Evergreen.V125.Id.UserId
            { position : Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.UserId Evergreen.V125.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginEmailInput : Evergreen.V125.TextInput.Model
    , oneTimePasswordInput : Evergreen.V125.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V125.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V125.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V125.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit )
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : Maybe ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : Effect.WebGL.Mesh Evergreen.V125.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V125.Tile.Category
    , tileCategoryPageIndex : AssocList.Dict Evergreen.V125.Tile.Category Int
    , lastHotkeyChange : Maybe Time.Posix
    , loginError : Maybe LoginError
    , hyperlinkInput : Evergreen.V125.TextInputMultiline.Model
    , lastTrainUpdate : Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V125.Audio.Model FrontendMsg_ FrontendModel_


type alias HumanUserData =
    { emailAddress : Evergreen.V125.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.UserId ()
    , timeOfDay : Evergreen.V125.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V125.Change.TileHotkey Evergreen.V125.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    , allowEmailNotifications : Bool
    , hyperlinksVisited : Set.Set String
    }


type BackendUserType
    = HumanUser HumanUserData
    | BotUser


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V125.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V125.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V125.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.UserId (List Evergreen.V125.MailEditor.Content)
    , cursor : Maybe Evergreen.V125.Cursor.Cursor
    , handColor : Evergreen.V125.Color.Colors
    , userType : BackendUserType
    , name : Evergreen.V125.DisplayName.DisplayName
    }


type BackendError
    = PostmarkError Evergreen.V125.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)


type alias Person =
    { name : Evergreen.V125.PersonName.PersonName
    , home : Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit
    , position : Evergreen.V125.Point2d.Point2d Evergreen.V125.Units.WorldUnit Evergreen.V125.Units.WorldUnit
    }


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V125.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V125.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V125.Grid.Grid Evergreen.V125.GridCell.BackendHistory
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V125.Bounds.Bounds Evergreen.V125.Units.CellUnit))
            , userId : Maybe (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
            }
    , users : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.TrainId Evergreen.V125.Train.Train
    , animals : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.AnimalId Evergreen.V125.Animal.Animal
    , people : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.PersonId Person
    , lastWorldUpdateTrains : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.TrainId Evergreen.V125.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.MailId Evergreen.V125.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V125.Id.SecretId Evergreen.V125.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
            }
    , pendingOneTimePasswords :
        AssocList.Dict
            Effect.Lamdera.SessionId
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V125.Id.Id Evergreen.V125.Id.UserId
            , loginAttempts : Int
            , oneTimePassword : Evergreen.V125.Id.SecretId Evergreen.V125.Id.OneTimePasswordId
            }
    , invites : AssocList.Dict (Evergreen.V125.Id.SecretId Evergreen.V125.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.UserId (List.Nonempty.Nonempty Evergreen.V125.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V125.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    , tileCountBot : Maybe Evergreen.V125.TileCountBot.Model
    }


type alias FrontendMsg =
    Evergreen.V125.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V125.Bounds.Bounds Evergreen.V125.Units.CellUnit) (Maybe Evergreen.V125.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V125.Id.Id Evergreen.V125.Id.EventId, Evergreen.V125.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V125.Untrusted.Untrusted Evergreen.V125.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V125.Untrusted.Untrusted Evergreen.V125.EmailAddress.EmailAddress)
    | PostOfficePositionRequest
    | ResetTileBotRequest
    | LoginAttemptRequest (Evergreen.V125.Id.SecretId Evergreen.V125.Id.OneTimePasswordId)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.ClientId
    | SentLoginEmail Effect.Time.Posix Evergreen.V125.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V125.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V125.Id.SecretId Evergreen.V125.Route.InviteToken) (Result Effect.Http.Error Evergreen.V125.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V125.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V125.Postmark.PostmarkSendResponse)
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V125.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V125.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix
    | TileCountBotUpdate Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V125.Grid.GridData
    , userStatus : Evergreen.V125.Change.UserStatus
    , viewBounds : Evergreen.V125.Bounds.Bounds Evergreen.V125.Units.CellUnit
    , trains : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.TrainId Evergreen.V125.Train.Train
    , mail : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.MailId Evergreen.V125.MailEditor.FrontendMail
    , cows : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.AnimalId Evergreen.V125.Animal.Animal
    , cursors : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.UserId Evergreen.V125.Cursor.Cursor
    , users : Evergreen.V125.IdDict.IdDict Evergreen.V125.Id.UserId Evergreen.V125.User.FrontendUser
    , inviteTree : Evergreen.V125.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V125.Change.AreTrainsAndAnimalsDisabled
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V125.Change.Change)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V125.EmailAddress.EmailAddress
    | SendInviteEmailResponse Evergreen.V125.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V125.Coord.Coord Evergreen.V125.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
    | LoginAttemptResponse LoginError
