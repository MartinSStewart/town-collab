module Evergreen.Migrate.V74 exposing (..)

import AssocList
import AssocSet
import Bitwise
import Dict
import Effect.Time
import Evergreen.V72.Bounds
import Evergreen.V72.Change
import Evergreen.V72.Color
import Evergreen.V72.Cursor
import Evergreen.V72.DisplayName
import Evergreen.V72.EmailAddress
import Evergreen.V72.Geometry.Types
import Evergreen.V72.Grid
import Evergreen.V72.GridCell
import Evergreen.V72.Id
import Evergreen.V72.IdDict
import Evergreen.V72.MailEditor
import Evergreen.V72.Postmark
import Evergreen.V72.Tile
import Evergreen.V72.Train
import Evergreen.V72.Types
import Evergreen.V74.Animal
import Evergreen.V74.Bounds
import Evergreen.V74.Change
import Evergreen.V74.Color
import Evergreen.V74.Cursor
import Evergreen.V74.DisplayName
import Evergreen.V74.EmailAddress
import Evergreen.V74.Geometry.Types
import Evergreen.V74.Grid
import Evergreen.V74.GridCell
import Evergreen.V74.Id
import Evergreen.V74.IdDict
import Evergreen.V74.MailEditor
import Evergreen.V74.Postmark
import Evergreen.V74.Tile
import Evergreen.V74.Train
import Evergreen.V74.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Quantity exposing (Quantity)
import Random


backendModel : Evergreen.V72.Types.BackendModel -> ModelMigration Evergreen.V74.Types.BackendModel Evergreen.V74.Types.BackendMsg
backendModel old =
    ModelMigrated
        ( migrateBackendModel old
        , Cmd.none
        )


frontendModel : Evergreen.V72.Types.FrontendModel -> ModelMigration Evergreen.V74.Types.FrontendModel Evergreen.V74.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V72.Types.FrontendMsg -> MsgMigration Evergreen.V74.Types.FrontendMsg Evergreen.V74.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V72.Types.BackendMsg -> MsgMigration Evergreen.V74.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V72.Types.BackendError -> Evergreen.V74.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V72.Types.PostmarkError a b ->
            Evergreen.V74.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V72.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V74.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V72.Types.BackendModel -> Evergreen.V74.Types.BackendModel
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
    , isGridReadOnly = old.isGridReadOnly
    , trainsDisabled =
        -- TODO
        Evergreen.V74.Change.TrainsEnabled
    , reported = migrateIdDict (List.Nonempty.map migrateBackendReported) old.reported
    , lastReportEmailToAdmin = old.lastReportEmailToAdmin
    }


migrateBackendReported : Evergreen.V72.Change.BackendReport -> Evergreen.V74.Change.BackendReport
migrateBackendReported old =
    { reportedUser = migrateId old.reportedUser
    , position = migrateCoord old.position
    , reportedAt = old.reportedAt
    }


migrateRequestedBy : Evergreen.V72.Types.LoginRequestedBy -> Evergreen.V74.Types.LoginRequestedBy
migrateRequestedBy old =
    case old of
        Evergreen.V72.Types.LoginRequestedByBackend ->
            Evergreen.V74.Types.LoginRequestedByBackend

        Evergreen.V72.Types.LoginRequestedByFrontend sessionId ->
            Evergreen.V74.Types.LoginRequestedByFrontend sessionId


migrateGrid : Evergreen.V72.Grid.Grid -> Evergreen.V74.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V72.Grid.Grid a ->
            Evergreen.V74.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V72.GridCell.Cell -> Evergreen.V74.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V72.GridCell.Cell a ->
            Evergreen.V74.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateIdDict identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V72.GridCell.Value -> Evergreen.V74.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V72.Bounds.Bounds a -> Evergreen.V74.Bounds.Bounds b
migrateBounds (Evergreen.V72.Bounds.Bounds old) =
    Evergreen.V74.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V72.Change.Cow -> Evergreen.V74.Animal.Animal
migrateCow old =
    { position = migratePoint2d old.position, animalType = Evergreen.V74.Animal.Cow }


migrateBackendMail : Evergreen.V72.MailEditor.BackendMail -> Evergreen.V74.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V72.MailEditor.MailStatus -> Evergreen.V74.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V72.MailEditor.MailWaitingPickup ->
            Evergreen.V74.MailEditor.MailWaitingPickup

        Evergreen.V72.MailEditor.MailInTransit a ->
            Evergreen.V74.MailEditor.MailInTransit (migrateId a)

        Evergreen.V72.MailEditor.MailReceived a ->
            Evergreen.V74.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V72.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V74.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V72.Types.Invite -> Evergreen.V74.Types.Invite
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


