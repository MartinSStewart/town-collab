module Evergreen.V91.Change exposing (..)

import AssocList
import Dict
import Effect.Time
import Evergreen.V91.Animal
import Evergreen.V91.Bounds
import Evergreen.V91.Color
import Evergreen.V91.Coord
import Evergreen.V91.Cursor
import Evergreen.V91.DisplayName
import Evergreen.V91.EmailAddress
import Evergreen.V91.Grid
import Evergreen.V91.GridCell
import Evergreen.V91.Id
import Evergreen.V91.IdDict
import Evergreen.V91.MailEditor
import Evergreen.V91.Point2d
import Evergreen.V91.Tile
import Evergreen.V91.Train
import Evergreen.V91.Units
import Evergreen.V91.User
import List.Nonempty


type AreTrainsDisabled
    = TrainsDisabled
    | TrainsEnabled


type AdminChange
    = AdminResetSessions
    | AdminSetGridReadOnly Bool
    | AdminSetTrainsDisabled AreTrainsDisabled
    | AdminDeleteMail (Evergreen.V91.Id.Id Evergreen.V91.Id.MailId) Effect.Time.Posix
    | AdminRestoreMail (Evergreen.V91.Id.Id Evergreen.V91.Id.MailId)


type alias Report =
    { reportedUser : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
    , position : Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit
    }


type TimeOfDay
    = Automatic
    | AlwaysDay
    | AlwaysNight


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


type LocalChange
    = LocalGridChange Evergreen.V91.Grid.LocalGridChange
    | LocalUndo
    | LocalRedo
    | LocalAddUndo
    | PickupCow (Evergreen.V91.Id.Id Evergreen.V91.Id.AnimalId) (Evergreen.V91.Point2d.Point2d Evergreen.V91.Units.WorldUnit Evergreen.V91.Units.WorldUnit) Effect.Time.Posix
    | DropCow (Evergreen.V91.Id.Id Evergreen.V91.Id.AnimalId) (Evergreen.V91.Point2d.Point2d Evergreen.V91.Units.WorldUnit Evergreen.V91.Units.WorldUnit) Effect.Time.Posix
    | MoveCursor (Evergreen.V91.Point2d.Point2d Evergreen.V91.Units.WorldUnit Evergreen.V91.Units.WorldUnit)
    | InvalidChange
    | ChangeHandColor Evergreen.V91.Color.Colors
    | ToggleRailSplit (Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit)
    | ChangeDisplayName Evergreen.V91.DisplayName.DisplayName
    | SubmitMail
        { content : List Evergreen.V91.MailEditor.Content
        , to : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
        }
    | UpdateDraft
        { content : List Evergreen.V91.MailEditor.Content
        , to : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
        }
    | TeleportHomeTrainRequest (Evergreen.V91.Id.Id Evergreen.V91.Id.TrainId) Effect.Time.Posix
    | LeaveHomeTrainRequest (Evergreen.V91.Id.Id Evergreen.V91.Id.TrainId) Effect.Time.Posix
    | ViewedMail (Evergreen.V91.Id.Id Evergreen.V91.Id.MailId)
    | SetAllowEmailNotifications Bool
    | ChangeTool Evergreen.V91.Cursor.OtherUsersTool
    | AdminChange AdminChange
    | ReportVandalism Report
    | RemoveReport (Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit)
    | SetTimeOfDay TimeOfDay
    | SetTileHotkey TileHotkey Evergreen.V91.Tile.TileGroup


type alias BackendReport =
    { reportedUser : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
    , position : Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit
    , reportedAt : Effect.Time.Posix
    }


type alias AdminData =
    { lastCacheRegeneration : Maybe Effect.Time.Posix
    , userSessions :
        List
            { userId : Maybe (Evergreen.V91.Id.Id Evergreen.V91.Id.UserId)
            , connectionCount : Int
            }
    , reported : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.UserId (List.Nonempty.Nonempty BackendReport)
    , mail : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.MailId Evergreen.V91.MailEditor.BackendMail
    }


type alias LoggedIn_ =
    { userId : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
    , undoHistory : List (Dict.Dict Evergreen.V91.Coord.RawCellCoord Int)
    , redoHistory : List (Dict.Dict Evergreen.V91.Coord.RawCellCoord Int)
    , undoCurrent : Dict.Dict Evergreen.V91.Coord.RawCellCoord Int
    , mailDrafts : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.UserId (List Evergreen.V91.MailEditor.Content)
    , emailAddress : Evergreen.V91.EmailAddress.EmailAddress
    , inbox : Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.MailId Evergreen.V91.MailEditor.ReceivedMail
    , allowEmailNotifications : Bool
    , adminData : Maybe AdminData
    , reports : List Report
    , isGridReadOnly : Bool
    , timeOfDay : TimeOfDay
    , tileHotkeys : AssocList.Dict TileHotkey Evergreen.V91.Tile.TileGroup
    }


