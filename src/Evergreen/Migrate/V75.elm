module Evergreen.Migrate.V75 exposing (..)

import AssocList
import AssocSet
import Bitwise
import Dict
import Effect.Time
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
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Quantity exposing (Quantity)
import Random


backendModel : Evergreen.V74.Types.BackendModel -> ModelMigration Evergreen.V75.Types.BackendModel Evergreen.V75.Types.BackendMsg
backendModel old =
    ModelMigrated
        ( migrateBackendModel old
        , Cmd.none
        )


frontendModel : Evergreen.V74.Types.FrontendModel -> ModelMigration Evergreen.V75.Types.FrontendModel Evergreen.V75.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V74.Types.FrontendMsg -> MsgMigration Evergreen.V75.Types.FrontendMsg Evergreen.V75.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V74.Types.BackendMsg -> MsgMigration Evergreen.V75.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V74.Types.BackendError -> Evergreen.V75.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V74.Types.PostmarkError a b ->
            Evergreen.V75.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V74.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V75.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V74.Types.BackendModel -> Evergreen.V75.Types.BackendModel
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


migrateAreTrainsDisabled : Evergreen.V74.Change.AreTrainsDisabled -> Evergreen.V75.Change.AreTrainsDisabled
migrateAreTrainsDisabled old =
    case old of
        Evergreen.V74.Change.TrainsDisabled ->
            Evergreen.V75.Change.TrainsDisabled

        Evergreen.V74.Change.TrainsEnabled ->
            Evergreen.V75.Change.TrainsEnabled


migrateBackendReported : Evergreen.V74.Change.BackendReport -> Evergreen.V75.Change.BackendReport
migrateBackendReported old =
    { reportedUser = migrateId old.reportedUser
    , position = migrateCoord old.position
    , reportedAt = old.reportedAt
    }


migrateRequestedBy : Evergreen.V74.Types.LoginRequestedBy -> Evergreen.V75.Types.LoginRequestedBy
migrateRequestedBy old =
    case old of
        Evergreen.V74.Types.LoginRequestedByBackend ->
            Evergreen.V75.Types.LoginRequestedByBackend

        Evergreen.V74.Types.LoginRequestedByFrontend sessionId ->
            Evergreen.V75.Types.LoginRequestedByFrontend sessionId


migrateGrid : Evergreen.V74.Grid.Grid -> Evergreen.V75.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V74.Grid.Grid a ->
            Evergreen.V75.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V74.GridCell.Cell -> Evergreen.V75.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V74.GridCell.Cell a ->
            Evergreen.V75.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateIdDict identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V74.GridCell.Value -> Evergreen.V75.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V74.Bounds.Bounds a -> Evergreen.V75.Bounds.Bounds b
migrateBounds (Evergreen.V74.Bounds.Bounds old) =
    Evergreen.V75.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V74.Animal.Animal -> Evergreen.V75.Animal.Animal
migrateCow old =
    { position = migratePoint2d old.position, animalType = migrateAnimalType old.animalType }


migrateAnimalType : Evergreen.V74.Animal.AnimalType -> Evergreen.V75.Animal.AnimalType
migrateAnimalType old =
    case old of
        Evergreen.V74.Animal.Cow ->
            Evergreen.V75.Animal.Cow

        Evergreen.V74.Animal.Hamster ->
            Evergreen.V75.Animal.Hamster

        Evergreen.V74.Animal.Sheep ->
            Evergreen.V75.Animal.Sheep


migrateBackendMail : Evergreen.V74.MailEditor.BackendMail -> Evergreen.V75.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V74.MailEditor.MailStatus -> Evergreen.V75.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V74.MailEditor.MailWaitingPickup ->
            Evergreen.V75.MailEditor.MailWaitingPickup

        Evergreen.V74.MailEditor.MailInTransit a ->
            Evergreen.V75.MailEditor.MailInTransit (migrateId a)

        Evergreen.V74.MailEditor.MailReceived a ->
            Evergreen.V75.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V74.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V75.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V74.Types.Invite -> Evergreen.V75.Types.Invite
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


migrateEmailAddress (Evergreen.V74.EmailAddress.EmailAddress old) =
    Evergreen.V75.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V74.Id.SecretId a -> Evergreen.V75.Id.SecretId b
