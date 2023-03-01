module Evergreen.Migrate.V72 exposing (..)

import AssocList
import AssocSet
import Bitwise
import Dict
import Effect.Time
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
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Quantity exposing (Quantity)
import Random


backendModel : Evergreen.V69.Types.BackendModel -> ModelMigration Evergreen.V72.Types.BackendModel Evergreen.V72.Types.BackendMsg
backendModel old =
    ModelMigrated
        ( migrateBackendModel old
        , Cmd.none
        )


frontendModel : Evergreen.V69.Types.FrontendModel -> ModelMigration Evergreen.V72.Types.FrontendModel Evergreen.V72.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V69.Types.FrontendMsg -> MsgMigration Evergreen.V72.Types.FrontendMsg Evergreen.V72.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V69.Types.BackendMsg -> MsgMigration Evergreen.V72.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V69.Types.BackendError -> Evergreen.V72.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V69.Types.PostmarkError a b ->
            Evergreen.V72.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V69.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V72.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V69.Types.BackendModel -> Evergreen.V72.Types.BackendModel
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
        Evergreen.V72.Change.TrainsEnabled
    , reported = migrateIdDict (List.Nonempty.map migrateBackendReported) old.reported
    , lastReportEmailToAdmin = old.lastReportEmailToAdmin
    }


migrateBackendReported : Evergreen.V69.Change.BackendReport -> Evergreen.V72.Change.BackendReport
migrateBackendReported old =
    { reportedUser = migrateId old.reportedUser
    , position = migrateCoord old.position
    , reportedAt = old.reportedAt
    }


migrateRequestedBy : Evergreen.V69.Types.LoginRequestedBy -> Evergreen.V72.Types.LoginRequestedBy
migrateRequestedBy old =
    case old of
        Evergreen.V69.Types.LoginRequestedByBackend ->
            Evergreen.V72.Types.LoginRequestedByBackend

        Evergreen.V69.Types.LoginRequestedByFrontend sessionId ->
            Evergreen.V72.Types.LoginRequestedByFrontend sessionId


migrateGrid : Evergreen.V69.Grid.Grid -> Evergreen.V72.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V69.Grid.Grid a ->
            Evergreen.V72.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V69.GridCell.Cell -> Evergreen.V72.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V69.GridCell.Cell a ->
            Evergreen.V72.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateIdDict identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V69.GridCell.Value -> Evergreen.V72.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V69.Bounds.Bounds a -> Evergreen.V72.Bounds.Bounds b
migrateBounds (Evergreen.V69.Bounds.Bounds old) =
    Evergreen.V72.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V69.Change.Cow -> Evergreen.V72.Change.Cow
migrateCow old =
    { position = migratePoint2d old.position }


migrateBackendMail : Evergreen.V69.MailEditor.BackendMail -> Evergreen.V72.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V69.MailEditor.MailStatus -> Evergreen.V72.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V69.MailEditor.MailWaitingPickup ->
            Evergreen.V72.MailEditor.MailWaitingPickup

        Evergreen.V69.MailEditor.MailInTransit a ->
            Evergreen.V72.MailEditor.MailInTransit (migrateId a)

        Evergreen.V69.MailEditor.MailReceived a ->
            Evergreen.V72.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V69.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V72.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V69.Types.Invite -> Evergreen.V72.Types.Invite
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


migrateEmailAddress (Evergreen.V69.EmailAddress.EmailAddress old) =
    Evergreen.V72.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V69.Id.SecretId a -> Evergreen.V72.Id.SecretId b
migrateSecretId (Evergreen.V69.Id.SecretId old) =
    Evergreen.V72.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V69.IdDict.IdDict a b -> Evergreen.V72.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V69.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V72.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V69.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V72.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V69.IdDict.NColor -> Evergreen.V72.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V69.IdDict.Red ->
            Evergreen.V72.IdDict.Red

        Evergreen.V69.IdDict.Black ->
            Evergreen.V72.IdDict.Black


migrateBackendUserData : Evergreen.V69.Types.BackendUserData -> Evergreen.V72.Types.BackendUserData
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


