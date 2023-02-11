module Evergreen.V58.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V58.Audio
import Evergreen.V58.Bounds
import Evergreen.V58.Change
import Evergreen.V58.Color
import Evergreen.V58.Coord
import Evergreen.V58.Cursor
import Evergreen.V58.DisplayName
import Evergreen.V58.EmailAddress
import Evergreen.V58.Grid
import Evergreen.V58.Id
import Evergreen.V58.IdDict
import Evergreen.V58.Keyboard
import Evergreen.V58.LocalGrid
import Evergreen.V58.LocalModel
import Evergreen.V58.MailEditor
import Evergreen.V58.PingData
import Evergreen.V58.Point2d
import Evergreen.V58.Postmark
import Evergreen.V58.Route
import Evergreen.V58.Shaders
import Evergreen.V58.Sound
import Evergreen.V58.TextInput
import Evergreen.V58.Tile
import Evergreen.V58.Train
import Evergreen.V58.Units
import Evergreen.V58.Untrusted
import Evergreen.V58.User
import Html.Events.Extra.Mouse
import Html.Events.Extra.Wheel
import Lamdera
import List.Nonempty
import Pixels
import Quantity
import Time
import Url
import WebGL


type CssPixel
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
    | SimplexLookupTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | KeyMsg Evergreen.V58.Keyboard.Msg
    | KeyDown Evergreen.V58.Keyboard.RawKey
    | WindowResized (Evergreen.V58.Coord.Coord CssPixel)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V58.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V58.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V58.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V58.Sound.Sound (Result Evergreen.V58.Audio.LoadError Evergreen.V58.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V58.LocalModel.LocalModel Evergreen.V58.Change.Change Evergreen.V58.LocalGrid.LocalGrid
    , trains : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.TrainId Evergreen.V58.Train.Train
    , mail : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.MailId Evergreen.V58.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V58.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V58.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V58.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V58.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V58.Coord.Coord Evergreen.V58.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V58.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V58.Sound.Sound (Result Evergreen.V58.Audio.LoadError Evergreen.V58.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V58.Point2d.Point2d Evergreen.V58.Units.WorldUnit Evergreen.V58.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V58.Id.Id Evergreen.V58.Id.TrainId
        , startViewPoint : Evergreen.V58.Point2d.Point2d Evergreen.V58.Units.WorldUnit Evergreen.V58.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V58.Tile.TileGroup
    | TilePickerToolButton
    | TextToolButton


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
    | MailEditorHover Evergreen.V58.MailEditor.Hover
    | YouGotMailButton
    | ShowMapButton
    | AllowEmailNotificationsCheckbox


type Hover
    = TileHover
        { tile : Evergreen.V58.Tile.Tile
        , userId : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
        , position : Evergreen.V58.Coord.Coord Evergreen.V58.Units.WorldUnit
        , colors : Evergreen.V58.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V58.Id.Id Evergreen.V58.Id.TrainId
        , train : Evergreen.V58.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V58.Id.Id Evergreen.V58.Id.CowId
        , cow : Evergreen.V58.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V58.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V58.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V58.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V58.Point2d.Point2d Evergreen.V58.Units.WorldUnit Evergreen.V58.Units.WorldUnit
        , current : Evergreen.V58.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V58.Coord.Coord Evergreen.V58.Units.WorldUnit
    , tile : Evergreen.V58.Tile.Tile
    , colors : Evergreen.V58.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V58.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V58.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V58.Coord.Coord Evergreen.V58.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V58.Units.WorldUnit
            }
        )


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = InviteMenu
    | SettingsMenu Evergreen.V58.TextInput.Model
    | LoggedOutSettingsMenu


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V58.LocalModel.LocalModel Evergreen.V58.Change.Change Evergreen.V58.LocalGrid.LocalGrid
    , trains : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.TrainId Evergreen.V58.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V58.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V58.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V58.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V58.Point2d.Point2d Evergreen.V58.Units.WorldUnit Evergreen.V58.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V58.Keyboard.Key
    , windowSize : Evergreen.V58.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V58.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V58.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V58.Id.Id Evergreen.V58.Id.EventId, Evergreen.V58.Change.LocalChange )
    , undoAddLast : Effect.Time.Posix
    , time : Effect.Time.Posix
    , startTime : Effect.Time.Posix
    , adminEnabled : Bool
    , animationElapsedTime : Duration.Duration
    , ignoreNextUrlChanged : Bool
    , lastTilePlaced :
        Maybe
            { time : Effect.Time.Posix
            , overwroteTiles : Bool
            , tile : Evergreen.V58.Tile.Tile
            , position : Evergreen.V58.Coord.Coord Evergreen.V58.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V58.Sound.Sound (Result Evergreen.V58.Audio.LoadError Evergreen.V58.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V58.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V58.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V58.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V58.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V58.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V58.Id.Id Evergreen.V58.Id.EventId
    , pingData : Maybe Evergreen.V58.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V58.Tile.TileGroup Evergreen.V58.Color.Colors
    , primaryColorTextInput : Evergreen.V58.TextInput.Model
    , secondaryColorTextInput : Evergreen.V58.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V58.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V58.IdDict.IdDict
            Evergreen.V58.Id.UserId
            { position : Evergreen.V58.Point2d.Point2d Evergreen.V58.Units.WorldUnit Evergreen.V58.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.UserId Evergreen.V58.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V58.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V58.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V58.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V58.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V58.Coord.Coord Evergreen.V58.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    , isReconnecting : Bool
    , lastCheckConnection : Time.Posix
    , showMap : Bool
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V58.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V58.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V58.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V58.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.UserId (List Evergreen.V58.MailEditor.Content)
    , cursor : Maybe Evergreen.V58.Cursor.Cursor
    , handColor : Evergreen.V58.Color.Colors
    , emailAddress : Evergreen.V58.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.UserId ()
    , name : Evergreen.V58.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V58.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V58.Id.Id Evergreen.V58.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V58.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V58.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V58.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V58.Bounds.Bounds Evergreen.V58.Units.CellUnit)
            , userId : Maybe (Evergreen.V58.Id.Id Evergreen.V58.Id.UserId)
            }
    , users : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.TrainId Evergreen.V58.Train.Train
    , cows : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.CowId Evergreen.V58.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.TrainId Evergreen.V58.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.MailId Evergreen.V58.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V58.Id.SecretId Evergreen.V58.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V58.Id.Id Evergreen.V58.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V58.Id.SecretId Evergreen.V58.Route.InviteToken) Invite
    }


