module Evergreen.Migrate.V76 exposing (..)

import AssocList
import AssocSet
import Bitwise
import Dict
import Effect.Time
import Evergreen.V75.Animal
import Evergreen.V75.Bounds
import Evergreen.V75.Change
import Evergreen.V75.Color
import Evergreen.V75.Cursor
import Evergreen.V75.DisplayName
import Evergreen.V75.EmailAddress
import Evergreen.V75.Geometry.Types
import Evergreen.V75.Grid
import Evergreen.V75.GridCell
import Evergreen.V75.Id
import Evergreen.V75.IdDict
import Evergreen.V75.MailEditor
import Evergreen.V75.Postmark
import Evergreen.V75.Tile
import Evergreen.V75.Train
import Evergreen.V75.Types
import Evergreen.V76.Animal
import Evergreen.V76.Bounds
import Evergreen.V76.Change
import Evergreen.V76.Color
import Evergreen.V76.Cursor
import Evergreen.V76.DisplayName
import Evergreen.V76.EmailAddress
import Evergreen.V76.Geometry.Types
import Evergreen.V76.Grid
import Evergreen.V76.GridCell
import Evergreen.V76.Id
import Evergreen.V76.IdDict
import Evergreen.V76.MailEditor
import Evergreen.V76.Postmark
import Evergreen.V76.Tile
import Evergreen.V76.Train
import Evergreen.V76.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Quantity exposing (Quantity)
import Random


backendModel : Evergreen.V75.Types.BackendModel -> ModelMigration Evergreen.V76.Types.BackendModel Evergreen.V76.Types.BackendMsg
backendModel old =
    ModelMigrated
        ( migrateBackendModel old
        , Cmd.none
        )


frontendModel : Evergreen.V75.Types.FrontendModel -> ModelMigration Evergreen.V76.Types.FrontendModel Evergreen.V76.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V75.Types.FrontendMsg -> MsgMigration Evergreen.V76.Types.FrontendMsg Evergreen.V76.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V75.Types.BackendMsg -> MsgMigration Evergreen.V76.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V75.Types.BackendError -> Evergreen.V76.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V75.Types.PostmarkError a b ->
            Evergreen.V76.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V75.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V76.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V75.Types.BackendModel -> Evergreen.V76.Types.BackendModel
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
    , trainsDisabled = migrateAreTrainsDisabled old.trainsDisabled
    , reported = migrateIdDict (List.Nonempty.map migrateBackendReported) old.reported
    , lastReportEmailToAdmin = old.lastReportEmailToAdmin
    }


migrateAreTrainsDisabled : Evergreen.V75.Change.AreTrainsDisabled -> Evergreen.V76.Change.AreTrainsDisabled
migrateAreTrainsDisabled old =
    case old of
        Evergreen.V75.Change.TrainsDisabled ->
            Evergreen.V76.Change.TrainsDisabled

        Evergreen.V75.Change.TrainsEnabled ->
            Evergreen.V76.Change.TrainsEnabled


migrateBackendReported : Evergreen.V75.Change.BackendReport -> Evergreen.V76.Change.BackendReport
migrateBackendReported old =
    { reportedUser = migrateId old.reportedUser
    , position = migrateCoord old.position
    , reportedAt = old.reportedAt
    }


migrateRequestedBy : Evergreen.V75.Types.LoginRequestedBy -> Evergreen.V76.Types.LoginRequestedBy
migrateRequestedBy old =
    case old of
        Evergreen.V75.Types.LoginRequestedByBackend ->
            Evergreen.V76.Types.LoginRequestedByBackend

        Evergreen.V75.Types.LoginRequestedByFrontend sessionId ->
            Evergreen.V76.Types.LoginRequestedByFrontend sessionId


migrateGrid : Evergreen.V75.Grid.Grid -> Evergreen.V76.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V75.Grid.Grid a ->
            Evergreen.V76.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V75.GridCell.Cell -> Evergreen.V76.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V75.GridCell.Cell a ->
            Evergreen.V76.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateIdDict identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V75.GridCell.Value -> Evergreen.V76.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V75.Bounds.Bounds a -> Evergreen.V76.Bounds.Bounds b
migrateBounds (Evergreen.V75.Bounds.Bounds old) =
    Evergreen.V76.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V75.Animal.Animal -> Evergreen.V76.Animal.Animal
migrateCow old =
    { position = migratePoint2d old.position, animalType = migrateAnimalType old.animalType }