migrateEmailAddress (Evergreen.V72.EmailAddress.EmailAddress old) =
    Evergreen.V74.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V72.Id.SecretId a -> Evergreen.V74.Id.SecretId b
migrateSecretId (Evergreen.V72.Id.SecretId old) =
    Evergreen.V74.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V72.IdDict.IdDict a b -> Evergreen.V74.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V72.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V74.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V72.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V74.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V72.IdDict.NColor -> Evergreen.V74.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V72.IdDict.Red ->
            Evergreen.V74.IdDict.Red

        Evergreen.V72.IdDict.Black ->
            Evergreen.V74.IdDict.Black


migrateBackendUserData : Evergreen.V72.Types.BackendUserData -> Evergreen.V74.Types.BackendUserData
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


migrateEmailResult : Evergreen.V72.Types.EmailResult -> Evergreen.V74.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V72.Types.EmailSending ->
            Evergreen.V74.Types.EmailSending

        Evergreen.V72.Types.EmailSendFailed a ->
            Evergreen.V74.Types.EmailSendFailed a

        Evergreen.V72.Types.EmailSent a ->
            Evergreen.V74.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V72.Postmark.PostmarkSendResponse -> Evergreen.V74.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V72.Tile.Tile -> Evergreen.V74.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V72.Tile.EmptyTile ->
            Evergreen.V74.Tile.EmptyTile

        Evergreen.V72.Tile.HouseDown ->
            Evergreen.V74.Tile.HouseDown

        Evergreen.V72.Tile.HouseRight ->
            Evergreen.V74.Tile.HouseRight

        Evergreen.V72.Tile.HouseUp ->
            Evergreen.V74.Tile.HouseUp

        Evergreen.V72.Tile.HouseLeft ->
            Evergreen.V74.Tile.HouseLeft

        Evergreen.V72.Tile.RailHorizontal ->
            Evergreen.V74.Tile.RailHorizontal

        Evergreen.V72.Tile.RailVertical ->
            Evergreen.V74.Tile.RailVertical

        Evergreen.V72.Tile.RailBottomToRight ->
            Evergreen.V74.Tile.RailBottomToRight

        Evergreen.V72.Tile.RailBottomToLeft ->
            Evergreen.V74.Tile.RailBottomToLeft

        Evergreen.V72.Tile.RailTopToRight ->
            Evergreen.V74.Tile.RailTopToRight

        Evergreen.V72.Tile.RailTopToLeft ->
            Evergreen.V74.Tile.RailTopToLeft

        Evergreen.V72.Tile.RailBottomToRightLarge ->
            Evergreen.V74.Tile.RailBottomToRightLarge

        Evergreen.V72.Tile.RailBottomToLeftLarge ->
            Evergreen.V74.Tile.RailBottomToLeftLarge

        Evergreen.V72.Tile.RailTopToRightLarge ->
            Evergreen.V74.Tile.RailTopToRightLarge

        Evergreen.V72.Tile.RailTopToLeftLarge ->
            Evergreen.V74.Tile.RailTopToLeftLarge

        Evergreen.V72.Tile.RailCrossing ->
            Evergreen.V74.Tile.RailCrossing

        Evergreen.V72.Tile.RailStrafeDown ->
            Evergreen.V74.Tile.RailStrafeDown

        Evergreen.V72.Tile.RailStrafeUp ->
            Evergreen.V74.Tile.RailStrafeUp

        Evergreen.V72.Tile.RailStrafeLeft ->
            Evergreen.V74.Tile.RailStrafeLeft

        Evergreen.V72.Tile.RailStrafeRight ->
            Evergreen.V74.Tile.RailStrafeRight

        Evergreen.V72.Tile.TrainHouseRight ->
            Evergreen.V74.Tile.TrainHouseRight

        Evergreen.V72.Tile.TrainHouseLeft ->
            Evergreen.V74.Tile.TrainHouseLeft

        Evergreen.V72.Tile.RailStrafeDownSmall ->
            Evergreen.V74.Tile.RailStrafeDownSmall

        Evergreen.V72.Tile.RailStrafeUpSmall ->
            Evergreen.V74.Tile.RailStrafeUpSmall

        Evergreen.V72.Tile.RailStrafeLeftSmall ->
            Evergreen.V74.Tile.RailStrafeLeftSmall

        Evergreen.V72.Tile.RailStrafeRightSmall ->
            Evergreen.V74.Tile.RailStrafeRightSmall

        Evergreen.V72.Tile.Sidewalk ->
            Evergreen.V74.Tile.Sidewalk

        Evergreen.V72.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V74.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V72.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V74.Tile.SidewalkVerticalRailCrossing

        Evergreen.V72.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V74.Tile.RailBottomToRight_SplitLeft

        Evergreen.V72.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V74.Tile.RailBottomToLeft_SplitUp

        Evergreen.V72.Tile.RailTopToRight_SplitDown ->
            Evergreen.V74.Tile.RailTopToRight_SplitDown

        Evergreen.V72.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V74.Tile.RailTopToLeft_SplitRight

        Evergreen.V72.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V74.Tile.RailBottomToRight_SplitUp

        Evergreen.V72.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V74.Tile.RailBottomToLeft_SplitRight

        Evergreen.V72.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V74.Tile.RailTopToRight_SplitLeft

        Evergreen.V72.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V74.Tile.RailTopToLeft_SplitDown

        Evergreen.V72.Tile.PostOffice ->
            Evergreen.V74.Tile.PostOffice

        Evergreen.V72.Tile.MowedGrass1 ->
            Evergreen.V74.Tile.MowedGrass1

        Evergreen.V72.Tile.MowedGrass4 ->
            Evergreen.V74.Tile.MowedGrass4

        Evergreen.V72.Tile.LogCabinDown ->
            Evergreen.V74.Tile.LogCabinDown

        Evergreen.V72.Tile.LogCabinRight ->
            Evergreen.V74.Tile.LogCabinRight

        Evergreen.V72.Tile.LogCabinUp ->
            Evergreen.V74.Tile.LogCabinUp

        Evergreen.V72.Tile.LogCabinLeft ->
            Evergreen.V74.Tile.LogCabinLeft

        Evergreen.V72.Tile.RoadHorizontal ->
            Evergreen.V74.Tile.RoadHorizontal

        Evergreen.V72.Tile.RoadVertical ->
            Evergreen.V74.Tile.RoadVertical

        Evergreen.V72.Tile.RoadBottomToLeft ->
            Evergreen.V74.Tile.RoadBottomToLeft

        Evergreen.V72.Tile.RoadTopToLeft ->
            Evergreen.V74.Tile.RoadTopToLeft

        Evergreen.V72.Tile.RoadTopToRight ->
            Evergreen.V74.Tile.RoadTopToRight

        Evergreen.V72.Tile.RoadBottomToRight ->
            Evergreen.V74.Tile.RoadBottomToRight

        Evergreen.V72.Tile.Road4Way ->
            Evergreen.V74.Tile.Road4Way

        Evergreen.V72.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V74.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V72.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V74.Tile.RoadSidewalkCrossingVertical

        Evergreen.V72.Tile.Road3WayDown ->
            Evergreen.V74.Tile.Road3WayDown

        Evergreen.V72.Tile.Road3WayLeft ->
            Evergreen.V74.Tile.Road3WayLeft

        Evergreen.V72.Tile.Road3WayUp ->
            Evergreen.V74.Tile.Road3WayUp

        Evergreen.V72.Tile.Road3WayRight ->
            Evergreen.V74.Tile.Road3WayRight

        Evergreen.V72.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V74.Tile.RoadRailCrossingHorizontal

        Evergreen.V72.Tile.RoadRailCrossingVertical ->
            Evergreen.V74.Tile.RoadRailCrossingVertical

        Evergreen.V72.Tile.FenceHorizontal ->
            Evergreen.V74.Tile.FenceHorizontal

        Evergreen.V72.Tile.FenceVertical ->
            Evergreen.V74.Tile.FenceVertical

        Evergreen.V72.Tile.FenceDiagonal ->
            Evergreen.V74.Tile.FenceDiagonal

        Evergreen.V72.Tile.FenceAntidiagonal ->
            Evergreen.V74.Tile.FenceAntidiagonal

        Evergreen.V72.Tile.RoadDeadendUp ->
            Evergreen.V74.Tile.RoadDeadendUp

        Evergreen.V72.Tile.RoadDeadendDown ->
            Evergreen.V74.Tile.RoadDeadendDown

        Evergreen.V72.Tile.BusStopDown ->
            Evergreen.V74.Tile.BusStopDown

        Evergreen.V72.Tile.BusStopLeft ->
            Evergreen.V74.Tile.BusStopLeft

        Evergreen.V72.Tile.BusStopRight ->
            Evergreen.V74.Tile.BusStopRight

        Evergreen.V72.Tile.BusStopUp ->
            Evergreen.V74.Tile.BusStopUp

        Evergreen.V72.Tile.Hospital ->
            Evergreen.V74.Tile.Hospital

        Evergreen.V72.Tile.Statue ->
            Evergreen.V74.Tile.Statue

        Evergreen.V72.Tile.HedgeRowDown ->
            Evergreen.V74.Tile.HedgeRowDown

        Evergreen.V72.Tile.HedgeRowLeft ->
            Evergreen.V74.Tile.HedgeRowLeft

        Evergreen.V72.Tile.HedgeRowRight ->
            Evergreen.V74.Tile.HedgeRowRight

        Evergreen.V72.Tile.HedgeRowUp ->
            Evergreen.V74.Tile.HedgeRowUp

        Evergreen.V72.Tile.HedgeCornerDownLeft ->
            Evergreen.V74.Tile.HedgeCornerDownLeft

        Evergreen.V72.Tile.HedgeCornerDownRight ->
            Evergreen.V74.Tile.HedgeCornerDownRight

        Evergreen.V72.Tile.HedgeCornerUpLeft ->
            Evergreen.V74.Tile.HedgeCornerUpLeft

        Evergreen.V72.Tile.HedgeCornerUpRight ->
            Evergreen.V74.Tile.HedgeCornerUpRight

        Evergreen.V72.Tile.ApartmentDown ->
            Evergreen.V74.Tile.ApartmentDown

        Evergreen.V72.Tile.ApartmentLeft ->
            Evergreen.V74.Tile.ApartmentLeft

        Evergreen.V72.Tile.ApartmentRight ->
            Evergreen.V74.Tile.ApartmentRight

        Evergreen.V72.Tile.ApartmentUp ->
            Evergreen.V74.Tile.ApartmentUp

        Evergreen.V72.Tile.RockDown ->
            Evergreen.V74.Tile.RockDown

        Evergreen.V72.Tile.RockLeft ->
            Evergreen.V74.Tile.RockLeft

        Evergreen.V72.Tile.RockRight ->
            Evergreen.V74.Tile.RockRight

        Evergreen.V72.Tile.RockUp ->
            Evergreen.V74.Tile.RockUp

        Evergreen.V72.Tile.PineTree1 ->
            Evergreen.V74.Tile.PineTree1

        Evergreen.V72.Tile.PineTree2 ->
            Evergreen.V74.Tile.PineTree2

        Evergreen.V72.Tile.HedgePillarDownLeft ->
            Evergreen.V74.Tile.HedgePillarDownLeft

        Evergreen.V72.Tile.HedgePillarDownRight ->
            Evergreen.V74.Tile.HedgePillarDownRight

        Evergreen.V72.Tile.HedgePillarUpLeft ->
            Evergreen.V74.Tile.HedgePillarUpLeft

        Evergreen.V72.Tile.HedgePillarUpRight ->
            Evergreen.V74.Tile.HedgePillarUpRight

        Evergreen.V72.Tile.Flowers1 ->
            Evergreen.V74.Tile.Flowers1

        Evergreen.V72.Tile.Flowers2 ->
            Evergreen.V74.Tile.Flowers2

        Evergreen.V72.Tile.ElmTree ->
            Evergreen.V74.Tile.ElmTree

        Evergreen.V72.Tile.DirtPathHorizontal ->
            Evergreen.V74.Tile.DirtPathHorizontal

        Evergreen.V72.Tile.DirtPathVertical ->
            Evergreen.V74.Tile.DirtPathVertical

        Evergreen.V72.Tile.BigText char ->
            Evergreen.V74.Tile.BigText char

        Evergreen.V72.Tile.BigPineTree ->
            Evergreen.V74.Tile.BigPineTree

        Evergreen.V72.Tile.Hyperlink ->
            Evergreen.V74.Tile.Hyperlink

        Evergreen.V72.Tile.BenchDown ->
            Evergreen.V74.Tile.BenchDown

        Evergreen.V72.Tile.BenchLeft ->
            Evergreen.V74.Tile.BenchLeft

        Evergreen.V72.Tile.BenchUp ->
            Evergreen.V74.Tile.BenchUp

        Evergreen.V72.Tile.BenchRight ->
            Evergreen.V74.Tile.BenchRight

        Evergreen.V72.Tile.ParkingDown ->
            Evergreen.V74.Tile.ParkingDown

        Evergreen.V72.Tile.ParkingLeft ->
            Evergreen.V74.Tile.ParkingLeft

        Evergreen.V72.Tile.ParkingUp ->
            Evergreen.V74.Tile.ParkingUp

        Evergreen.V72.Tile.ParkingRight ->
            Evergreen.V74.Tile.ParkingRight

        Evergreen.V72.Tile.ParkingRoad ->
            Evergreen.V74.Tile.ParkingRoad

        Evergreen.V72.Tile.ParkingRoundabout ->
            Evergreen.V74.Tile.ParkingRoundabout

        Evergreen.V72.Tile.CornerHouseUpLeft ->
            Evergreen.V74.Tile.CornerHouseUpLeft

        Evergreen.V72.Tile.CornerHouseUpRight ->
            Evergreen.V74.Tile.CornerHouseUpRight

        Evergreen.V72.Tile.CornerHouseDownLeft ->
            Evergreen.V74.Tile.CornerHouseDownLeft

        Evergreen.V72.Tile.CornerHouseDownRight ->
            Evergreen.V74.Tile.CornerHouseDownRight


