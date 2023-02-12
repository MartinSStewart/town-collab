module Evergreen.Migrate.V62 exposing (..)

import AssocList
import AssocSet
import Dict
import Effect.Time
import Evergreen.V60.Bounds
import Evergreen.V60.Change
import Evergreen.V60.Color
import Evergreen.V60.Cursor
import Evergreen.V60.DisplayName
import Evergreen.V60.EmailAddress
import Evergreen.V60.Geometry.Types
import Evergreen.V60.Grid
import Evergreen.V60.GridCell
import Evergreen.V60.Id
import Evergreen.V60.IdDict
import Evergreen.V60.MailEditor
import Evergreen.V60.Postmark
import Evergreen.V60.Tile
import Evergreen.V60.Train
import Evergreen.V60.Types
import Evergreen.V62.Bounds
import Evergreen.V62.Change
import Evergreen.V62.Color
import Evergreen.V62.Cursor
import Evergreen.V62.DisplayName
import Evergreen.V62.EmailAddress
import Evergreen.V62.Geometry.Types
import Evergreen.V62.Grid
import Evergreen.V62.GridCell
import Evergreen.V62.Id
import Evergreen.V62.IdDict
import Evergreen.V62.MailEditor
import Evergreen.V62.Postmark
import Evergreen.V62.Tile
import Evergreen.V62.Train
import Evergreen.V62.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Quantity exposing (Quantity)


backendModel : Evergreen.V60.Types.BackendModel -> ModelMigration Evergreen.V62.Types.BackendModel Evergreen.V62.Types.BackendMsg
backendModel old =
    ModelMigrated
        ( migrateBackendModel old
        , Cmd.none
        )


frontendModel : Evergreen.V60.Types.FrontendModel -> ModelMigration Evergreen.V62.Types.FrontendModel Evergreen.V62.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V60.Types.FrontendMsg -> MsgMigration Evergreen.V62.Types.FrontendMsg Evergreen.V62.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V60.Types.BackendMsg -> MsgMigration Evergreen.V62.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V60.Types.BackendError -> Evergreen.V62.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V60.Types.PostmarkError a b ->
            Evergreen.V62.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V60.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V62.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V60.Types.BackendModel -> Evergreen.V62.Types.BackendModel
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
    , lastCacheRegeneration = old.lastCacheRegeneration
    }


migrateRequestedBy : Evergreen.V60.Types.LoginRequestedBy -> Evergreen.V62.Types.LoginRequestedBy
migrateRequestedBy old =
    case old of
        Evergreen.V60.Types.LoginRequestedByBackend ->
            Evergreen.V62.Types.LoginRequestedByBackend

        Evergreen.V60.Types.LoginRequestedByFrontend sessionId ->
            Evergreen.V62.Types.LoginRequestedByFrontend sessionId


migrateGrid : Evergreen.V60.Grid.Grid -> Evergreen.V62.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V60.Grid.Grid a ->
            Evergreen.V62.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V60.GridCell.Cell -> Evergreen.V62.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V60.GridCell.Cell a ->
            Evergreen.V62.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateDict identity identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V60.GridCell.Value -> Evergreen.V62.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V60.Bounds.Bounds a -> Evergreen.V62.Bounds.Bounds b
migrateBounds (Evergreen.V60.Bounds.Bounds old) =
    Evergreen.V62.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V60.Change.Cow -> Evergreen.V62.Change.Cow
migrateCow old =
    { position = migratePoint2d old.position }


migrateBackendMail : Evergreen.V60.MailEditor.BackendMail -> Evergreen.V62.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V60.MailEditor.MailStatus -> Evergreen.V62.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V60.MailEditor.MailWaitingPickup ->
            Evergreen.V62.MailEditor.MailWaitingPickup

        Evergreen.V60.MailEditor.MailInTransit a ->
            Evergreen.V62.MailEditor.MailInTransit (migrateId a)

        Evergreen.V60.MailEditor.MailReceived a ->
            Evergreen.V62.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V60.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V62.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V60.Types.Invite -> Evergreen.V62.Types.Invite
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


migrateEmailAddress (Evergreen.V60.EmailAddress.EmailAddress old) =
    Evergreen.V62.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V60.Id.SecretId a -> Evergreen.V62.Id.SecretId b
