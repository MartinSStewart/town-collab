module Evergreen.V46.Types exposing (..)

import AssocList
import Browser
import Dict
import Duration
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Effect.Time
import Effect.WebGL.Texture
import Evergreen.V46.Audio
import Evergreen.V46.Bounds
import Evergreen.V46.Change
import Evergreen.V46.Color
import Evergreen.V46.Coord
import Evergreen.V46.Cursor
import Evergreen.V46.DisplayName
import Evergreen.V46.EmailAddress
import Evergreen.V46.Grid
import Evergreen.V46.Id
import Evergreen.V46.IdDict
import Evergreen.V46.Keyboard
import Evergreen.V46.LocalGrid
import Evergreen.V46.LocalModel
import Evergreen.V46.MailEditor
import Evergreen.V46.PingData
import Evergreen.V46.Point2d
import Evergreen.V46.Postmark
import Evergreen.V46.Route
import Evergreen.V46.Shaders
import Evergreen.V46.Sound
import Evergreen.V46.TextInput
import Evergreen.V46.Tile
import Evergreen.V46.Train
import Evergreen.V46.Units
import Evergreen.V46.Untrusted
import Evergreen.V46.User
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
    | KeyMsg Evergreen.V46.Keyboard.Msg
    | KeyDown Evergreen.V46.Keyboard.RawKey
    | WindowResized (Evergreen.V46.Coord.Coord Pixels.Pixels)
    | GotDevicePixelRatio Float
    | MouseDown Html.Events.Extra.Mouse.Button (Evergreen.V46.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseUp Html.Events.Extra.Mouse.Button (Evergreen.V46.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseMove (Evergreen.V46.Point2d.Point2d Pixels.Pixels Pixels.Pixels)
    | MouseWheel Html.Events.Extra.Wheel.Event
    | MouseLeave
    | ShortIntervalElapsed Effect.Time.Posix
    | ZoomFactorPressed Int
    | ToggleAdminEnabledPressed
    | AnimationFrame Effect.Time.Posix
    | SoundLoaded Evergreen.V46.Sound.Sound (Result Evergreen.V46.Audio.LoadError Evergreen.V46.Audio.Source)
    | VisibilityChanged
    | PastedText String
    | GotUserAgentPlatform String
    | LoadedUserSettings UserSettings


type alias LoadedLocalModel_ =
    { localModel : Evergreen.V46.LocalModel.LocalModel Evergreen.V46.Change.Change Evergreen.V46.LocalGrid.LocalGrid
    , trains : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.TrainId Evergreen.V46.Train.Train
    , mail : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.MailId Evergreen.V46.MailEditor.FrontendMail
    }


type LoadingLocalModel
    = LoadingLocalModel (List Evergreen.V46.Change.Change)
    | LoadedLocalModel LoadedLocalModel_


type alias FrontendLoading =
    { key : Effect.Browser.Navigation.Key
    , windowSize : Evergreen.V46.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Maybe Float
    , zoomFactor : Int
    , time : Maybe Effect.Time.Posix
    , viewPoint : Evergreen.V46.Coord.Coord Evergreen.V46.Units.WorldUnit
    , showInbox : Bool
    , mousePosition : Evergreen.V46.Point2d.Point2d Pixels.Pixels Pixels.Pixels
    , sounds : AssocList.Dict Evergreen.V46.Sound.Sound (Result Evergreen.V46.Audio.LoadError Evergreen.V46.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , texture : Maybe Effect.WebGL.Texture.Texture
    , localModel : LoadingLocalModel
    , hasCmdKey : Bool
    }


type ViewPoint
    = NormalViewPoint (Evergreen.V46.Point2d.Point2d Evergreen.V46.Units.WorldUnit Evergreen.V46.Units.WorldUnit)
    | TrainViewPoint
        { trainId : Evergreen.V46.Id.Id Evergreen.V46.Id.TrainId
        , startViewPoint : Evergreen.V46.Point2d.Point2d Evergreen.V46.Units.WorldUnit Evergreen.V46.Units.WorldUnit
        , startTime : Effect.Time.Posix
        }


type ToolButton
    = HandToolButton
    | TilePlacerToolButton Evergreen.V46.Tile.TileGroup
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
    | MailEditorHover Evergreen.V46.MailEditor.Hover
    | YouGotMailButton


type Hover
    = TileHover
        { tile : Evergreen.V46.Tile.Tile
        , userId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
        , position : Evergreen.V46.Coord.Coord Evergreen.V46.Units.WorldUnit
        , colors : Evergreen.V46.Color.Colors
        }
    | TrainHover
        { trainId : Evergreen.V46.Id.Id Evergreen.V46.Id.TrainId
        , train : Evergreen.V46.Train.Train
        }
    | MapHover
    | CowHover
        { cowId : Evergreen.V46.Id.Id Evergreen.V46.Id.CowId
        , cow : Evergreen.V46.Change.Cow
        }
    | UiBackgroundHover
    | UiHover
        UiHover
        { position : Evergreen.V46.Coord.Coord Pixels.Pixels
        }


type MouseButtonState
    = MouseButtonUp
        { current : Evergreen.V46.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        }
    | MouseButtonDown
        { start : Evergreen.V46.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , start_ : Evergreen.V46.Point2d.Point2d Evergreen.V46.Units.WorldUnit Evergreen.V46.Units.WorldUnit
        , current : Evergreen.V46.Point2d.Point2d Pixels.Pixels Pixels.Pixels
        , hover : Hover
        }


type alias RemovedTileParticle =
    { time : Effect.Time.Posix
    , position : Evergreen.V46.Coord.Coord Evergreen.V46.Units.WorldUnit
    , tile : Evergreen.V46.Tile.Tile
    , colors : Evergreen.V46.Color.Colors
    }


type Tool
    = HandTool
    | TilePlacerTool
        { tileGroup : Evergreen.V46.Tile.TileGroup
        , index : Int
        , mesh : WebGL.Mesh Evergreen.V46.Shaders.Vertex
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
    | SettingsMenu Evergreen.V46.TextInput.Model
    | LoggedOutSettingsMenu


type alias FrontendLoaded =
    { key : Effect.Browser.Navigation.Key
    , localModel : Evergreen.V46.LocalModel.LocalModel Evergreen.V46.Change.Change Evergreen.V46.LocalGrid.LocalGrid
    , trains : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.TrainId Evergreen.V46.Train.Train
    , meshes :
        Dict.Dict
            Evergreen.V46.Coord.RawCellCoord
            { foreground : WebGL.Mesh Evergreen.V46.Shaders.Vertex
            , background : WebGL.Mesh Evergreen.V46.Shaders.Vertex
            }
    , viewPoint : ViewPoint
    , viewPointLastInterval : Evergreen.V46.Point2d.Point2d Evergreen.V46.Units.WorldUnit Evergreen.V46.Units.WorldUnit
    , texture : Effect.WebGL.Texture.Texture
    , trainTexture : Maybe Effect.WebGL.Texture.Texture
    , pressedKeys : List Evergreen.V46.Keyboard.Key
    , windowSize : Evergreen.V46.Coord.Coord Pixels.Pixels
    , devicePixelRatio : Float
    , zoomFactor : Int
    , mouseLeft : MouseButtonState
    , mouseMiddle : MouseButtonState
    , pendingChanges : List ( Evergreen.V46.Id.Id Evergreen.V46.Id.EventId, Evergreen.V46.Change.LocalChange )
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
            , tile : Evergreen.V46.Tile.Tile
            , position : Evergreen.V46.Coord.Coord Evergreen.V46.Units.WorldUnit
            }
    , sounds : AssocList.Dict Evergreen.V46.Sound.Sound (Result Evergreen.V46.Audio.LoadError Evergreen.V46.Audio.Source)
    , musicVolume : Int
    , soundEffectVolume : Int
    , removedTileParticles : List RemovedTileParticle
    , debrisMesh : WebGL.Mesh Evergreen.V46.Shaders.DebrisVertex
    , lastTrainWhistle : Maybe Effect.Time.Posix
    , mailEditor : Maybe Evergreen.V46.MailEditor.Model
    , lastMailEditorToggle : Maybe Effect.Time.Posix
    , currentTool : Tool
    , lastTileRotation : List Effect.Time.Posix
    , lastPlacementError : Maybe Effect.Time.Posix
    , tileHotkeys : Dict.Dict String Evergreen.V46.Tile.TileGroup
    , uiMesh : WebGL.Mesh Evergreen.V46.Shaders.Vertex
    , previousTileHover : Maybe Evergreen.V46.Tile.TileGroup
    , lastHouseClick : Maybe Effect.Time.Posix
    , eventIdCounter : Evergreen.V46.Id.Id Evergreen.V46.Id.EventId
    , pingData : Maybe Evergreen.V46.PingData.PingData
    , pingStartTime : Maybe Effect.Time.Posix
    , localTime : Effect.Time.Posix
    , scrollThreshold : Float
    , tileColors : AssocList.Dict Evergreen.V46.Tile.TileGroup Evergreen.V46.Color.Colors
    , primaryColorTextInput : Evergreen.V46.TextInput.Model
    , secondaryColorTextInput : Evergreen.V46.TextInput.Model
    , focus : Hover
    , music :
        { startTime : Effect.Time.Posix
        , sound : Evergreen.V46.Sound.Sound
        }
    , previousCursorPositions :
        Evergreen.V46.IdDict.IdDict
            Evergreen.V46.Id.UserId
            { position : Evergreen.V46.Point2d.Point2d Evergreen.V46.Units.WorldUnit Evergreen.V46.Units.WorldUnit
            , time : Effect.Time.Posix
            }
    , handMeshes : AssocList.Dict Evergreen.V46.Color.Colors Evergreen.V46.Cursor.CursorMeshes
    , hasCmdKey : Bool
    , loginTextInput : Evergreen.V46.TextInput.Model
    , pressedSubmitEmail : SubmitStatus Evergreen.V46.EmailAddress.EmailAddress
    , topMenuOpened : Maybe TopMenu
    , inviteTextInput : Evergreen.V46.TextInput.Model
    , inviteSubmitStatus : SubmitStatus Evergreen.V46.EmailAddress.EmailAddress
    , railToggles : List ( Time.Posix, Evergreen.V46.Coord.Coord Evergreen.V46.Units.WorldUnit )
    , debugText : String
    , lastReceivedMail : Maybe Time.Posix
    }


type FrontendModel_
    = Loading FrontendLoading
    | Loaded FrontendLoaded


type alias FrontendModel =
    Evergreen.V46.Audio.Model FrontendMsg_ FrontendModel_


type alias BackendUserData =
    { undoHistory : List (Dict.Dict Evergreen.V46.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V46.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V46.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.UserId (List Evergreen.V46.MailEditor.Content)
    , cursor : Maybe Evergreen.V46.LocalGrid.Cursor
    , handColor : Evergreen.V46.Color.Colors
    , emailAddress : Evergreen.V46.EmailAddress.EmailAddress
    , acceptedInvites : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.UserId ()
    , name : Evergreen.V46.DisplayName.DisplayName
    , sendEmailWhenReceivingALetter : Bool
    }


type BackendError
    = PostmarkError Evergreen.V46.EmailAddress.EmailAddress Effect.Http.Error
    | UserNotFoundWhenLoggingIn (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)


type EmailResult
    = EmailSending
    | EmailSendFailed Effect.Http.Error
    | EmailSent Evergreen.V46.Postmark.PostmarkSendResponse


type alias Invite =
    { invitedBy : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , invitedAt : Time.Posix
    , invitedEmailAddress : Evergreen.V46.EmailAddress.EmailAddress
    , emailResult : EmailResult
    }


type alias BackendModel =
    { grid : Evergreen.V46.Grid.Grid
    , userSessions :
        Dict.Dict
            Lamdera.SessionId
            { clientIds : AssocList.Dict Effect.Lamdera.ClientId (Evergreen.V46.Bounds.Bounds Evergreen.V46.Units.CellUnit)
            , userId : Maybe (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
            }
    , users : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.UserId BackendUserData
    , secretLinkCounter : Int
    , errors : List ( Effect.Time.Posix, BackendError )
    , trains : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.TrainId Evergreen.V46.Train.Train
    , cows : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.CowId Evergreen.V46.Change.Cow
    , lastWorldUpdateTrains : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.TrainId Evergreen.V46.Train.Train
    , lastWorldUpdate : Maybe Effect.Time.Posix
    , mail : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.MailId Evergreen.V46.MailEditor.BackendMail
    , pendingLoginTokens :
        AssocList.Dict
            (Evergreen.V46.Id.SecretId Evergreen.V46.Route.LoginToken)
            { requestTime : Effect.Time.Posix
            , userId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
            , requestedBy : Effect.Lamdera.SessionId
            }
    , invites : AssocList.Dict (Evergreen.V46.Id.SecretId Evergreen.V46.Route.InviteToken) Invite
    , dummyField : Int
    }


type alias FrontendMsg =
    Evergreen.V46.Audio.Msg FrontendMsg_


type ToBackend
    = ConnectToBackend (Evergreen.V46.Bounds.Bounds Evergreen.V46.Units.CellUnit) (Maybe Evergreen.V46.Route.LoginOrInviteToken)
    | GridChange (List.Nonempty.Nonempty ( Evergreen.V46.Id.Id Evergreen.V46.Id.EventId, Evergreen.V46.Change.LocalChange ))
    | ChangeViewBounds (Evergreen.V46.Bounds.Bounds Evergreen.V46.Units.CellUnit)
    | PingRequest
    | SendLoginEmailRequest (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.EmailAddress.EmailAddress)
    | SendInviteEmailRequest (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.EmailAddress.EmailAddress)
    | PostOfficePositionRequest


type BackendMsg
    = UserDisconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NotifyAdminEmailSent
    | SentLoginEmail Effect.Time.Posix Evergreen.V46.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V46.Postmark.PostmarkSendResponse)
    | UpdateFromFrontend Effect.Lamdera.SessionId Effect.Lamdera.ClientId ToBackend Effect.Time.Posix
    | WorldUpdateTimeElapsed Effect.Time.Posix
    | SentInviteEmail (Evergreen.V46.Id.SecretId Evergreen.V46.Route.InviteToken) (Result Effect.Http.Error Evergreen.V46.Postmark.PostmarkSendResponse)


type alias LoadingData_ =
    { grid : Evergreen.V46.Grid.GridData
    , userStatus : Evergreen.V46.Change.UserStatus
    , viewBounds : Evergreen.V46.Bounds.Bounds Evergreen.V46.Units.CellUnit
    , trains : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.TrainId Evergreen.V46.Train.Train
    , mail : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.MailId Evergreen.V46.MailEditor.FrontendMail
    , cows : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.CowId Evergreen.V46.Change.Cow
    , cursors : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.UserId Evergreen.V46.LocalGrid.Cursor
    , users : Evergreen.V46.IdDict.IdDict Evergreen.V46.Id.UserId Evergreen.V46.User.FrontendUser
    }


type ToFrontend
    = LoadingData LoadingData_
    | ChangeBroadcast (List.Nonempty.Nonempty Evergreen.V46.Change.Change)
    | UnsubscribeEmailConfirmed
    | PingResponse Effect.Time.Posix
    | SendLoginEmailResponse Evergreen.V46.EmailAddress.EmailAddress
    | DebugResponse String
    | SendInviteEmailResponse Evergreen.V46.EmailAddress.EmailAddress
    | PostOfficePositionResponse (Maybe (Evergreen.V46.Coord.Coord Evergreen.V46.Units.WorldUnit))
