module Evergreen.Migrate.V67 exposing (..)

import AssocList
import AssocSet
import Dict
import Effect.Time
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
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Quantity exposing (Quantity)


backendModel : Evergreen.V62.Types.BackendModel -> ModelMigration Evergreen.V67.Types.BackendModel Evergreen.V67.Types.BackendMsg
backendModel old =
    ModelMigrated
        ( migrateBackendModel old
        , Cmd.none
        )


frontendModel : Evergreen.V62.Types.FrontendModel -> ModelMigration Evergreen.V67.Types.FrontendModel Evergreen.V67.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V62.Types.FrontendMsg -> MsgMigration Evergreen.V67.Types.FrontendMsg Evergreen.V67.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V62.Types.BackendMsg -> MsgMigration Evergreen.V67.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V62.Types.BackendError -> Evergreen.V67.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V62.Types.PostmarkError a b ->
            Evergreen.V67.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V62.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V67.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V62.Types.BackendModel -> Evergreen.V67.Types.BackendModel
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


migrateRequestedBy : Evergreen.V62.Types.LoginRequestedBy -> Evergreen.V67.Types.LoginRequestedBy
migrateRequestedBy old =
    case old of
        Evergreen.V62.Types.LoginRequestedByBackend ->
            Evergreen.V67.Types.LoginRequestedByBackend

        Evergreen.V62.Types.LoginRequestedByFrontend sessionId ->
            Evergreen.V67.Types.LoginRequestedByFrontend sessionId


migrateGrid : Evergreen.V62.Grid.Grid -> Evergreen.V67.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V62.Grid.Grid a ->
            Evergreen.V67.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V62.GridCell.Cell -> Evergreen.V67.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V62.GridCell.Cell a ->
            Evergreen.V67.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateIdDict identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V62.GridCell.Value -> Evergreen.V67.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V62.Bounds.Bounds a -> Evergreen.V67.Bounds.Bounds b
migrateBounds (Evergreen.V62.Bounds.Bounds old) =
    Evergreen.V67.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V62.Change.Cow -> Evergreen.V67.Change.Cow
migrateCow old =
    { position = migratePoint2d old.position }


migrateBackendMail : Evergreen.V62.MailEditor.BackendMail -> Evergreen.V67.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V62.MailEditor.MailStatus -> Evergreen.V67.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V62.MailEditor.MailWaitingPickup ->
            Evergreen.V67.MailEditor.MailWaitingPickup

        Evergreen.V62.MailEditor.MailInTransit a ->
            Evergreen.V67.MailEditor.MailInTransit (migrateId a)

        Evergreen.V62.MailEditor.MailReceived a ->
            Evergreen.V67.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V62.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V67.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V62.Types.Invite -> Evergreen.V67.Types.Invite
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


migrateEmailAddress (Evergreen.V62.EmailAddress.EmailAddress old) =
    Evergreen.V67.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V62.Id.SecretId a -> Evergreen.V67.Id.SecretId b
migrateSecretId (Evergreen.V62.Id.SecretId old) =
    Evergreen.V67.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V62.IdDict.IdDict a b -> Evergreen.V67.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V62.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V67.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V62.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V67.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V62.IdDict.NColor -> Evergreen.V67.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V62.IdDict.Red ->
            Evergreen.V67.IdDict.Red

        Evergreen.V62.IdDict.Black ->
            Evergreen.V67.IdDict.Black


migrateBackendUserData : Evergreen.V62.Types.BackendUserData -> Evergreen.V67.Types.BackendUserData
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