migrateAnimalType : Evergreen.V75.Animal.AnimalType -> Evergreen.V76.Animal.AnimalType
migrateAnimalType old =
    case old of
        Evergreen.V75.Animal.Cow ->
            Evergreen.V76.Animal.Cow

        Evergreen.V75.Animal.Hamster ->
            Evergreen.V76.Animal.Hamster

        Evergreen.V75.Animal.Sheep ->
            Evergreen.V76.Animal.Sheep


migrateBackendMail : Evergreen.V75.MailEditor.BackendMail -> Evergreen.V76.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V75.MailEditor.MailStatus -> Evergreen.V76.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V75.MailEditor.MailWaitingPickup ->
            Evergreen.V76.MailEditor.MailWaitingPickup

        Evergreen.V75.MailEditor.MailInTransit a ->
            Evergreen.V76.MailEditor.MailInTransit (migrateId a)

        Evergreen.V75.MailEditor.MailReceived a ->
            Evergreen.V76.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V75.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V76.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V75.Types.Invite -> Evergreen.V76.Types.Invite
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


migrateEmailAddress (Evergreen.V75.EmailAddress.EmailAddress old) =
    Evergreen.V76.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V75.Id.SecretId a -> Evergreen.V76.Id.SecretId b
migrateSecretId (Evergreen.V75.Id.SecretId old) =
    Evergreen.V76.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V75.IdDict.IdDict a b -> Evergreen.V76.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V75.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V76.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V75.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V76.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V75.IdDict.NColor -> Evergreen.V76.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V75.IdDict.Red ->
            Evergreen.V76.IdDict.Red

        Evergreen.V75.IdDict.Black ->
            Evergreen.V76.IdDict.Black


migrateBackendUserData : Evergreen.V75.Types.BackendUserData -> Evergreen.V76.Types.BackendUserData
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


