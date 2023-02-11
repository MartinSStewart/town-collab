module Evergreen.Migrate.V58 exposing (..)

import AssocList
import AssocSet
import Dict
import Effect.Time
import Evergreen.V57.Bounds
import Evergreen.V57.Change
import Evergreen.V57.Color
import Evergreen.V57.Cursor
import Evergreen.V57.DisplayName
import Evergreen.V57.EmailAddress
import Evergreen.V57.Geometry.Types
import Evergreen.V57.Grid
import Evergreen.V57.GridCell
import Evergreen.V57.Id
import Evergreen.V57.IdDict
import Evergreen.V57.LocalGrid
import Evergreen.V57.MailEditor
import Evergreen.V57.Postmark
import Evergreen.V57.Tile
import Evergreen.V57.Train
import Evergreen.V57.Types
import Evergreen.V58.Bounds
import Evergreen.V58.Change
import Evergreen.V58.Color
import Evergreen.V58.Coord
import Evergreen.V58.Cursor
import Evergreen.V58.DisplayName
import Evergreen.V58.EmailAddress
import Evergreen.V58.Geometry.Types
import Evergreen.V58.Grid
import Evergreen.V58.GridCell
import Evergreen.V58.Id
import Evergreen.V58.IdDict
import Evergreen.V58.LocalGrid
import Evergreen.V58.MailEditor
import Evergreen.V58.Postmark
import Evergreen.V58.Tile
import Evergreen.V58.Train
import Evergreen.V58.Types
import IdDict
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Process
import Quantity exposing (Quantity)
import Task


backendModel : Evergreen.V57.Types.BackendModel -> ModelMigration Evergreen.V58.Types.BackendModel Evergreen.V58.Types.BackendMsg
backendModel old =
    ModelMigrated
        ( migrateBackendModel old
        , Process.sleep 1000 |> Task.perform (\() -> Evergreen.V58.Types.RegenerateCache)
        )


frontendModel : Evergreen.V57.Types.FrontendModel -> ModelMigration Evergreen.V58.Types.FrontendModel Evergreen.V58.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V57.Types.FrontendMsg -> MsgMigration Evergreen.V58.Types.FrontendMsg Evergreen.V58.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V57.Types.BackendMsg -> MsgMigration Evergreen.V58.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V57.Types.BackendError -> Evergreen.V58.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V57.Types.PostmarkError a b ->
            Evergreen.V58.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V57.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V58.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V57.Types.BackendModel -> Evergreen.V58.Types.BackendModel
migrateBackendModel old =
    { grid = migrateGrid old.grid
    , userSessions =
        migrateDict
            identity
            (\a ->
                { clientIds = AssocList.map (\_ b -> migrateBounds b) a.clientIds
                , userId = Maybe.map migrateId a.userId
                }
            )
            old.userSessions
    , users = migrateIdDict migrateBackendUserData old.users
    , secretLinkCounter = old.secretLinkCounter
    , errors = List.map (Tuple.mapSecond migrateBackendError) old.errors
    , trains = migrateIdDict migrateTrain old.trains
    , cows = migrateIdDict migrateCow old.cows
    , lastWorldUpdateTrains = migrateIdDict migrateTrain old.lastWorldUpdateTrains
    , lastWorldUpdate = old.lastWorldUpdate
    , mail = migrateIdDict migrateBackendMail old.mail
    , pendingLoginTokens =
        migrateAssocList
            migrateSecretId
            (\a ->
                { requestTime = a.requestTime
                , userId = migrateId a.userId
                , requestedBy = migrateRequestedBy a.requestedBy
                }
            )
            old.pendingLoginTokens
    , invites = migrateAssocList migrateSecretId migrateInvite old.invites
    }


migrateRequestedBy : Evergreen.V57.Types.LoginRequestedBy -> Evergreen.V58.Types.LoginRequestedBy
migrateRequestedBy old =
    case old of
        Evergreen.V57.Types.LoginRequestedByBackend ->
            Evergreen.V58.Types.LoginRequestedByBackend

        Evergreen.V57.Types.LoginRequestedByFrontend sessionId ->
            Evergreen.V58.Types.LoginRequestedByFrontend sessionId


