module Evergreen.V126.Types exposing (..)

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
import Evergreen.V126.AdminPage
import Evergreen.V126.Animal
import Evergreen.V126.Audio
import Evergreen.V126.Bounds
import Evergreen.V126.Change
import Evergreen.V126.Color
import Evergreen.V126.Coord
import Evergreen.V126.Cursor
import Evergreen.V126.DisplayName
import Evergreen.V126.EmailAddress
import Evergreen.V126.Grid
import Evergreen.V126.GridCell
import Evergreen.V126.Id
import Evergreen.V126.IdDict
import Evergreen.V126.Keyboard
import Evergreen.V126.Local
import Evergreen.V126.LocalGrid
import Evergreen.V126.MailEditor
import Evergreen.V126.Npc
import Evergreen.V126.PingData
import Evergreen.V126.Point2d
import Evergreen.V126.Postmark
import Evergreen.V126.Route
import Evergreen.V126.Shaders
import Evergreen.V126.Sound
import Evergreen.V126.Sprite
import Evergreen.V126.TextInput
import Evergreen.V126.TextInputMultiline
import Evergreen.V126.Tile
import Evergreen.V126.TileCountBot
import Evergreen.V126.TimeOfDay
import Evergreen.V126.Tool
import Evergreen.V126.Train
import Evergreen.V126.Ui
import Evergreen.V126.Units
import Evergreen.V126.Untrusted
import Evergreen.V126.User
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
    | KeyUp Evergreen.V126.Keyboard.RawKey
    | KeyDown Evergreen.V126.Keyboard.RawKey
    | WindowResized (Evergreen.V126.Coord.Coord CssPixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V126.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V126.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V126.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel
        { deltaY : Float
        , deltaMode : Html.Events.Extra.Wheel.DeltaMode
        }
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V126.Sound.Sound (Result Evergreen.V126.Audio.LoadError Evergreen.V126.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings
    | ImportedMail Effect.File.File
    | ImportedMail2 (Result () (List Evergreen.V126.MailEditor.Content))


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V126.Local.Local Evergreen.V126.Change.Change Evergreen.V126.LocalGrid.LocalGrid
    , trains : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.TrainId Evergreen.V126.Train.Train
    , mail : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.MailId Evergreen.V126.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V126.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V126.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V126.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V126.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
    , route : Evergreen.V126.Route.PageRoute
    , mousePosition : Evergreen.V126.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V126.Sound.Sound (Result Evergreen.V126.Audio.LoadError Evergreen.V126.Audio.Source)
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
    = NormalViewPoint (Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V126.Id.Id Evergreen.V126.Id.TrainId
        , startViewPoint : Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V126.Tile.TileGroup
    | TilePickerToolButton
    | TextToolButton
    | ReportToolButton


type UiId
    = EmailAddressTextInput
    | SendEmailButton
    | ToolButton ToolButton
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
    | MailEditorUi Evergreen.V126.MailEditor.Hover
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
    | AdminUi Evergreen.V126.AdminPage.Hover
    | CategoryButton Evergreen.V126.Tile.Category
    | NotificationsButton
    | CloseNotifications
    | MapChangeNotification (Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit)
    | ShowInviteTreeButton
    | CloseInviteTreeButton
    | LogoutButton
    | ClearNotificationsButton
    | OneTimePasswordInput
    | HyperlinkInput
    | CategoryNextPageButton
    | CategoryPreviousPageButton
    | TileContainer
    | WorldContainer
    | BlockInputContainer
    | NpcContextMenuInput
    | AnimalContextMenuInput


type Hover
    = TileHover
        { tile : Evergreen.V126.Tile.Tile
        , userId : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
        , position : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
        , colors : Evergreen.V126.Color.Colors
        , time : Effect.Time.Posix
        }
    | TrainHover
        { trainId : Evergreen.V126.Id.Id Evergreen.V126.Id.TrainId
        , train : Evergreen.V126.Train.Train
        }
    | MapHover
    | AnimalHover
        { animalId : Evergreen.V126.Id.Id Evergreen.V126.Id.AnimalId
        , animal : Evergreen.V126.Animal.Animal
        }
    | NpcHover
        { npcId : Evergreen.V126.Id.Id Evergreen.V126.Id.NpcId
        , npc : Evergreen.V126.Npc.Npc
        }
    | UiHover
        (List
            ( UiId
            , { relativePositionToUi : Evergreen.V126.Coord.Coord Pixels.Pixels
              , ui : Evergreen.V126.Ui.Element UiId
              }
            )
        )


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V126.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V126.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit
        , current : Evergreen.V126.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
    , tile : Evergreen.V126.Tile.Tile
    , colors : Evergreen.V126.Color.Colors
    }


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = SettingsMenu Evergreen.V126.TextInput.Model
    | LoggedOutSettingsMenu


type alias MapContextMenuData =
    { change :
        Maybe
            { userId : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
            , tile : Evergreen.V126.Tile.Tile
            , position : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
            , colors : Evergreen.V126.Color.Colors
            , time : Effect.Time.Posix
            }
    , position : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
    , linkCopied : Bool
    }


type ContextMenu
    = MapContextMenu MapContextMenuData
    | NpcContextMenu
        { npcId : Evergreen.V126.Id.Id Evergreen.V126.Id.NpcId
        , openedAt : Evergreen.V126.Coord.Coord Pixels.Pixels
        , nameInput : Evergreen.V126.TextInput.Model
        }
    | AnimalContextMenu
        { animalId : Evergreen.V126.Id.Id Evergreen.V126.Id.AnimalId
        , openedAt : Evergreen.V126.Coord.Coord Pixels.Pixels
        , nameInput : Evergreen.V126.TextInput.Model
        }
    | NoContextMenu


type alias WorldPage2 =
    { showMap : Bool
    , showInvite : Bool
    }


type Page
    = MailPage Evergreen.V126.MailEditor.Model
    | AdminPage Evergreen.V126.AdminPage.Model
    | WorldPage WorldPage2
    | InviteTreePage


type alias UpdateMeshesData =
    { localModel : Evergreen.V126.Local.Local Evergreen.V126.Change.Change Evergreen.V126.LocalGrid.LocalGrid
    , pressedKeys : AssocSet.Set Evergreen.V126.Keyboard.Key
    , currentTool : Evergreen.V126.Tool.Tool
    , mouseLeft : MouseButtonState
    , windowSize : Evergreen.V126.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , page : Page
    , mouseMiddle : MouseButtonState
    , viewPoint : ViewPoint
    , time : Effect.Time.Posix
    }


type LoginError
    = OneTimePasswordExpiredOrTooManyAttempts
    | WrongOneTimePassword (Evergreen.V126.Id.SecretId Evergreen.V126.Id.OneTimePasswordId)


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V126.Local.Local Evergreen.V126.Change.Change Evergreen.V126.LocalGrid.LocalGrid
    , meshes :
        Dict.Dict
            Evergreen.V126.Coord.RawCellCoord
            { foreground : Effect.WebGL.Mesh Evergreen.V126.Sprite.Vertex
            , background : Effect.WebGL.Mesh Evergreen.V126.Sprite.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , lightsTexture : Effect.WebGL.Texture.Texture
    , depthTexture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , trainLightsTexture : Maybe Effect.WebGL.Texture.Texture
    , trainDepthTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : AssocSet.Set Evergreen.V126.Keyboard.Key
    , windowSize : Evergreen.V126.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V126.Coord.Coord CssPixels
    , cssCanvasSize : Evergreen.V126.Coord.Coord CssPixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V126.Id.Id Evergreen.V126.Id.EventId, Evergreen.V126.Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Effect.Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V126.Tile.Tile
            , position : Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V126.Sound.Sound (Result Evergreen.V126.Audio.LoadError Evergreen.V126.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : Effect.WebGL.Mesh Evergreen.V126.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Evergreen.V126.Tool.Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , ui : Evergreen.V126.Ui.Element UiId
    , uiMesh : Effect.WebGL.Mesh Evergreen.V126.Sprite.Vertex
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V126.Id.Id Evergreen.V126.Id.EventId
    , pingData : Maybe Evergreen.V126.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V126.Tile.TileGroup Evergreen.V126.Color.Colors
    , primaryColorTextInput : Evergreen.V126.TextInput.Model
    , secondaryColorTextInput : Evergreen.V126.TextInput.Model
    , previousFocus : Maybe UiId
    , focus : Maybe UiId
    , previousHover : Maybe UiId
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V126.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V126.IdDict.IdDict
            Evergreen.V126.Id.UserId
            { position : Evergreen.V126.Point2d.Point2d Evergreen.V126.Units.WorldUnit Evergreen.V126.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.UserId Evergreen.V126.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginEmailInput : Evergreen.V126.TextInput.Model
    , oneTimePasswordInput : Evergreen.V126.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V126.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V126.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V126.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit )
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showOnlineUsers : Bool
    , contextMenu : ContextMenu
    , previousUpdateMeshData : UpdateMeshesData
    , reportsMesh : Effect.WebGL.Mesh Evergreen.V126.Sprite.Vertex
    , lastReportTilePlaced : Maybe Effect.Time.Posix
    , lastReportTileRemoved : Maybe Effect.Time.Posix
    , hideUi : Bool
    , lightsSwitched : Maybe Time.Posix
    , page : Page
    , selectedTileCategory : Evergreen.V126.Tile.Category
    , tileCategoryPageIndex : AssocList.Dict Evergreen.V126.Tile.Category Int
    , lastHotkeyChange : Maybe Time.Posix
    , loginError : Maybe LoginError
    , hyperlinkInput : Evergreen.V126.TextInputMultiline.Model
    , lastTrainUpdate : Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V126.Audio.Model FrontendMsg_ FrontendModel_


type alias HumanUserData =
    { emailAddress : Evergreen.V126.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.UserId ()
    , timeOfDay : Evergreen.V126.TimeOfDay.TimeOfDay
    , tileHotkeys : AssocList.Dict Evergreen.V126.Change.TileHotkey Evergreen.V126.Tile.TileGroup
    , showNotifications : Bool
    , notificationsClearedAt : Effect.Time.Posix
    , allowEmailNotifications : Bool
    , hyperlinksVisited : Set.Set String
    }


type BackendUserType
    = HumanUser HumanUserData
    | BotUser


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V126.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V126.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V126.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.UserId (List Evergreen.V126.MailEditor.Content)
    , cursor : Maybe Evergreen.V126.Cursor.Cursor
    , handColor : Evergreen.V126.Color.Colors
    , userType : BackendUserType
    , name : Evergreen.V126.DisplayName.DisplayName
    }


type BackendError
    = PostmarkError Evergreen.V126.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V126.Id.Id Evergreen.V126.Id.UserId)


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V126.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V126.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V126.Grid.Grid Evergreen.V126.GridCell.BackendHistory
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (List (Evergreen.V126.Bounds.Bounds Evergreen.V126.Units.CellUnit))
            , userId : Maybe (Evergreen.V126.Id.Id Evergreen.V126.Id.UserId)
            }
    , users : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.TrainId Evergreen.V126.Train.Train
    , animals : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.AnimalId Evergreen.V126.Animal.Animal
    , npcs : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.NpcId Evergreen.V126.Npc.Npc
    , lastWorldUpdateTrains : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.TrainId Evergreen.V126.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.MailId Evergreen.V126.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V126.Id.SecretId Evergreen.V126.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
            }
    , pendingOneTimePasswords :
        AssocList.Dict
            Effect.Lamdera.SessionId
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V126.Id.Id Evergreen.V126.Id.UserId
            , loginAttempts : Int
            , oneTimePassword : Evergreen.V126.Id.SecretId Evergreen.V126.Id.OneTimePasswordId
            }
    , invites : AssocList.Dict (Evergreen.V126.Id.SecretId Evergreen.V126.Route.InviteToken) Invite
    , lastCacheRegeneration : Maybe Effect.Time.Posix
    , reported : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.UserId (List.Nonempty.Nonempty Evergreen.V126.Change.BackendReport)
    , isGridReadOnly : Bool
    , trainsAndAnimalsDisabled : Evergreen.V126.Change.AreTrainsAndAnimalsDisabled
    , lastReportEmailToAdmin : Maybe Effect.Time.Posix
    , worldUpdateDurations : Array.Array Duration.Duration
    , tileCountBot : Maybe Evergreen.V126.TileCountBot.Model
    }