migrateSecretId (Evergreen.V74.Id.SecretId old) =
    Evergreen.V75.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V74.IdDict.IdDict a b -> Evergreen.V75.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V74.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V75.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V74.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V75.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V74.IdDict.NColor -> Evergreen.V75.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V74.IdDict.Red ->
            Evergreen.V75.IdDict.Red

        Evergreen.V74.IdDict.Black ->
            Evergreen.V75.IdDict.Black


migrateBackendUserData : Evergreen.V74.Types.BackendUserData -> Evergreen.V75.Types.BackendUserData
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


migrateEmailResult : Evergreen.V74.Types.EmailResult -> Evergreen.V75.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V74.Types.EmailSending ->
            Evergreen.V75.Types.EmailSending

        Evergreen.V74.Types.EmailSendFailed a ->
            Evergreen.V75.Types.EmailSendFailed a

        Evergreen.V74.Types.EmailSent a ->
            Evergreen.V75.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V74.Postmark.PostmarkSendResponse -> Evergreen.V75.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V74.Tile.Tile -> Evergreen.V75.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V74.Tile.EmptyTile ->
            Evergreen.V75.Tile.EmptyTile

        Evergreen.V74.Tile.HouseDown ->
            Evergreen.V75.Tile.HouseDown

        Evergreen.V74.Tile.HouseRight ->
            Evergreen.V75.Tile.HouseRight

        Evergreen.V74.Tile.HouseUp ->
            Evergreen.V75.Tile.HouseUp

        Evergreen.V74.Tile.HouseLeft ->
            Evergreen.V75.Tile.HouseLeft

        Evergreen.V74.Tile.RailHorizontal ->
            Evergreen.V75.Tile.RailHorizontal

        Evergreen.V74.Tile.RailVertical ->
            Evergreen.V75.Tile.RailVertical

        Evergreen.V74.Tile.RailBottomToRight ->
            Evergreen.V75.Tile.RailBottomToRight

        Evergreen.V74.Tile.RailBottomToLeft ->
            Evergreen.V75.Tile.RailBottomToLeft

        Evergreen.V74.Tile.RailTopToRight ->
            Evergreen.V75.Tile.RailTopToRight

        Evergreen.V74.Tile.RailTopToLeft ->
            Evergreen.V75.Tile.RailTopToLeft

        Evergreen.V74.Tile.RailBottomToRightLarge ->
            Evergreen.V75.Tile.RailBottomToRightLarge

        Evergreen.V74.Tile.RailBottomToLeftLarge ->
            Evergreen.V75.Tile.RailBottomToLeftLarge

        Evergreen.V74.Tile.RailTopToRightLarge ->
            Evergreen.V75.Tile.RailTopToRightLarge

        Evergreen.V74.Tile.RailTopToLeftLarge ->
            Evergreen.V75.Tile.RailTopToLeftLarge

        Evergreen.V74.Tile.RailCrossing ->
            Evergreen.V75.Tile.RailCrossing

        Evergreen.V74.Tile.RailStrafeDown ->
            Evergreen.V75.Tile.RailStrafeDown

        Evergreen.V74.Tile.RailStrafeUp ->
            Evergreen.V75.Tile.RailStrafeUp

        Evergreen.V74.Tile.RailStrafeLeft ->
            Evergreen.V75.Tile.RailStrafeLeft

        Evergreen.V74.Tile.RailStrafeRight ->
            Evergreen.V75.Tile.RailStrafeRight

        Evergreen.V74.Tile.TrainHouseRight ->
            Evergreen.V75.Tile.TrainHouseRight

        Evergreen.V74.Tile.TrainHouseLeft ->
            Evergreen.V75.Tile.TrainHouseLeft

        Evergreen.V74.Tile.RailStrafeDownSmall ->
            Evergreen.V75.Tile.RailStrafeDownSmall

        Evergreen.V74.Tile.RailStrafeUpSmall ->
            Evergreen.V75.Tile.RailStrafeUpSmall

        Evergreen.V74.Tile.RailStrafeLeftSmall ->
            Evergreen.V75.Tile.RailStrafeLeftSmall

        Evergreen.V74.Tile.RailStrafeRightSmall ->
            Evergreen.V75.Tile.RailStrafeRightSmall

        Evergreen.V74.Tile.Sidewalk ->
            Evergreen.V75.Tile.Sidewalk

        Evergreen.V74.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V75.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V74.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V75.Tile.SidewalkVerticalRailCrossing

        Evergreen.V74.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V75.Tile.RailBottomToRight_SplitLeft

        Evergreen.V74.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V75.Tile.RailBottomToLeft_SplitUp

        Evergreen.V74.Tile.RailTopToRight_SplitDown ->
            Evergreen.V75.Tile.RailTopToRight_SplitDown

        Evergreen.V74.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V75.Tile.RailTopToLeft_SplitRight

        Evergreen.V74.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V75.Tile.RailBottomToRight_SplitUp

        Evergreen.V74.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V75.Tile.RailBottomToLeft_SplitRight

        Evergreen.V74.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V75.Tile.RailTopToRight_SplitLeft

        Evergreen.V74.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V75.Tile.RailTopToLeft_SplitDown

        Evergreen.V74.Tile.PostOffice ->
            Evergreen.V75.Tile.PostOffice

        Evergreen.V74.Tile.MowedGrass1 ->
            Evergreen.V75.Tile.MowedGrass1

        Evergreen.V74.Tile.MowedGrass4 ->
            Evergreen.V75.Tile.MowedGrass4

        Evergreen.V74.Tile.LogCabinDown ->
            Evergreen.V75.Tile.LogCabinDown

        Evergreen.V74.Tile.LogCabinRight ->
            Evergreen.V75.Tile.LogCabinRight

        Evergreen.V74.Tile.LogCabinUp ->
            Evergreen.V75.Tile.LogCabinUp

        Evergreen.V74.Tile.LogCabinLeft ->
            Evergreen.V75.Tile.LogCabinLeft

        Evergreen.V74.Tile.RoadHorizontal ->
            Evergreen.V75.Tile.RoadHorizontal

        Evergreen.V74.Tile.RoadVertical ->
            Evergreen.V75.Tile.RoadVertical

        Evergreen.V74.Tile.RoadBottomToLeft ->
            Evergreen.V75.Tile.RoadBottomToLeft

        Evergreen.V74.Tile.RoadTopToLeft ->
            Evergreen.V75.Tile.RoadTopToLeft

        Evergreen.V74.Tile.RoadTopToRight ->
            Evergreen.V75.Tile.RoadTopToRight

        Evergreen.V74.Tile.RoadBottomToRight ->
            Evergreen.V75.Tile.RoadBottomToRight

        Evergreen.V74.Tile.Road4Way ->
            Evergreen.V75.Tile.Road4Way

        Evergreen.V74.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V75.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V74.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V75.Tile.RoadSidewalkCrossingVertical

        Evergreen.V74.Tile.Road3WayDown ->
            Evergreen.V75.Tile.Road3WayDown

        Evergreen.V74.Tile.Road3WayLeft ->
            Evergreen.V75.Tile.Road3WayLeft

        Evergreen.V74.Tile.Road3WayUp ->
            Evergreen.V75.Tile.Road3WayUp

        Evergreen.V74.Tile.Road3WayRight ->
            Evergreen.V75.Tile.Road3WayRight

        Evergreen.V74.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V75.Tile.RoadRailCrossingHorizontal

        Evergreen.V74.Tile.RoadRailCrossingVertical ->
            Evergreen.V75.Tile.RoadRailCrossingVertical

        Evergreen.V74.Tile.FenceHorizontal ->
            Evergreen.V75.Tile.FenceHorizontal

        Evergreen.V74.Tile.FenceVertical ->
            Evergreen.V75.Tile.FenceVertical

        Evergreen.V74.Tile.FenceDiagonal ->
            Evergreen.V75.Tile.FenceDiagonal

        Evergreen.V74.Tile.FenceAntidiagonal ->
            Evergreen.V75.Tile.FenceAntidiagonal

        Evergreen.V74.Tile.RoadDeadendUp ->
            Evergreen.V75.Tile.RoadDeadendUp

        Evergreen.V74.Tile.RoadDeadendDown ->
            Evergreen.V75.Tile.RoadDeadendDown

        Evergreen.V74.Tile.BusStopDown ->
            Evergreen.V75.Tile.BusStopDown

        Evergreen.V74.Tile.BusStopLeft ->
            Evergreen.V75.Tile.BusStopLeft

        Evergreen.V74.Tile.BusStopRight ->
            Evergreen.V75.Tile.BusStopRight

        Evergreen.V74.Tile.BusStopUp ->
            Evergreen.V75.Tile.BusStopUp

        Evergreen.V74.Tile.Hospital ->
            Evergreen.V75.Tile.Hospital

        Evergreen.V74.Tile.Statue ->
            Evergreen.V75.Tile.Statue

        Evergreen.V74.Tile.HedgeRowDown ->
            Evergreen.V75.Tile.HedgeRowDown

        Evergreen.V74.Tile.HedgeRowLeft ->
            Evergreen.V75.Tile.HedgeRowLeft

        Evergreen.V74.Tile.HedgeRowRight ->
            Evergreen.V75.Tile.HedgeRowRight

        Evergreen.V74.Tile.HedgeRowUp ->
            Evergreen.V75.Tile.HedgeRowUp

        Evergreen.V74.Tile.HedgeCornerDownLeft ->
            Evergreen.V75.Tile.HedgeCornerDownLeft

        Evergreen.V74.Tile.HedgeCornerDownRight ->
            Evergreen.V75.Tile.HedgeCornerDownRight

        Evergreen.V74.Tile.HedgeCornerUpLeft ->
            Evergreen.V75.Tile.HedgeCornerUpLeft

        Evergreen.V74.Tile.HedgeCornerUpRight ->
            Evergreen.V75.Tile.HedgeCornerUpRight

        Evergreen.V74.Tile.ApartmentDown ->
            Evergreen.V75.Tile.ApartmentDown

        Evergreen.V74.Tile.ApartmentLeft ->
            Evergreen.V75.Tile.ApartmentLeft

        Evergreen.V74.Tile.ApartmentRight ->
            Evergreen.V75.Tile.ApartmentRight

        Evergreen.V74.Tile.ApartmentUp ->
            Evergreen.V75.Tile.ApartmentUp

        Evergreen.V74.Tile.RockDown ->
            Evergreen.V75.Tile.RockDown

        Evergreen.V74.Tile.RockLeft ->
            Evergreen.V75.Tile.RockLeft

        Evergreen.V74.Tile.RockRight ->
            Evergreen.V75.Tile.RockRight

        Evergreen.V74.Tile.RockUp ->
            Evergreen.V75.Tile.RockUp

        Evergreen.V74.Tile.PineTree1 ->
            Evergreen.V75.Tile.PineTree1

        Evergreen.V74.Tile.PineTree2 ->
            Evergreen.V75.Tile.PineTree2

        Evergreen.V74.Tile.HedgePillarDownLeft ->
            Evergreen.V75.Tile.HedgePillarDownLeft

        Evergreen.V74.Tile.HedgePillarDownRight ->
            Evergreen.V75.Tile.HedgePillarDownRight

        Evergreen.V74.Tile.HedgePillarUpLeft ->
            Evergreen.V75.Tile.HedgePillarUpLeft

        Evergreen.V74.Tile.HedgePillarUpRight ->
            Evergreen.V75.Tile.HedgePillarUpRight

        Evergreen.V74.Tile.Flowers1 ->
            Evergreen.V75.Tile.Flowers1

        Evergreen.V74.Tile.Flowers2 ->
            Evergreen.V75.Tile.Flowers2

        Evergreen.V74.Tile.ElmTree ->
            Evergreen.V75.Tile.ElmTree

        Evergreen.V74.Tile.DirtPathHorizontal ->
            Evergreen.V75.Tile.DirtPathHorizontal

        Evergreen.V74.Tile.DirtPathVertical ->
            Evergreen.V75.Tile.DirtPathVertical

        Evergreen.V74.Tile.BigText char ->
            Evergreen.V75.Tile.BigText char

        Evergreen.V74.Tile.BigPineTree ->
            Evergreen.V75.Tile.BigPineTree

        Evergreen.V74.Tile.Hyperlink ->
            Evergreen.V75.Tile.Hyperlink

        Evergreen.V74.Tile.BenchDown ->
            Evergreen.V75.Tile.BenchDown

        Evergreen.V74.Tile.BenchLeft ->
            Evergreen.V75.Tile.BenchLeft

        Evergreen.V74.Tile.BenchUp ->
            Evergreen.V75.Tile.BenchUp

        Evergreen.V74.Tile.BenchRight ->
            Evergreen.V75.Tile.BenchRight

        Evergreen.V74.Tile.ParkingDown ->
            Evergreen.V75.Tile.ParkingDown

        Evergreen.V74.Tile.ParkingLeft ->
            Evergreen.V75.Tile.ParkingLeft

        Evergreen.V74.Tile.ParkingUp ->
            Evergreen.V75.Tile.ParkingUp

        Evergreen.V74.Tile.ParkingRight ->
            Evergreen.V75.Tile.ParkingRight

        Evergreen.V74.Tile.ParkingRoad ->
            Evergreen.V75.Tile.ParkingRoad

        Evergreen.V74.Tile.ParkingRoundabout ->
            Evergreen.V75.Tile.ParkingRoundabout

        Evergreen.V74.Tile.CornerHouseUpLeft ->
            Evergreen.V75.Tile.CornerHouseUpLeft

        Evergreen.V74.Tile.CornerHouseUpRight ->
            Evergreen.V75.Tile.CornerHouseUpRight

        Evergreen.V74.Tile.CornerHouseDownLeft ->
            Evergreen.V75.Tile.CornerHouseDownLeft

        Evergreen.V74.Tile.CornerHouseDownRight ->
            Evergreen.V75.Tile.CornerHouseDownRight