migrateEmailResult : Evergreen.V75.Types.EmailResult -> Evergreen.V76.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V75.Types.EmailSending ->
            Evergreen.V76.Types.EmailSending

        Evergreen.V75.Types.EmailSendFailed a ->
            Evergreen.V76.Types.EmailSendFailed a

        Evergreen.V75.Types.EmailSent a ->
            Evergreen.V76.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V75.Postmark.PostmarkSendResponse -> Evergreen.V76.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V75.Tile.Tile -> Evergreen.V76.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V75.Tile.EmptyTile ->
            Evergreen.V76.Tile.EmptyTile

        Evergreen.V75.Tile.HouseDown ->
            Evergreen.V76.Tile.HouseDown

        Evergreen.V75.Tile.HouseRight ->
            Evergreen.V76.Tile.HouseRight

        Evergreen.V75.Tile.HouseUp ->
            Evergreen.V76.Tile.HouseUp

        Evergreen.V75.Tile.HouseLeft ->
            Evergreen.V76.Tile.HouseLeft

        Evergreen.V75.Tile.RailHorizontal ->
            Evergreen.V76.Tile.RailHorizontal

        Evergreen.V75.Tile.RailVertical ->
            Evergreen.V76.Tile.RailVertical

        Evergreen.V75.Tile.RailBottomToRight ->
            Evergreen.V76.Tile.RailBottomToRight

        Evergreen.V75.Tile.RailBottomToLeft ->
            Evergreen.V76.Tile.RailBottomToLeft

        Evergreen.V75.Tile.RailTopToRight ->
            Evergreen.V76.Tile.RailTopToRight

        Evergreen.V75.Tile.RailTopToLeft ->
            Evergreen.V76.Tile.RailTopToLeft

        Evergreen.V75.Tile.RailBottomToRightLarge ->
            Evergreen.V76.Tile.RailBottomToRightLarge

        Evergreen.V75.Tile.RailBottomToLeftLarge ->
            Evergreen.V76.Tile.RailBottomToLeftLarge

        Evergreen.V75.Tile.RailTopToRightLarge ->
            Evergreen.V76.Tile.RailTopToRightLarge

        Evergreen.V75.Tile.RailTopToLeftLarge ->
            Evergreen.V76.Tile.RailTopToLeftLarge

        Evergreen.V75.Tile.RailCrossing ->
            Evergreen.V76.Tile.RailCrossing

        Evergreen.V75.Tile.RailStrafeDown ->
            Evergreen.V76.Tile.RailStrafeDown

        Evergreen.V75.Tile.RailStrafeUp ->
            Evergreen.V76.Tile.RailStrafeUp

        Evergreen.V75.Tile.RailStrafeLeft ->
            Evergreen.V76.Tile.RailStrafeLeft

        Evergreen.V75.Tile.RailStrafeRight ->
            Evergreen.V76.Tile.RailStrafeRight

        Evergreen.V75.Tile.TrainHouseRight ->
            Evergreen.V76.Tile.TrainHouseRight

        Evergreen.V75.Tile.TrainHouseLeft ->
            Evergreen.V76.Tile.TrainHouseLeft

        Evergreen.V75.Tile.RailStrafeDownSmall ->
            Evergreen.V76.Tile.RailStrafeDownSmall

        Evergreen.V75.Tile.RailStrafeUpSmall ->
            Evergreen.V76.Tile.RailStrafeUpSmall

        Evergreen.V75.Tile.RailStrafeLeftSmall ->
            Evergreen.V76.Tile.RailStrafeLeftSmall

        Evergreen.V75.Tile.RailStrafeRightSmall ->
            Evergreen.V76.Tile.RailStrafeRightSmall

        Evergreen.V75.Tile.Sidewalk ->
            Evergreen.V76.Tile.Sidewalk

        Evergreen.V75.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V76.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V75.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V76.Tile.SidewalkVerticalRailCrossing

        Evergreen.V75.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V76.Tile.RailBottomToRight_SplitLeft

        Evergreen.V75.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V76.Tile.RailBottomToLeft_SplitUp

        Evergreen.V75.Tile.RailTopToRight_SplitDown ->
            Evergreen.V76.Tile.RailTopToRight_SplitDown

        Evergreen.V75.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V76.Tile.RailTopToLeft_SplitRight

        Evergreen.V75.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V76.Tile.RailBottomToRight_SplitUp

        Evergreen.V75.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V76.Tile.RailBottomToLeft_SplitRight

        Evergreen.V75.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V76.Tile.RailTopToRight_SplitLeft

        Evergreen.V75.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V76.Tile.RailTopToLeft_SplitDown

        Evergreen.V75.Tile.PostOffice ->
            Evergreen.V76.Tile.PostOffice

        Evergreen.V75.Tile.MowedGrass1 ->
            Evergreen.V76.Tile.MowedGrass1

        Evergreen.V75.Tile.MowedGrass4 ->
            Evergreen.V76.Tile.MowedGrass4

        Evergreen.V75.Tile.LogCabinDown ->
            Evergreen.V76.Tile.LogCabinDown

        Evergreen.V75.Tile.LogCabinRight ->
            Evergreen.V76.Tile.LogCabinRight

        Evergreen.V75.Tile.LogCabinUp ->
            Evergreen.V76.Tile.LogCabinUp

        Evergreen.V75.Tile.LogCabinLeft ->
            Evergreen.V76.Tile.LogCabinLeft

        Evergreen.V75.Tile.RoadHorizontal ->
            Evergreen.V76.Tile.RoadHorizontal

        Evergreen.V75.Tile.RoadVertical ->
            Evergreen.V76.Tile.RoadVertical

        Evergreen.V75.Tile.RoadBottomToLeft ->
            Evergreen.V76.Tile.RoadBottomToLeft

        Evergreen.V75.Tile.RoadTopToLeft ->
            Evergreen.V76.Tile.RoadTopToLeft

        Evergreen.V75.Tile.RoadTopToRight ->
            Evergreen.V76.Tile.RoadTopToRight

        Evergreen.V75.Tile.RoadBottomToRight ->
            Evergreen.V76.Tile.RoadBottomToRight

        Evergreen.V75.Tile.Road4Way ->
            Evergreen.V76.Tile.Road4Way

        Evergreen.V75.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V76.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V75.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V76.Tile.RoadSidewalkCrossingVertical

        Evergreen.V75.Tile.Road3WayDown ->
            Evergreen.V76.Tile.Road3WayDown

        Evergreen.V75.Tile.Road3WayLeft ->
            Evergreen.V76.Tile.Road3WayLeft

        Evergreen.V75.Tile.Road3WayUp ->
            Evergreen.V76.Tile.Road3WayUp

        Evergreen.V75.Tile.Road3WayRight ->
            Evergreen.V76.Tile.Road3WayRight

        Evergreen.V75.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V76.Tile.RoadRailCrossingHorizontal

        Evergreen.V75.Tile.RoadRailCrossingVertical ->
            Evergreen.V76.Tile.RoadRailCrossingVertical

        Evergreen.V75.Tile.FenceHorizontal ->
            Evergreen.V76.Tile.FenceHorizontal

        Evergreen.V75.Tile.FenceVertical ->
            Evergreen.V76.Tile.FenceVertical

        Evergreen.V75.Tile.FenceDiagonal ->
            Evergreen.V76.Tile.FenceDiagonal

        Evergreen.V75.Tile.FenceAntidiagonal ->
            Evergreen.V76.Tile.FenceAntidiagonal

        Evergreen.V75.Tile.RoadDeadendUp ->
            Evergreen.V76.Tile.RoadDeadendUp

        Evergreen.V75.Tile.RoadDeadendDown ->
            Evergreen.V76.Tile.RoadDeadendDown

        Evergreen.V75.Tile.BusStopDown ->
            Evergreen.V76.Tile.BusStopDown

        Evergreen.V75.Tile.BusStopLeft ->
            Evergreen.V76.Tile.BusStopLeft

        Evergreen.V75.Tile.BusStopRight ->
            Evergreen.V76.Tile.BusStopRight

        Evergreen.V75.Tile.BusStopUp ->
            Evergreen.V76.Tile.BusStopUp

        Evergreen.V75.Tile.Hospital ->
            Evergreen.V76.Tile.Hospital

        Evergreen.V75.Tile.Statue ->
            Evergreen.V76.Tile.Statue

        Evergreen.V75.Tile.HedgeRowDown ->
            Evergreen.V76.Tile.HedgeRowDown

        Evergreen.V75.Tile.HedgeRowLeft ->
            Evergreen.V76.Tile.HedgeRowLeft

        Evergreen.V75.Tile.HedgeRowRight ->
            Evergreen.V76.Tile.HedgeRowRight

        Evergreen.V75.Tile.HedgeRowUp ->
            Evergreen.V76.Tile.HedgeRowUp

        Evergreen.V75.Tile.HedgeCornerDownLeft ->
            Evergreen.V76.Tile.HedgeCornerDownLeft

        Evergreen.V75.Tile.HedgeCornerDownRight ->
            Evergreen.V76.Tile.HedgeCornerDownRight

        Evergreen.V75.Tile.HedgeCornerUpLeft ->
            Evergreen.V76.Tile.HedgeCornerUpLeft

        Evergreen.V75.Tile.HedgeCornerUpRight ->
            Evergreen.V76.Tile.HedgeCornerUpRight

        Evergreen.V75.Tile.ApartmentDown ->
            Evergreen.V76.Tile.ApartmentDown

        Evergreen.V75.Tile.ApartmentLeft ->
            Evergreen.V76.Tile.ApartmentLeft

        Evergreen.V75.Tile.ApartmentRight ->
            Evergreen.V76.Tile.ApartmentRight

        Evergreen.V75.Tile.ApartmentUp ->
            Evergreen.V76.Tile.ApartmentUp

        Evergreen.V75.Tile.RockDown ->
            Evergreen.V76.Tile.RockDown

        Evergreen.V75.Tile.RockLeft ->
            Evergreen.V76.Tile.RockLeft

        Evergreen.V75.Tile.RockRight ->
            Evergreen.V76.Tile.RockRight

        Evergreen.V75.Tile.RockUp ->
            Evergreen.V76.Tile.RockUp

        Evergreen.V75.Tile.PineTree1 ->
            Evergreen.V76.Tile.PineTree1

        Evergreen.V75.Tile.PineTree2 ->
            Evergreen.V76.Tile.PineTree2

        Evergreen.V75.Tile.HedgePillarDownLeft ->
            Evergreen.V76.Tile.HedgePillarDownLeft

        Evergreen.V75.Tile.HedgePillarDownRight ->
            Evergreen.V76.Tile.HedgePillarDownRight

        Evergreen.V75.Tile.HedgePillarUpLeft ->
            Evergreen.V76.Tile.HedgePillarUpLeft

        Evergreen.V75.Tile.HedgePillarUpRight ->
            Evergreen.V76.Tile.HedgePillarUpRight

        Evergreen.V75.Tile.Flowers1 ->
            Evergreen.V76.Tile.Flowers1

        Evergreen.V75.Tile.Flowers2 ->
            Evergreen.V76.Tile.Flowers2

        Evergreen.V75.Tile.ElmTree ->
            Evergreen.V76.Tile.ElmTree

        Evergreen.V75.Tile.DirtPathHorizontal ->
            Evergreen.V76.Tile.DirtPathHorizontal

        Evergreen.V75.Tile.DirtPathVertical ->
            Evergreen.V76.Tile.DirtPathVertical

        Evergreen.V75.Tile.BigText char ->
            Evergreen.V76.Tile.BigText char

        Evergreen.V75.Tile.BigPineTree ->
            Evergreen.V76.Tile.BigPineTree

        Evergreen.V75.Tile.Hyperlink ->
            Evergreen.V76.Tile.Hyperlink

        Evergreen.V75.Tile.BenchDown ->
            Evergreen.V76.Tile.BenchDown

        Evergreen.V75.Tile.BenchLeft ->
            Evergreen.V76.Tile.BenchLeft

        Evergreen.V75.Tile.BenchUp ->
            Evergreen.V76.Tile.BenchUp

        Evergreen.V75.Tile.BenchRight ->
            Evergreen.V76.Tile.BenchRight

        Evergreen.V75.Tile.ParkingDown ->
            Evergreen.V76.Tile.ParkingDown

        Evergreen.V75.Tile.ParkingLeft ->
            Evergreen.V76.Tile.ParkingLeft

        Evergreen.V75.Tile.ParkingUp ->
            Evergreen.V76.Tile.ParkingUp

        Evergreen.V75.Tile.ParkingRight ->
            Evergreen.V76.Tile.ParkingRight

        Evergreen.V75.Tile.ParkingRoad ->
            Evergreen.V76.Tile.ParkingRoad

        Evergreen.V75.Tile.ParkingRoundabout ->
            Evergreen.V76.Tile.ParkingRoundabout

        Evergreen.V75.Tile.CornerHouseUpLeft ->
            Evergreen.V76.Tile.CornerHouseUpLeft

        Evergreen.V75.Tile.CornerHouseUpRight ->
            Evergreen.V76.Tile.CornerHouseUpRight

        Evergreen.V75.Tile.CornerHouseDownLeft ->
            Evergreen.V76.Tile.CornerHouseDownLeft

        Evergreen.V75.Tile.CornerHouseDownRight ->
            Evergreen.V76.Tile.CornerHouseDownRight