migrateSecretId (Evergreen.V60.Id.SecretId old) =
    Evergreen.V62.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V60.IdDict.IdDict a b -> Evergreen.V62.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V60.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V62.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V60.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V62.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V60.IdDict.NColor -> Evergreen.V62.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V60.IdDict.Red ->
            Evergreen.V62.IdDict.Red

        Evergreen.V60.IdDict.Black ->
            Evergreen.V62.IdDict.Black


migrateBackendUserData : Evergreen.V60.Types.BackendUserData -> Evergreen.V62.Types.BackendUserData
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


migrateEmailResult : Evergreen.V60.Types.EmailResult -> Evergreen.V62.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V60.Types.EmailSending ->
            Evergreen.V62.Types.EmailSending

        Evergreen.V60.Types.EmailSendFailed a ->
            Evergreen.V62.Types.EmailSendFailed a

        Evergreen.V60.Types.EmailSent a ->
            Evergreen.V62.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V60.Postmark.PostmarkSendResponse -> Evergreen.V62.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V60.Tile.Tile -> Evergreen.V62.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V60.Tile.EmptyTile ->
            Evergreen.V62.Tile.EmptyTile

        Evergreen.V60.Tile.HouseDown ->
            Evergreen.V62.Tile.HouseDown

        Evergreen.V60.Tile.HouseRight ->
            Evergreen.V62.Tile.HouseRight

        Evergreen.V60.Tile.HouseUp ->
            Evergreen.V62.Tile.HouseUp

        Evergreen.V60.Tile.HouseLeft ->
            Evergreen.V62.Tile.HouseLeft

        Evergreen.V60.Tile.RailHorizontal ->
            Evergreen.V62.Tile.RailHorizontal

        Evergreen.V60.Tile.RailVertical ->
            Evergreen.V62.Tile.RailVertical

        Evergreen.V60.Tile.RailBottomToRight ->
            Evergreen.V62.Tile.RailBottomToRight

        Evergreen.V60.Tile.RailBottomToLeft ->
            Evergreen.V62.Tile.RailBottomToLeft

        Evergreen.V60.Tile.RailTopToRight ->
            Evergreen.V62.Tile.RailTopToRight

        Evergreen.V60.Tile.RailTopToLeft ->
            Evergreen.V62.Tile.RailTopToLeft

        Evergreen.V60.Tile.RailBottomToRightLarge ->
            Evergreen.V62.Tile.RailBottomToRightLarge

        Evergreen.V60.Tile.RailBottomToLeftLarge ->
            Evergreen.V62.Tile.RailBottomToLeftLarge

        Evergreen.V60.Tile.RailTopToRightLarge ->
            Evergreen.V62.Tile.RailTopToRightLarge

        Evergreen.V60.Tile.RailTopToLeftLarge ->
            Evergreen.V62.Tile.RailTopToLeftLarge

        Evergreen.V60.Tile.RailCrossing ->
            Evergreen.V62.Tile.RailCrossing

        Evergreen.V60.Tile.RailStrafeDown ->
            Evergreen.V62.Tile.RailStrafeDown

        Evergreen.V60.Tile.RailStrafeUp ->
            Evergreen.V62.Tile.RailStrafeUp

        Evergreen.V60.Tile.RailStrafeLeft ->
            Evergreen.V62.Tile.RailStrafeLeft

        Evergreen.V60.Tile.RailStrafeRight ->
            Evergreen.V62.Tile.RailStrafeRight

        Evergreen.V60.Tile.TrainHouseRight ->
            Evergreen.V62.Tile.TrainHouseRight

        Evergreen.V60.Tile.TrainHouseLeft ->
            Evergreen.V62.Tile.TrainHouseLeft

        Evergreen.V60.Tile.RailStrafeDownSmall ->
            Evergreen.V62.Tile.RailStrafeDownSmall

        Evergreen.V60.Tile.RailStrafeUpSmall ->
            Evergreen.V62.Tile.RailStrafeUpSmall

        Evergreen.V60.Tile.RailStrafeLeftSmall ->
            Evergreen.V62.Tile.RailStrafeLeftSmall

        Evergreen.V60.Tile.RailStrafeRightSmall ->
            Evergreen.V62.Tile.RailStrafeRightSmall

        Evergreen.V60.Tile.Sidewalk ->
            Evergreen.V62.Tile.Sidewalk

        Evergreen.V60.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V62.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V60.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V62.Tile.SidewalkVerticalRailCrossing

        Evergreen.V60.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V62.Tile.RailBottomToRight_SplitLeft

        Evergreen.V60.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V62.Tile.RailBottomToLeft_SplitUp

        Evergreen.V60.Tile.RailTopToRight_SplitDown ->
            Evergreen.V62.Tile.RailTopToRight_SplitDown

        Evergreen.V60.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V62.Tile.RailTopToLeft_SplitRight

        Evergreen.V60.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V62.Tile.RailBottomToRight_SplitUp

        Evergreen.V60.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V62.Tile.RailBottomToLeft_SplitRight

        Evergreen.V60.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V62.Tile.RailTopToRight_SplitLeft

        Evergreen.V60.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V62.Tile.RailTopToLeft_SplitDown

        Evergreen.V60.Tile.PostOffice ->
            Evergreen.V62.Tile.PostOffice

        Evergreen.V60.Tile.MowedGrass1 ->
            Evergreen.V62.Tile.MowedGrass1

        Evergreen.V60.Tile.MowedGrass4 ->
            Evergreen.V62.Tile.MowedGrass4

        Evergreen.V60.Tile.LogCabinDown ->
            Evergreen.V62.Tile.LogCabinDown

        Evergreen.V60.Tile.LogCabinRight ->
            Evergreen.V62.Tile.LogCabinRight

        Evergreen.V60.Tile.LogCabinUp ->
            Evergreen.V62.Tile.LogCabinUp

        Evergreen.V60.Tile.LogCabinLeft ->
            Evergreen.V62.Tile.LogCabinLeft

        Evergreen.V60.Tile.RoadHorizontal ->
            Evergreen.V62.Tile.RoadHorizontal

        Evergreen.V60.Tile.RoadVertical ->
            Evergreen.V62.Tile.RoadVertical

        Evergreen.V60.Tile.RoadBottomToLeft ->
            Evergreen.V62.Tile.RoadBottomToLeft

        Evergreen.V60.Tile.RoadTopToLeft ->
            Evergreen.V62.Tile.RoadTopToLeft

        Evergreen.V60.Tile.RoadTopToRight ->
            Evergreen.V62.Tile.RoadTopToRight

        Evergreen.V60.Tile.RoadBottomToRight ->
            Evergreen.V62.Tile.RoadBottomToRight

        Evergreen.V60.Tile.Road4Way ->
            Evergreen.V62.Tile.Road4Way

        Evergreen.V60.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V62.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V60.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V62.Tile.RoadSidewalkCrossingVertical

        Evergreen.V60.Tile.Road3WayDown ->
            Evergreen.V62.Tile.Road3WayDown

        Evergreen.V60.Tile.Road3WayLeft ->
            Evergreen.V62.Tile.Road3WayLeft

        Evergreen.V60.Tile.Road3WayUp ->
            Evergreen.V62.Tile.Road3WayUp

        Evergreen.V60.Tile.Road3WayRight ->
            Evergreen.V62.Tile.Road3WayRight

        Evergreen.V60.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V62.Tile.RoadRailCrossingHorizontal

        Evergreen.V60.Tile.RoadRailCrossingVertical ->
            Evergreen.V62.Tile.RoadRailCrossingVertical

        Evergreen.V60.Tile.FenceHorizontal ->
            Evergreen.V62.Tile.FenceHorizontal

        Evergreen.V60.Tile.FenceVertical ->
            Evergreen.V62.Tile.FenceVertical

        Evergreen.V60.Tile.FenceDiagonal ->
            Evergreen.V62.Tile.FenceDiagonal

        Evergreen.V60.Tile.FenceAntidiagonal ->
            Evergreen.V62.Tile.FenceAntidiagonal

        Evergreen.V60.Tile.RoadDeadendUp ->
            Evergreen.V62.Tile.RoadDeadendUp

        Evergreen.V60.Tile.RoadDeadendDown ->
            Evergreen.V62.Tile.RoadDeadendDown

        Evergreen.V60.Tile.BusStopDown ->
            Evergreen.V62.Tile.BusStopDown

        Evergreen.V60.Tile.BusStopLeft ->
            Evergreen.V62.Tile.BusStopLeft

        Evergreen.V60.Tile.BusStopRight ->
            Evergreen.V62.Tile.BusStopRight

        Evergreen.V60.Tile.BusStopUp ->
            Evergreen.V62.Tile.BusStopUp

        Evergreen.V60.Tile.Hospital ->
            Evergreen.V62.Tile.Hospital

        Evergreen.V60.Tile.Statue ->
            Evergreen.V62.Tile.Statue

        Evergreen.V60.Tile.HedgeRowDown ->
            Evergreen.V62.Tile.HedgeRowDown

        Evergreen.V60.Tile.HedgeRowLeft ->
            Evergreen.V62.Tile.HedgeRowLeft

        Evergreen.V60.Tile.HedgeRowRight ->
            Evergreen.V62.Tile.HedgeRowRight

        Evergreen.V60.Tile.HedgeRowUp ->
            Evergreen.V62.Tile.HedgeRowUp

        Evergreen.V60.Tile.HedgeCornerDownLeft ->
            Evergreen.V62.Tile.HedgeCornerDownLeft

        Evergreen.V60.Tile.HedgeCornerDownRight ->
            Evergreen.V62.Tile.HedgeCornerDownRight

        Evergreen.V60.Tile.HedgeCornerUpLeft ->
            Evergreen.V62.Tile.HedgeCornerUpLeft

        Evergreen.V60.Tile.HedgeCornerUpRight ->
            Evergreen.V62.Tile.HedgeCornerUpRight

        Evergreen.V60.Tile.ApartmentDown ->
            Evergreen.V62.Tile.ApartmentDown

        Evergreen.V60.Tile.ApartmentLeft ->
            Evergreen.V62.Tile.ApartmentLeft

        Evergreen.V60.Tile.ApartmentRight ->
            Evergreen.V62.Tile.ApartmentRight

        Evergreen.V60.Tile.ApartmentUp ->
            Evergreen.V62.Tile.ApartmentUp

        Evergreen.V60.Tile.RockDown ->
            Evergreen.V62.Tile.RockDown

        Evergreen.V60.Tile.RockLeft ->
            Evergreen.V62.Tile.RockLeft

        Evergreen.V60.Tile.RockRight ->
            Evergreen.V62.Tile.RockRight

        Evergreen.V60.Tile.RockUp ->
            Evergreen.V62.Tile.RockUp

        Evergreen.V60.Tile.PineTree1 ->
            Evergreen.V62.Tile.PineTree1

        Evergreen.V60.Tile.PineTree2 ->
            Evergreen.V62.Tile.PineTree2

        Evergreen.V60.Tile.HedgePillarDownLeft ->
            Evergreen.V62.Tile.HedgePillarDownLeft

        Evergreen.V60.Tile.HedgePillarDownRight ->
            Evergreen.V62.Tile.HedgePillarDownRight

        Evergreen.V60.Tile.HedgePillarUpLeft ->
            Evergreen.V62.Tile.HedgePillarUpLeft

        Evergreen.V60.Tile.HedgePillarUpRight ->
            Evergreen.V62.Tile.HedgePillarUpRight

        Evergreen.V60.Tile.Flowers1 ->
            Evergreen.V62.Tile.Flowers1

        Evergreen.V60.Tile.Flowers2 ->
            Evergreen.V62.Tile.Flowers2

        Evergreen.V60.Tile.ElmTree ->
            Evergreen.V62.Tile.ElmTree

        Evergreen.V60.Tile.DirtPathHorizontal ->
            Evergreen.V62.Tile.DirtPathHorizontal

        Evergreen.V60.Tile.DirtPathVertical ->
            Evergreen.V62.Tile.DirtPathVertical

        Evergreen.V60.Tile.BigText char ->
            Evergreen.V62.Tile.BigText char

        Evergreen.V60.Tile.BigPineTree ->
            Evergreen.V62.Tile.BigPineTree

        Evergreen.V60.Tile.Hyperlink ->
            Evergreen.V62.Tile.Hyperlink

        Evergreen.V60.Tile.BenchDown ->
            Evergreen.V62.Tile.BenchDown

        Evergreen.V60.Tile.BenchLeft ->
            Evergreen.V62.Tile.BenchLeft

        Evergreen.V60.Tile.BenchUp ->
            Evergreen.V62.Tile.BenchUp

        Evergreen.V60.Tile.BenchRight ->
            Evergreen.V62.Tile.BenchRight

        Evergreen.V60.Tile.ParkingDown ->
            Evergreen.V62.Tile.ParkingDown

        Evergreen.V60.Tile.ParkingLeft ->
            Evergreen.V62.Tile.ParkingLeft

        Evergreen.V60.Tile.ParkingUp ->
            Evergreen.V62.Tile.ParkingUp

        Evergreen.V60.Tile.ParkingRight ->
            Evergreen.V62.Tile.ParkingRight

        Evergreen.V60.Tile.ParkingExitDown ->
            Evergreen.V62.Tile.RoadVertical

        Evergreen.V60.Tile.ParkingExitLeft ->
            Evergreen.V62.Tile.RoadHorizontal

        Evergreen.V60.Tile.ParkingExitUp ->
            Evergreen.V62.Tile.RoadVertical

        Evergreen.V60.Tile.ParkingExitRight ->
            Evergreen.V62.Tile.RoadHorizontal

        Evergreen.V60.Tile.ParkingRoad ->
            Evergreen.V62.Tile.ParkingRoad

        Evergreen.V60.Tile.ParkingRoundabout ->
            Evergreen.V62.Tile.ParkingRoundabout