migrateTrain : Evergreen.V74.Train.Train -> Evergreen.V75.Train.Train
migrateTrain old =
    case old of
        Evergreen.V74.Train.Train a ->
            Evergreen.V75.Train.Train
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


migrateIsStuckOrDerailed : Evergreen.V74.Train.IsStuckOrDerailed -> Evergreen.V75.Train.IsStuckOrDerailed
migrateIsStuckOrDerailed old =
    case old of
        Evergreen.V74.Train.IsStuck a ->
            Evergreen.V75.Train.IsStuck (migratePosix a)

        Evergreen.V74.Train.IsDerailed a b ->
            Evergreen.V75.Train.IsDerailed (migratePosix a) (migrateId b)

        Evergreen.V74.Train.IsNotStuckOrDerailed ->
            Evergreen.V75.Train.IsNotStuckOrDerailed


rgb255 : Int -> Int -> Int -> Evergreen.V75.Color.Color
rgb255 red2 green2 blue2 =
    Bitwise.shiftLeftBy 16 (clamp 0 255 red2)
        + Bitwise.shiftLeftBy 8 (clamp 0 255 green2)
        + clamp 0 255 blue2
        |> Evergreen.V75.Color.Color


migrateStatus : Evergreen.V74.Train.Status -> Evergreen.V75.Train.Status
migrateStatus old =
    case old of
        Evergreen.V74.Train.WaitingAtHome ->
            Evergreen.V75.Train.WaitingAtHome

        Evergreen.V74.Train.TeleportingHome a ->
            Evergreen.V75.Train.TeleportingHome (migratePosix a)

        Evergreen.V74.Train.Travelling ->
            Evergreen.V75.Train.Travelling

        Evergreen.V74.Train.StoppedAtPostOffice a ->
            Evergreen.V75.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V74.Tile.RailPath -> Evergreen.V75.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V74.Tile.RailPathHorizontal a ->
            Evergreen.V75.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V74.Tile.RailPathVertical a ->
            Evergreen.V75.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V74.Tile.RailPathBottomToRight ->
            Evergreen.V75.Tile.RailPathBottomToRight

        Evergreen.V74.Tile.RailPathBottomToLeft ->
            Evergreen.V75.Tile.RailPathBottomToLeft

        Evergreen.V74.Tile.RailPathTopToRight ->
            Evergreen.V75.Tile.RailPathTopToRight

        Evergreen.V74.Tile.RailPathTopToLeft ->
            Evergreen.V75.Tile.RailPathTopToLeft

        Evergreen.V74.Tile.RailPathBottomToRightLarge ->
            Evergreen.V75.Tile.RailPathBottomToRightLarge

        Evergreen.V74.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V75.Tile.RailPathBottomToLeftLarge

        Evergreen.V74.Tile.RailPathTopToRightLarge ->
            Evergreen.V75.Tile.RailPathTopToRightLarge

        Evergreen.V74.Tile.RailPathTopToLeftLarge ->
            Evergreen.V75.Tile.RailPathTopToLeftLarge

        Evergreen.V74.Tile.RailPathStrafeDown ->
            Evergreen.V75.Tile.RailPathStrafeDown

        Evergreen.V74.Tile.RailPathStrafeUp ->
            Evergreen.V75.Tile.RailPathStrafeUp

        Evergreen.V74.Tile.RailPathStrafeLeft ->
            Evergreen.V75.Tile.RailPathStrafeLeft

        Evergreen.V74.Tile.RailPathStrafeRight ->
            Evergreen.V75.Tile.RailPathStrafeRight

        Evergreen.V74.Tile.RailPathStrafeDownSmall ->
            Evergreen.V75.Tile.RailPathStrafeDownSmall

        Evergreen.V74.Tile.RailPathStrafeUpSmall ->
            Evergreen.V75.Tile.RailPathStrafeUpSmall

        Evergreen.V74.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V75.Tile.RailPathStrafeLeftSmall

        Evergreen.V74.Tile.RailPathStrafeRightSmall ->
            Evergreen.V75.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V74.Train.PreviousPath -> Evergreen.V75.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V74.MailEditor.Image -> Evergreen.V75.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V74.MailEditor.Stamp a ->
            Evergreen.V75.MailEditor.Stamp (migrateColors a)

        Evergreen.V74.MailEditor.SunglassesEmoji a ->
            Evergreen.V75.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V74.MailEditor.NormalEmoji a ->
            Evergreen.V75.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V74.MailEditor.SadEmoji a ->
            Evergreen.V75.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V74.MailEditor.Animal a b ->
            Evergreen.V75.MailEditor.Animal (migrateAnimalType a) (migrateColors b)

        Evergreen.V74.MailEditor.Man a ->
            Evergreen.V75.MailEditor.Man (migrateColors a)

        Evergreen.V74.MailEditor.TileImage a b c ->
            Evergreen.V75.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V74.MailEditor.Grass ->
            Evergreen.V75.MailEditor.Grass

        Evergreen.V74.MailEditor.DefaultCursor a ->
            Evergreen.V75.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V74.MailEditor.DragCursor a ->
            Evergreen.V75.MailEditor.DragCursor (migrateColors a)

        Evergreen.V74.MailEditor.PinchCursor a ->
            Evergreen.V75.MailEditor.PinchCursor (migrateColors a)

        Evergreen.V74.MailEditor.Line int color ->
            Evergreen.V75.MailEditor.Line int (migrateColor color)


