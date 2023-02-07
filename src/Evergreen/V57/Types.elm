module Evergreen.V57.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V57.Audio
import Evergreen.V57.Bounds
import Evergreen.V57.Change
import Evergreen.V57.Color
import Evergreen.V57.Coord
import Evergreen.V57.Cursor
import Evergreen.V57.DisplayName
import Evergreen.V57.EmailAddress
import Evergreen.V57.Grid
import Evergreen.V57.Id
import Evergreen.V57.IdDict
import Evergreen.V57.Keyboard
import Evergreen.V57.LocalGrid
import Evergreen.V57.LocalModel
import Evergreen.V57.MailEditor
import Evergreen.V57.PingData
import Evergreen.V57.Point2d
import Evergreen.V57.Postmark
import Evergreen.V57.Route
import Evergreen.V57.Shaders
import Evergreen.V57.Sound
import Evergreen.V57.TextInput
import Evergreen.V57.Tile
import Evergreen.V57.Train
import Evergreen.V57.Units
import Evergreen.V57.Untrusted
import Evergreen.V57.User
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
    | KeyMsg Evergreen.V57.Keyboard.Msg
    | KeyDown Evergreen.V57.Keyboard.RawKey
    | WindowResized (Evergreen.V57.Coord.Coord CssPixel)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V57.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V57.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V57.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V57.Sound.Sound (Result Evergreen.V57.Audio.LoadError Evergreen.V57.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V57.LocalModel.LocalModel Evergreen.V57.Change.Change Evergreen.V57.LocalGrid.LocalGrid
    , trains : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.TrainId Evergreen.V57.Train.Train
    , mail : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.MailId Evergreen.V57.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V57.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V57.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V57.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V57.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V57.Coord.Coord Evergreen.V57.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V57.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V57.Sound.Sound (Result Evergreen.V57.Audio.LoadError Evergreen.V57.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V57.Point2d.Point2d Evergreen.V57.Units.WorldUnit Evergreen.V57.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V57.Id.Id Evergreen.V57.Id.TrainId
        , startViewPoint : Evergreen.V57.Point2d.Point2d Evergreen.V57.Units.WorldUnit Evergreen.V57.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V57.Tile.TileGroup
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
    | MailEditorHover Evergreen.V57.MailEditor.Hover
    | YouGotMailButton
    | ShowMapButton
    | AllowEmailNotificationsCheckbox


type Hover
    = TileHover
        { tile : Evergreen.V57.Tile.Tile
        , userId : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
        , position : Evergreen.V57.Coord.Coord Evergreen.V57.Units.WorldUnit
        , colors : Evergreen.V57.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V57.Id.Id Evergreen.V57.Id.TrainId
        , train : Evergreen.V57.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V57.Id.Id Evergreen.V57.Id.CowId
        , cow : Evergreen.V57.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V57.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V57.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V57.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V57.Point2d.Point2d Evergreen.V57.Units.WorldUnit Evergreen.V57.Units.WorldUnit
        , current : Evergreen.V57.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V57.Coord.Coord Evergreen.V57.Units.WorldUnit
    , tile : Evergreen.V57.Tile.Tile
    , colors : Evergreen.V57.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V57.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V57.Shaders.Vertex
        }
    | TilePickerTool
    | TextTool
        (Maybe
            { cursorPosition : Evergreen.V57.Coord.Coord Evergreen.V57.Units.WorldUnit
            , startColumn : Quantity.Quantity Int Evergreen.V57.Units.WorldUnit
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
    | SettingsMenu Evergreen.V57.TextInput.Model
    | LoggedOutSettingsMenu


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V57.LocalModel.LocalModel Evergreen.V57.Change.Change Evergreen.V57.LocalGrid.LocalGrid
    , trains : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.TrainId Evergreen.V57.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V57.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V57.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V57.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V57.Point2d.Point2d Evergreen.V57.Units.WorldUnit Evergreen.V57.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , simplexNoiseLookup : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V57.Keyboard.Key
    , windowSize : Evergreen.V57.Coord.Coord Pixels.Pixels
    , cssWindowSize : Evergreen.V57.Coord.Coord CssPixel
    , cssCanvasSize : Evergreen.V57.Coord.Coord CssPixel
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V57.Id.Id Evergreen.V57.Id.EventId, Evergreen.V57.Change.LocalChange )
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
            , tile : Evergreen.V57.Tile.Tile
            , position : Evergreen.V57.Coord.Coord Evergreen.V57.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V57.Sound.Sound (Result Evergreen.V57.Audio.LoadError Evergreen.V57.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V57.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V57.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V57.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V57.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V57.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V57.Id.Id Evergreen.V57.Id.EventId
    , pingData : Maybe Evergreen.V57.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V57.Tile.TileGroup Evergreen.V57.Color.Colors
    , primaryColorTextInput : Evergreen.V57.TextInput.Model
    , secondaryColorTextInput : Evergreen.V57.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V57.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V57.IdDict.IdDict
            Evergreen.V57.Id.UserId
            { position : Evergreen.V57.Point2d.Point2d Evergreen.V57.Units.WorldUnit Evergreen.V57.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.UserId Evergreen.V57.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V57.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V57.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V57.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V57.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V57.Coord.Coord Evergreen.V57.Units.WorldUnit )
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
    Evergreen.V57.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V57.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V57.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V57.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.UserId (List Evergreen.V57.MailEditor.Content)
    , cursor : Maybe Evergreen.V57.Cursor.Cursor
    , handColor : Evergreen.V57.Color.Colors
    , emailAddress : Evergreen.V57.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.UserId ()
    , name : Evergreen.V57.DisplayName.DisplayName
    , allowEmailNotifications : Bool
    }


type BackendError
    = PostmarkError Evergreen.V57.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V57.Id.Id Evergreen.V57.Id.UserId)


type LoginRequestedBy
    = LoginRequestedByBackend
    | LoginRequestedByFrontend Effect.Lamdera.SessionId


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V57.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V57.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V57.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V57.Bounds.Bounds Evergreen.V57.Units.CellUnit)
            , userId : Maybe (Evergreen.V57.Id.Id Evergreen.V57.Id.UserId)
            }
    , users : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.TrainId Evergreen.V57.Train.Train
    , cows : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.CowId Evergreen.V57.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.TrainId Evergreen.V57.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.MailId Evergreen.V57.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V57.Id.SecretId Evergreen.V57.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V57.Id.Id Evergreen.V57.Id.UserId
            , requestedBy : LoginRequestedBy
            }
    , invites : AssocList.Dict (Evergreen.V57.Id.SecretId Evergreen.V57.Route.InviteToken) Invite
    }


