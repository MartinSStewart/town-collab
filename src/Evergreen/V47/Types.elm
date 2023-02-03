module Evergreen.V47.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V47.Audio
import Evergreen.V47.Bounds
import Evergreen.V47.Change
import Evergreen.V47.Color
import Evergreen.V47.Coord
import Evergreen.V47.Cursor
import Evergreen.V47.DisplayName
import Evergreen.V47.EmailAddress
import Evergreen.V47.Grid
import Evergreen.V47.Id
import Evergreen.V47.IdDict
import Evergreen.V47.Keyboard
import Evergreen.V47.LocalGrid
import Evergreen.V47.LocalModel
import Evergreen.V47.MailEditor
import Evergreen.V47.PingData
import Evergreen.V47.Point2d
import Evergreen.V47.Postmark
import Evergreen.V47.Route
import Evergreen.V47.Shaders
import Evergreen.V47.Sound
import Evergreen.V47.TextInput
import Evergreen.V47.Tile
import Evergreen.V47.Train
import Evergreen.V47.Units
import Evergreen.V47.Untrusted
import Evergreen.V47.User
import Html.Events.Extra.Mouse
import Html.Events.Extra.Wheel
import Lamdera
import List.Nonempty
import Pixels
import Time
import Url
import WebGL


type alias UserSettings =
    { musicVolume : Int
    , soundEffectVolume : Int
    }