migrateTileGroup : Evergreen.V74.Tile.TileGroup -> Evergreen.V75.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V74.Tile.EmptyTileGroup ->
            Evergreen.V75.Tile.EmptyTileGroup

        Evergreen.V74.Tile.HouseGroup ->
            Evergreen.V75.Tile.HouseGroup

        Evergreen.V74.Tile.RailStraightGroup ->
            Evergreen.V75.Tile.RailStraightGroup

        Evergreen.V74.Tile.RailTurnGroup ->
            Evergreen.V75.Tile.RailTurnGroup

        Evergreen.V74.Tile.RailTurnLargeGroup ->
            Evergreen.V75.Tile.RailTurnLargeGroup

        Evergreen.V74.Tile.RailStrafeGroup ->
            Evergreen.V75.Tile.RailStrafeGroup

        Evergreen.V74.Tile.RailStrafeSmallGroup ->
            Evergreen.V75.Tile.RailStrafeSmallGroup

        Evergreen.V74.Tile.RailCrossingGroup ->
            Evergreen.V75.Tile.RailCrossingGroup

        Evergreen.V74.Tile.TrainHouseGroup ->
            Evergreen.V75.Tile.TrainHouseGroup

        Evergreen.V74.Tile.SidewalkGroup ->
            Evergreen.V75.Tile.SidewalkGroup

        Evergreen.V74.Tile.SidewalkRailGroup ->
            Evergreen.V75.Tile.SidewalkRailGroup

        Evergreen.V74.Tile.RailTurnSplitGroup ->
            Evergreen.V75.Tile.RailTurnSplitGroup

        Evergreen.V74.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V75.Tile.RailTurnSplitMirrorGroup

        Evergreen.V74.Tile.PostOfficeGroup ->
            Evergreen.V75.Tile.PostOfficeGroup

        Evergreen.V74.Tile.PineTreeGroup ->
            Evergreen.V75.Tile.PineTreeGroup

        Evergreen.V74.Tile.LogCabinGroup ->
            Evergreen.V75.Tile.LogCabinGroup

        Evergreen.V74.Tile.RoadStraightGroup ->
            Evergreen.V75.Tile.RoadStraightGroup

        Evergreen.V74.Tile.RoadTurnGroup ->
            Evergreen.V75.Tile.RoadTurnGroup

        Evergreen.V74.Tile.Road4WayGroup ->
            Evergreen.V75.Tile.Road4WayGroup

        Evergreen.V74.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V75.Tile.RoadSidewalkCrossingGroup

        Evergreen.V74.Tile.Road3WayGroup ->
            Evergreen.V75.Tile.Road3WayGroup

        Evergreen.V74.Tile.RoadRailCrossingGroup ->
            Evergreen.V75.Tile.RoadRailCrossingGroup

        Evergreen.V74.Tile.RoadDeadendGroup ->
            Evergreen.V75.Tile.RoadDeadendGroup

        Evergreen.V74.Tile.FenceStraightGroup ->
            Evergreen.V75.Tile.FenceStraightGroup

        Evergreen.V74.Tile.BusStopGroup ->
            Evergreen.V75.Tile.BusStopGroup

        Evergreen.V74.Tile.HospitalGroup ->
            Evergreen.V75.Tile.HospitalGroup

        Evergreen.V74.Tile.StatueGroup ->
            Evergreen.V75.Tile.StatueGroup

        Evergreen.V74.Tile.HedgeRowGroup ->
            Evergreen.V75.Tile.HedgeRowGroup

        Evergreen.V74.Tile.HedgeCornerGroup ->
            Evergreen.V75.Tile.HedgeCornerGroup

        Evergreen.V74.Tile.ApartmentGroup ->
            Evergreen.V75.Tile.ApartmentGroup

        Evergreen.V74.Tile.RockGroup ->
            Evergreen.V75.Tile.RockGroup

        Evergreen.V74.Tile.FlowersGroup ->
            Evergreen.V75.Tile.FlowersGroup

        Evergreen.V74.Tile.HedgePillarGroup ->
            Evergreen.V75.Tile.HedgePillarGroup

        Evergreen.V74.Tile.ElmTreeGroup ->
            Evergreen.V75.Tile.ElmTreeGroup

        Evergreen.V74.Tile.DirtPathGroup ->
            Evergreen.V75.Tile.DirtPathGroup

        Evergreen.V74.Tile.BigTextGroup ->
            Evergreen.V75.Tile.BigTextGroup

        Evergreen.V74.Tile.BigPineTreeGroup ->
            Evergreen.V75.Tile.BigPineTreeGroup

        Evergreen.V74.Tile.HyperlinkGroup ->
            Evergreen.V75.Tile.HyperlinkGroup

        Evergreen.V74.Tile.BenchGroup ->
            Evergreen.V75.Tile.BenchGroup

        Evergreen.V74.Tile.ParkingLotGroup ->
            Evergreen.V75.Tile.ParkingLotGroup

        Evergreen.V74.Tile.ParkingRoadGroup ->
            Evergreen.V75.Tile.ParkingRoadGroup

        Evergreen.V74.Tile.ParkingRoundaboutGroup ->
            Evergreen.V75.Tile.ParkingRoundaboutGroup

        Evergreen.V74.Tile.CornerHouseGroup ->
            Evergreen.V75.Tile.CornerHouseGroup