type alias FrontendMsg =
    Evergreen.V126.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V126.Bounds.Bounds Evergreen.V126.Units.CellUnit) (Maybe Evergreen.V126.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V126.Id.Id Evergreen.V126.Id.EventId, Evergreen.V126.Change.LocalChange ))
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V126.Untrusted.Untrusted Evergreen.V126.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V126.Untrusted.Untrusted Evergreen.V126.EmailAddress.EmailAddress)
    | PostOfficePositionRequest
    | ResetTileBotRequest
    | LoginAttemptRequest (Evergreen.V126.Id.SecretId Evergreen.V126.Id.OneTimePasswordId)


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.ClientId
    | SentLoginEmail Effect.Time.Posix Evergreen.V126.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V126.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V126.Id.SecretId Evergreen.V126.Route.InviteToken) (Result Effect.Http.Error Evergreen.V126.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V126.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V126.Postmark.PostmarkSendResponse)
    | SentReportVandalismAdminEmail Effect.Time.Posix Evergreen.V126.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V126.Postmark.PostmarkSendResponse)
    | GotTimeAfterWorldUpdate Effect.Time.Posix Effect.Time.Posix
    | TileCountBotUpdate Effect.Time.Posix


type alias LoadingData_ =
    { grid : Evergreen.V126.Grid.GridData
    , userStatus : Evergreen.V126.Change.UserStatus
    , viewBounds : Evergreen.V126.Bounds.Bounds Evergreen.V126.Units.CellUnit
    , trains : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.TrainId Evergreen.V126.Train.Train
    , mail : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.MailId Evergreen.V126.MailEditor.FrontendMail
    , animals : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.AnimalId Evergreen.V126.Animal.Animal
    , cursors : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.UserId Evergreen.V126.Cursor.Cursor
    , users : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.UserId Evergreen.V126.User.FrontendUser
    , inviteTree : Evergreen.V126.User.InviteTree
    , isGridReadOnly : Bool
    , trainsDisabled : Evergreen.V126.Change.AreTrainsAndAnimalsDisabled
    , npcs : Evergreen.V126.IdDict.IdDict Evergreen.V126.Id.NpcId Evergreen.V126.Npc.Npc
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V126.Change.Change)
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V126.EmailAddress.EmailAddress
    | SendInviteEmailResponse Evergreen.V126.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V126.Coord.Coord Evergreen.V126.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
    | LoginAttemptResponse LoginError