migrateTrain : Evergreen.V72.Train.Train -> Evergreen.V74.Train.Train
migrateTrain old =
    case old of
        Evergreen.V72.Train.Train a ->
            Evergreen.V74.Train.Train
                { position = migrateCoord a.position
                , path = migrateRailPath a.path
                , previousPaths = migrateList migratePreviousPath a.previousPaths
                , t = identity a.t
                , speed = migrateQuantity a.speed
                , home = migrateCoord a.home
                , homePath = migrateRailPath a.homePath
                , status = migrateStatus a.status
                , owner = migrateId a.owner
                , isStuckOrDerailed = migrateIsStuckOrDerailed a.isStuckOrDerailed
                , color = migrateColor a.color
                }


migrateIsStuckOrDerailed : Evergreen.V72.Train.IsStuckOrDerailed -> Evergreen.V74.Train.IsStuckOrDerailed
migrateIsStuckOrDerailed old =
    Debug.todo ""


rgb255 : Int -> Int -> Int -> Evergreen.V74.Color.Color
rgb255 red2 green2 blue2 =
    Bitwise.shiftLeftBy 16 (clamp 0 255 red2)
        + Bitwise.shiftLeftBy 8 (clamp 0 255 green2)
        + clamp 0 255 blue2
        |> Evergreen.V74.Color.Color


