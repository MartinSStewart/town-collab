module Evergreen.Migrate.V69 exposing (..)

import AssocList
import AssocSet
import Dict
import Effect.Time
import Evergreen.V67.Bounds
import Evergreen.V67.Change
import Evergreen.V67.Color
import Evergreen.V67.Cursor
import Evergreen.V67.DisplayName
import Evergreen.V67.EmailAddress
import Evergreen.V67.Geometry.Types
import Evergreen.V67.Grid
import Evergreen.V67.GridCell
import Evergreen.V67.Id
import Evergreen.V67.IdDict
import Evergreen.V67.MailEditor
import Evergreen.V67.Postmark
import Evergreen.V67.Tile
import Evergreen.V67.Train
import Evergreen.V67.Types
import Evergreen.V69.Bounds
import Evergreen.V69.Change
import Evergreen.V69.Color
import Evergreen.V69.Cursor
import Evergreen.V69.DisplayName
import Evergreen.V69.EmailAddress
import Evergreen.V69.Geometry.Types
import Evergreen.V69.Grid
import Evergreen.V69.GridCell
import Evergreen.V69.Id
import Evergreen.V69.IdDict
import Evergreen.V69.MailEditor
import Evergreen.V69.Postmark
import Evergreen.V69.Tile
import Evergreen.V69.Train
import Evergreen.V69.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Quantity exposing (Quantity)


backendModel : Evergreen.V67.Types.BackendModel -> ModelMigration Evergreen.V69.Types.BackendModel Evergreen.V69.Types.BackendMsg
backendModel old =
    ModelMigrated
        ( migrateBackendModel old
        , Cmd.none
        )


frontendModel : Evergreen.V67.Types.FrontendModel -> ModelMigration Evergreen.V69.Types.FrontendModel Evergreen.V69.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V67.Types.FrontendMsg -> MsgMigration Evergreen.V69.Types.FrontendMsg Evergreen.V69.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V67.Types.BackendMsg -> MsgMigration Evergreen.V69.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V67.Types.BackendError -> Evergreen.V69.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V67.Types.PostmarkError a b ->
            Evergreen.V69.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V67.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V69.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V67.Types.BackendModel -> Evergreen.V69.Types.BackendModel
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
    , reported = Evergreen.V69.IdDict.RBEmpty_elm_builtin
    }


migrateRequestedBy : Evergreen.V67.Types.LoginRequestedBy -> Evergreen.V69.Types.LoginRequestedBy
migrateRequestedBy old =
    case old of
        Evergreen.V67.Types.LoginRequestedByBackend ->
            Evergreen.V69.Types.LoginRequestedByBackend

        Evergreen.V67.Types.LoginRequestedByFrontend sessionId ->
            Evergreen.V69.Types.LoginRequestedByFrontend sessionId


migrateGrid : Evergreen.V67.Grid.Grid -> Evergreen.V69.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V67.Grid.Grid a ->
            Evergreen.V69.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V67.GridCell.Cell -> Evergreen.V69.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V67.GridCell.Cell a ->
            Evergreen.V69.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateIdDict identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V67.GridCell.Value -> Evergreen.V69.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V67.Bounds.Bounds a -> Evergreen.V69.Bounds.Bounds b
migrateBounds (Evergreen.V67.Bounds.Bounds old) =
    Evergreen.V69.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V67.Change.Cow -> Evergreen.V69.Change.Cow
migrateCow old =
    { position = migratePoint2d old.position }


migrateBackendMail : Evergreen.V67.MailEditor.BackendMail -> Evergreen.V69.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V67.MailEditor.MailStatus -> Evergreen.V69.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V67.MailEditor.MailWaitingPickup ->
            Evergreen.V69.MailEditor.MailWaitingPickup

        Evergreen.V67.MailEditor.MailInTransit a ->
            Evergreen.V69.MailEditor.MailInTransit (migrateId a)

        Evergreen.V67.MailEditor.MailReceived a ->
            Evergreen.V69.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V67.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V69.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V67.Types.Invite -> Evergreen.V69.Types.Invite
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


migrateEmailAddress (Evergreen.V67.EmailAddress.EmailAddress old) =
    Evergreen.V69.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V67.Id.SecretId a -> Evergreen.V69.Id.SecretId b