migrateEmailResult : Evergreen.V69.Types.EmailResult -> Evergreen.V72.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V69.Types.EmailSending ->
            Evergreen.V72.Types.EmailSending

        Evergreen.V69.Types.EmailSendFailed a ->
            Evergreen.V72.Types.EmailSendFailed a

        Evergreen.V69.Types.EmailSent a ->
            Evergreen.V72.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V69.Postmark.PostmarkSendResponse -> Evergreen.V72.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V69.Tile.Tile -> Evergreen.V72.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V69.Tile.EmptyTile ->
            Evergreen.V72.Tile.EmptyTile

        Evergreen.V69.Tile.HouseDown ->
            Evergreen.V72.Tile.HouseDown

        Evergreen.V69.Tile.HouseRight ->
            Evergreen.V72.Tile.HouseRight

        Evergreen.V69.Tile.HouseUp ->
            Evergreen.V72.Tile.HouseUp

        Evergreen.V69.Tile.HouseLeft ->
            Evergreen.V72.Tile.HouseLeft

        Evergreen.V69.Tile.RailHorizontal ->
            Evergreen.V72.Tile.RailHorizontal

        Evergreen.V69.Tile.RailVertical ->
            Evergreen.V72.Tile.RailVertical

        Evergreen.V69.Tile.RailBottomToRight ->
            Evergreen.V72.Tile.RailBottomToRight

        Evergreen.V69.Tile.RailBottomToLeft ->
            Evergreen.V72.Tile.RailBottomToLeft

        Evergreen.V69.Tile.RailTopToRight ->
            Evergreen.V72.Tile.RailTopToRight

        Evergreen.V69.Tile.RailTopToLeft ->
            Evergreen.V72.Tile.RailTopToLeft

        Evergreen.V69.Tile.RailBottomToRightLarge ->
            Evergreen.V72.Tile.RailBottomToRightLarge

        Evergreen.V69.Tile.RailBottomToLeftLarge ->
            Evergreen.V72.Tile.RailBottomToLeftLarge

        Evergreen.V69.Tile.RailTopToRightLarge ->
            Evergreen.V72.Tile.RailTopToRightLarge

        Evergreen.V69.Tile.RailTopToLeftLarge ->
            Evergreen.V72.Tile.RailTopToLeftLarge

        Evergreen.V69.Tile.RailCrossing ->
            Evergreen.V72.Tile.RailCrossing

        Evergreen.V69.Tile.RailStrafeDown ->
            Evergreen.V72.Tile.RailStrafeDown

        Evergreen.V69.Tile.RailStrafeUp ->
            Evergreen.V72.Tile.RailStrafeUp

        Evergreen.V69.Tile.RailStrafeLeft ->
            Evergreen.V72.Tile.RailStrafeLeft

        Evergreen.V69.Tile.RailStrafeRight ->
            Evergreen.V72.Tile.RailStrafeRight

        Evergreen.V69.Tile.TrainHouseRight ->
            Evergreen.V72.Tile.TrainHouseRight

        Evergreen.V69.Tile.TrainHouseLeft ->
            Evergreen.V72.Tile.TrainHouseLeft

        Evergreen.V69.Tile.RailStrafeDownSmall ->
            Evergreen.V72.Tile.RailStrafeDownSmall

        Evergreen.V69.Tile.RailStrafeUpSmall ->
            Evergreen.V72.Tile.RailStrafeUpSmall

        Evergreen.V69.Tile.RailStrafeLeftSmall ->
            Evergreen.V72.Tile.RailStrafeLeftSmall

        Evergreen.V69.Tile.RailStrafeRightSmall ->
            Evergreen.V72.Tile.RailStrafeRightSmall

        Evergreen.V69.Tile.Sidewalk ->
            Evergreen.V72.Tile.Sidewalk

        Evergreen.V69.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V72.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V69.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V72.Tile.SidewalkVerticalRailCrossing

        Evergreen.V69.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V72.Tile.RailBottomToRight_SplitLeft

        Evergreen.V69.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V72.Tile.RailBottomToLeft_SplitUp

        Evergreen.V69.Tile.RailTopToRight_SplitDown ->
            Evergreen.V72.Tile.RailTopToRight_SplitDown

        Evergreen.V69.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V72.Tile.RailTopToLeft_SplitRight

        Evergreen.V69.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V72.Tile.RailBottomToRight_SplitUp

        Evergreen.V69.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V72.Tile.RailBottomToLeft_SplitRight

        Evergreen.V69.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V72.Tile.RailTopToRight_SplitLeft

        Evergreen.V69.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V72.Tile.RailTopToLeft_SplitDown

        Evergreen.V69.Tile.PostOffice ->
            Evergreen.V72.Tile.PostOffice

        Evergreen.V69.Tile.MowedGrass1 ->
            Evergreen.V72.Tile.MowedGrass1

        Evergreen.V69.Tile.MowedGrass4 ->
            Evergreen.V72.Tile.MowedGrass4

        Evergreen.V69.Tile.LogCabinDown ->
            Evergreen.V72.Tile.LogCabinDown

        Evergreen.V69.Tile.LogCabinRight ->
            Evergreen.V72.Tile.LogCabinRight

        Evergreen.V69.Tile.LogCabinUp ->
            Evergreen.V72.Tile.LogCabinUp

        Evergreen.V69.Tile.LogCabinLeft ->
            Evergreen.V72.Tile.LogCabinLeft

        Evergreen.V69.Tile.RoadHorizontal ->
            Evergreen.V72.Tile.RoadHorizontal

        Evergreen.V69.Tile.RoadVertical ->
            Evergreen.V72.Tile.RoadVertical

        Evergreen.V69.Tile.RoadBottomToLeft ->
            Evergreen.V72.Tile.RoadBottomToLeft

        Evergreen.V69.Tile.RoadTopToLeft ->
            Evergreen.V72.Tile.RoadTopToLeft

        Evergreen.V69.Tile.RoadTopToRight ->
            Evergreen.V72.Tile.RoadTopToRight

        Evergreen.V69.Tile.RoadBottomToRight ->
            Evergreen.V72.Tile.RoadBottomToRight

        Evergreen.V69.Tile.Road4Way ->
            Evergreen.V72.Tile.Road4Way

        Evergreen.V69.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V72.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V69.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V72.Tile.RoadSidewalkCrossingVertical

        Evergreen.V69.Tile.Road3WayDown ->
            Evergreen.V72.Tile.Road3WayDown

        Evergreen.V69.Tile.Road3WayLeft ->
            Evergreen.V72.Tile.Road3WayLeft

        Evergreen.V69.Tile.Road3WayUp ->
            Evergreen.V72.Tile.Road3WayUp

        Evergreen.V69.Tile.Road3WayRight ->
            Evergreen.V72.Tile.Road3WayRight

        Evergreen.V69.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V72.Tile.RoadRailCrossingHorizontal

        Evergreen.V69.Tile.RoadRailCrossingVertical ->
            Evergreen.V72.Tile.RoadRailCrossingVertical

        Evergreen.V69.Tile.FenceHorizontal ->
            Evergreen.V72.Tile.FenceHorizontal

        Evergreen.V69.Tile.FenceVertical ->
            Evergreen.V72.Tile.FenceVertical

        Evergreen.V69.Tile.FenceDiagonal ->
            Evergreen.V72.Tile.FenceDiagonal

        Evergreen.V69.Tile.FenceAntidiagonal ->
            Evergreen.V72.Tile.FenceAntidiagonal

        Evergreen.V69.Tile.RoadDeadendUp ->
            Evergreen.V72.Tile.RoadDeadendUp

        Evergreen.V69.Tile.RoadDeadendDown ->
            Evergreen.V72.Tile.RoadDeadendDown

        Evergreen.V69.Tile.BusStopDown ->
            Evergreen.V72.Tile.BusStopDown

        Evergreen.V69.Tile.BusStopLeft ->
            Evergreen.V72.Tile.BusStopLeft

        Evergreen.V69.Tile.BusStopRight ->
            Evergreen.V72.Tile.BusStopRight

        Evergreen.V69.Tile.BusStopUp ->
            Evergreen.V72.Tile.BusStopUp

        Evergreen.V69.Tile.Hospital ->
            Evergreen.V72.Tile.Hospital

        Evergreen.V69.Tile.Statue ->
            Evergreen.V72.Tile.Statue

        Evergreen.V69.Tile.HedgeRowDown ->
            Evergreen.V72.Tile.HedgeRowDown

        Evergreen.V69.Tile.HedgeRowLeft ->
            Evergreen.V72.Tile.HedgeRowLeft

        Evergreen.V69.Tile.HedgeRowRight ->
            Evergreen.V72.Tile.HedgeRowRight

        Evergreen.V69.Tile.HedgeRowUp ->
            Evergreen.V72.Tile.HedgeRowUp

        Evergreen.V69.Tile.HedgeCornerDownLeft ->
            Evergreen.V72.Tile.HedgeCornerDownLeft

        Evergreen.V69.Tile.HedgeCornerDownRight ->
            Evergreen.V72.Tile.HedgeCornerDownRight

        Evergreen.V69.Tile.HedgeCornerUpLeft ->
            Evergreen.V72.Tile.HedgeCornerUpLeft

        Evergreen.V69.Tile.HedgeCornerUpRight ->
            Evergreen.V72.Tile.HedgeCornerUpRight

        Evergreen.V69.Tile.ApartmentDown ->
            Evergreen.V72.Tile.ApartmentDown

        Evergreen.V69.Tile.ApartmentLeft ->
            Evergreen.V72.Tile.ApartmentLeft

        Evergreen.V69.Tile.ApartmentRight ->
            Evergreen.V72.Tile.ApartmentRight

        Evergreen.V69.Tile.ApartmentUp ->
            Evergreen.V72.Tile.ApartmentUp

        Evergreen.V69.Tile.RockDown ->
            Evergreen.V72.Tile.RockDown

        Evergreen.V69.Tile.RockLeft ->
            Evergreen.V72.Tile.RockLeft

        Evergreen.V69.Tile.RockRight ->
            Evergreen.V72.Tile.RockRight

        Evergreen.V69.Tile.RockUp ->
            Evergreen.V72.Tile.RockUp

        Evergreen.V69.Tile.PineTree1 ->
            Evergreen.V72.Tile.PineTree1

        Evergreen.V69.Tile.PineTree2 ->
            Evergreen.V72.Tile.PineTree2

        Evergreen.V69.Tile.HedgePillarDownLeft ->
            Evergreen.V72.Tile.HedgePillarDownLeft

        Evergreen.V69.Tile.HedgePillarDownRight ->
            Evergreen.V72.Tile.HedgePillarDownRight

        Evergreen.V69.Tile.HedgePillarUpLeft ->
            Evergreen.V72.Tile.HedgePillarUpLeft

        Evergreen.V69.Tile.HedgePillarUpRight ->
            Evergreen.V72.Tile.HedgePillarUpRight

        Evergreen.V69.Tile.Flowers1 ->
            Evergreen.V72.Tile.Flowers1

        Evergreen.V69.Tile.Flowers2 ->
            Evergreen.V72.Tile.Flowers2

        Evergreen.V69.Tile.ElmTree ->
            Evergreen.V72.Tile.ElmTree

        Evergreen.V69.Tile.DirtPathHorizontal ->
            Evergreen.V72.Tile.DirtPathHorizontal

        Evergreen.V69.Tile.DirtPathVertical ->
            Evergreen.V72.Tile.DirtPathVertical

        Evergreen.V69.Tile.BigText char ->
            Evergreen.V72.Tile.BigText char

        Evergreen.V69.Tile.BigPineTree ->
            Evergreen.V72.Tile.BigPineTree

        Evergreen.V69.Tile.Hyperlink ->
            Evergreen.V72.Tile.Hyperlink

        Evergreen.V69.Tile.BenchDown ->
            Evergreen.V72.Tile.BenchDown

        Evergreen.V69.Tile.BenchLeft ->
            Evergreen.V72.Tile.BenchLeft

        Evergreen.V69.Tile.BenchUp ->
            Evergreen.V72.Tile.BenchUp

        Evergreen.V69.Tile.BenchRight ->
            Evergreen.V72.Tile.BenchRight

        Evergreen.V69.Tile.ParkingDown ->
            Evergreen.V72.Tile.ParkingDown

        Evergreen.V69.Tile.ParkingLeft ->
            Evergreen.V72.Tile.ParkingLeft

        Evergreen.V69.Tile.ParkingUp ->
            Evergreen.V72.Tile.ParkingUp

        Evergreen.V69.Tile.ParkingRight ->
            Evergreen.V72.Tile.ParkingRight

        Evergreen.V69.Tile.ParkingRoad ->
            Evergreen.V72.Tile.ParkingRoad

        Evergreen.V69.Tile.ParkingRoundabout ->
            Evergreen.V72.Tile.ParkingRoundabout

        Evergreen.V69.Tile.CornerHouseUpLeft ->
            Evergreen.V72.Tile.CornerHouseUpLeft

        Evergreen.V69.Tile.CornerHouseUpRight ->
            Evergreen.V72.Tile.CornerHouseUpRight

        Evergreen.V69.Tile.CornerHouseDownLeft ->
            Evergreen.V72.Tile.CornerHouseDownLeft

        Evergreen.V69.Tile.CornerHouseDownRight ->
            Evergreen.V72.Tile.CornerHouseDownRight