migrateStatus : Evergreen.V72.Train.Status -> Evergreen.V74.Train.Status
migrateStatus old =
    case old of
        Evergreen.V72.Train.WaitingAtHome ->
            Evergreen.V74.Train.WaitingAtHome

        Evergreen.V72.Train.TeleportingHome a ->
            Evergreen.V74.Train.TeleportingHome (migratePosix a)

        Evergreen.V72.Train.Travelling ->
            Evergreen.V74.Train.Travelling

        Evergreen.V72.Train.StoppedAtPostOffice a ->
            Evergreen.V74.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V72.Tile.RailPath -> Evergreen.V74.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V72.Tile.RailPathHorizontal a ->
            Evergreen.V74.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V72.Tile.RailPathVertical a ->
            Evergreen.V74.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V72.Tile.RailPathBottomToRight ->
            Evergreen.V74.Tile.RailPathBottomToRight

        Evergreen.V72.Tile.RailPathBottomToLeft ->
            Evergreen.V74.Tile.RailPathBottomToLeft

        Evergreen.V72.Tile.RailPathTopToRight ->
            Evergreen.V74.Tile.RailPathTopToRight

        Evergreen.V72.Tile.RailPathTopToLeft ->
            Evergreen.V74.Tile.RailPathTopToLeft

        Evergreen.V72.Tile.RailPathBottomToRightLarge ->
            Evergreen.V74.Tile.RailPathBottomToRightLarge

        Evergreen.V72.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V74.Tile.RailPathBottomToLeftLarge

        Evergreen.V72.Tile.RailPathTopToRightLarge ->
            Evergreen.V74.Tile.RailPathTopToRightLarge

        Evergreen.V72.Tile.RailPathTopToLeftLarge ->
            Evergreen.V74.Tile.RailPathTopToLeftLarge

        Evergreen.V72.Tile.RailPathStrafeDown ->
            Evergreen.V74.Tile.RailPathStrafeDown

        Evergreen.V72.Tile.RailPathStrafeUp ->
            Evergreen.V74.Tile.RailPathStrafeUp

        Evergreen.V72.Tile.RailPathStrafeLeft ->
            Evergreen.V74.Tile.RailPathStrafeLeft

        Evergreen.V72.Tile.RailPathStrafeRight ->
            Evergreen.V74.Tile.RailPathStrafeRight

        Evergreen.V72.Tile.RailPathStrafeDownSmall ->
            Evergreen.V74.Tile.RailPathStrafeDownSmall

        Evergreen.V72.Tile.RailPathStrafeUpSmall ->
            Evergreen.V74.Tile.RailPathStrafeUpSmall

        Evergreen.V72.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V74.Tile.RailPathStrafeLeftSmall

        Evergreen.V72.Tile.RailPathStrafeRightSmall ->
            Evergreen.V74.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V72.Train.PreviousPath -> Evergreen.V74.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V72.MailEditor.Image -> Evergreen.V74.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V72.MailEditor.Stamp a ->
            Evergreen.V74.MailEditor.Stamp (migrateColors a)

        Evergreen.V72.MailEditor.SunglassesEmoji a ->
            Evergreen.V74.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V72.MailEditor.NormalEmoji a ->
            Evergreen.V74.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V72.MailEditor.SadEmoji a ->
            Evergreen.V74.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V72.MailEditor.Cow a ->
            Evergreen.V74.MailEditor.Animal Evergreen.V74.Animal.Cow (migrateColors a)

        Evergreen.V72.MailEditor.Man a ->
            Evergreen.V74.MailEditor.Man (migrateColors a)

        Evergreen.V72.MailEditor.TileImage a b c ->
            Evergreen.V74.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V72.MailEditor.Grass ->
            Evergreen.V74.MailEditor.Grass

        Evergreen.V72.MailEditor.DefaultCursor a ->
            Evergreen.V74.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V72.MailEditor.DragCursor a ->
            Evergreen.V74.MailEditor.DragCursor (migrateColors a)

        Evergreen.V72.MailEditor.PinchCursor a ->
            Evergreen.V74.MailEditor.PinchCursor (migrateColors a)

        Evergreen.V72.MailEditor.Line int color ->
            Evergreen.V74.MailEditor.Line int (migrateColor color)