migrateSecretId (Evergreen.V67.Id.SecretId old) =
    Evergreen.V69.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V67.IdDict.IdDict a b -> Evergreen.V69.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V67.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V69.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V67.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V69.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V67.IdDict.NColor -> Evergreen.V69.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V67.IdDict.Red ->
            Evergreen.V69.IdDict.Red

        Evergreen.V67.IdDict.Black ->
            Evergreen.V69.IdDict.Black


migrateBackendUserData : Evergreen.V67.Types.BackendUserData -> Evergreen.V69.Types.BackendUserData
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


migrateEmailResult : Evergreen.V67.Types.EmailResult -> Evergreen.V69.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V67.Types.EmailSending ->
            Evergreen.V69.Types.EmailSending

        Evergreen.V67.Types.EmailSendFailed a ->
            Evergreen.V69.Types.EmailSendFailed a

        Evergreen.V67.Types.EmailSent a ->
            Evergreen.V69.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V67.Postmark.PostmarkSendResponse -> Evergreen.V69.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V67.Tile.Tile -> Evergreen.V69.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V67.Tile.EmptyTile ->
            Evergreen.V69.Tile.EmptyTile

        Evergreen.V67.Tile.HouseDown ->
            Evergreen.V69.Tile.HouseDown

        Evergreen.V67.Tile.HouseRight ->
            Evergreen.V69.Tile.HouseRight

        Evergreen.V67.Tile.HouseUp ->
            Evergreen.V69.Tile.HouseUp

        Evergreen.V67.Tile.HouseLeft ->
            Evergreen.V69.Tile.HouseLeft

        Evergreen.V67.Tile.RailHorizontal ->
            Evergreen.V69.Tile.RailHorizontal

        Evergreen.V67.Tile.RailVertical ->
            Evergreen.V69.Tile.RailVertical

        Evergreen.V67.Tile.RailBottomToRight ->
            Evergreen.V69.Tile.RailBottomToRight

        Evergreen.V67.Tile.RailBottomToLeft ->
            Evergreen.V69.Tile.RailBottomToLeft

        Evergreen.V67.Tile.RailTopToRight ->
            Evergreen.V69.Tile.RailTopToRight

        Evergreen.V67.Tile.RailTopToLeft ->
            Evergreen.V69.Tile.RailTopToLeft

        Evergreen.V67.Tile.RailBottomToRightLarge ->
            Evergreen.V69.Tile.RailBottomToRightLarge

        Evergreen.V67.Tile.RailBottomToLeftLarge ->
            Evergreen.V69.Tile.RailBottomToLeftLarge

        Evergreen.V67.Tile.RailTopToRightLarge ->
            Evergreen.V69.Tile.RailTopToRightLarge

        Evergreen.V67.Tile.RailTopToLeftLarge ->
            Evergreen.V69.Tile.RailTopToLeftLarge

        Evergreen.V67.Tile.RailCrossing ->
            Evergreen.V69.Tile.RailCrossing

        Evergreen.V67.Tile.RailStrafeDown ->
            Evergreen.V69.Tile.RailStrafeDown

        Evergreen.V67.Tile.RailStrafeUp ->
            Evergreen.V69.Tile.RailStrafeUp

        Evergreen.V67.Tile.RailStrafeLeft ->
            Evergreen.V69.Tile.RailStrafeLeft

        Evergreen.V67.Tile.RailStrafeRight ->
            Evergreen.V69.Tile.RailStrafeRight

        Evergreen.V67.Tile.TrainHouseRight ->
            Evergreen.V69.Tile.TrainHouseRight

        Evergreen.V67.Tile.TrainHouseLeft ->
            Evergreen.V69.Tile.TrainHouseLeft

        Evergreen.V67.Tile.RailStrafeDownSmall ->
            Evergreen.V69.Tile.RailStrafeDownSmall

        Evergreen.V67.Tile.RailStrafeUpSmall ->
            Evergreen.V69.Tile.RailStrafeUpSmall

        Evergreen.V67.Tile.RailStrafeLeftSmall ->
            Evergreen.V69.Tile.RailStrafeLeftSmall

        Evergreen.V67.Tile.RailStrafeRightSmall ->
            Evergreen.V69.Tile.RailStrafeRightSmall

        Evergreen.V67.Tile.Sidewalk ->
            Evergreen.V69.Tile.Sidewalk

        Evergreen.V67.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V69.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V67.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V69.Tile.SidewalkVerticalRailCrossing

        Evergreen.V67.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V69.Tile.RailBottomToRight_SplitLeft

        Evergreen.V67.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V69.Tile.RailBottomToLeft_SplitUp

        Evergreen.V67.Tile.RailTopToRight_SplitDown ->
            Evergreen.V69.Tile.RailTopToRight_SplitDown

        Evergreen.V67.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V69.Tile.RailTopToLeft_SplitRight

        Evergreen.V67.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V69.Tile.RailBottomToRight_SplitUp

        Evergreen.V67.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V69.Tile.RailBottomToLeft_SplitRight

        Evergreen.V67.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V69.Tile.RailTopToRight_SplitLeft

        Evergreen.V67.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V69.Tile.RailTopToLeft_SplitDown

        Evergreen.V67.Tile.PostOffice ->
            Evergreen.V69.Tile.PostOffice

        Evergreen.V67.Tile.MowedGrass1 ->
            Evergreen.V69.Tile.MowedGrass1

        Evergreen.V67.Tile.MowedGrass4 ->
            Evergreen.V69.Tile.MowedGrass4

        Evergreen.V67.Tile.LogCabinDown ->
            Evergreen.V69.Tile.LogCabinDown

        Evergreen.V67.Tile.LogCabinRight ->
            Evergreen.V69.Tile.LogCabinRight

        Evergreen.V67.Tile.LogCabinUp ->
            Evergreen.V69.Tile.LogCabinUp

        Evergreen.V67.Tile.LogCabinLeft ->
            Evergreen.V69.Tile.LogCabinLeft

        Evergreen.V67.Tile.RoadHorizontal ->
            Evergreen.V69.Tile.RoadHorizontal

        Evergreen.V67.Tile.RoadVertical ->
            Evergreen.V69.Tile.RoadVertical

        Evergreen.V67.Tile.RoadBottomToLeft ->
            Evergreen.V69.Tile.RoadBottomToLeft

        Evergreen.V67.Tile.RoadTopToLeft ->
            Evergreen.V69.Tile.RoadTopToLeft

        Evergreen.V67.Tile.RoadTopToRight ->
            Evergreen.V69.Tile.RoadTopToRight

        Evergreen.V67.Tile.RoadBottomToRight ->
            Evergreen.V69.Tile.RoadBottomToRight

        Evergreen.V67.Tile.Road4Way ->
            Evergreen.V69.Tile.Road4Way

        Evergreen.V67.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V69.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V67.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V69.Tile.RoadSidewalkCrossingVertical

        Evergreen.V67.Tile.Road3WayDown ->
            Evergreen.V69.Tile.Road3WayDown

        Evergreen.V67.Tile.Road3WayLeft ->
            Evergreen.V69.Tile.Road3WayLeft

        Evergreen.V67.Tile.Road3WayUp ->
            Evergreen.V69.Tile.Road3WayUp

        Evergreen.V67.Tile.Road3WayRight ->
            Evergreen.V69.Tile.Road3WayRight

        Evergreen.V67.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V69.Tile.RoadRailCrossingHorizontal

        Evergreen.V67.Tile.RoadRailCrossingVertical ->
            Evergreen.V69.Tile.RoadRailCrossingVertical

        Evergreen.V67.Tile.FenceHorizontal ->
            Evergreen.V69.Tile.FenceHorizontal

        Evergreen.V67.Tile.FenceVertical ->
            Evergreen.V69.Tile.FenceVertical

        Evergreen.V67.Tile.FenceDiagonal ->
            Evergreen.V69.Tile.FenceDiagonal

        Evergreen.V67.Tile.FenceAntidiagonal ->
            Evergreen.V69.Tile.FenceAntidiagonal

        Evergreen.V67.Tile.RoadDeadendUp ->
            Evergreen.V69.Tile.RoadDeadendUp

        Evergreen.V67.Tile.RoadDeadendDown ->
            Evergreen.V69.Tile.RoadDeadendDown

        Evergreen.V67.Tile.BusStopDown ->
            Evergreen.V69.Tile.BusStopDown

        Evergreen.V67.Tile.BusStopLeft ->
            Evergreen.V69.Tile.BusStopLeft

        Evergreen.V67.Tile.BusStopRight ->
            Evergreen.V69.Tile.BusStopRight

        Evergreen.V67.Tile.BusStopUp ->
            Evergreen.V69.Tile.BusStopUp

        Evergreen.V67.Tile.Hospital ->
            Evergreen.V69.Tile.Hospital

        Evergreen.V67.Tile.Statue ->
            Evergreen.V69.Tile.Statue

        Evergreen.V67.Tile.HedgeRowDown ->
            Evergreen.V69.Tile.HedgeRowDown

        Evergreen.V67.Tile.HedgeRowLeft ->
            Evergreen.V69.Tile.HedgeRowLeft

        Evergreen.V67.Tile.HedgeRowRight ->
            Evergreen.V69.Tile.HedgeRowRight

        Evergreen.V67.Tile.HedgeRowUp ->
            Evergreen.V69.Tile.HedgeRowUp

        Evergreen.V67.Tile.HedgeCornerDownLeft ->
            Evergreen.V69.Tile.HedgeCornerDownLeft

        Evergreen.V67.Tile.HedgeCornerDownRight ->
            Evergreen.V69.Tile.HedgeCornerDownRight

        Evergreen.V67.Tile.HedgeCornerUpLeft ->
            Evergreen.V69.Tile.HedgeCornerUpLeft

        Evergreen.V67.Tile.HedgeCornerUpRight ->
            Evergreen.V69.Tile.HedgeCornerUpRight

        Evergreen.V67.Tile.ApartmentDown ->
            Evergreen.V69.Tile.ApartmentDown

        Evergreen.V67.Tile.ApartmentLeft ->
            Evergreen.V69.Tile.ApartmentLeft

        Evergreen.V67.Tile.ApartmentRight ->
            Evergreen.V69.Tile.ApartmentRight

        Evergreen.V67.Tile.ApartmentUp ->
            Evergreen.V69.Tile.ApartmentUp

        Evergreen.V67.Tile.RockDown ->
            Evergreen.V69.Tile.RockDown

        Evergreen.V67.Tile.RockLeft ->
            Evergreen.V69.Tile.RockLeft

        Evergreen.V67.Tile.RockRight ->
            Evergreen.V69.Tile.RockRight

        Evergreen.V67.Tile.RockUp ->
            Evergreen.V69.Tile.RockUp

        Evergreen.V67.Tile.PineTree1 ->
            Evergreen.V69.Tile.PineTree1

        Evergreen.V67.Tile.PineTree2 ->
            Evergreen.V69.Tile.PineTree2

        Evergreen.V67.Tile.HedgePillarDownLeft ->
            Evergreen.V69.Tile.HedgePillarDownLeft

        Evergreen.V67.Tile.HedgePillarDownRight ->
            Evergreen.V69.Tile.HedgePillarDownRight

        Evergreen.V67.Tile.HedgePillarUpLeft ->
            Evergreen.V69.Tile.HedgePillarUpLeft

        Evergreen.V67.Tile.HedgePillarUpRight ->
            Evergreen.V69.Tile.HedgePillarUpRight

        Evergreen.V67.Tile.Flowers1 ->
            Evergreen.V69.Tile.Flowers1

        Evergreen.V67.Tile.Flowers2 ->
            Evergreen.V69.Tile.Flowers2

        Evergreen.V67.Tile.ElmTree ->
            Evergreen.V69.Tile.ElmTree

        Evergreen.V67.Tile.DirtPathHorizontal ->
            Evergreen.V69.Tile.DirtPathHorizontal

        Evergreen.V67.Tile.DirtPathVertical ->
            Evergreen.V69.Tile.DirtPathVertical

        Evergreen.V67.Tile.BigText char ->
            Evergreen.V69.Tile.BigText char

        Evergreen.V67.Tile.BigPineTree ->
            Evergreen.V69.Tile.BigPineTree

        Evergreen.V67.Tile.Hyperlink ->
            Evergreen.V69.Tile.Hyperlink

        Evergreen.V67.Tile.BenchDown ->
            Evergreen.V69.Tile.BenchDown

        Evergreen.V67.Tile.BenchLeft ->
            Evergreen.V69.Tile.BenchLeft

        Evergreen.V67.Tile.BenchUp ->
            Evergreen.V69.Tile.BenchUp

        Evergreen.V67.Tile.BenchRight ->
            Evergreen.V69.Tile.BenchRight

        Evergreen.V67.Tile.ParkingDown ->
            Evergreen.V69.Tile.ParkingDown

        Evergreen.V67.Tile.ParkingLeft ->
            Evergreen.V69.Tile.ParkingLeft

        Evergreen.V67.Tile.ParkingUp ->
            Evergreen.V69.Tile.ParkingUp

        Evergreen.V67.Tile.ParkingRight ->
            Evergreen.V69.Tile.ParkingRight

        Evergreen.V67.Tile.ParkingRoad ->
            Evergreen.V69.Tile.ParkingRoad

        Evergreen.V67.Tile.ParkingRoundabout ->
            Evergreen.V69.Tile.ParkingRoundabout

        Evergreen.V67.Tile.CornerHouseUpLeft ->
            Evergreen.V69.Tile.CornerHouseUpLeft

        Evergreen.V67.Tile.CornerHouseUpRight ->
            Evergreen.V69.Tile.CornerHouseUpRight

        Evergreen.V67.Tile.CornerHouseDownLeft ->
            Evergreen.V69.Tile.CornerHouseDownLeft

        Evergreen.V67.Tile.CornerHouseDownRight ->
            Evergreen.V69.Tile.CornerHouseDownRight