migrateTrain : Evergreen.V75.Train.Train -> Evergreen.V76.Train.Train
migrateTrain old =
    case old of
        Evergreen.V75.Train.Train a ->
            Evergreen.V76.Train.Train
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


migrateIsStuckOrDerailed : Evergreen.V75.Train.IsStuckOrDerailed -> Evergreen.V76.Train.IsStuckOrDerailed
migrateIsStuckOrDerailed old =
    case old of
        Evergreen.V75.Train.IsStuck a ->
            Evergreen.V76.Train.IsStuck (migratePosix a)

        Evergreen.V75.Train.IsDerailed a b ->
            Evergreen.V76.Train.IsDerailed (migratePosix a) (migrateId b)

        Evergreen.V75.Train.IsNotStuckOrDerailed ->
            Evergreen.V76.Train.IsNotStuckOrDerailed


rgb255 : Int -> Int -> Int -> Evergreen.V76.Color.Color
rgb255 red2 green2 blue2 =
    Bitwise.shiftLeftBy 16 (clamp 0 255 red2)
        + Bitwise.shiftLeftBy 8 (clamp 0 255 green2)
        + clamp 0 255 blue2
        |> Evergreen.V76.Color.Color


migrateStatus : Evergreen.V75.Train.Status -> Evergreen.V76.Train.Status
migrateStatus old =
    case old of
        Evergreen.V75.Train.WaitingAtHome ->
            Evergreen.V76.Train.WaitingAtHome

        Evergreen.V75.Train.TeleportingHome a ->
            Evergreen.V76.Train.TeleportingHome (migratePosix a)

        Evergreen.V75.Train.Travelling ->
            Evergreen.V76.Train.Travelling

        Evergreen.V75.Train.StoppedAtPostOffice a ->
            Evergreen.V76.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V75.Tile.RailPath -> Evergreen.V76.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V75.Tile.RailPathHorizontal a ->
            Evergreen.V76.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V75.Tile.RailPathVertical a ->
            Evergreen.V76.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V75.Tile.RailPathBottomToRight ->
            Evergreen.V76.Tile.RailPathBottomToRight

        Evergreen.V75.Tile.RailPathBottomToLeft ->
            Evergreen.V76.Tile.RailPathBottomToLeft

        Evergreen.V75.Tile.RailPathTopToRight ->
            Evergreen.V76.Tile.RailPathTopToRight

        Evergreen.V75.Tile.RailPathTopToLeft ->
            Evergreen.V76.Tile.RailPathTopToLeft

        Evergreen.V75.Tile.RailPathBottomToRightLarge ->
            Evergreen.V76.Tile.RailPathBottomToRightLarge

        Evergreen.V75.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V76.Tile.RailPathBottomToLeftLarge

        Evergreen.V75.Tile.RailPathTopToRightLarge ->
            Evergreen.V76.Tile.RailPathTopToRightLarge

        Evergreen.V75.Tile.RailPathTopToLeftLarge ->
            Evergreen.V76.Tile.RailPathTopToLeftLarge

        Evergreen.V75.Tile.RailPathStrafeDown ->
            Evergreen.V76.Tile.RailPathStrafeDown

        Evergreen.V75.Tile.RailPathStrafeUp ->
            Evergreen.V76.Tile.RailPathStrafeUp

        Evergreen.V75.Tile.RailPathStrafeLeft ->
            Evergreen.V76.Tile.RailPathStrafeLeft

        Evergreen.V75.Tile.RailPathStrafeRight ->
            Evergreen.V76.Tile.RailPathStrafeRight

        Evergreen.V75.Tile.RailPathStrafeDownSmall ->
            Evergreen.V76.Tile.RailPathStrafeDownSmall

        Evergreen.V75.Tile.RailPathStrafeUpSmall ->
            Evergreen.V76.Tile.RailPathStrafeUpSmall

        Evergreen.V75.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V76.Tile.RailPathStrafeLeftSmall

        Evergreen.V75.Tile.RailPathStrafeRightSmall ->
            Evergreen.V76.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V75.Train.PreviousPath -> Evergreen.V76.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V75.MailEditor.Image -> Evergreen.V76.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V75.MailEditor.Stamp a ->
            Evergreen.V76.MailEditor.Stamp (migrateColors a)

        Evergreen.V75.MailEditor.SunglassesEmoji a ->
            Evergreen.V76.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V75.MailEditor.NormalEmoji a ->
            Evergreen.V76.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V75.MailEditor.SadEmoji a ->
            Evergreen.V76.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V75.MailEditor.Animal a b ->
            Evergreen.V76.MailEditor.Animal (migrateAnimalType a) (migrateColors b)

        Evergreen.V75.MailEditor.Man a ->
            Evergreen.V76.MailEditor.Man (migrateColors a)

        Evergreen.V75.MailEditor.TileImage a b c ->
            Evergreen.V76.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V75.MailEditor.Grass ->
            Evergreen.V76.MailEditor.Grass

        Evergreen.V75.MailEditor.DefaultCursor a ->
            Evergreen.V76.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V75.MailEditor.DragCursor a ->
            Evergreen.V76.MailEditor.DragCursor (migrateColors a)

        Evergreen.V75.MailEditor.PinchCursor a ->
            Evergreen.V76.MailEditor.PinchCursor (migrateColors a)

        Evergreen.V75.MailEditor.Line int color ->
            Evergreen.V76.MailEditor.Line int (migrateColor color)