migrateGrid : Evergreen.V57.Grid.Grid -> Evergreen.V58.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V57.Grid.Grid a ->
            Evergreen.V58.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V57.GridCell.Cell -> Evergreen.V58.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V57.GridCell.Cell a ->
            Evergreen.V58.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateDict identity identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V57.GridCell.Value -> Evergreen.V58.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V57.Bounds.Bounds a -> Evergreen.V58.Bounds.Bounds b
migrateBounds (Evergreen.V57.Bounds.Bounds old) =
    Evergreen.V58.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V57.Change.Cow -> Evergreen.V58.Change.Cow
migrateCow old =
    { position = migratePoint2d old.position }


migrateBackendMail : Evergreen.V57.MailEditor.BackendMail -> Evergreen.V58.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V57.MailEditor.MailStatus -> Evergreen.V58.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V57.MailEditor.MailWaitingPickup ->
            Evergreen.V58.MailEditor.MailWaitingPickup

        Evergreen.V57.MailEditor.MailInTransit a ->
            Evergreen.V58.MailEditor.MailInTransit (migrateId a)

        Evergreen.V57.MailEditor.MailReceived a ->
            Evergreen.V58.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V57.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V58.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V57.Types.Invite -> Evergreen.V58.Types.Invite
migrateInvite old =
    { invitedBy = migrateId old.invitedBy
    , invitedAt = old.invitedAt
    , invitedEmailAddress = migrateEmailAddress old.invitedEmailAddress
    , emailResult = migrateEmailResult old.emailResult
    }


migrateAssocList migrateKey migrateValue2 old =
    AssocList.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> AssocList.fromList


migrateSessionId =
    identity


migrateClientId =
    identity


migrateEmailAddress (Evergreen.V57.EmailAddress.EmailAddress old) =
    Evergreen.V58.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V57.Id.SecretId a -> Evergreen.V58.Id.SecretId b
migrateSecretId (Evergreen.V57.Id.SecretId old) =
    Evergreen.V58.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V57.IdDict.IdDict a b -> Evergreen.V58.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V57.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V58.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V57.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V58.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V57.IdDict.NColor -> Evergreen.V58.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V57.IdDict.Red ->
            Evergreen.V58.IdDict.Red

        Evergreen.V57.IdDict.Black ->
            Evergreen.V58.IdDict.Black


migrateBackendUserData : Evergreen.V57.Types.BackendUserData -> Evergreen.V58.Types.BackendUserData
migrateBackendUserData old =
    { undoHistory = migrateList (migrateDict migrateRawCellCoord identity) old.undoHistory
    , redoHistory = migrateList (migrateDict migrateRawCellCoord identity) old.redoHistory
    , undoCurrent = migrateDict migrateRawCellCoord identity old.undoCurrent
    , mailDrafts = migrateIdDict (migrateList migrateContent) old.mailDrafts
    , cursor = migrateMaybe migrateCursor old.cursor
    , handColor = migrateColors old.handColor
    , emailAddress = migrateEmailAddress old.emailAddress
    , acceptedInvites = migrateIdDict identity old.acceptedInvites
    , name = migrateDisplayName old.name
    , allowEmailNotifications = old.allowEmailNotifications
    }


migrateRawCellCoord =
    identity