migrateTrain : Evergreen.V67.Train.Train -> Evergreen.V69.Train.Train
migrateTrain old =
    case old of
        Evergreen.V67.Train.Train a ->
            Evergreen.V69.Train.Train
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


migrateStatus : Evergreen.V67.Train.Status -> Evergreen.V69.Train.Status
migrateStatus old =
    case old of
        Evergreen.V67.Train.WaitingAtHome ->
            Evergreen.V69.Train.WaitingAtHome

        Evergreen.V67.Train.TeleportingHome a ->
            Evergreen.V69.Train.TeleportingHome (migratePosix a)

        Evergreen.V67.Train.Travelling ->
            Evergreen.V69.Train.Travelling

        Evergreen.V67.Train.StoppedAtPostOffice a ->
            Evergreen.V69.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V67.Tile.RailPath -> Evergreen.V69.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V67.Tile.RailPathHorizontal a ->
            Evergreen.V69.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V67.Tile.RailPathVertical a ->
            Evergreen.V69.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V67.Tile.RailPathBottomToRight ->
            Evergreen.V69.Tile.RailPathBottomToRight

        Evergreen.V67.Tile.RailPathBottomToLeft ->
            Evergreen.V69.Tile.RailPathBottomToLeft

        Evergreen.V67.Tile.RailPathTopToRight ->
            Evergreen.V69.Tile.RailPathTopToRight

        Evergreen.V67.Tile.RailPathTopToLeft ->
            Evergreen.V69.Tile.RailPathTopToLeft

        Evergreen.V67.Tile.RailPathBottomToRightLarge ->
            Evergreen.V69.Tile.RailPathBottomToRightLarge

        Evergreen.V67.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V69.Tile.RailPathBottomToLeftLarge

        Evergreen.V67.Tile.RailPathTopToRightLarge ->
            Evergreen.V69.Tile.RailPathTopToRightLarge

        Evergreen.V67.Tile.RailPathTopToLeftLarge ->
            Evergreen.V69.Tile.RailPathTopToLeftLarge

        Evergreen.V67.Tile.RailPathStrafeDown ->
            Evergreen.V69.Tile.RailPathStrafeDown

        Evergreen.V67.Tile.RailPathStrafeUp ->
            Evergreen.V69.Tile.RailPathStrafeUp

        Evergreen.V67.Tile.RailPathStrafeLeft ->
            Evergreen.V69.Tile.RailPathStrafeLeft

        Evergreen.V67.Tile.RailPathStrafeRight ->
            Evergreen.V69.Tile.RailPathStrafeRight

        Evergreen.V67.Tile.RailPathStrafeDownSmall ->
            Evergreen.V69.Tile.RailPathStrafeDownSmall

        Evergreen.V67.Tile.RailPathStrafeUpSmall ->
            Evergreen.V69.Tile.RailPathStrafeUpSmall

        Evergreen.V67.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V69.Tile.RailPathStrafeLeftSmall

        Evergreen.V67.Tile.RailPathStrafeRightSmall ->
            Evergreen.V69.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V67.Train.PreviousPath -> Evergreen.V69.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V67.MailEditor.Image -> Evergreen.V69.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V67.MailEditor.Stamp a ->
            Evergreen.V69.MailEditor.Stamp (migrateColors a)

        Evergreen.V67.MailEditor.SunglassesEmoji a ->
            Evergreen.V69.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V67.MailEditor.NormalEmoji a ->
            Evergreen.V69.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V67.MailEditor.SadEmoji a ->
            Evergreen.V69.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V67.MailEditor.Cow a ->
            Evergreen.V69.MailEditor.Cow (migrateColors a)

        Evergreen.V67.MailEditor.Man a ->
            Evergreen.V69.MailEditor.Man (migrateColors a)

        Evergreen.V67.MailEditor.TileImage a b c ->
            Evergreen.V69.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V67.MailEditor.Grass ->
            Evergreen.V69.MailEditor.Grass

        Evergreen.V67.MailEditor.DefaultCursor a ->
            Evergreen.V69.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V67.MailEditor.DragCursor a ->
            Evergreen.V69.MailEditor.DragCursor (migrateColors a)

        Evergreen.V67.MailEditor.PinchCursor a ->
            Evergreen.V69.MailEditor.PinchCursor (migrateColors a)

        Evergreen.V67.MailEditor.Line int color ->
            Evergreen.V69.MailEditor.Line int (migrateColor color)