migrateEmailResult : Evergreen.V62.Types.EmailResult -> Evergreen.V67.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V62.Types.EmailSending ->
            Evergreen.V67.Types.EmailSending

        Evergreen.V62.Types.EmailSendFailed a ->
            Evergreen.V67.Types.EmailSendFailed a

        Evergreen.V62.Types.EmailSent a ->
            Evergreen.V67.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V62.Postmark.PostmarkSendResponse -> Evergreen.V67.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V62.Tile.Tile -> Evergreen.V67.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V62.Tile.EmptyTile ->
            Evergreen.V67.Tile.EmptyTile

        Evergreen.V62.Tile.HouseDown ->
            Evergreen.V67.Tile.HouseDown

        Evergreen.V62.Tile.HouseRight ->
            Evergreen.V67.Tile.HouseRight

        Evergreen.V62.Tile.HouseUp ->
            Evergreen.V67.Tile.HouseUp

        Evergreen.V62.Tile.HouseLeft ->
            Evergreen.V67.Tile.HouseLeft

        Evergreen.V62.Tile.RailHorizontal ->
            Evergreen.V67.Tile.RailHorizontal

        Evergreen.V62.Tile.RailVertical ->
            Evergreen.V67.Tile.RailVertical

        Evergreen.V62.Tile.RailBottomToRight ->
            Evergreen.V67.Tile.RailBottomToRight

        Evergreen.V62.Tile.RailBottomToLeft ->
            Evergreen.V67.Tile.RailBottomToLeft

        Evergreen.V62.Tile.RailTopToRight ->
            Evergreen.V67.Tile.RailTopToRight

        Evergreen.V62.Tile.RailTopToLeft ->
            Evergreen.V67.Tile.RailTopToLeft

        Evergreen.V62.Tile.RailBottomToRightLarge ->
            Evergreen.V67.Tile.RailBottomToRightLarge

        Evergreen.V62.Tile.RailBottomToLeftLarge ->
            Evergreen.V67.Tile.RailBottomToLeftLarge

        Evergreen.V62.Tile.RailTopToRightLarge ->
            Evergreen.V67.Tile.RailTopToRightLarge

        Evergreen.V62.Tile.RailTopToLeftLarge ->
            Evergreen.V67.Tile.RailTopToLeftLarge

        Evergreen.V62.Tile.RailCrossing ->
            Evergreen.V67.Tile.RailCrossing

        Evergreen.V62.Tile.RailStrafeDown ->
            Evergreen.V67.Tile.RailStrafeDown

        Evergreen.V62.Tile.RailStrafeUp ->
            Evergreen.V67.Tile.RailStrafeUp

        Evergreen.V62.Tile.RailStrafeLeft ->
            Evergreen.V67.Tile.RailStrafeLeft

        Evergreen.V62.Tile.RailStrafeRight ->
            Evergreen.V67.Tile.RailStrafeRight

        Evergreen.V62.Tile.TrainHouseRight ->
            Evergreen.V67.Tile.TrainHouseRight

        Evergreen.V62.Tile.TrainHouseLeft ->
            Evergreen.V67.Tile.TrainHouseLeft

        Evergreen.V62.Tile.RailStrafeDownSmall ->
            Evergreen.V67.Tile.RailStrafeDownSmall

        Evergreen.V62.Tile.RailStrafeUpSmall ->
            Evergreen.V67.Tile.RailStrafeUpSmall

        Evergreen.V62.Tile.RailStrafeLeftSmall ->
            Evergreen.V67.Tile.RailStrafeLeftSmall

        Evergreen.V62.Tile.RailStrafeRightSmall ->
            Evergreen.V67.Tile.RailStrafeRightSmall

        Evergreen.V62.Tile.Sidewalk ->
            Evergreen.V67.Tile.Sidewalk

        Evergreen.V62.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V67.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V62.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V67.Tile.SidewalkVerticalRailCrossing

        Evergreen.V62.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V67.Tile.RailBottomToRight_SplitLeft

        Evergreen.V62.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V67.Tile.RailBottomToLeft_SplitUp

        Evergreen.V62.Tile.RailTopToRight_SplitDown ->
            Evergreen.V67.Tile.RailTopToRight_SplitDown

        Evergreen.V62.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V67.Tile.RailTopToLeft_SplitRight

        Evergreen.V62.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V67.Tile.RailBottomToRight_SplitUp

        Evergreen.V62.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V67.Tile.RailBottomToLeft_SplitRight

        Evergreen.V62.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V67.Tile.RailTopToRight_SplitLeft

        Evergreen.V62.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V67.Tile.RailTopToLeft_SplitDown

        Evergreen.V62.Tile.PostOffice ->
            Evergreen.V67.Tile.PostOffice

        Evergreen.V62.Tile.MowedGrass1 ->
            Evergreen.V67.Tile.MowedGrass1

        Evergreen.V62.Tile.MowedGrass4 ->
            Evergreen.V67.Tile.MowedGrass4

        Evergreen.V62.Tile.LogCabinDown ->
            Evergreen.V67.Tile.LogCabinDown

        Evergreen.V62.Tile.LogCabinRight ->
            Evergreen.V67.Tile.LogCabinRight

        Evergreen.V62.Tile.LogCabinUp ->
            Evergreen.V67.Tile.LogCabinUp

        Evergreen.V62.Tile.LogCabinLeft ->
            Evergreen.V67.Tile.LogCabinLeft

        Evergreen.V62.Tile.RoadHorizontal ->
            Evergreen.V67.Tile.RoadHorizontal

        Evergreen.V62.Tile.RoadVertical ->
            Evergreen.V67.Tile.RoadVertical

        Evergreen.V62.Tile.RoadBottomToLeft ->
            Evergreen.V67.Tile.RoadBottomToLeft

        Evergreen.V62.Tile.RoadTopToLeft ->
            Evergreen.V67.Tile.RoadTopToLeft

        Evergreen.V62.Tile.RoadTopToRight ->
            Evergreen.V67.Tile.RoadTopToRight

        Evergreen.V62.Tile.RoadBottomToRight ->
            Evergreen.V67.Tile.RoadBottomToRight

        Evergreen.V62.Tile.Road4Way ->
            Evergreen.V67.Tile.Road4Way

        Evergreen.V62.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V67.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V62.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V67.Tile.RoadSidewalkCrossingVertical

        Evergreen.V62.Tile.Road3WayDown ->
            Evergreen.V67.Tile.Road3WayDown

        Evergreen.V62.Tile.Road3WayLeft ->
            Evergreen.V67.Tile.Road3WayLeft

        Evergreen.V62.Tile.Road3WayUp ->
            Evergreen.V67.Tile.Road3WayUp

        Evergreen.V62.Tile.Road3WayRight ->
            Evergreen.V67.Tile.Road3WayRight

        Evergreen.V62.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V67.Tile.RoadRailCrossingHorizontal

        Evergreen.V62.Tile.RoadRailCrossingVertical ->
            Evergreen.V67.Tile.RoadRailCrossingVertical

        Evergreen.V62.Tile.FenceHorizontal ->
            Evergreen.V67.Tile.FenceHorizontal

        Evergreen.V62.Tile.FenceVertical ->
            Evergreen.V67.Tile.FenceVertical

        Evergreen.V62.Tile.FenceDiagonal ->
            Evergreen.V67.Tile.FenceDiagonal

        Evergreen.V62.Tile.FenceAntidiagonal ->
            Evergreen.V67.Tile.FenceAntidiagonal

        Evergreen.V62.Tile.RoadDeadendUp ->
            Evergreen.V67.Tile.RoadDeadendUp

        Evergreen.V62.Tile.RoadDeadendDown ->
            Evergreen.V67.Tile.RoadDeadendDown

        Evergreen.V62.Tile.BusStopDown ->
            Evergreen.V67.Tile.BusStopDown

        Evergreen.V62.Tile.BusStopLeft ->
            Evergreen.V67.Tile.BusStopLeft

        Evergreen.V62.Tile.BusStopRight ->
            Evergreen.V67.Tile.BusStopRight

        Evergreen.V62.Tile.BusStopUp ->
            Evergreen.V67.Tile.BusStopUp

        Evergreen.V62.Tile.Hospital ->
            Evergreen.V67.Tile.Hospital

        Evergreen.V62.Tile.Statue ->
            Evergreen.V67.Tile.Statue

        Evergreen.V62.Tile.HedgeRowDown ->
            Evergreen.V67.Tile.HedgeRowDown

        Evergreen.V62.Tile.HedgeRowLeft ->
            Evergreen.V67.Tile.HedgeRowLeft

        Evergreen.V62.Tile.HedgeRowRight ->
            Evergreen.V67.Tile.HedgeRowRight

        Evergreen.V62.Tile.HedgeRowUp ->
            Evergreen.V67.Tile.HedgeRowUp

        Evergreen.V62.Tile.HedgeCornerDownLeft ->
            Evergreen.V67.Tile.HedgeCornerDownLeft

        Evergreen.V62.Tile.HedgeCornerDownRight ->
            Evergreen.V67.Tile.HedgeCornerDownRight

        Evergreen.V62.Tile.HedgeCornerUpLeft ->
            Evergreen.V67.Tile.HedgeCornerUpLeft

        Evergreen.V62.Tile.HedgeCornerUpRight ->
            Evergreen.V67.Tile.HedgeCornerUpRight

        Evergreen.V62.Tile.ApartmentDown ->
            Evergreen.V67.Tile.ApartmentDown

        Evergreen.V62.Tile.ApartmentLeft ->
            Evergreen.V67.Tile.ApartmentLeft

        Evergreen.V62.Tile.ApartmentRight ->
            Evergreen.V67.Tile.ApartmentRight

        Evergreen.V62.Tile.ApartmentUp ->
            Evergreen.V67.Tile.ApartmentUp

        Evergreen.V62.Tile.RockDown ->
            Evergreen.V67.Tile.RockDown

        Evergreen.V62.Tile.RockLeft ->
            Evergreen.V67.Tile.RockLeft

        Evergreen.V62.Tile.RockRight ->
            Evergreen.V67.Tile.RockRight

        Evergreen.V62.Tile.RockUp ->
            Evergreen.V67.Tile.RockUp

        Evergreen.V62.Tile.PineTree1 ->
            Evergreen.V67.Tile.PineTree1

        Evergreen.V62.Tile.PineTree2 ->
            Evergreen.V67.Tile.PineTree2

        Evergreen.V62.Tile.HedgePillarDownLeft ->
            Evergreen.V67.Tile.HedgePillarDownLeft

        Evergreen.V62.Tile.HedgePillarDownRight ->
            Evergreen.V67.Tile.HedgePillarDownRight

        Evergreen.V62.Tile.HedgePillarUpLeft ->
            Evergreen.V67.Tile.HedgePillarUpLeft

        Evergreen.V62.Tile.HedgePillarUpRight ->
            Evergreen.V67.Tile.HedgePillarUpRight

        Evergreen.V62.Tile.Flowers1 ->
            Evergreen.V67.Tile.Flowers1

        Evergreen.V62.Tile.Flowers2 ->
            Evergreen.V67.Tile.Flowers2

        Evergreen.V62.Tile.ElmTree ->
            Evergreen.V67.Tile.ElmTree

        Evergreen.V62.Tile.DirtPathHorizontal ->
            Evergreen.V67.Tile.DirtPathHorizontal

        Evergreen.V62.Tile.DirtPathVertical ->
            Evergreen.V67.Tile.DirtPathVertical

        Evergreen.V62.Tile.BigText char ->
            Evergreen.V67.Tile.BigText char

        Evergreen.V62.Tile.BigPineTree ->
            Evergreen.V67.Tile.BigPineTree

        Evergreen.V62.Tile.Hyperlink ->
            Evergreen.V67.Tile.Hyperlink

        Evergreen.V62.Tile.BenchDown ->
            Evergreen.V67.Tile.BenchDown

        Evergreen.V62.Tile.BenchLeft ->
            Evergreen.V67.Tile.BenchLeft

        Evergreen.V62.Tile.BenchUp ->
            Evergreen.V67.Tile.BenchUp

        Evergreen.V62.Tile.BenchRight ->
            Evergreen.V67.Tile.BenchRight

        Evergreen.V62.Tile.ParkingDown ->
            Evergreen.V67.Tile.ParkingDown

        Evergreen.V62.Tile.ParkingLeft ->
            Evergreen.V67.Tile.ParkingLeft

        Evergreen.V62.Tile.ParkingUp ->
            Evergreen.V67.Tile.ParkingUp

        Evergreen.V62.Tile.ParkingRight ->
            Evergreen.V67.Tile.ParkingRight

        Evergreen.V62.Tile.ParkingRoad ->
            Evergreen.V67.Tile.ParkingRoad

        Evergreen.V62.Tile.ParkingRoundabout ->
            Evergreen.V67.Tile.ParkingRoundabout

        Evergreen.V62.Tile.CornerHouseUpLeft ->
            Evergreen.V67.Tile.CornerHouseUpLeft

        Evergreen.V62.Tile.CornerHouseUpRight ->
            Evergreen.V67.Tile.CornerHouseUpRight

        Evergreen.V62.Tile.CornerHouseDownLeft ->
            Evergreen.V67.Tile.CornerHouseDownLeft

        Evergreen.V62.Tile.CornerHouseDownRight ->
            Evergreen.V67.Tile.CornerHouseDownRight