migrateTrain : Evergreen.V60.Train.Train -> Evergreen.V62.Train.Train
migrateTrain old =
    case old of
        Evergreen.V60.Train.Train a ->
            Evergreen.V62.Train.Train
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


migrateStatus : Evergreen.V60.Train.Status -> Evergreen.V62.Train.Status
migrateStatus old =
    case old of
        Evergreen.V60.Train.WaitingAtHome ->
            Evergreen.V62.Train.WaitingAtHome

        Evergreen.V60.Train.TeleportingHome a ->
            Evergreen.V62.Train.TeleportingHome (migratePosix a)

        Evergreen.V60.Train.Travelling ->
            Evergreen.V62.Train.Travelling

        Evergreen.V60.Train.StoppedAtPostOffice a ->
            Evergreen.V62.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V60.Tile.RailPath -> Evergreen.V62.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V60.Tile.RailPathHorizontal a ->
            Evergreen.V62.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V60.Tile.RailPathVertical a ->
            Evergreen.V62.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V60.Tile.RailPathBottomToRight ->
            Evergreen.V62.Tile.RailPathBottomToRight

        Evergreen.V60.Tile.RailPathBottomToLeft ->
            Evergreen.V62.Tile.RailPathBottomToLeft

        Evergreen.V60.Tile.RailPathTopToRight ->
            Evergreen.V62.Tile.RailPathTopToRight

        Evergreen.V60.Tile.RailPathTopToLeft ->
            Evergreen.V62.Tile.RailPathTopToLeft

        Evergreen.V60.Tile.RailPathBottomToRightLarge ->
            Evergreen.V62.Tile.RailPathBottomToRightLarge

        Evergreen.V60.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V62.Tile.RailPathBottomToLeftLarge

        Evergreen.V60.Tile.RailPathTopToRightLarge ->
            Evergreen.V62.Tile.RailPathTopToRightLarge

        Evergreen.V60.Tile.RailPathTopToLeftLarge ->
            Evergreen.V62.Tile.RailPathTopToLeftLarge

        Evergreen.V60.Tile.RailPathStrafeDown ->
            Evergreen.V62.Tile.RailPathStrafeDown

        Evergreen.V60.Tile.RailPathStrafeUp ->
            Evergreen.V62.Tile.RailPathStrafeUp

        Evergreen.V60.Tile.RailPathStrafeLeft ->
            Evergreen.V62.Tile.RailPathStrafeLeft

        Evergreen.V60.Tile.RailPathStrafeRight ->
            Evergreen.V62.Tile.RailPathStrafeRight

        Evergreen.V60.Tile.RailPathStrafeDownSmall ->
            Evergreen.V62.Tile.RailPathStrafeDownSmall

        Evergreen.V60.Tile.RailPathStrafeUpSmall ->
            Evergreen.V62.Tile.RailPathStrafeUpSmall

        Evergreen.V60.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V62.Tile.RailPathStrafeLeftSmall

        Evergreen.V60.Tile.RailPathStrafeRightSmall ->
            Evergreen.V62.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V60.Train.PreviousPath -> Evergreen.V62.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V60.MailEditor.Image -> Evergreen.V62.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V60.MailEditor.Stamp a ->
            Evergreen.V62.MailEditor.Stamp (migrateColors a)

        Evergreen.V60.MailEditor.SunglassesEmoji a ->
            Evergreen.V62.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V60.MailEditor.NormalEmoji a ->
            Evergreen.V62.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V60.MailEditor.SadEmoji a ->
            Evergreen.V62.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V60.MailEditor.Cow a ->
            Evergreen.V62.MailEditor.Cow (migrateColors a)

        Evergreen.V60.MailEditor.Man a ->
            Evergreen.V62.MailEditor.Man (migrateColors a)

        Evergreen.V60.MailEditor.TileImage a b c ->
            Evergreen.V62.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V60.MailEditor.Grass ->
            Evergreen.V62.MailEditor.Grass

        Evergreen.V60.MailEditor.DefaultCursor a ->
            Evergreen.V62.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V60.MailEditor.DragCursor a ->
            Evergreen.V62.MailEditor.DragCursor (migrateColors a)

        Evergreen.V60.MailEditor.PinchCursor a ->
            Evergreen.V62.MailEditor.PinchCursor (migrateColors a)

        Evergreen.V60.MailEditor.Line int color ->
            Evergreen.V62.MailEditor.Line int (migrateColor color)