migrateEmailResult : Evergreen.V57.Types.EmailResult -> Evergreen.V58.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V57.Types.EmailSending ->
            Evergreen.V58.Types.EmailSending

        Evergreen.V57.Types.EmailSendFailed a ->
            Evergreen.V58.Types.EmailSendFailed a

        Evergreen.V57.Types.EmailSent a ->
            Evergreen.V58.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V57.Postmark.PostmarkSendResponse -> Evergreen.V58.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V57.Tile.Tile -> Evergreen.V58.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V57.Tile.EmptyTile ->
            Evergreen.V58.Tile.EmptyTile

        Evergreen.V57.Tile.HouseDown ->
            Evergreen.V58.Tile.HouseDown

        Evergreen.V57.Tile.HouseRight ->
            Evergreen.V58.Tile.HouseRight

        Evergreen.V57.Tile.HouseUp ->
            Evergreen.V58.Tile.HouseUp

        Evergreen.V57.Tile.HouseLeft ->
            Evergreen.V58.Tile.HouseLeft

        Evergreen.V57.Tile.RailHorizontal ->
            Evergreen.V58.Tile.RailHorizontal

        Evergreen.V57.Tile.RailVertical ->
            Evergreen.V58.Tile.RailVertical

        Evergreen.V57.Tile.RailBottomToRight ->
            Evergreen.V58.Tile.RailBottomToRight

        Evergreen.V57.Tile.RailBottomToLeft ->
            Evergreen.V58.Tile.RailBottomToLeft

        Evergreen.V57.Tile.RailTopToRight ->
            Evergreen.V58.Tile.RailTopToRight

        Evergreen.V57.Tile.RailTopToLeft ->
            Evergreen.V58.Tile.RailTopToLeft

        Evergreen.V57.Tile.RailBottomToRightLarge ->
            Evergreen.V58.Tile.RailBottomToRightLarge

        Evergreen.V57.Tile.RailBottomToLeftLarge ->
            Evergreen.V58.Tile.RailBottomToLeftLarge

        Evergreen.V57.Tile.RailTopToRightLarge ->
            Evergreen.V58.Tile.RailTopToRightLarge

        Evergreen.V57.Tile.RailTopToLeftLarge ->
            Evergreen.V58.Tile.RailTopToLeftLarge

        Evergreen.V57.Tile.RailCrossing ->
            Evergreen.V58.Tile.RailCrossing

        Evergreen.V57.Tile.RailStrafeDown ->
            Evergreen.V58.Tile.RailStrafeDown

        Evergreen.V57.Tile.RailStrafeUp ->
            Evergreen.V58.Tile.RailStrafeUp

        Evergreen.V57.Tile.RailStrafeLeft ->
            Evergreen.V58.Tile.RailStrafeLeft

        Evergreen.V57.Tile.RailStrafeRight ->
            Evergreen.V58.Tile.RailStrafeRight

        Evergreen.V57.Tile.TrainHouseRight ->
            Evergreen.V58.Tile.TrainHouseRight

        Evergreen.V57.Tile.TrainHouseLeft ->
            Evergreen.V58.Tile.TrainHouseLeft

        Evergreen.V57.Tile.RailStrafeDownSmall ->
            Evergreen.V58.Tile.RailStrafeDownSmall

        Evergreen.V57.Tile.RailStrafeUpSmall ->
            Evergreen.V58.Tile.RailStrafeUpSmall

        Evergreen.V57.Tile.RailStrafeLeftSmall ->
            Evergreen.V58.Tile.RailStrafeLeftSmall

        Evergreen.V57.Tile.RailStrafeRightSmall ->
            Evergreen.V58.Tile.RailStrafeRightSmall

        Evergreen.V57.Tile.Sidewalk ->
            Evergreen.V58.Tile.Sidewalk

        Evergreen.V57.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V58.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V57.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V58.Tile.SidewalkVerticalRailCrossing

        Evergreen.V57.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V58.Tile.RailBottomToRight_SplitLeft

        Evergreen.V57.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V58.Tile.RailBottomToLeft_SplitUp

        Evergreen.V57.Tile.RailTopToRight_SplitDown ->
            Evergreen.V58.Tile.RailTopToRight_SplitDown

        Evergreen.V57.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V58.Tile.RailTopToLeft_SplitRight

        Evergreen.V57.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V58.Tile.RailBottomToRight_SplitUp

        Evergreen.V57.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V58.Tile.RailBottomToLeft_SplitRight

        Evergreen.V57.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V58.Tile.RailTopToRight_SplitLeft

        Evergreen.V57.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V58.Tile.RailTopToLeft_SplitDown

        Evergreen.V57.Tile.PostOffice ->
            Evergreen.V58.Tile.PostOffice

        Evergreen.V57.Tile.MowedGrass1 ->
            Evergreen.V58.Tile.MowedGrass1

        Evergreen.V57.Tile.MowedGrass4 ->
            Evergreen.V58.Tile.MowedGrass4

        Evergreen.V57.Tile.LogCabinDown ->
            Evergreen.V58.Tile.LogCabinDown

        Evergreen.V57.Tile.LogCabinRight ->
            Evergreen.V58.Tile.LogCabinRight

        Evergreen.V57.Tile.LogCabinUp ->
            Evergreen.V58.Tile.LogCabinUp

        Evergreen.V57.Tile.LogCabinLeft ->
            Evergreen.V58.Tile.LogCabinLeft

        Evergreen.V57.Tile.RoadHorizontal ->
            Evergreen.V58.Tile.RoadHorizontal

        Evergreen.V57.Tile.RoadVertical ->
            Evergreen.V58.Tile.RoadVertical

        Evergreen.V57.Tile.RoadBottomToLeft ->
            Evergreen.V58.Tile.RoadBottomToLeft

        Evergreen.V57.Tile.RoadTopToLeft ->
            Evergreen.V58.Tile.RoadTopToLeft

        Evergreen.V57.Tile.RoadTopToRight ->
            Evergreen.V58.Tile.RoadTopToRight

        Evergreen.V57.Tile.RoadBottomToRight ->
            Evergreen.V58.Tile.RoadBottomToRight

        Evergreen.V57.Tile.Road4Way ->
            Evergreen.V58.Tile.Road4Way

        Evergreen.V57.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V58.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V57.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V58.Tile.RoadSidewalkCrossingVertical

        Evergreen.V57.Tile.Road3WayDown ->
            Evergreen.V58.Tile.Road3WayDown

        Evergreen.V57.Tile.Road3WayLeft ->
            Evergreen.V58.Tile.Road3WayLeft

        Evergreen.V57.Tile.Road3WayUp ->
            Evergreen.V58.Tile.Road3WayUp

        Evergreen.V57.Tile.Road3WayRight ->
            Evergreen.V58.Tile.Road3WayRight

        Evergreen.V57.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V58.Tile.RoadRailCrossingHorizontal

        Evergreen.V57.Tile.RoadRailCrossingVertical ->
            Evergreen.V58.Tile.RoadRailCrossingVertical

        Evergreen.V57.Tile.FenceHorizontal ->
            Evergreen.V58.Tile.FenceHorizontal

        Evergreen.V57.Tile.FenceVertical ->
            Evergreen.V58.Tile.FenceVertical

        Evergreen.V57.Tile.FenceDiagonal ->
            Evergreen.V58.Tile.FenceDiagonal

        Evergreen.V57.Tile.FenceAntidiagonal ->
            Evergreen.V58.Tile.FenceAntidiagonal

        Evergreen.V57.Tile.RoadDeadendUp ->
            Evergreen.V58.Tile.RoadDeadendUp

        Evergreen.V57.Tile.RoadDeadendDown ->
            Evergreen.V58.Tile.RoadDeadendDown

        Evergreen.V57.Tile.BusStopDown ->
            Evergreen.V58.Tile.BusStopDown

        Evergreen.V57.Tile.BusStopLeft ->
            Evergreen.V58.Tile.BusStopLeft

        Evergreen.V57.Tile.BusStopRight ->
            Evergreen.V58.Tile.BusStopRight

        Evergreen.V57.Tile.BusStopUp ->
            Evergreen.V58.Tile.BusStopUp

        Evergreen.V57.Tile.Hospital ->
            Evergreen.V58.Tile.Hospital

        Evergreen.V57.Tile.Statue ->
            Evergreen.V58.Tile.Statue

        Evergreen.V57.Tile.HedgeRowDown ->
            Evergreen.V58.Tile.HedgeRowDown

        Evergreen.V57.Tile.HedgeRowLeft ->
            Evergreen.V58.Tile.HedgeRowLeft

        Evergreen.V57.Tile.HedgeRowRight ->
            Evergreen.V58.Tile.HedgeRowRight

        Evergreen.V57.Tile.HedgeRowUp ->
            Evergreen.V58.Tile.HedgeRowUp

        Evergreen.V57.Tile.HedgeCornerDownLeft ->
            Evergreen.V58.Tile.HedgeCornerDownLeft

        Evergreen.V57.Tile.HedgeCornerDownRight ->
            Evergreen.V58.Tile.HedgeCornerDownRight

        Evergreen.V57.Tile.HedgeCornerUpLeft ->
            Evergreen.V58.Tile.HedgeCornerUpLeft

        Evergreen.V57.Tile.HedgeCornerUpRight ->
            Evergreen.V58.Tile.HedgeCornerUpRight

        Evergreen.V57.Tile.ApartmentDown ->
            Evergreen.V58.Tile.ApartmentDown

        Evergreen.V57.Tile.ApartmentLeft ->
            Evergreen.V58.Tile.ApartmentLeft

        Evergreen.V57.Tile.ApartmentRight ->
            Evergreen.V58.Tile.ApartmentRight

        Evergreen.V57.Tile.ApartmentUp ->
            Evergreen.V58.Tile.ApartmentUp

        Evergreen.V57.Tile.RockDown ->
            Evergreen.V58.Tile.RockDown

        Evergreen.V57.Tile.RockLeft ->
            Evergreen.V58.Tile.RockLeft

        Evergreen.V57.Tile.RockRight ->
            Evergreen.V58.Tile.RockRight

        Evergreen.V57.Tile.RockUp ->
            Evergreen.V58.Tile.RockUp

        Evergreen.V57.Tile.PineTree1 ->
            Evergreen.V58.Tile.PineTree1

        Evergreen.V57.Tile.PineTree2 ->
            Evergreen.V58.Tile.PineTree2

        Evergreen.V57.Tile.HedgePillarDownLeft ->
            Evergreen.V58.Tile.HedgePillarDownLeft

        Evergreen.V57.Tile.HedgePillarDownRight ->
            Evergreen.V58.Tile.HedgePillarDownRight

        Evergreen.V57.Tile.HedgePillarUpLeft ->
            Evergreen.V58.Tile.HedgePillarUpLeft

        Evergreen.V57.Tile.HedgePillarUpRight ->
            Evergreen.V58.Tile.HedgePillarUpRight

        Evergreen.V57.Tile.Flowers1 ->
            Evergreen.V58.Tile.Flowers1

        Evergreen.V57.Tile.Flowers2 ->
            Evergreen.V58.Tile.Flowers2

        Evergreen.V57.Tile.ElmTree ->
            Evergreen.V58.Tile.ElmTree

        Evergreen.V57.Tile.DirtPathHorizontal ->
            Evergreen.V58.Tile.DirtPathHorizontal

        Evergreen.V57.Tile.DirtPathVertical ->
            Evergreen.V58.Tile.DirtPathVertical

        Evergreen.V57.Tile.BigText char ->
            Evergreen.V58.Tile.BigText char