migrateTrain : Evergreen.V62.Train.Train -> Evergreen.V67.Train.Train
migrateTrain old =
    case old of
        Evergreen.V62.Train.Train a ->
            Evergreen.V67.Train.Train
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


migrateStatus : Evergreen.V62.Train.Status -> Evergreen.V67.Train.Status
migrateStatus old =
    case old of
        Evergreen.V62.Train.WaitingAtHome ->
            Evergreen.V67.Train.WaitingAtHome

        Evergreen.V62.Train.TeleportingHome a ->
            Evergreen.V67.Train.TeleportingHome (migratePosix a)

        Evergreen.V62.Train.Travelling ->
            Evergreen.V67.Train.Travelling

        Evergreen.V62.Train.StoppedAtPostOffice a ->
            Evergreen.V67.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V62.Tile.RailPath -> Evergreen.V67.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V62.Tile.RailPathHorizontal a ->
            Evergreen.V67.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V62.Tile.RailPathVertical a ->
            Evergreen.V67.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V62.Tile.RailPathBottomToRight ->
            Evergreen.V67.Tile.RailPathBottomToRight

        Evergreen.V62.Tile.RailPathBottomToLeft ->
            Evergreen.V67.Tile.RailPathBottomToLeft

        Evergreen.V62.Tile.RailPathTopToRight ->
            Evergreen.V67.Tile.RailPathTopToRight

        Evergreen.V62.Tile.RailPathTopToLeft ->
            Evergreen.V67.Tile.RailPathTopToLeft

        Evergreen.V62.Tile.RailPathBottomToRightLarge ->
            Evergreen.V67.Tile.RailPathBottomToRightLarge

        Evergreen.V62.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V67.Tile.RailPathBottomToLeftLarge

        Evergreen.V62.Tile.RailPathTopToRightLarge ->
            Evergreen.V67.Tile.RailPathTopToRightLarge

        Evergreen.V62.Tile.RailPathTopToLeftLarge ->
            Evergreen.V67.Tile.RailPathTopToLeftLarge

        Evergreen.V62.Tile.RailPathStrafeDown ->
            Evergreen.V67.Tile.RailPathStrafeDown

        Evergreen.V62.Tile.RailPathStrafeUp ->
            Evergreen.V67.Tile.RailPathStrafeUp

        Evergreen.V62.Tile.RailPathStrafeLeft ->
            Evergreen.V67.Tile.RailPathStrafeLeft

        Evergreen.V62.Tile.RailPathStrafeRight ->
            Evergreen.V67.Tile.RailPathStrafeRight

        Evergreen.V62.Tile.RailPathStrafeDownSmall ->
            Evergreen.V67.Tile.RailPathStrafeDownSmall

        Evergreen.V62.Tile.RailPathStrafeUpSmall ->
            Evergreen.V67.Tile.RailPathStrafeUpSmall

        Evergreen.V62.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V67.Tile.RailPathStrafeLeftSmall

        Evergreen.V62.Tile.RailPathStrafeRightSmall ->
            Evergreen.V67.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V62.Train.PreviousPath -> Evergreen.V67.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V62.MailEditor.Image -> Evergreen.V67.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V62.MailEditor.Stamp a ->
            Evergreen.V67.MailEditor.Stamp (migrateColors a)

        Evergreen.V62.MailEditor.SunglassesEmoji a ->
            Evergreen.V67.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V62.MailEditor.NormalEmoji a ->
            Evergreen.V67.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V62.MailEditor.SadEmoji a ->
            Evergreen.V67.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V62.MailEditor.Cow a ->
            Evergreen.V67.MailEditor.Cow (migrateColors a)

        Evergreen.V62.MailEditor.Man a ->
            Evergreen.V67.MailEditor.Man (migrateColors a)

        Evergreen.V62.MailEditor.TileImage a b c ->
            Evergreen.V67.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V62.MailEditor.Grass ->
            Evergreen.V67.MailEditor.Grass

        Evergreen.V62.MailEditor.DefaultCursor a ->
            Evergreen.V67.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V62.MailEditor.DragCursor a ->
            Evergreen.V67.MailEditor.DragCursor (migrateColors a)

        Evergreen.V62.MailEditor.PinchCursor a ->
            Evergreen.V67.MailEditor.PinchCursor (migrateColors a)

        Evergreen.V62.MailEditor.Line int color ->
            Evergreen.V67.MailEditor.Line int (migrateColor color)