migrateTrain : Evergreen.V69.Train.Train -> Evergreen.V72.Train.Train
migrateTrain old =
    case old of
        Evergreen.V69.Train.Train a ->
            Evergreen.V72.Train.Train
                { position = migrateCoord a.position
                , path = migrateRailPath a.path
                , previousPaths = migrateList migratePreviousPath a.previousPaths
                , t = identity a.t
                , speed = migrateQuantity a.speed
                , home = migrateCoord a.home
                , homePath = migrateRailPath a.homePath
                , status = migrateStatus a.status
                , owner = migrateId a.owner
                , isStuckOrDerailed =
                    case a.isStuck of
                        Just time ->
                            Evergreen.V72.Train.IsStuck time

                        Nothing ->
                            Evergreen.V72.Train.IsNotStuckOrDerailed
                , color = rgb255 240 100 100
                }


rgb255 : Int -> Int -> Int -> Evergreen.V72.Color.Color
rgb255 red2 green2 blue2 =
    Bitwise.shiftLeftBy 16 (clamp 0 255 red2)
        + Bitwise.shiftLeftBy 8 (clamp 0 255 green2)
        + clamp 0 255 blue2
        |> Evergreen.V72.Color.Color


migrateStatus : Evergreen.V69.Train.Status -> Evergreen.V72.Train.Status
migrateStatus old =
    case old of
        Evergreen.V69.Train.WaitingAtHome ->
            Evergreen.V72.Train.WaitingAtHome

        Evergreen.V69.Train.TeleportingHome a ->
            Evergreen.V72.Train.TeleportingHome (migratePosix a)

        Evergreen.V69.Train.Travelling ->
            Evergreen.V72.Train.Travelling

        Evergreen.V69.Train.StoppedAtPostOffice a ->
            Evergreen.V72.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V69.Tile.RailPath -> Evergreen.V72.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V69.Tile.RailPathHorizontal a ->
            Evergreen.V72.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V69.Tile.RailPathVertical a ->
            Evergreen.V72.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V69.Tile.RailPathBottomToRight ->
            Evergreen.V72.Tile.RailPathBottomToRight

        Evergreen.V69.Tile.RailPathBottomToLeft ->
            Evergreen.V72.Tile.RailPathBottomToLeft

        Evergreen.V69.Tile.RailPathTopToRight ->
            Evergreen.V72.Tile.RailPathTopToRight

        Evergreen.V69.Tile.RailPathTopToLeft ->
            Evergreen.V72.Tile.RailPathTopToLeft

        Evergreen.V69.Tile.RailPathBottomToRightLarge ->
            Evergreen.V72.Tile.RailPathBottomToRightLarge

        Evergreen.V69.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V72.Tile.RailPathBottomToLeftLarge

        Evergreen.V69.Tile.RailPathTopToRightLarge ->
            Evergreen.V72.Tile.RailPathTopToRightLarge

        Evergreen.V69.Tile.RailPathTopToLeftLarge ->
            Evergreen.V72.Tile.RailPathTopToLeftLarge

        Evergreen.V69.Tile.RailPathStrafeDown ->
            Evergreen.V72.Tile.RailPathStrafeDown

        Evergreen.V69.Tile.RailPathStrafeUp ->
            Evergreen.V72.Tile.RailPathStrafeUp

        Evergreen.V69.Tile.RailPathStrafeLeft ->
            Evergreen.V72.Tile.RailPathStrafeLeft

        Evergreen.V69.Tile.RailPathStrafeRight ->
            Evergreen.V72.Tile.RailPathStrafeRight

        Evergreen.V69.Tile.RailPathStrafeDownSmall ->
            Evergreen.V72.Tile.RailPathStrafeDownSmall

        Evergreen.V69.Tile.RailPathStrafeUpSmall ->
            Evergreen.V72.Tile.RailPathStrafeUpSmall

        Evergreen.V69.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V72.Tile.RailPathStrafeLeftSmall

        Evergreen.V69.Tile.RailPathStrafeRightSmall ->
            Evergreen.V72.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V69.Train.PreviousPath -> Evergreen.V72.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V69.MailEditor.Image -> Evergreen.V72.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V69.MailEditor.Stamp a ->
            Evergreen.V72.MailEditor.Stamp (migrateColors a)

        Evergreen.V69.MailEditor.SunglassesEmoji a ->
            Evergreen.V72.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V69.MailEditor.NormalEmoji a ->
            Evergreen.V72.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V69.MailEditor.SadEmoji a ->
            Evergreen.V72.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V69.MailEditor.Cow a ->
            Evergreen.V72.MailEditor.Cow (migrateColors a)

        Evergreen.V69.MailEditor.Man a ->
            Evergreen.V72.MailEditor.Man (migrateColors a)

        Evergreen.V69.MailEditor.TileImage a b c ->
            Evergreen.V72.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V69.MailEditor.Grass ->
            Evergreen.V72.MailEditor.Grass

        Evergreen.V69.MailEditor.DefaultCursor a ->
            Evergreen.V72.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V69.MailEditor.DragCursor a ->
            Evergreen.V72.MailEditor.DragCursor (migrateColors a)

        Evergreen.V69.MailEditor.PinchCursor a ->
            Evergreen.V72.MailEditor.PinchCursor (migrateColors a)

        Evergreen.V69.MailEditor.Line int color ->
            Evergreen.V72.MailEditor.Line int (migrateColor color)