migrateTrain : Evergreen.V57.Train.Train -> Evergreen.V58.Train.Train
migrateTrain old =
    case old of
        Evergreen.V57.Train.Train a ->
            Evergreen.V58.Train.Train
                { position = migrateCoord a.position
                , path = migrateRailPath a.path
                , previousPaths = migrateList migratePreviousPath a.previousPaths
                , t = identity a.t
                , speed = migrateQuantity a.speed
                , home = migrateCoord a.home
                , homePath = migrateRailPath a.homePath
                , isStuck = migrateMaybe migratePosix a.isStuck
                , status = migrateStatus a.status
                , owner = migrateId a.owner
                }


migrateStatus : Evergreen.V57.Train.Status -> Evergreen.V58.Train.Status
migrateStatus old =
    case old of
        Evergreen.V57.Train.WaitingAtHome ->
            Evergreen.V58.Train.WaitingAtHome

        Evergreen.V57.Train.TeleportingHome a ->
            Evergreen.V58.Train.TeleportingHome (migratePosix a)

        Evergreen.V57.Train.Travelling ->
            Evergreen.V58.Train.Travelling

        Evergreen.V57.Train.StoppedAtPostOffice a ->
            Evergreen.V58.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V57.Tile.RailPath -> Evergreen.V58.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V57.Tile.RailPathHorizontal a ->
            Evergreen.V58.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V57.Tile.RailPathVertical a ->
            Evergreen.V58.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V57.Tile.RailPathBottomToRight ->
            Evergreen.V58.Tile.RailPathBottomToRight

        Evergreen.V57.Tile.RailPathBottomToLeft ->
            Evergreen.V58.Tile.RailPathBottomToLeft

        Evergreen.V57.Tile.RailPathTopToRight ->
            Evergreen.V58.Tile.RailPathTopToRight

        Evergreen.V57.Tile.RailPathTopToLeft ->
            Evergreen.V58.Tile.RailPathTopToLeft

        Evergreen.V57.Tile.RailPathBottomToRightLarge ->
            Evergreen.V58.Tile.RailPathBottomToRightLarge

        Evergreen.V57.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V58.Tile.RailPathBottomToLeftLarge

        Evergreen.V57.Tile.RailPathTopToRightLarge ->
            Evergreen.V58.Tile.RailPathTopToRightLarge

        Evergreen.V57.Tile.RailPathTopToLeftLarge ->
            Evergreen.V58.Tile.RailPathTopToLeftLarge

        Evergreen.V57.Tile.RailPathStrafeDown ->
            Evergreen.V58.Tile.RailPathStrafeDown

        Evergreen.V57.Tile.RailPathStrafeUp ->
            Evergreen.V58.Tile.RailPathStrafeUp

        Evergreen.V57.Tile.RailPathStrafeLeft ->
            Evergreen.V58.Tile.RailPathStrafeLeft

        Evergreen.V57.Tile.RailPathStrafeRight ->
            Evergreen.V58.Tile.RailPathStrafeRight

        Evergreen.V57.Tile.RailPathStrafeDownSmall ->
            Evergreen.V58.Tile.RailPathStrafeDownSmall

        Evergreen.V57.Tile.RailPathStrafeUpSmall ->
            Evergreen.V58.Tile.RailPathStrafeUpSmall

        Evergreen.V57.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V58.Tile.RailPathStrafeLeftSmall

        Evergreen.V57.Tile.RailPathStrafeRightSmall ->
            Evergreen.V58.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V57.Train.PreviousPath -> Evergreen.V58.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V57.MailEditor.Image -> Evergreen.V58.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V57.MailEditor.Stamp a ->
            Evergreen.V58.MailEditor.Stamp (migrateColors a)

        Evergreen.V57.MailEditor.SunglassesEmoji a ->
            Evergreen.V58.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V57.MailEditor.NormalEmoji a ->
            Evergreen.V58.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V57.MailEditor.SadEmoji a ->
            Evergreen.V58.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V57.MailEditor.Cow a ->
            Evergreen.V58.MailEditor.Cow (migrateColors a)

        Evergreen.V57.MailEditor.Man a ->
            Evergreen.V58.MailEditor.Man (migrateColors a)

        Evergreen.V57.MailEditor.TileImage a b c ->
            Evergreen.V58.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V57.MailEditor.Grass ->
            Evergreen.V58.MailEditor.Grass

        Evergreen.V57.MailEditor.DefaultCursor a ->
            Evergreen.V58.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V57.MailEditor.DragCursor a ->
            Evergreen.V58.MailEditor.DragCursor (migrateColors a)

        Evergreen.V57.MailEditor.PinchCursor a ->
            Evergreen.V58.MailEditor.PinchCursor (migrateColors a)

        Evergreen.V57.MailEditor.Line int color ->
            Evergreen.V58.MailEditor.Line int (migrateColor color)