migrateTileGroup : Evergreen.V62.Tile.TileGroup -> Evergreen.V67.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V62.Tile.EmptyTileGroup ->
            Evergreen.V67.Tile.EmptyTileGroup

        Evergreen.V62.Tile.HouseGroup ->
            Evergreen.V67.Tile.HouseGroup

        Evergreen.V62.Tile.RailStraightGroup ->
            Evergreen.V67.Tile.RailStraightGroup

        Evergreen.V62.Tile.RailTurnGroup ->
            Evergreen.V67.Tile.RailTurnGroup

        Evergreen.V62.Tile.RailTurnLargeGroup ->
            Evergreen.V67.Tile.RailTurnLargeGroup

        Evergreen.V62.Tile.RailStrafeGroup ->
            Evergreen.V67.Tile.RailStrafeGroup

        Evergreen.V62.Tile.RailStrafeSmallGroup ->
            Evergreen.V67.Tile.RailStrafeSmallGroup

        Evergreen.V62.Tile.RailCrossingGroup ->
            Evergreen.V67.Tile.RailCrossingGroup

        Evergreen.V62.Tile.TrainHouseGroup ->
            Evergreen.V67.Tile.TrainHouseGroup

        Evergreen.V62.Tile.SidewalkGroup ->
            Evergreen.V67.Tile.SidewalkGroup

        Evergreen.V62.Tile.SidewalkRailGroup ->
            Evergreen.V67.Tile.SidewalkRailGroup

        Evergreen.V62.Tile.RailTurnSplitGroup ->
            Evergreen.V67.Tile.RailTurnSplitGroup

        Evergreen.V62.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V67.Tile.RailTurnSplitMirrorGroup

        Evergreen.V62.Tile.PostOfficeGroup ->
            Evergreen.V67.Tile.PostOfficeGroup

        Evergreen.V62.Tile.PineTreeGroup ->
            Evergreen.V67.Tile.PineTreeGroup

        Evergreen.V62.Tile.LogCabinGroup ->
            Evergreen.V67.Tile.LogCabinGroup

        Evergreen.V62.Tile.RoadStraightGroup ->
            Evergreen.V67.Tile.RoadStraightGroup

        Evergreen.V62.Tile.RoadTurnGroup ->
            Evergreen.V67.Tile.RoadTurnGroup

        Evergreen.V62.Tile.Road4WayGroup ->
            Evergreen.V67.Tile.Road4WayGroup

        Evergreen.V62.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V67.Tile.RoadSidewalkCrossingGroup

        Evergreen.V62.Tile.Road3WayGroup ->
            Evergreen.V67.Tile.Road3WayGroup

        Evergreen.V62.Tile.RoadRailCrossingGroup ->
            Evergreen.V67.Tile.RoadRailCrossingGroup

        Evergreen.V62.Tile.RoadDeadendGroup ->
            Evergreen.V67.Tile.RoadDeadendGroup

        Evergreen.V62.Tile.FenceStraightGroup ->
            Evergreen.V67.Tile.FenceStraightGroup

        Evergreen.V62.Tile.BusStopGroup ->
            Evergreen.V67.Tile.BusStopGroup

        Evergreen.V62.Tile.HospitalGroup ->
            Evergreen.V67.Tile.HospitalGroup

        Evergreen.V62.Tile.StatueGroup ->
            Evergreen.V67.Tile.StatueGroup

        Evergreen.V62.Tile.HedgeRowGroup ->
            Evergreen.V67.Tile.HedgeRowGroup

        Evergreen.V62.Tile.HedgeCornerGroup ->
            Evergreen.V67.Tile.HedgeCornerGroup

        Evergreen.V62.Tile.ApartmentGroup ->
            Evergreen.V67.Tile.ApartmentGroup

        Evergreen.V62.Tile.RockGroup ->
            Evergreen.V67.Tile.RockGroup

        Evergreen.V62.Tile.FlowersGroup ->
            Evergreen.V67.Tile.FlowersGroup

        Evergreen.V62.Tile.HedgePillarGroup ->
            Evergreen.V67.Tile.HedgePillarGroup

        Evergreen.V62.Tile.ElmTreeGroup ->
            Evergreen.V67.Tile.ElmTreeGroup

        Evergreen.V62.Tile.DirtPathGroup ->
            Evergreen.V67.Tile.DirtPathGroup

        Evergreen.V62.Tile.BigTextGroup ->
            Evergreen.V67.Tile.BigTextGroup

        Evergreen.V62.Tile.BigPineTreeGroup ->
            Evergreen.V67.Tile.BigPineTreeGroup

        Evergreen.V62.Tile.HyperlinkGroup ->
            Evergreen.V67.Tile.HyperlinkGroup

        Evergreen.V62.Tile.BenchGroup ->
            Evergreen.V67.Tile.BenchGroup

        Evergreen.V62.Tile.ParkingLotGroup ->
            Evergreen.V67.Tile.ParkingLotGroup

        Evergreen.V62.Tile.ParkingRoadGroup ->
            Evergreen.V67.Tile.ParkingRoadGroup

        Evergreen.V62.Tile.ParkingRoundaboutGroup ->
            Evergreen.V67.Tile.ParkingRoundaboutGroup

        Evergreen.V62.Tile.CornerHouseGroup ->
            Evergreen.V67.Tile.CornerHouseGroup