migrateTileGroup : Evergreen.V72.Tile.TileGroup -> Evergreen.V74.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V72.Tile.EmptyTileGroup ->
            Evergreen.V74.Tile.EmptyTileGroup

        Evergreen.V72.Tile.HouseGroup ->
            Evergreen.V74.Tile.HouseGroup

        Evergreen.V72.Tile.RailStraightGroup ->
            Evergreen.V74.Tile.RailStraightGroup

        Evergreen.V72.Tile.RailTurnGroup ->
            Evergreen.V74.Tile.RailTurnGroup

        Evergreen.V72.Tile.RailTurnLargeGroup ->
            Evergreen.V74.Tile.RailTurnLargeGroup

        Evergreen.V72.Tile.RailStrafeGroup ->
            Evergreen.V74.Tile.RailStrafeGroup

        Evergreen.V72.Tile.RailStrafeSmallGroup ->
            Evergreen.V74.Tile.RailStrafeSmallGroup

        Evergreen.V72.Tile.RailCrossingGroup ->
            Evergreen.V74.Tile.RailCrossingGroup

        Evergreen.V72.Tile.TrainHouseGroup ->
            Evergreen.V74.Tile.TrainHouseGroup

        Evergreen.V72.Tile.SidewalkGroup ->
            Evergreen.V74.Tile.SidewalkGroup

        Evergreen.V72.Tile.SidewalkRailGroup ->
            Evergreen.V74.Tile.SidewalkRailGroup

        Evergreen.V72.Tile.RailTurnSplitGroup ->
            Evergreen.V74.Tile.RailTurnSplitGroup

        Evergreen.V72.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V74.Tile.RailTurnSplitMirrorGroup

        Evergreen.V72.Tile.PostOfficeGroup ->
            Evergreen.V74.Tile.PostOfficeGroup

        Evergreen.V72.Tile.PineTreeGroup ->
            Evergreen.V74.Tile.PineTreeGroup

        Evergreen.V72.Tile.LogCabinGroup ->
            Evergreen.V74.Tile.LogCabinGroup

        Evergreen.V72.Tile.RoadStraightGroup ->
            Evergreen.V74.Tile.RoadStraightGroup

        Evergreen.V72.Tile.RoadTurnGroup ->
            Evergreen.V74.Tile.RoadTurnGroup

        Evergreen.V72.Tile.Road4WayGroup ->
            Evergreen.V74.Tile.Road4WayGroup

        Evergreen.V72.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V74.Tile.RoadSidewalkCrossingGroup

        Evergreen.V72.Tile.Road3WayGroup ->
            Evergreen.V74.Tile.Road3WayGroup

        Evergreen.V72.Tile.RoadRailCrossingGroup ->
            Evergreen.V74.Tile.RoadRailCrossingGroup

        Evergreen.V72.Tile.RoadDeadendGroup ->
            Evergreen.V74.Tile.RoadDeadendGroup

        Evergreen.V72.Tile.FenceStraightGroup ->
            Evergreen.V74.Tile.FenceStraightGroup

        Evergreen.V72.Tile.BusStopGroup ->
            Evergreen.V74.Tile.BusStopGroup

        Evergreen.V72.Tile.HospitalGroup ->
            Evergreen.V74.Tile.HospitalGroup

        Evergreen.V72.Tile.StatueGroup ->
            Evergreen.V74.Tile.StatueGroup

        Evergreen.V72.Tile.HedgeRowGroup ->
            Evergreen.V74.Tile.HedgeRowGroup

        Evergreen.V72.Tile.HedgeCornerGroup ->
            Evergreen.V74.Tile.HedgeCornerGroup

        Evergreen.V72.Tile.ApartmentGroup ->
            Evergreen.V74.Tile.ApartmentGroup

        Evergreen.V72.Tile.RockGroup ->
            Evergreen.V74.Tile.RockGroup

        Evergreen.V72.Tile.FlowersGroup ->
            Evergreen.V74.Tile.FlowersGroup

        Evergreen.V72.Tile.HedgePillarGroup ->
            Evergreen.V74.Tile.HedgePillarGroup

        Evergreen.V72.Tile.ElmTreeGroup ->
            Evergreen.V74.Tile.ElmTreeGroup

        Evergreen.V72.Tile.DirtPathGroup ->
            Evergreen.V74.Tile.DirtPathGroup

        Evergreen.V72.Tile.BigTextGroup ->
            Evergreen.V74.Tile.BigTextGroup

        Evergreen.V72.Tile.BigPineTreeGroup ->
            Evergreen.V74.Tile.BigPineTreeGroup

        Evergreen.V72.Tile.HyperlinkGroup ->
            Evergreen.V74.Tile.HyperlinkGroup

        Evergreen.V72.Tile.BenchGroup ->
            Evergreen.V74.Tile.BenchGroup

        Evergreen.V72.Tile.ParkingLotGroup ->
            Evergreen.V74.Tile.ParkingLotGroup

        Evergreen.V72.Tile.ParkingRoadGroup ->
            Evergreen.V74.Tile.ParkingRoadGroup

        Evergreen.V72.Tile.ParkingRoundaboutGroup ->
            Evergreen.V74.Tile.ParkingRoundaboutGroup

        Evergreen.V72.Tile.CornerHouseGroup ->
            Evergreen.V74.Tile.CornerHouseGroup