migrateTileGroup : Evergreen.V69.Tile.TileGroup -> Evergreen.V72.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V69.Tile.EmptyTileGroup ->
            Evergreen.V72.Tile.EmptyTileGroup

        Evergreen.V69.Tile.HouseGroup ->
            Evergreen.V72.Tile.HouseGroup

        Evergreen.V69.Tile.RailStraightGroup ->
            Evergreen.V72.Tile.RailStraightGroup

        Evergreen.V69.Tile.RailTurnGroup ->
            Evergreen.V72.Tile.RailTurnGroup

        Evergreen.V69.Tile.RailTurnLargeGroup ->
            Evergreen.V72.Tile.RailTurnLargeGroup

        Evergreen.V69.Tile.RailStrafeGroup ->
            Evergreen.V72.Tile.RailStrafeGroup

        Evergreen.V69.Tile.RailStrafeSmallGroup ->
            Evergreen.V72.Tile.RailStrafeSmallGroup

        Evergreen.V69.Tile.RailCrossingGroup ->
            Evergreen.V72.Tile.RailCrossingGroup

        Evergreen.V69.Tile.TrainHouseGroup ->
            Evergreen.V72.Tile.TrainHouseGroup

        Evergreen.V69.Tile.SidewalkGroup ->
            Evergreen.V72.Tile.SidewalkGroup

        Evergreen.V69.Tile.SidewalkRailGroup ->
            Evergreen.V72.Tile.SidewalkRailGroup

        Evergreen.V69.Tile.RailTurnSplitGroup ->
            Evergreen.V72.Tile.RailTurnSplitGroup

        Evergreen.V69.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V72.Tile.RailTurnSplitMirrorGroup

        Evergreen.V69.Tile.PostOfficeGroup ->
            Evergreen.V72.Tile.PostOfficeGroup

        Evergreen.V69.Tile.PineTreeGroup ->
            Evergreen.V72.Tile.PineTreeGroup

        Evergreen.V69.Tile.LogCabinGroup ->
            Evergreen.V72.Tile.LogCabinGroup

        Evergreen.V69.Tile.RoadStraightGroup ->
            Evergreen.V72.Tile.RoadStraightGroup

        Evergreen.V69.Tile.RoadTurnGroup ->
            Evergreen.V72.Tile.RoadTurnGroup

        Evergreen.V69.Tile.Road4WayGroup ->
            Evergreen.V72.Tile.Road4WayGroup

        Evergreen.V69.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V72.Tile.RoadSidewalkCrossingGroup

        Evergreen.V69.Tile.Road3WayGroup ->
            Evergreen.V72.Tile.Road3WayGroup

        Evergreen.V69.Tile.RoadRailCrossingGroup ->
            Evergreen.V72.Tile.RoadRailCrossingGroup

        Evergreen.V69.Tile.RoadDeadendGroup ->
            Evergreen.V72.Tile.RoadDeadendGroup

        Evergreen.V69.Tile.FenceStraightGroup ->
            Evergreen.V72.Tile.FenceStraightGroup

        Evergreen.V69.Tile.BusStopGroup ->
            Evergreen.V72.Tile.BusStopGroup

        Evergreen.V69.Tile.HospitalGroup ->
            Evergreen.V72.Tile.HospitalGroup

        Evergreen.V69.Tile.StatueGroup ->
            Evergreen.V72.Tile.StatueGroup

        Evergreen.V69.Tile.HedgeRowGroup ->
            Evergreen.V72.Tile.HedgeRowGroup

        Evergreen.V69.Tile.HedgeCornerGroup ->
            Evergreen.V72.Tile.HedgeCornerGroup

        Evergreen.V69.Tile.ApartmentGroup ->
            Evergreen.V72.Tile.ApartmentGroup

        Evergreen.V69.Tile.RockGroup ->
            Evergreen.V72.Tile.RockGroup

        Evergreen.V69.Tile.FlowersGroup ->
            Evergreen.V72.Tile.FlowersGroup

        Evergreen.V69.Tile.HedgePillarGroup ->
            Evergreen.V72.Tile.HedgePillarGroup

        Evergreen.V69.Tile.ElmTreeGroup ->
            Evergreen.V72.Tile.ElmTreeGroup

        Evergreen.V69.Tile.DirtPathGroup ->
            Evergreen.V72.Tile.DirtPathGroup

        Evergreen.V69.Tile.BigTextGroup ->
            Evergreen.V72.Tile.BigTextGroup

        Evergreen.V69.Tile.BigPineTreeGroup ->
            Evergreen.V72.Tile.BigPineTreeGroup

        Evergreen.V69.Tile.HyperlinkGroup ->
            Evergreen.V72.Tile.HyperlinkGroup

        Evergreen.V69.Tile.BenchGroup ->
            Evergreen.V72.Tile.BenchGroup

        Evergreen.V69.Tile.ParkingLotGroup ->
            Evergreen.V72.Tile.ParkingLotGroup

        Evergreen.V69.Tile.ParkingRoadGroup ->
            Evergreen.V72.Tile.ParkingRoadGroup

        Evergreen.V69.Tile.ParkingRoundaboutGroup ->
            Evergreen.V72.Tile.ParkingRoundaboutGroup

        Evergreen.V69.Tile.CornerHouseGroup ->
            Evergreen.V72.Tile.CornerHouseGroup