migrateDisplayName : Evergreen.V62.DisplayName.DisplayName -> Evergreen.V67.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V62.DisplayName.DisplayName a ->
            Evergreen.V67.DisplayName.DisplayName a


migrateCursor : Evergreen.V62.Cursor.Cursor -> Evergreen.V67.Cursor.Cursor
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
        Evergreen.V67.Cursor.HandTool
    }


migrateContent : Evergreen.V62.MailEditor.Content -> Evergreen.V67.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, item = migrateImageOrText old.item }


migrateImageOrText : Evergreen.V62.MailEditor.ImageOrText -> Evergreen.V67.MailEditor.ImageOrText
migrateImageOrText old =
    case old of
        Evergreen.V62.MailEditor.ImageType imageType ->
            migrateImage imageType |> Evergreen.V67.MailEditor.ImageType

        Evergreen.V62.MailEditor.TextType string ->
            Evergreen.V67.MailEditor.TextType string


migrateColors : Evergreen.V62.Color.Colors -> Evergreen.V67.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V62.Color.Color -> Evergreen.V67.Color.Color
migrateColor old =
    case old of
        Evergreen.V62.Color.Color a ->
            Evergreen.V67.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V62.Types.ViewPoint -> Evergreen.V67.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V62.Types.NormalViewPoint a ->
            Evergreen.V67.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V62.Types.TrainViewPoint a ->
            Evergreen.V67.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V62.Geometry.Types.Point2d old) =
    Evergreen.V67.Geometry.Types.Point2d old