migrateDisplayName : Evergreen.V74.DisplayName.DisplayName -> Evergreen.V75.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V74.DisplayName.DisplayName a ->
            Evergreen.V75.DisplayName.DisplayName a


migrateCursor : Evergreen.V74.Cursor.Cursor -> Evergreen.V75.Cursor.Cursor
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
        Evergreen.V75.Cursor.HandTool
    }


migrateContent : Evergreen.V74.MailEditor.Content -> Evergreen.V75.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, item = migrateImageOrText old.item }


migrateImageOrText : Evergreen.V74.MailEditor.ImageOrText -> Evergreen.V75.MailEditor.ImageOrText
migrateImageOrText old =
    case old of
        Evergreen.V74.MailEditor.ImageType imageType ->
            migrateImage imageType |> Evergreen.V75.MailEditor.ImageType

        Evergreen.V74.MailEditor.TextType string ->
            Evergreen.V75.MailEditor.TextType string


migrateColors : Evergreen.V74.Color.Colors -> Evergreen.V75.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V74.Color.Color -> Evergreen.V75.Color.Color
migrateColor old =
    case old of
        Evergreen.V74.Color.Color a ->
            Evergreen.V75.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V74.Types.ViewPoint -> Evergreen.V75.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V74.Types.NormalViewPoint a ->
            Evergreen.V75.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V74.Types.TrainViewPoint a ->
            Evergreen.V75.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V74.Geometry.Types.Point2d old) =
    Evergreen.V75.Geometry.Types.Point2d old