migrateDisplayName : Evergreen.V69.DisplayName.DisplayName -> Evergreen.V72.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V69.DisplayName.DisplayName a ->
            Evergreen.V72.DisplayName.DisplayName a


migrateCursor : Evergreen.V69.Cursor.Cursor -> Evergreen.V72.Cursor.Cursor
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
        Evergreen.V72.Cursor.HandTool
    }


migrateContent : Evergreen.V69.MailEditor.Content -> Evergreen.V72.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, item = migrateImageOrText old.item }


migrateImageOrText : Evergreen.V69.MailEditor.ImageOrText -> Evergreen.V72.MailEditor.ImageOrText
migrateImageOrText old =
    case old of
        Evergreen.V69.MailEditor.ImageType imageType ->
            migrateImage imageType |> Evergreen.V72.MailEditor.ImageType

        Evergreen.V69.MailEditor.TextType string ->
            Evergreen.V72.MailEditor.TextType string


migrateColors : Evergreen.V69.Color.Colors -> Evergreen.V72.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V69.Color.Color -> Evergreen.V72.Color.Color
migrateColor old =
    case old of
        Evergreen.V69.Color.Color a ->
            Evergreen.V72.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V69.Types.ViewPoint -> Evergreen.V72.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V69.Types.NormalViewPoint a ->
            Evergreen.V72.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V69.Types.TrainViewPoint a ->
            Evergreen.V72.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V69.Geometry.Types.Point2d old) =
    Evergreen.V72.Geometry.Types.Point2d old