migrateTileGroup : Evergreen.V67.Tile.TileGroup -> Evergreen.V69.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V67.Tile.EmptyTileGroup ->
            Evergreen.V69.Tile.EmptyTileGroup

        Evergreen.V67.Tile.HouseGroup ->
            Evergreen.V69.Tile.HouseGroup

        Evergreen.V67.Tile.RailStraightGroup ->
            Evergreen.V69.Tile.RailStraightGroup

        Evergreen.V67.Tile.RailTurnGroup ->
            Evergreen.V69.Tile.RailTurnGroup

        Evergreen.V67.Tile.RailTurnLargeGroup ->
            Evergreen.V69.Tile.RailTurnLargeGroup

        Evergreen.V67.Tile.RailStrafeGroup ->
            Evergreen.V69.Tile.RailStrafeGroup

        Evergreen.V67.Tile.RailStrafeSmallGroup ->
            Evergreen.V69.Tile.RailStrafeSmallGroup

        Evergreen.V67.Tile.RailCrossingGroup ->
            Evergreen.V69.Tile.RailCrossingGroup

        Evergreen.V67.Tile.TrainHouseGroup ->
            Evergreen.V69.Tile.TrainHouseGroup

        Evergreen.V67.Tile.SidewalkGroup ->
            Evergreen.V69.Tile.SidewalkGroup

        Evergreen.V67.Tile.SidewalkRailGroup ->
            Evergreen.V69.Tile.SidewalkRailGroup

        Evergreen.V67.Tile.RailTurnSplitGroup ->
            Evergreen.V69.Tile.RailTurnSplitGroup

        Evergreen.V67.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V69.Tile.RailTurnSplitMirrorGroup

        Evergreen.V67.Tile.PostOfficeGroup ->
            Evergreen.V69.Tile.PostOfficeGroup

        Evergreen.V67.Tile.PineTreeGroup ->
            Evergreen.V69.Tile.PineTreeGroup

        Evergreen.V67.Tile.LogCabinGroup ->
            Evergreen.V69.Tile.LogCabinGroup

        Evergreen.V67.Tile.RoadStraightGroup ->
            Evergreen.V69.Tile.RoadStraightGroup

        Evergreen.V67.Tile.RoadTurnGroup ->
            Evergreen.V69.Tile.RoadTurnGroup

        Evergreen.V67.Tile.Road4WayGroup ->
            Evergreen.V69.Tile.Road4WayGroup

        Evergreen.V67.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V69.Tile.RoadSidewalkCrossingGroup

        Evergreen.V67.Tile.Road3WayGroup ->
            Evergreen.V69.Tile.Road3WayGroup

        Evergreen.V67.Tile.RoadRailCrossingGroup ->
            Evergreen.V69.Tile.RoadRailCrossingGroup

        Evergreen.V67.Tile.RoadDeadendGroup ->
            Evergreen.V69.Tile.RoadDeadendGroup

        Evergreen.V67.Tile.FenceStraightGroup ->
            Evergreen.V69.Tile.FenceStraightGroup

        Evergreen.V67.Tile.BusStopGroup ->
            Evergreen.V69.Tile.BusStopGroup

        Evergreen.V67.Tile.HospitalGroup ->
            Evergreen.V69.Tile.HospitalGroup

        Evergreen.V67.Tile.StatueGroup ->
            Evergreen.V69.Tile.StatueGroup

        Evergreen.V67.Tile.HedgeRowGroup ->
            Evergreen.V69.Tile.HedgeRowGroup

        Evergreen.V67.Tile.HedgeCornerGroup ->
            Evergreen.V69.Tile.HedgeCornerGroup

        Evergreen.V67.Tile.ApartmentGroup ->
            Evergreen.V69.Tile.ApartmentGroup

        Evergreen.V67.Tile.RockGroup ->
            Evergreen.V69.Tile.RockGroup

        Evergreen.V67.Tile.FlowersGroup ->
            Evergreen.V69.Tile.FlowersGroup

        Evergreen.V67.Tile.HedgePillarGroup ->
            Evergreen.V69.Tile.HedgePillarGroup

        Evergreen.V67.Tile.ElmTreeGroup ->
            Evergreen.V69.Tile.ElmTreeGroup

        Evergreen.V67.Tile.DirtPathGroup ->
            Evergreen.V69.Tile.DirtPathGroup

        Evergreen.V67.Tile.BigTextGroup ->
            Evergreen.V69.Tile.BigTextGroup

        Evergreen.V67.Tile.BigPineTreeGroup ->
            Evergreen.V69.Tile.BigPineTreeGroup

        Evergreen.V67.Tile.HyperlinkGroup ->
            Evergreen.V69.Tile.HyperlinkGroup

        Evergreen.V67.Tile.BenchGroup ->
            Evergreen.V69.Tile.BenchGroup

        Evergreen.V67.Tile.ParkingLotGroup ->
            Evergreen.V69.Tile.ParkingLotGroup

        Evergreen.V67.Tile.ParkingRoadGroup ->
            Evergreen.V69.Tile.ParkingRoadGroup

        Evergreen.V67.Tile.ParkingRoundaboutGroup ->
            Evergreen.V69.Tile.ParkingRoundaboutGroup

        Evergreen.V67.Tile.CornerHouseGroup ->
            Evergreen.V69.Tile.CornerHouseGroup