migrateTileGroup : Evergreen.V75.Tile.TileGroup -> Evergreen.V76.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V75.Tile.EmptyTileGroup ->
            Evergreen.V76.Tile.EmptyTileGroup

        Evergreen.V75.Tile.HouseGroup ->
            Evergreen.V76.Tile.HouseGroup

        Evergreen.V75.Tile.RailStraightGroup ->
            Evergreen.V76.Tile.RailStraightGroup

        Evergreen.V75.Tile.RailTurnGroup ->
            Evergreen.V76.Tile.RailTurnGroup

        Evergreen.V75.Tile.RailTurnLargeGroup ->
            Evergreen.V76.Tile.RailTurnLargeGroup

        Evergreen.V75.Tile.RailStrafeGroup ->
            Evergreen.V76.Tile.RailStrafeGroup

        Evergreen.V75.Tile.RailStrafeSmallGroup ->
            Evergreen.V76.Tile.RailStrafeSmallGroup

        Evergreen.V75.Tile.RailCrossingGroup ->
            Evergreen.V76.Tile.RailCrossingGroup

        Evergreen.V75.Tile.TrainHouseGroup ->
            Evergreen.V76.Tile.TrainHouseGroup

        Evergreen.V75.Tile.SidewalkGroup ->
            Evergreen.V76.Tile.SidewalkGroup

        Evergreen.V75.Tile.SidewalkRailGroup ->
            Evergreen.V76.Tile.SidewalkRailGroup

        Evergreen.V75.Tile.RailTurnSplitGroup ->
            Evergreen.V76.Tile.RailTurnSplitGroup

        Evergreen.V75.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V76.Tile.RailTurnSplitMirrorGroup

        Evergreen.V75.Tile.PostOfficeGroup ->
            Evergreen.V76.Tile.PostOfficeGroup

        Evergreen.V75.Tile.PineTreeGroup ->
            Evergreen.V76.Tile.PineTreeGroup

        Evergreen.V75.Tile.LogCabinGroup ->
            Evergreen.V76.Tile.LogCabinGroup

        Evergreen.V75.Tile.RoadStraightGroup ->
            Evergreen.V76.Tile.RoadStraightGroup

        Evergreen.V75.Tile.RoadTurnGroup ->
            Evergreen.V76.Tile.RoadTurnGroup

        Evergreen.V75.Tile.Road4WayGroup ->
            Evergreen.V76.Tile.Road4WayGroup

        Evergreen.V75.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V76.Tile.RoadSidewalkCrossingGroup

        Evergreen.V75.Tile.Road3WayGroup ->
            Evergreen.V76.Tile.Road3WayGroup

        Evergreen.V75.Tile.RoadRailCrossingGroup ->
            Evergreen.V76.Tile.RoadRailCrossingGroup

        Evergreen.V75.Tile.RoadDeadendGroup ->
            Evergreen.V76.Tile.RoadDeadendGroup

        Evergreen.V75.Tile.FenceStraightGroup ->
            Evergreen.V76.Tile.FenceStraightGroup

        Evergreen.V75.Tile.BusStopGroup ->
            Evergreen.V76.Tile.BusStopGroup

        Evergreen.V75.Tile.HospitalGroup ->
            Evergreen.V76.Tile.HospitalGroup

        Evergreen.V75.Tile.StatueGroup ->
            Evergreen.V76.Tile.StatueGroup

        Evergreen.V75.Tile.HedgeRowGroup ->
            Evergreen.V76.Tile.HedgeRowGroup

        Evergreen.V75.Tile.HedgeCornerGroup ->
            Evergreen.V76.Tile.HedgeCornerGroup

        Evergreen.V75.Tile.ApartmentGroup ->
            Evergreen.V76.Tile.ApartmentGroup

        Evergreen.V75.Tile.RockGroup ->
            Evergreen.V76.Tile.RockGroup

        Evergreen.V75.Tile.FlowersGroup ->
            Evergreen.V76.Tile.FlowersGroup

        Evergreen.V75.Tile.HedgePillarGroup ->
            Evergreen.V76.Tile.HedgePillarGroup

        Evergreen.V75.Tile.ElmTreeGroup ->
            Evergreen.V76.Tile.ElmTreeGroup

        Evergreen.V75.Tile.DirtPathGroup ->
            Evergreen.V76.Tile.DirtPathGroup

        Evergreen.V75.Tile.BigTextGroup ->
            Evergreen.V76.Tile.BigTextGroup

        Evergreen.V75.Tile.BigPineTreeGroup ->
            Evergreen.V76.Tile.BigPineTreeGroup

        Evergreen.V75.Tile.HyperlinkGroup ->
            Evergreen.V76.Tile.HyperlinkGroup

        Evergreen.V75.Tile.BenchGroup ->
            Evergreen.V76.Tile.BenchGroup

        Evergreen.V75.Tile.ParkingLotGroup ->
            Evergreen.V76.Tile.ParkingLotGroup

        Evergreen.V75.Tile.ParkingRoadGroup ->
            Evergreen.V76.Tile.ParkingRoadGroup

        Evergreen.V75.Tile.ParkingRoundaboutGroup ->
            Evergreen.V76.Tile.ParkingRoundaboutGroup

        Evergreen.V75.Tile.CornerHouseGroup ->
            Evergreen.V76.Tile.CornerHouseGroup