migrateId : Evergreen.V62.Id.Id a -> Evergreen.V67.Id.Id b
migrateId (Evergreen.V62.Id.Id old) =
    Evergreen.V67.Id.Id old


migrateDictToIdDict : Dict.Dict Int a -> Evergreen.V67.IdDict.IdDict id a
migrateDictToIdDict dict =
    Dict.toList dict |> List.map (Tuple.mapFirst Evergreen.V67.Id.Id) |> fromList


{-| Convert an association list into a dictionary.
-}
fromList : List ( Evergreen.V67.Id.Id a, v ) -> Evergreen.V67.IdDict.IdDict a v
fromList assocs =
    List.foldl (\( key, value ) dict -> insert key value dict) empty assocs


{-| Create an empty dictionary.
-}
empty : Evergreen.V67.IdDict.IdDict k v
empty =
    Evergreen.V67.IdDict.RBEmpty_elm_builtin


{-| Insert a key-value pair into a dictionary. Replaces value when there is
a collision.
-}
insert : Evergreen.V67.Id.Id a -> v -> Evergreen.V67.IdDict.IdDict a v -> Evergreen.V67.IdDict.IdDict a v
insert key value dict =
    -- Root node is always Black
    case insertHelp key value dict of
        Evergreen.V67.IdDict.RBNode_elm_builtin Evergreen.V67.IdDict.Red k v l r ->
            Evergreen.V67.IdDict.RBNode_elm_builtin Evergreen.V67.IdDict.Black k v l r

        x ->
            x