migrateDisplayName : Evergreen.V72.DisplayName.DisplayName -> Evergreen.V74.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V72.DisplayName.DisplayName a ->
            Evergreen.V74.DisplayName.DisplayName a


migrateCursor : Evergreen.V72.Cursor.Cursor -> Evergreen.V74.Cursor.Cursor
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
        Evergreen.V74.Cursor.HandTool
    }


migrateContent : Evergreen.V72.MailEditor.Content -> Evergreen.V74.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, item = migrateImageOrText old.item }


migrateImageOrText : Evergreen.V72.MailEditor.ImageOrText -> Evergreen.V74.MailEditor.ImageOrText
migrateImageOrText old =
    case old of
        Evergreen.V72.MailEditor.ImageType imageType ->
            migrateImage imageType |> Evergreen.V74.MailEditor.ImageType

        Evergreen.V72.MailEditor.TextType string ->
            Evergreen.V74.MailEditor.TextType string


migrateColors : Evergreen.V72.Color.Colors -> Evergreen.V74.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V72.Color.Color -> Evergreen.V74.Color.Color
migrateColor old =
    case old of
        Evergreen.V72.Color.Color a ->
            Evergreen.V74.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V72.Types.ViewPoint -> Evergreen.V74.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V72.Types.NormalViewPoint a ->
            Evergreen.V74.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V72.Types.TrainViewPoint a ->
            Evergreen.V74.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V72.Geometry.Types.Point2d old) =
    Evergreen.V74.Geometry.Types.Point2d old