migrateDisplayName : Evergreen.V75.DisplayName.DisplayName -> Evergreen.V76.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V75.DisplayName.DisplayName a ->
            Evergreen.V76.DisplayName.DisplayName a


migrateCursor : Evergreen.V75.Cursor.Cursor -> Evergreen.V76.Cursor.Cursor
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
        Evergreen.V76.Cursor.HandTool
    }


migrateContent : Evergreen.V75.MailEditor.Content -> Evergreen.V76.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, item = migrateImageOrText old.item }


migrateImageOrText : Evergreen.V75.MailEditor.ImageOrText -> Evergreen.V76.MailEditor.ImageOrText
migrateImageOrText old =
    case old of
        Evergreen.V75.MailEditor.ImageType imageType ->
            migrateImage imageType |> Evergreen.V76.MailEditor.ImageType

        Evergreen.V75.MailEditor.TextType string ->
            Evergreen.V76.MailEditor.TextType string


migrateColors : Evergreen.V75.Color.Colors -> Evergreen.V76.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V75.Color.Color -> Evergreen.V76.Color.Color
migrateColor old =
    case old of
        Evergreen.V75.Color.Color a ->
            Evergreen.V76.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V75.Types.ViewPoint -> Evergreen.V76.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V75.Types.NormalViewPoint a ->
            Evergreen.V76.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V75.Types.TrainViewPoint a ->
            Evergreen.V76.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V75.Geometry.Types.Point2d old) =
    Evergreen.V76.Geometry.Types.Point2d old