migrateId : Evergreen.V74.Id.Id a -> Evergreen.V75.Id.Id b
migrateId (Evergreen.V74.Id.Id old) =
    Evergreen.V75.Id.Id old


migrateDictToIdDict : Dict.Dict Int a -> Evergreen.V75.IdDict.IdDict id a
migrateDictToIdDict dict =
    Dict.toList dict |> List.map (Tuple.mapFirst Evergreen.V75.Id.Id) |> fromList


{-| Convert an association list into a dictionary.
-}
fromList : List ( Evergreen.V75.Id.Id a, v ) -> Evergreen.V75.IdDict.IdDict a v
fromList assocs =
    List.foldl (\( key, value ) dict -> insert key value dict) empty assocs


{-| Create an empty dictionary.
-}
empty : Evergreen.V75.IdDict.IdDict k v
empty =
    Evergreen.V75.IdDict.RBEmpty_elm_builtin


{-| Insert a key-value pair into a dictionary. Replaces value when there is
a collision.
-}
insert : Evergreen.V75.Id.Id a -> v -> Evergreen.V75.IdDict.IdDict a v -> Evergreen.V75.IdDict.IdDict a v
insert key value dict =
    -- Root node is always Black
    case insertHelp key value dict of
        Evergreen.V75.IdDict.RBNode_elm_builtin Evergreen.V75.IdDict.Red k v l r ->
            Evergreen.V75.IdDict.RBNode_elm_builtin Evergreen.V75.IdDict.Black k v l r

        x ->
            x