migrateId : Evergreen.V72.Id.Id a -> Evergreen.V74.Id.Id b
migrateId (Evergreen.V72.Id.Id old) =
    Evergreen.V74.Id.Id old


migrateDictToIdDict : Dict.Dict Int a -> Evergreen.V74.IdDict.IdDict id a
migrateDictToIdDict dict =
    Dict.toList dict |> List.map (Tuple.mapFirst Evergreen.V74.Id.Id) |> fromList


{-| Convert an association list into a dictionary.
-}
fromList : List ( Evergreen.V74.Id.Id a, v ) -> Evergreen.V74.IdDict.IdDict a v
fromList assocs =
    List.foldl (\( key, value ) dict -> insert key value dict) empty assocs


{-| Create an empty dictionary.
-}
empty : Evergreen.V74.IdDict.IdDict k v
empty =
    Evergreen.V74.IdDict.RBEmpty_elm_builtin


{-| Insert a key-value pair into a dictionary. Replaces value when there is
a collision.
-}
insert : Evergreen.V74.Id.Id a -> v -> Evergreen.V74.IdDict.IdDict a v -> Evergreen.V74.IdDict.IdDict a v
insert key value dict =
    -- Root node is always Black
    case insertHelp key value dict of
        Evergreen.V74.IdDict.RBNode_elm_builtin Evergreen.V74.IdDict.Red k v l r ->
            Evergreen.V74.IdDict.RBNode_elm_builtin Evergreen.V74.IdDict.Black k v l r

        x ->
            x