migrateTileGroup : Evergreen.V60.Tile.TileGroup -> Evergreen.V62.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V60.Tile.EmptyTileGroup ->
            Evergreen.V62.Tile.EmptyTileGroup

        Evergreen.V60.Tile.HouseGroup ->
            Evergreen.V62.Tile.HouseGroup

        Evergreen.V60.Tile.RailStraightGroup ->
            Evergreen.V62.Tile.RailStraightGroup

        Evergreen.V60.Tile.RailTurnGroup ->
            Evergreen.V62.Tile.RailTurnGroup

        Evergreen.V60.Tile.RailTurnLargeGroup ->
            Evergreen.V62.Tile.RailTurnLargeGroup

        Evergreen.V60.Tile.RailStrafeGroup ->
            Evergreen.V62.Tile.RailStrafeGroup

        Evergreen.V60.Tile.RailStrafeSmallGroup ->
            Evergreen.V62.Tile.RailStrafeSmallGroup

        Evergreen.V60.Tile.RailCrossingGroup ->
            Evergreen.V62.Tile.RailCrossingGroup

        Evergreen.V60.Tile.TrainHouseGroup ->
            Evergreen.V62.Tile.TrainHouseGroup

        Evergreen.V60.Tile.SidewalkGroup ->
            Evergreen.V62.Tile.SidewalkGroup

        Evergreen.V60.Tile.SidewalkRailGroup ->
            Evergreen.V62.Tile.SidewalkRailGroup

        Evergreen.V60.Tile.RailTurnSplitGroup ->
            Evergreen.V62.Tile.RailTurnSplitGroup

        Evergreen.V60.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V62.Tile.RailTurnSplitMirrorGroup

        Evergreen.V60.Tile.PostOfficeGroup ->
            Evergreen.V62.Tile.PostOfficeGroup

        Evergreen.V60.Tile.PineTreeGroup ->
            Evergreen.V62.Tile.PineTreeGroup

        Evergreen.V60.Tile.LogCabinGroup ->
            Evergreen.V62.Tile.LogCabinGroup

        Evergreen.V60.Tile.RoadStraightGroup ->
            Evergreen.V62.Tile.RoadStraightGroup

        Evergreen.V60.Tile.RoadTurnGroup ->
            Evergreen.V62.Tile.RoadTurnGroup

        Evergreen.V60.Tile.Road4WayGroup ->
            Evergreen.V62.Tile.Road4WayGroup

        Evergreen.V60.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V62.Tile.RoadSidewalkCrossingGroup

        Evergreen.V60.Tile.Road3WayGroup ->
            Evergreen.V62.Tile.Road3WayGroup

        Evergreen.V60.Tile.RoadRailCrossingGroup ->
            Evergreen.V62.Tile.RoadRailCrossingGroup

        Evergreen.V60.Tile.RoadDeadendGroup ->
            Evergreen.V62.Tile.RoadDeadendGroup

        Evergreen.V60.Tile.FenceStraightGroup ->
            Evergreen.V62.Tile.FenceStraightGroup

        Evergreen.V60.Tile.BusStopGroup ->
            Evergreen.V62.Tile.BusStopGroup

        Evergreen.V60.Tile.HospitalGroup ->
            Evergreen.V62.Tile.HospitalGroup

        Evergreen.V60.Tile.StatueGroup ->
            Evergreen.V62.Tile.StatueGroup

        Evergreen.V60.Tile.HedgeRowGroup ->
            Evergreen.V62.Tile.HedgeRowGroup

        Evergreen.V60.Tile.HedgeCornerGroup ->
            Evergreen.V62.Tile.HedgeCornerGroup

        Evergreen.V60.Tile.ApartmentGroup ->
            Evergreen.V62.Tile.ApartmentGroup

        Evergreen.V60.Tile.RockGroup ->
            Evergreen.V62.Tile.RockGroup

        Evergreen.V60.Tile.FlowersGroup ->
            Evergreen.V62.Tile.FlowersGroup

        Evergreen.V60.Tile.HedgePillarGroup ->
            Evergreen.V62.Tile.HedgePillarGroup

        Evergreen.V60.Tile.ElmTreeGroup ->
            Evergreen.V62.Tile.ElmTreeGroup

        Evergreen.V60.Tile.DirtPathGroup ->
            Evergreen.V62.Tile.DirtPathGroup

        Evergreen.V60.Tile.BigTextGroup ->
            Evergreen.V62.Tile.BigTextGroup

        Evergreen.V60.Tile.BigPineTreeGroup ->
            Evergreen.V62.Tile.BigPineTreeGroup

        Evergreen.V60.Tile.HyperlinkGroup ->
            Evergreen.V62.Tile.HyperlinkGroup

        Evergreen.V60.Tile.BenchGroup ->
            Evergreen.V62.Tile.BenchGroup

        Evergreen.V60.Tile.ParkingLotGroup ->
            Evergreen.V62.Tile.ParkingLotGroup

        Evergreen.V60.Tile.ParkingExitGroup ->
            Evergreen.V62.Tile.RoadStraightGroup

        Evergreen.V60.Tile.ParkingRoadGroup ->
            Evergreen.V62.Tile.ParkingRoadGroup

        Evergreen.V60.Tile.ParkingRoundaboutGroup ->
            Evergreen.V62.Tile.ParkingRoundaboutGroup