type ServerChange
    = ServerGridChange
        { gridChange : Evergreen.V91.Grid.GridChange
        , newCells : List (Evergreen.V91.Coord.Coord Evergreen.V91.Units.CellUnit)
        , newCows : List ( Evergreen.V91.Id.Id Evergreen.V91.Id.AnimalId, Evergreen.V91.Animal.Animal )
        }
    | ServerUndoPoint
        { userId : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
        , undoPoints : Dict.Dict Evergreen.V91.Coord.RawCellCoord Int
        }
    | ServerPickupCow (Evergreen.V91.Id.Id Evergreen.V91.Id.UserId) (Evergreen.V91.Id.Id Evergreen.V91.Id.AnimalId) (Evergreen.V91.Point2d.Point2d Evergreen.V91.Units.WorldUnit Evergreen.V91.Units.WorldUnit) Effect.Time.Posix
    | ServerDropCow (Evergreen.V91.Id.Id Evergreen.V91.Id.UserId) (Evergreen.V91.Id.Id Evergreen.V91.Id.AnimalId) (Evergreen.V91.Point2d.Point2d Evergreen.V91.Units.WorldUnit Evergreen.V91.Units.WorldUnit)
    | ServerMoveCursor (Evergreen.V91.Id.Id Evergreen.V91.Id.UserId) (Evergreen.V91.Point2d.Point2d Evergreen.V91.Units.WorldUnit Evergreen.V91.Units.WorldUnit)
    | ServerUserDisconnected (Evergreen.V91.Id.Id Evergreen.V91.Id.UserId)
    | ServerUserConnected
        { userId : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
        , user : Evergreen.V91.User.FrontendUser
        , cowsSpawnedFromVisibleRegion : List ( Evergreen.V91.Id.Id Evergreen.V91.Id.AnimalId, Evergreen.V91.Animal.Animal )
        }
    | ServerYouLoggedIn LoggedIn_ Evergreen.V91.User.FrontendUser
    | ServerChangeHandColor (Evergreen.V91.Id.Id Evergreen.V91.Id.UserId) Evergreen.V91.Color.Colors
    | ServerToggleRailSplit (Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit)
    | ServerChangeDisplayName (Evergreen.V91.Id.Id Evergreen.V91.Id.UserId) Evergreen.V91.DisplayName.DisplayName
    | ServerSubmitMail
        { from : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
        , to : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
        }
    | ServerMailStatusChanged (Evergreen.V91.Id.Id Evergreen.V91.Id.MailId) Evergreen.V91.MailEditor.MailStatus
    | ServerTeleportHomeTrainRequest (Evergreen.V91.Id.Id Evergreen.V91.Id.TrainId) Effect.Time.Posix
    | ServerLeaveHomeTrainRequest (Evergreen.V91.Id.Id Evergreen.V91.Id.TrainId) Effect.Time.Posix
    | ServerWorldUpdateBroadcast (Evergreen.V91.IdDict.IdDict Evergreen.V91.Id.TrainId Evergreen.V91.Train.TrainDiff)
    | ServerReceivedMail
        { mailId : Evergreen.V91.Id.Id Evergreen.V91.Id.MailId
        , from : Evergreen.V91.Id.Id Evergreen.V91.Id.UserId
        , content : List Evergreen.V91.MailEditor.Content
        , deliveryTime : Effect.Time.Posix
        }
    | ServerViewedMail (Evergreen.V91.Id.Id Evergreen.V91.Id.MailId) (Evergreen.V91.Id.Id Evergreen.V91.Id.UserId)
    | ServerNewCows (List.Nonempty.Nonempty ( Evergreen.V91.Id.Id Evergreen.V91.Id.AnimalId, Evergreen.V91.Animal.Animal ))
    | ServerChangeTool (Evergreen.V91.Id.Id Evergreen.V91.Id.UserId) Evergreen.V91.Cursor.OtherUsersTool
    | ServerGridReadOnly Bool
    | ServerVandalismReportedToAdmin (Evergreen.V91.Id.Id Evergreen.V91.Id.UserId) BackendReport
    | ServerVandalismRemovedToAdmin (Evergreen.V91.Id.Id Evergreen.V91.Id.UserId) (Evergreen.V91.Coord.Coord Evergreen.V91.Units.WorldUnit)
    | ServerSetTrainsDisabled AreTrainsDisabled


type ClientChange
    = ViewBoundsChange (Evergreen.V91.Bounds.Bounds Evergreen.V91.Units.CellUnit) (List ( Evergreen.V91.Coord.Coord Evergreen.V91.Units.CellUnit, Evergreen.V91.GridCell.CellData )) (List ( Evergreen.V91.Id.Id Evergreen.V91.Id.AnimalId, Evergreen.V91.Animal.Animal ))


type Change
    = LocalChange (Evergreen.V91.Id.Id Evergreen.V91.Id.EventId) LocalChange
    | ServerChange ServerChange
    | ClientChange ClientChange


type alias NotLoggedIn_ =
    { timeOfDay : TimeOfDay
    }


type UserStatus
    = LoggedIn LoggedIn_
    | NotLoggedIn NotLoggedIn_