migrateId : Evergreen.V75.Id.Id a -> Evergreen.V76.Id.Id b
migrateId (Evergreen.V75.Id.Id old) =
    Evergreen.V76.Id.Id old


migrateDictToIdDict : Dict.Dict Int a -> Evergreen.V76.IdDict.IdDict id a
migrateDictToIdDict dict =
    Dict.toList dict |> List.map (Tuple.mapFirst Evergreen.V76.Id.Id) |> fromList


{-| Convert an association list into a dictionary.
-}
fromList : List ( Evergreen.V76.Id.Id a, v ) -> Evergreen.V76.IdDict.IdDict a v
fromList assocs =
    List.foldl (\( key, value ) dict -> insert key value dict) empty assocs


{-| Create an empty dictionary.
-}
empty : Evergreen.V76.IdDict.IdDict k v
empty =
    Evergreen.V76.IdDict.RBEmpty_elm_builtin


{-| Insert a key-value pair into a dictionary. Replaces value when there is
a collision.
-}
insert : Evergreen.V76.Id.Id a -> v -> Evergreen.V76.IdDict.IdDict a v -> Evergreen.V76.IdDict.IdDict a v
insert key value dict =
    -- Root node is always Black
    case insertHelp key value dict of
        Evergreen.V76.IdDict.RBNode_elm_builtin Evergreen.V76.IdDict.Red k v l r ->
            Evergreen.V76.IdDict.RBNode_elm_builtin Evergreen.V76.IdDict.Black k v l r

        x ->
            x