migrateDisplayName : Evergreen.V67.DisplayName.DisplayName -> Evergreen.V69.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V67.DisplayName.DisplayName a ->
            Evergreen.V69.DisplayName.DisplayName a


migrateCursor : Evergreen.V67.Cursor.Cursor -> Evergreen.V69.Cursor.Cursor
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
        Evergreen.V69.Cursor.HandTool
    }


migrateContent : Evergreen.V67.MailEditor.Content -> Evergreen.V69.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, item = migrateImageOrText old.item }


migrateImageOrText : Evergreen.V67.MailEditor.ImageOrText -> Evergreen.V69.MailEditor.ImageOrText
migrateImageOrText old =
    case old of
        Evergreen.V67.MailEditor.ImageType imageType ->
            migrateImage imageType |> Evergreen.V69.MailEditor.ImageType

        Evergreen.V67.MailEditor.TextType string ->
            Evergreen.V69.MailEditor.TextType string


migrateColors : Evergreen.V67.Color.Colors -> Evergreen.V69.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V67.Color.Color -> Evergreen.V69.Color.Color
migrateColor old =
    case old of
        Evergreen.V67.Color.Color a ->
            Evergreen.V69.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V67.Types.ViewPoint -> Evergreen.V69.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V67.Types.NormalViewPoint a ->
            Evergreen.V69.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V67.Types.TrainViewPoint a ->
            Evergreen.V69.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V67.Geometry.Types.Point2d old) =
    Evergreen.V69.Geometry.Types.Point2d old