idToInt (Evergreen.V74.Id.Id id) =
    id


insertHelp : Evergreen.V74.Id.Id a -> v -> Evergreen.V74.IdDict.IdDict a v -> Evergreen.V74.IdDict.IdDict a v
insertHelp key value dict =
    case dict of
        Evergreen.V74.IdDict.RBEmpty_elm_builtin ->
            -- New nodes are always red. If it violates the rules, it will be fixed
            -- when balancing.
            Evergreen.V74.IdDict.RBNode_elm_builtin Evergreen.V74.IdDict.Red (idToInt key) value Evergreen.V74.IdDict.RBEmpty_elm_builtin Evergreen.V74.IdDict.RBEmpty_elm_builtin

        Evergreen.V74.IdDict.RBNode_elm_builtin nColor nKey nValue nLeft nRight ->
            case compare (idToInt key) nKey of
                LT ->
                    balance nColor nKey nValue (insertHelp key value nLeft) nRight

                EQ ->
                    Evergreen.V74.IdDict.RBNode_elm_builtin nColor nKey value nLeft nRight

                GT ->
                    balance nColor nKey nValue nLeft (insertHelp key value nRight)


balance : Evergreen.V74.IdDict.NColor -> Int -> v -> Evergreen.V74.IdDict.IdDict k v -> Evergreen.V74.IdDict.IdDict k v -> Evergreen.V74.IdDict.IdDict k v
balance color key value left right =
    case right of
        Evergreen.V74.IdDict.RBNode_elm_builtin Evergreen.V74.IdDict.Red rK rV rLeft rRight ->
            case left of
                Evergreen.V74.IdDict.RBNode_elm_builtin Evergreen.V74.IdDict.Red lK lV lLeft lRight ->
                    Evergreen.V74.IdDict.RBNode_elm_builtin
                        Evergreen.V74.IdDict.Red
                        key
                        value
                        (Evergreen.V74.IdDict.RBNode_elm_builtin Evergreen.V74.IdDict.Black lK lV lLeft lRight)
                        (Evergreen.V74.IdDict.RBNode_elm_builtin Evergreen.V74.IdDict.Black rK rV rLeft rRight)

                _ ->
                    Evergreen.V74.IdDict.RBNode_elm_builtin color rK rV (Evergreen.V74.IdDict.RBNode_elm_builtin Evergreen.V74.IdDict.Red key value left rLeft) rRight

        _ ->
            case left of
                Evergreen.V74.IdDict.RBNode_elm_builtin Evergreen.V74.IdDict.Red lK lV (Evergreen.V74.IdDict.RBNode_elm_builtin Evergreen.V74.IdDict.Red llK llV llLeft llRight) lRight ->
                    Evergreen.V74.IdDict.RBNode_elm_builtin
                        Evergreen.V74.IdDict.Red
                        lK
                        lV
                        (Evergreen.V74.IdDict.RBNode_elm_builtin Evergreen.V74.IdDict.Black llK llV llLeft llRight)
                        (Evergreen.V74.IdDict.RBNode_elm_builtin Evergreen.V74.IdDict.Black key value lRight right)

                _ ->
                    Evergreen.V74.IdDict.RBNode_elm_builtin color key value left right