migrateTileGroup : Evergreen.V57.Tile.TileGroup -> Evergreen.V58.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V57.Tile.EmptyTileGroup ->
            Evergreen.V58.Tile.EmptyTileGroup

        Evergreen.V57.Tile.HouseGroup ->
            Evergreen.V58.Tile.HouseGroup

        Evergreen.V57.Tile.RailStraightGroup ->
            Evergreen.V58.Tile.RailStraightGroup

        Evergreen.V57.Tile.RailTurnGroup ->
            Evergreen.V58.Tile.RailTurnGroup

        Evergreen.V57.Tile.RailTurnLargeGroup ->
            Evergreen.V58.Tile.RailTurnLargeGroup

        Evergreen.V57.Tile.RailStrafeGroup ->
            Evergreen.V58.Tile.RailStrafeGroup

        Evergreen.V57.Tile.RailStrafeSmallGroup ->
            Evergreen.V58.Tile.RailStrafeSmallGroup

        Evergreen.V57.Tile.RailCrossingGroup ->
            Evergreen.V58.Tile.RailCrossingGroup

        Evergreen.V57.Tile.TrainHouseGroup ->
            Evergreen.V58.Tile.TrainHouseGroup

        Evergreen.V57.Tile.SidewalkGroup ->
            Evergreen.V58.Tile.SidewalkGroup

        Evergreen.V57.Tile.SidewalkRailGroup ->
            Evergreen.V58.Tile.SidewalkRailGroup

        Evergreen.V57.Tile.RailTurnSplitGroup ->
            Evergreen.V58.Tile.RailTurnSplitGroup

        Evergreen.V57.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V58.Tile.RailTurnSplitMirrorGroup

        Evergreen.V57.Tile.PostOfficeGroup ->
            Evergreen.V58.Tile.PostOfficeGroup

        Evergreen.V57.Tile.PineTreeGroup ->
            Evergreen.V58.Tile.PineTreeGroup

        Evergreen.V57.Tile.LogCabinGroup ->
            Evergreen.V58.Tile.LogCabinGroup

        Evergreen.V57.Tile.RoadStraightGroup ->
            Evergreen.V58.Tile.RoadStraightGroup

        Evergreen.V57.Tile.RoadTurnGroup ->
            Evergreen.V58.Tile.RoadTurnGroup

        Evergreen.V57.Tile.Road4WayGroup ->
            Evergreen.V58.Tile.Road4WayGroup

        Evergreen.V57.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V58.Tile.RoadSidewalkCrossingGroup

        Evergreen.V57.Tile.Road3WayGroup ->
            Evergreen.V58.Tile.Road3WayGroup

        Evergreen.V57.Tile.RoadRailCrossingGroup ->
            Evergreen.V58.Tile.RoadRailCrossingGroup

        Evergreen.V57.Tile.RoadDeadendGroup ->
            Evergreen.V58.Tile.RoadDeadendGroup

        Evergreen.V57.Tile.FenceStraightGroup ->
            Evergreen.V58.Tile.FenceStraightGroup

        Evergreen.V57.Tile.BusStopGroup ->
            Evergreen.V58.Tile.BusStopGroup

        Evergreen.V57.Tile.HospitalGroup ->
            Evergreen.V58.Tile.HospitalGroup

        Evergreen.V57.Tile.StatueGroup ->
            Evergreen.V58.Tile.StatueGroup

        Evergreen.V57.Tile.HedgeRowGroup ->
            Evergreen.V58.Tile.HedgeRowGroup

        Evergreen.V57.Tile.HedgeCornerGroup ->
            Evergreen.V58.Tile.HedgeCornerGroup

        Evergreen.V57.Tile.ApartmentGroup ->
            Evergreen.V58.Tile.ApartmentGroup

        Evergreen.V57.Tile.RockGroup ->
            Evergreen.V58.Tile.RockGroup

        Evergreen.V57.Tile.FlowersGroup ->
            Evergreen.V58.Tile.FlowersGroup

        Evergreen.V57.Tile.HedgePillarGroup ->
            Evergreen.V58.Tile.HedgePillarGroup

        Evergreen.V57.Tile.ElmTreeGroup ->
            Evergreen.V58.Tile.ElmTreeGroup

        Evergreen.V57.Tile.DirtPathGroup ->
            Evergreen.V58.Tile.DirtPathGroup

        Evergreen.V57.Tile.BigTextGroup ->
            Evergreen.V58.Tile.BigTextGroup