migrateDisplayName : Evergreen.V60.DisplayName.DisplayName -> Evergreen.V62.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V60.DisplayName.DisplayName a ->
            Evergreen.V62.DisplayName.DisplayName a


migrateCursor : Evergreen.V60.Cursor.Cursor -> Evergreen.V62.Cursor.Cursor
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
        Evergreen.V62.Cursor.HandTool
    }


migrateContent : Evergreen.V60.MailEditor.Content -> Evergreen.V62.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, item = migrateImageOrText old.item }


migrateImageOrText : Evergreen.V60.MailEditor.ImageOrText -> Evergreen.V62.MailEditor.ImageOrText
migrateImageOrText old =
    case old of
        Evergreen.V60.MailEditor.ImageType imageType ->
            migrateImage imageType |> Evergreen.V62.MailEditor.ImageType

        Evergreen.V60.MailEditor.TextType string ->
            Evergreen.V62.MailEditor.TextType string


migrateColors : Evergreen.V60.Color.Colors -> Evergreen.V62.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V60.Color.Color -> Evergreen.V62.Color.Color
migrateColor old =
    case old of
        Evergreen.V60.Color.Color a ->
            Evergreen.V62.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V60.Types.ViewPoint -> Evergreen.V62.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V60.Types.NormalViewPoint a ->
            Evergreen.V62.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V60.Types.TrainViewPoint a ->
            Evergreen.V62.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V60.Geometry.Types.Point2d old) =
    Evergreen.V62.Geometry.Types.Point2d old


migrateId : Evergreen.V60.Id.Id a -> Evergreen.V62.Id.Id b
migrateId (Evergreen.V60.Id.Id old) =
    Evergreen.V62.Id.Id old