type FrontendMsg_
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | NoOpFrontendMsg
    | TextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | TrainTextureLoaded (Result Effect.WebGL.Texture.Error Effect.WebGL.Texture.Texture)
    | KeyMsg Evergreen.V47.Keyboard.Msg
    | KeyDown Evergreen.V47.Keyboard.RawKey
    | WindowResized (Evergreen.V47.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V47.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V47.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V47.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V47.Sound.Sound (Result Evergreen.V47.Audio.LoadError Evergreen.V47.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V47.LocalModel.LocalModel Evergreen.V47.Change.Change Evergreen.V47.LocalGrid.LocalGrid
    , trains : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.TrainId Evergreen.V47.Train.Train
    , mail : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.MailId Evergreen.V47.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V47.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V47.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Maybe Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V47.Coord.Coord Evergreen.V47.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V47.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V47.Sound.Sound (Result Evergreen.V47.Audio.LoadError Evergreen.V47.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V47.Point2d.Point2d Evergreen.V47.Units.WorldUnit Evergreen.V47.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V47.Id.Id Evergreen.V47.Id.TrainId
        , startViewPoint : Evergreen.V47.Point2d.Point2d Evergreen.V47.Units.WorldUnit Evergreen.V47.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V47.Tile.TileGroup
    | TilePickerToolButton


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
    | MailEditorHover Evergreen.V47.MailEditor.Hover
    | YouGotMailButton


type Hover
    = TileHover
        { tile : Evergreen.V47.Tile.Tile
        , userId : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
        , position : Evergreen.V47.Coord.Coord Evergreen.V47.Units.WorldUnit
        , colors : Evergreen.V47.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V47.Id.Id Evergreen.V47.Id.TrainId
        , train : Evergreen.V47.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V47.Id.Id Evergreen.V47.Id.CowId
        , cow : Evergreen.V47.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V47.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V47.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V47.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V47.Point2d.Point2d Evergreen.V47.Units.WorldUnit Evergreen.V47.Units.WorldUnit
        , current : Evergreen.V47.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V47.Coord.Coord Evergreen.V47.Units.WorldUnit
    , tile : Evergreen.V47.Tile.Tile
    , colors : Evergreen.V47.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V47.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V47.Shaders.Vertex
        }
    | TilePickerTool


type SubmitStatus a
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | Submitting
    | Submitted a


type TopMenu
    = InviteMenu
    | SettingsMenu Evergreen.V47.TextInput.Model
    | LoggedOutSettingsMenu


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V47.LocalModel.LocalModel Evergreen.V47.Change.Change Evergreen.V47.LocalGrid.LocalGrid
    , trains : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.TrainId Evergreen.V47.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V47.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V47.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V47.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V47.Point2d.Point2d Evergreen.V47.Units.WorldUnit Evergreen.V47.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V47.Keyboard.Key
    , windowSize : Evergreen.V47.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V47.Id.Id Evergreen.V47.Id.EventId, Evergreen.V47.Change.LocalChange )
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
            , tile : Evergreen.V47.Tile.Tile
            , position : Evergreen.V47.Coord.Coord Evergreen.V47.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V47.Sound.Sound (Result Evergreen.V47.Audio.LoadError Evergreen.V47.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V47.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V47.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V47.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V47.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V47.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V47.Id.Id Evergreen.V47.Id.EventId
    , pingData : Maybe Evergreen.V47.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V47.Tile.TileGroup Evergreen.V47.Color.Colors
    , primaryColorTextInput : Evergreen.V47.TextInput.Model
    , secondaryColorTextInput : Evergreen.V47.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V47.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V47.IdDict.IdDict
            Evergreen.V47.Id.UserId
            { position : Evergreen.V47.Point2d.Point2d Evergreen.V47.Units.WorldUnit Evergreen.V47.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : AssocList.Dict Evergreen.V47.Color.Colors Evergreen.V47.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V47.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V47.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V47.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V47.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V47.Coord.Coord Evergreen.V47.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V47.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V47.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V47.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V47.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.UserId (List Evergreen.V47.MailEditor.Content)
    , cursor : Maybe Evergreen.V47.LocalGrid.Cursor
    , handColor : Evergreen.V47.Color.Colors
    , emailAddress : Evergreen.V47.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.UserId ()
    , name : Evergreen.V47.DisplayName.DisplayName
    , sendEmailWhenReceivingALetter : Bool
    }


type BackendError
    = PostmarkError Evergreen.V47.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V47.Id.Id Evergreen.V47.Id.UserId)


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V47.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V47.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V47.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V47.Bounds.Bounds Evergreen.V47.Units.CellUnit)
            , userId : Maybe (Evergreen.V47.Id.Id Evergreen.V47.Id.UserId)
            }
    , users : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.TrainId Evergreen.V47.Train.Train
    , cows : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.CowId Evergreen.V47.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.TrainId Evergreen.V47.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.MailId Evergreen.V47.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V47.Id.SecretId Evergreen.V47.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V47.Id.Id Evergreen.V47.Id.UserId
            , requestedBy : Effect.Lamdera.SessionId
            }
    , invites : AssocList.Dict (Evergreen.V47.Id.SecretId Evergreen.V47.Route.InviteToken) Invite
    }


type alias FrontendMsg =
    Evergreen.V47.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V47.Bounds.Bounds Evergreen.V47.Units.CellUnit) (Maybe Evergreen.V47.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V47.Id.Id Evergreen.V47.Id.EventId, Evergreen.V47.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V47.Bounds.Bounds Evergreen.V47.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V47.Untrusted.Untrusted Evergreen.V47.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V47.Untrusted.Untrusted Evergreen.V47.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V47.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V47.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V47.Id.SecretId Evergreen.V47.Route.InviteToken) (Result Effect.Http.Error Evergreen.V47.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V47.Grid.GridData
    , userStatus : Evergreen.V47.Change.UserStatus
    , viewBounds : Evergreen.V47.Bounds.Bounds Evergreen.V47.Units.CellUnit
    , trains : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.TrainId Evergreen.V47.Train.Train
    , mail : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.MailId Evergreen.V47.MailEditor.FrontendMail
    , cows : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.CowId Evergreen.V47.Change.Cow
    , cursors : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.UserId Evergreen.V47.LocalGrid.Cursor
    , users : Evergreen.V47.IdDict.IdDict Evergreen.V47.Id.UserId Evergreen.V47.User.FrontendUser
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V47.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V47.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V47.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V47.Coord.Coord Evergreen.V47.Units.WorldUnit))