migrateDisplayName : Evergreen.V57.DisplayName.DisplayName -> Evergreen.V58.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V57.DisplayName.DisplayName a ->
            Evergreen.V58.DisplayName.DisplayName a


migrateCursor : Evergreen.V57.Cursor.Cursor -> Evergreen.V58.Cursor.Cursor
migrateCursor old =
    { position = migratePoint2d old.position
    , holdingCow =
        migrateMaybe
            (\a ->
                { cowId = migrateId a.cowId
                , pickupTime = a.pickupTime
                }
            )
            old.holdingCow
    , currentTool =
        -- Since the user has to reload the page we might as well reset their cursor
        Evergreen.V58.Cursor.HandTool
    }


migrateContent : Evergreen.V57.MailEditor.Content -> Evergreen.V58.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, item = migrateImageOrText old.item }


migrateImageOrText : Evergreen.V57.MailEditor.ImageOrText -> Evergreen.V58.MailEditor.ImageOrText
migrateImageOrText old =
    case old of
        Evergreen.V57.MailEditor.ImageType imageType ->
            migrateImage imageType |> Evergreen.V58.MailEditor.ImageType

        Evergreen.V57.MailEditor.TextType string ->
            Evergreen.V58.MailEditor.TextType string


migrateColors : Evergreen.V57.Color.Colors -> Evergreen.V58.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V57.Color.Color -> Evergreen.V58.Color.Color
migrateColor old =
    case old of
        Evergreen.V57.Color.Color a ->
            Evergreen.V58.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V57.Types.ViewPoint -> Evergreen.V58.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V57.Types.NormalViewPoint a ->
            Evergreen.V58.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V57.Types.TrainViewPoint a ->
            Evergreen.V58.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V57.Geometry.Types.Point2d old) =
    Evergreen.V58.Geometry.Types.Point2d old


migrateId : Evergreen.V57.Id.Id a -> Evergreen.V58.Id.Id b
migrateId (Evergreen.V57.Id.Id old) =
    Evergreen.V58.Id.Id old