migrateId : Evergreen.V67.Id.Id a -> Evergreen.V69.Id.Id b
migrateId (Evergreen.V67.Id.Id old) =
    Evergreen.V69.Id.Id old


migrateDictToIdDict : Dict.Dict Int a -> Evergreen.V69.IdDict.IdDict id a
migrateDictToIdDict dict =
    Dict.toList dict |> List.map (Tuple.mapFirst Evergreen.V69.Id.Id) |> fromList


{-| Convert an association list into a dictionary.
-}
fromList : List ( Evergreen.V69.Id.Id a, v ) -> Evergreen.V69.IdDict.IdDict a v
fromList assocs =
    List.foldl (\( key, value ) dict -> insert key value dict) empty assocs


{-| Create an empty dictionary.
-}
empty : Evergreen.V69.IdDict.IdDict k v
empty =
    Evergreen.V69.IdDict.RBEmpty_elm_builtin


{-| Insert a key-value pair into a dictionary. Replaces value when there is
a collision.
-}
insert : Evergreen.V69.Id.Id a -> v -> Evergreen.V69.IdDict.IdDict a v -> Evergreen.V69.IdDict.IdDict a v
insert key value dict =
    -- Root node is always Black
    case insertHelp key value dict of
        Evergreen.V69.IdDict.RBNode_elm_builtin Evergreen.V69.IdDict.Red k v l r ->
            Evergreen.V69.IdDict.RBNode_elm_builtin Evergreen.V69.IdDict.Black k v l r

        x ->
            x