type alias FrontendMsg =
    Evergreen.V57.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V57.Bounds.Bounds Evergreen.V57.Units.CellUnit) (Maybe Evergreen.V57.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V57.Id.Id Evergreen.V57.Id.EventId, Evergreen.V57.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V57.Bounds.Bounds Evergreen.V57.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V57.Untrusted.Untrusted Evergreen.V57.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V57.Untrusted.Untrusted Evergreen.V57.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | UserConnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V57.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V57.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V57.Id.SecretId Evergreen.V57.Route.InviteToken) (Result Effect.Http.Error Evergreen.V57.Postmark.PostmarkSendResponse)
    | CheckConnectionTimeElapsed
    | SentMailNotification Effect.Time.Posix Evergreen.V57.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V57.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V57.Grid.GridData
    , userStatus : Evergreen.V57.Change.UserStatus
    , viewBounds : Evergreen.V57.Bounds.Bounds Evergreen.V57.Units.CellUnit
    , trains : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.TrainId Evergreen.V57.Train.Train
    , mail : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.MailId Evergreen.V57.MailEditor.FrontendMail
    , cows : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.CowId Evergreen.V57.Change.Cow
    , cursors : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.UserId Evergreen.V57.Cursor.Cursor
    , users : Evergreen.V57.IdDict.IdDict Evergreen.V57.Id.UserId Evergreen.V57.User.FrontendUser
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V57.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V57.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V57.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V57.Coord.Coord Evergreen.V57.Units.WorldUnit))
    | ClientConnected
    | CheckConnectionBroadcast