idToInt (Evergreen.V76.Id.Id id) =
    id


insertHelp : Evergreen.V76.Id.Id a -> v -> Evergreen.V76.IdDict.IdDict a v -> Evergreen.V76.IdDict.IdDict a v
insertHelp key value dict =
    case dict of
        Evergreen.V76.IdDict.RBEmpty_elm_builtin ->
            -- New nodes are always red. If it violates the rules, it will be fixed
            -- when balancing.
            Evergreen.V76.IdDict.RBNode_elm_builtin Evergreen.V76.IdDict.Red (idToInt key) value Evergreen.V76.IdDict.RBEmpty_elm_builtin Evergreen.V76.IdDict.RBEmpty_elm_builtin

        Evergreen.V76.IdDict.RBNode_elm_builtin nColor nKey nValue nLeft nRight ->
            case compare (idToInt key) nKey of
                LT ->
                    balance nColor nKey nValue (insertHelp key value nLeft) nRight

                EQ ->
                    Evergreen.V76.IdDict.RBNode_elm_builtin nColor nKey value nLeft nRight

                GT ->
                    balance nColor nKey nValue nLeft (insertHelp key value nRight)


balance : Evergreen.V76.IdDict.NColor -> Int -> v -> Evergreen.V76.IdDict.IdDict k v -> Evergreen.V76.IdDict.IdDict k v -> Evergreen.V76.IdDict.IdDict k v
balance color key value left right =
    case right of
        Evergreen.V76.IdDict.RBNode_elm_builtin Evergreen.V76.IdDict.Red rK rV rLeft rRight ->
            case left of
                Evergreen.V76.IdDict.RBNode_elm_builtin Evergreen.V76.IdDict.Red lK lV lLeft lRight ->
                    Evergreen.V76.IdDict.RBNode_elm_builtin
                        Evergreen.V76.IdDict.Red
                        key
                        value
                        (Evergreen.V76.IdDict.RBNode_elm_builtin Evergreen.V76.IdDict.Black lK lV lLeft lRight)
                        (Evergreen.V76.IdDict.RBNode_elm_builtin Evergreen.V76.IdDict.Black rK rV rLeft rRight)

                _ ->
                    Evergreen.V76.IdDict.RBNode_elm_builtin color rK rV (Evergreen.V76.IdDict.RBNode_elm_builtin Evergreen.V76.IdDict.Red key value left rLeft) rRight

        _ ->
            case left of
                Evergreen.V76.IdDict.RBNode_elm_builtin Evergreen.V76.IdDict.Red lK lV (Evergreen.V76.IdDict.RBNode_elm_builtin Evergreen.V76.IdDict.Red llK llV llLeft llRight) lRight ->
                    Evergreen.V76.IdDict.RBNode_elm_builtin
                        Evergreen.V76.IdDict.Red
                        lK
                        lV
                        (Evergreen.V76.IdDict.RBNode_elm_builtin Evergreen.V76.IdDict.Black llK llV llLeft llRight)
                        (Evergreen.V76.IdDict.RBNode_elm_builtin Evergreen.V76.IdDict.Black key value lRight right)

                _ ->
                    Evergreen.V76.IdDict.RBNode_elm_builtin color key value left right