type alias FrontendMsg =
    Evergreen.V58.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V58.Bounds.Bounds Evergreen.V58.Units.CellUnit) (Maybe Evergreen.V58.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V58.Id.Id Evergreen.V58.Id.EventId, Evergreen.V58.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V58.Bounds.Bounds Evergreen.V58.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V58.Untrusted.Untrusted Evergreen.V58.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V58.Untrusted.Untrusted Evergreen.V58.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V58.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V58.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V58.Id.SecretId Evergreen.V58.Route.InviteToken) (Result Effect.Http.Error Evergreen.V58.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V58.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V58.Postmark.PostmarkSendResponse)
    | RegenerateCache


type alias LoadingData_ =
    { grid : Evergreen.V58.Grid.GridData
    , userStatus : Evergreen.V58.Change.UserStatus
    , viewBounds : Evergreen.V58.Bounds.Bounds Evergreen.V58.Units.CellUnit
    , trains : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.TrainId Evergreen.V58.Train.Train
    , mail : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.MailId Evergreen.V58.MailEditor.FrontendMail
    , cows : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.CowId Evergreen.V58.Change.Cow
    , cursors : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.UserId Evergreen.V58.Cursor.Cursor
    , users : Evergreen.V58.IdDict.IdDict Evergreen.V58.Id.UserId Evergreen.V58.User.FrontendUser
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V58.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V58.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V58.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V58.Coord.Coord Evergreen.V58.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