idToInt (Evergreen.V75.Id.Id id) =
    id


insertHelp : Evergreen.V75.Id.Id a -> v -> Evergreen.V75.IdDict.IdDict a v -> Evergreen.V75.IdDict.IdDict a v
insertHelp key value dict =
    case dict of
        Evergreen.V75.IdDict.RBEmpty_elm_builtin ->
            -- New nodes are always red. If it violates the rules, it will be fixed
            -- when balancing.
            Evergreen.V75.IdDict.RBNode_elm_builtin Evergreen.V75.IdDict.Red (idToInt key) value Evergreen.V75.IdDict.RBEmpty_elm_builtin Evergreen.V75.IdDict.RBEmpty_elm_builtin

        Evergreen.V75.IdDict.RBNode_elm_builtin nColor nKey nValue nLeft nRight ->
            case compare (idToInt key) nKey of
                LT ->
                    balance nColor nKey nValue (insertHelp key value nLeft) nRight

                EQ ->
                    Evergreen.V75.IdDict.RBNode_elm_builtin nColor nKey value nLeft nRight

                GT ->
                    balance nColor nKey nValue nLeft (insertHelp key value nRight)


balance : Evergreen.V75.IdDict.NColor -> Int -> v -> Evergreen.V75.IdDict.IdDict k v -> Evergreen.V75.IdDict.IdDict k v -> Evergreen.V75.IdDict.IdDict k v
balance color key value left right =
    case right of
        Evergreen.V75.IdDict.RBNode_elm_builtin Evergreen.V75.IdDict.Red rK rV rLeft rRight ->
            case left of
                Evergreen.V75.IdDict.RBNode_elm_builtin Evergreen.V75.IdDict.Red lK lV lLeft lRight ->
                    Evergreen.V75.IdDict.RBNode_elm_builtin
                        Evergreen.V75.IdDict.Red
                        key
                        value
                        (Evergreen.V75.IdDict.RBNode_elm_builtin Evergreen.V75.IdDict.Black lK lV lLeft lRight)
                        (Evergreen.V75.IdDict.RBNode_elm_builtin Evergreen.V75.IdDict.Black rK rV rLeft rRight)

                _ ->
                    Evergreen.V75.IdDict.RBNode_elm_builtin color rK rV (Evergreen.V75.IdDict.RBNode_elm_builtin Evergreen.V75.IdDict.Red key value left rLeft) rRight

        _ ->
            case left of
                Evergreen.V75.IdDict.RBNode_elm_builtin Evergreen.V75.IdDict.Red lK lV (Evergreen.V75.IdDict.RBNode_elm_builtin Evergreen.V75.IdDict.Red llK llV llLeft llRight) lRight ->
                    Evergreen.V75.IdDict.RBNode_elm_builtin
                        Evergreen.V75.IdDict.Red
                        lK
                        lV
                        (Evergreen.V75.IdDict.RBNode_elm_builtin Evergreen.V75.IdDict.Black llK llV llLeft llRight)
                        (Evergreen.V75.IdDict.RBNode_elm_builtin Evergreen.V75.IdDict.Black key value lRight right)

                _ ->
                    Evergreen.V75.IdDict.RBNode_elm_builtin color key value left right