migrateId : Evergreen.V69.Id.Id a -> Evergreen.V72.Id.Id b
migrateId (Evergreen.V69.Id.Id old) =
    Evergreen.V72.Id.Id old


migrateDictToIdDict : Dict.Dict Int a -> Evergreen.V72.IdDict.IdDict id a
migrateDictToIdDict dict =
    Dict.toList dict |> List.map (Tuple.mapFirst Evergreen.V72.Id.Id) |> fromList


{-| Convert an association list into a dictionary.
-}
fromList : List ( Evergreen.V72.Id.Id a, v ) -> Evergreen.V72.IdDict.IdDict a v
fromList assocs =
    List.foldl (\( key, value ) dict -> insert key value dict) empty assocs


{-| Create an empty dictionary.
-}
empty : Evergreen.V72.IdDict.IdDict k v
empty =
    Evergreen.V72.IdDict.RBEmpty_elm_builtin


{-| Insert a key-value pair into a dictionary. Replaces value when there is
a collision.
-}
insert : Evergreen.V72.Id.Id a -> v -> Evergreen.V72.IdDict.IdDict a v -> Evergreen.V72.IdDict.IdDict a v
insert key value dict =
    -- Root node is always Black
    case insertHelp key value dict of
        Evergreen.V72.IdDict.RBNode_elm_builtin Evergreen.V72.IdDict.Red k v l r ->
            Evergreen.V72.IdDict.RBNode_elm_builtin Evergreen.V72.IdDict.Black k v l r

        x ->
            x