idToInt (Evergreen.V67.Id.Id id) =
    id


insertHelp : Evergreen.V67.Id.Id a -> v -> Evergreen.V67.IdDict.IdDict a v -> Evergreen.V67.IdDict.IdDict a v
insertHelp key value dict =
    case dict of
        Evergreen.V67.IdDict.RBEmpty_elm_builtin ->
            -- New nodes are always red. If it violates the rules, it will be fixed
            -- when balancing.
            Evergreen.V67.IdDict.RBNode_elm_builtin Evergreen.V67.IdDict.Red (idToInt key) value Evergreen.V67.IdDict.RBEmpty_elm_builtin Evergreen.V67.IdDict.RBEmpty_elm_builtin

        Evergreen.V67.IdDict.RBNode_elm_builtin nColor nKey nValue nLeft nRight ->
            case compare (idToInt key) nKey of
                LT ->
                    balance nColor nKey nValue (insertHelp key value nLeft) nRight

                EQ ->
                    Evergreen.V67.IdDict.RBNode_elm_builtin nColor nKey value nLeft nRight

                GT ->
                    balance nColor nKey nValue nLeft (insertHelp key value nRight)


balance : Evergreen.V67.IdDict.NColor -> Int -> v -> Evergreen.V67.IdDict.IdDict k v -> Evergreen.V67.IdDict.IdDict k v -> Evergreen.V67.IdDict.IdDict k v
balance color key value left right =
    case right of
        Evergreen.V67.IdDict.RBNode_elm_builtin Evergreen.V67.IdDict.Red rK rV rLeft rRight ->
            case left of
                Evergreen.V67.IdDict.RBNode_elm_builtin Evergreen.V67.IdDict.Red lK lV lLeft lRight ->
                    Evergreen.V67.IdDict.RBNode_elm_builtin
                        Evergreen.V67.IdDict.Red
                        key
                        value
                        (Evergreen.V67.IdDict.RBNode_elm_builtin Evergreen.V67.IdDict.Black lK lV lLeft lRight)
                        (Evergreen.V67.IdDict.RBNode_elm_builtin Evergreen.V67.IdDict.Black rK rV rLeft rRight)

                _ ->
                    Evergreen.V67.IdDict.RBNode_elm_builtin color rK rV (Evergreen.V67.IdDict.RBNode_elm_builtin Evergreen.V67.IdDict.Red key value left rLeft) rRight

        _ ->
            case left of
                Evergreen.V67.IdDict.RBNode_elm_builtin Evergreen.V67.IdDict.Red lK lV (Evergreen.V67.IdDict.RBNode_elm_builtin Evergreen.V67.IdDict.Red llK llV llLeft llRight) lRight ->
                    Evergreen.V67.IdDict.RBNode_elm_builtin
                        Evergreen.V67.IdDict.Red
                        lK
                        lV
                        (Evergreen.V67.IdDict.RBNode_elm_builtin Evergreen.V67.IdDict.Black llK llV llLeft llRight)
                        (Evergreen.V67.IdDict.RBNode_elm_builtin Evergreen.V67.IdDict.Black key value lRight right)

                _ ->
                    Evergreen.V67.IdDict.RBNode_elm_builtin color key value left right
