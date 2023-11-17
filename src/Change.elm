module Change exposing
    ( AdminChange(..)
    , AdminData
    , AreTrainsAndAnimalsDisabled(..)
    , BackendReport
    , Change(..)
    , LocalChange(..)
    , LoggedIn_
    , MovementChange
    , NotLoggedIn_
    , Report
    , ServerChange(..)
    , TileHotkey(..)
    , UserStatus(..)
    , ViewBoundsChange2
    , tileHotkeyDict
    )

import Animal exposing (Animal)
import Array exposing (Array)
import AssocList
import Bounds exposing (Bounds)
import Color exposing (Colors)
import Coord exposing (Coord, RawCellCoord)
import Cursor
import Dict exposing (Dict)
import DisplayName exposing (DisplayName)
import Duration exposing (Duration)
import Effect.Time
import EmailAddress exposing (EmailAddress)
import Grid
import GridCell
import Hyperlink exposing (Hyperlink)
import Id exposing (AnimalId, EventId, Id, MailId, TrainId, UserId)
import IdDict exposing (IdDict)
import List.Nonempty exposing (Nonempty)
import MailEditor exposing (BackendMail, MailStatus)
import Point2d exposing (Point2d)
import Set exposing (Set)
import Tile exposing (TileGroup)
import TimeOfDay exposing (TimeOfDay)
import Train exposing (TrainDiff)
import Units exposing (CellUnit, WorldUnit)
import User exposing (FrontendUser)


type Change
    = LocalChange (Id EventId) LocalChange
    | ServerChange ServerChange


type LocalChange
    = LocalGridChange Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupAnimal (Id AnimalId) (Point2d WorldUnit WorldUnit) Effect.Time.Posix
    | DropAnimal (Id AnimalId) (Point2d WorldUnit WorldUnit) Effect.Time.Posix
    | MoveCursor (Point2d WorldUnit WorldUnit)
    | InvalidChange
    | ChangeHandColor Colors
    | ToggleRailSplit (Coord WorldUnit)
    | ChangeDisplayName DisplayName
    | SubmitMail { content : List MailEditor.Content, to : Id UserId }
    | UpdateDraft { content : List MailEditor.Content, to : Id UserId }
    | TeleportHomeTrainRequest (Id TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Id TrainId) Effect.Time.Posix
    | ViewedMail (Id MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Coord WorldUnit)
    | SetTimeOfDay TimeOfDay
    | SetTileHotkey TileHotkey TileGroup
    | ShowNotifications Bool
    | Logout
    | ViewBoundsChange ViewBoundsChange2
    | ClearNotifications Effect.Time.Posix
    | VisitedHyperlink Hyperlink


type alias ViewBoundsChange2 =
    { viewBounds : Bounds CellUnit
    , previewBounds : Maybe (Bounds CellUnit)
    , newCells : List ( Coord CellUnit, GridCell.CellData )
    , newCows : List ( Id AnimalId, Animal )
    }


tileHotkeyDict : Dict String TileHotkey
tileHotkeyDict =
    Dict.fromList
        [ ( "Digit0", Hotkey0 )
        , ( "Digit1", Hotkey1 )
        , ( "Digit2", Hotkey2 )
        , ( "Digit3", Hotkey3 )
        , ( "Digit4", Hotkey4 )
        , ( "Digit5", Hotkey5 )
        , ( "Digit6", Hotkey6 )
        , ( "Digit7", Hotkey7 )
        , ( "Digit8", Hotkey8 )
        , ( "Digit9", Hotkey9 )
        ]


type TileHotkey
    = Hotkey0
    | Hotkey1
    | Hotkey2
    | Hotkey3
    | Hotkey4
    | Hotkey5
    | Hotkey6
    | Hotkey7
    | Hotkey8
    | Hotkey9


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | AdminDeleteMail (Id MailId) Effect.Time.Posix
    | AdminRestoreMail (Id MailId)
    | AdminResetUpdateDuration
    | AdminRegenerateGridCellCache Effect.Time.Posix


type AreTrainsAndAnimalsDisabled
    = TrainsAndAnimalsDisabled
    | TrainsAndAnimalsEnabled


type ServerChange
    = ServerGridChange
        { gridChange : Grid.GridChange
        , newCells : List (Coord CellUnit)
        , newAnimals : List ( Id AnimalId, Animal )
        }
    | ServerUndoPoint { userId : Id UserId, undoPoints : Dict RawCellCoord Int }
    | ServerPickupAnimal (Id UserId) (Id AnimalId) (Point2d WorldUnit WorldUnit) Effect.Time.Posix
    | ServerDropAnimal (Id UserId) (Id AnimalId) (Point2d WorldUnit WorldUnit)
    | ServerMoveCursor (Id UserId) (Point2d WorldUnit WorldUnit)
    | ServerUserDisconnected (Id UserId)
    | ServerUserConnected
        { maybeLoggedIn : Maybe { userId : Id UserId, user : FrontendUser }
        , cowsSpawnedFromVisibleRegion : List ( Id AnimalId, Animal )
        }
    | ServerYouLoggedIn LoggedIn_ FrontendUser
    | ServerChangeHandColor (Id UserId) Colors
    | ServerToggleRailSplit (Coord WorldUnit)
    | ServerChangeDisplayName (Id UserId) DisplayName
    | ServerSubmitMail { from : Id UserId, to : Id UserId }
    | ServerMailStatusChanged (Id MailId) MailStatus
    | ServerTeleportHomeTrainRequest (Id TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Id TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (IdDict TrainId TrainDiff)
    | ServerWorldUpdateDuration Duration
    | ServerReceivedMail
        { mailId : Id MailId
        , from : Id UserId
        , content : List MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Id MailId) (Id UserId)
    | ServerNewCows (Nonempty ( Id AnimalId, Animal ))
    | ServerChangeTool (Id UserId) Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Id UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Id UserId) (Coord WorldUnit)
    | ServerSetTrainsDisabled AreTrainsAndAnimalsDisabled
    | ServerLogout
    | ServerAnimalMovement (Nonempty ( Id AnimalId, MovementChange ))
    | ServerRegenerateCache Effect.Time.Posix


type alias MovementChange =
    { startTime : Effect.Time.Posix
    , position : Point2d WorldUnit WorldUnit
    , endPosition : Point2d WorldUnit WorldUnit
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_


type alias NotLoggedIn_ =
    { timeOfDay : TimeOfDay }


type alias LoggedIn_ =
    { userId : Id UserId
    , undoHistory : List (Dict RawCellCoord Int)
    , redoHistory : List (Dict RawCellCoord Int)
    , undoCurrent : Dict RawCellCoord Int
    , mailDrafts : IdDict UserId (List MailEditor.Content)
    , emailAddress : EmailAddress
    , inbox : IdDict MailId MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey TileGroup
    , showNotifications : Bool
    , notifications : List (Coord WorldUnit)
    , notificationsClearedAt : Effect.Time.Posix
    , hyperlinksVisited : Set String
    }


type alias Report =
    { reportedUser : Id UserId, position : Coord WorldUnit }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions : List { userId : Maybe (Id UserId), connectionCount : Int }
    , reported : IdDict UserId (Nonempty BackendReport)
    , mail : IdDict MailId BackendMail
    , worldUpdateDurations : Array Duration
    , totalGridCells : Int
    }


type alias BackendReport =
    { reportedUser : Id UserId, position : Coord WorldUnit, reportedAt : Effect.Time.Posix }