idToInt (Evergreen.V72.Id.Id id) =
    id


insertHelp : Evergreen.V72.Id.Id a -> v -> Evergreen.V72.IdDict.IdDict a v -> Evergreen.V72.IdDict.IdDict a v
insertHelp key value dict =
    case dict of
        Evergreen.V72.IdDict.RBEmpty_elm_builtin ->
            -- New nodes are always red. If it violates the rules, it will be fixed
            -- when balancing.
            Evergreen.V72.IdDict.RBNode_elm_builtin Evergreen.V72.IdDict.Red (idToInt key) value Evergreen.V72.IdDict.RBEmpty_elm_builtin Evergreen.V72.IdDict.RBEmpty_elm_builtin

        Evergreen.V72.IdDict.RBNode_elm_builtin nColor nKey nValue nLeft nRight ->
            case compare (idToInt key) nKey of
                LT ->
                    balance nColor nKey nValue (insertHelp key value nLeft) nRight

                EQ ->
                    Evergreen.V72.IdDict.RBNode_elm_builtin nColor nKey value nLeft nRight

                GT ->
                    balance nColor nKey nValue nLeft (insertHelp key value nRight)


balance : Evergreen.V72.IdDict.NColor -> Int -> v -> Evergreen.V72.IdDict.IdDict k v -> Evergreen.V72.IdDict.IdDict k v -> Evergreen.V72.IdDict.IdDict k v
balance color key value left right =
    case right of
        Evergreen.V72.IdDict.RBNode_elm_builtin Evergreen.V72.IdDict.Red rK rV rLeft rRight ->
            case left of
                Evergreen.V72.IdDict.RBNode_elm_builtin Evergreen.V72.IdDict.Red lK lV lLeft lRight ->
                    Evergreen.V72.IdDict.RBNode_elm_builtin
                        Evergreen.V72.IdDict.Red
                        key
                        value
                        (Evergreen.V72.IdDict.RBNode_elm_builtin Evergreen.V72.IdDict.Black lK lV lLeft lRight)
                        (Evergreen.V72.IdDict.RBNode_elm_builtin Evergreen.V72.IdDict.Black rK rV rLeft rRight)

                _ ->
                    Evergreen.V72.IdDict.RBNode_elm_builtin color rK rV (Evergreen.V72.IdDict.RBNode_elm_builtin Evergreen.V72.IdDict.Red key value left rLeft) rRight

        _ ->
            case left of
                Evergreen.V72.IdDict.RBNode_elm_builtin Evergreen.V72.IdDict.Red lK lV (Evergreen.V72.IdDict.RBNode_elm_builtin Evergreen.V72.IdDict.Red llK llV llLeft llRight) lRight ->
                    Evergreen.V72.IdDict.RBNode_elm_builtin
                        Evergreen.V72.IdDict.Red
                        lK
                        lV
                        (Evergreen.V72.IdDict.RBNode_elm_builtin Evergreen.V72.IdDict.Black llK llV llLeft llRight)
                        (Evergreen.V72.IdDict.RBNode_elm_builtin Evergreen.V72.IdDict.Black key value lRight right)

                _ ->
                    Evergreen.V72.IdDict.RBNode_elm_builtin color key value left right