idToInt (Evergreen.V69.Id.Id id) =
    id


insertHelp : Evergreen.V69.Id.Id a -> v -> Evergreen.V69.IdDict.IdDict a v -> Evergreen.V69.IdDict.IdDict a v
insertHelp key value dict =
    case dict of
        Evergreen.V69.IdDict.RBEmpty_elm_builtin ->
            -- New nodes are always red. If it violates the rules, it will be fixed
            -- when balancing.
            Evergreen.V69.IdDict.RBNode_elm_builtin Evergreen.V69.IdDict.Red (idToInt key) value Evergreen.V69.IdDict.RBEmpty_elm_builtin Evergreen.V69.IdDict.RBEmpty_elm_builtin

        Evergreen.V69.IdDict.RBNode_elm_builtin nColor nKey nValue nLeft nRight ->
            case compare (idToInt key) nKey of
                LT ->
                    balance nColor nKey nValue (insertHelp key value nLeft) nRight

                EQ ->
                    Evergreen.V69.IdDict.RBNode_elm_builtin nColor nKey value nLeft nRight

                GT ->
                    balance nColor nKey nValue nLeft (insertHelp key value nRight)


balance : Evergreen.V69.IdDict.NColor -> Int -> v -> Evergreen.V69.IdDict.IdDict k v -> Evergreen.V69.IdDict.IdDict k v -> Evergreen.V69.IdDict.IdDict k v
balance color key value left right =
    case right of
        Evergreen.V69.IdDict.RBNode_elm_builtin Evergreen.V69.IdDict.Red rK rV rLeft rRight ->
            case left of
                Evergreen.V69.IdDict.RBNode_elm_builtin Evergreen.V69.IdDict.Red lK lV lLeft lRight ->
                    Evergreen.V69.IdDict.RBNode_elm_builtin
                        Evergreen.V69.IdDict.Red
                        key
                        value
                        (Evergreen.V69.IdDict.RBNode_elm_builtin Evergreen.V69.IdDict.Black lK lV lLeft lRight)
                        (Evergreen.V69.IdDict.RBNode_elm_builtin Evergreen.V69.IdDict.Black rK rV rLeft rRight)

                _ ->
                    Evergreen.V69.IdDict.RBNode_elm_builtin color rK rV (Evergreen.V69.IdDict.RBNode_elm_builtin Evergreen.V69.IdDict.Red key value left rLeft) rRight

        _ ->
            case left of
                Evergreen.V69.IdDict.RBNode_elm_builtin Evergreen.V69.IdDict.Red lK lV (Evergreen.V69.IdDict.RBNode_elm_builtin Evergreen.V69.IdDict.Red llK llV llLeft llRight) lRight ->
                    Evergreen.V69.IdDict.RBNode_elm_builtin
                        Evergreen.V69.IdDict.Red
                        lK
                        lV
                        (Evergreen.V69.IdDict.RBNode_elm_builtin Evergreen.V69.IdDict.Black llK llV llLeft llRight)
                        (Evergreen.V69.IdDict.RBNode_elm_builtin Evergreen.V69.IdDict.Black key value lRight right)

                _ ->
                    Evergreen.V69.IdDict.RBNode_elm_builtin color key value left right
