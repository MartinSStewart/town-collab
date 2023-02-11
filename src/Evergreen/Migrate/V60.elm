module Evergreen.Migrate.V60 exposing (..)

import AssocList
import AssocSet
import Dict
import Effect.Time
import Evergreen.V59.Bounds
import Evergreen.V59.Change
import Evergreen.V59.Color
import Evergreen.V59.Cursor
import Evergreen.V59.DisplayName
import Evergreen.V59.EmailAddress
import Evergreen.V59.Geometry.Types
import Evergreen.V59.Grid
import Evergreen.V59.GridCell
import Evergreen.V59.Id
import Evergreen.V59.IdDict
import Evergreen.V59.LocalGrid
import Evergreen.V59.MailEditor
import Evergreen.V59.Postmark
import Evergreen.V59.Tile
import Evergreen.V59.Train
import Evergreen.V59.Types
import Evergreen.V60.Bounds
import Evergreen.V60.Change
import Evergreen.V60.Color
import Evergreen.V60.Coord
import Evergreen.V60.Cursor
import Evergreen.V60.DisplayName
import Evergreen.V60.EmailAddress
import Evergreen.V60.Geometry.Types
import Evergreen.V60.Grid
import Evergreen.V60.GridCell
import Evergreen.V60.Id
import Evergreen.V60.IdDict
import Evergreen.V60.LocalGrid
import Evergreen.V60.MailEditor
import Evergreen.V60.Postmark
import Evergreen.V60.Tile
import Evergreen.V60.Train
import Evergreen.V60.Types
import IdDict
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Process
import Quantity exposing (Quantity)
import Task
import Time


backendModel : Evergreen.V59.Types.BackendModel -> ModelMigration Evergreen.V60.Types.BackendModel Evergreen.V60.Types.BackendMsg
backendModel old =
    ModelMigrated
        ( migrateBackendModel old
        , Cmd.none
        )


frontendModel : Evergreen.V59.Types.FrontendModel -> ModelMigration Evergreen.V60.Types.FrontendModel Evergreen.V60.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V59.Types.FrontendMsg -> MsgMigration Evergreen.V60.Types.FrontendMsg Evergreen.V60.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V59.Types.BackendMsg -> MsgMigration Evergreen.V60.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V59.Types.BackendError -> Evergreen.V60.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V59.Types.PostmarkError a b ->
            Evergreen.V60.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V59.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V60.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V59.Types.BackendModel -> Evergreen.V60.Types.BackendModel
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
    , lastCacheRegeneration = Nothing
    }


migrateRequestedBy : Evergreen.V59.Types.LoginRequestedBy -> Evergreen.V60.Types.LoginRequestedBy
migrateRequestedBy old =
    case old of
        Evergreen.V59.Types.LoginRequestedByBackend ->
            Evergreen.V60.Types.LoginRequestedByBackend

        Evergreen.V59.Types.LoginRequestedByFrontend sessionId ->
            Evergreen.V60.Types.LoginRequestedByFrontend sessionId


migrateGrid : Evergreen.V59.Grid.Grid -> Evergreen.V60.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V59.Grid.Grid a ->
            Evergreen.V60.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V59.GridCell.Cell -> Evergreen.V60.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V59.GridCell.Cell a ->
            Evergreen.V60.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateDict identity identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V59.GridCell.Value -> Evergreen.V60.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V59.Bounds.Bounds a -> Evergreen.V60.Bounds.Bounds b
migrateBounds (Evergreen.V59.Bounds.Bounds old) =
    Evergreen.V60.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V59.Change.Cow -> Evergreen.V60.Change.Cow
migrateCow old =
    { position = migratePoint2d old.position }


migrateBackendMail : Evergreen.V59.MailEditor.BackendMail -> Evergreen.V60.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V59.MailEditor.MailStatus -> Evergreen.V60.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V59.MailEditor.MailWaitingPickup ->
            Evergreen.V60.MailEditor.MailWaitingPickup

        Evergreen.V59.MailEditor.MailInTransit a ->
            Evergreen.V60.MailEditor.MailInTransit (migrateId a)

        Evergreen.V59.MailEditor.MailReceived a ->
            Evergreen.V60.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V59.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V60.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V59.Types.Invite -> Evergreen.V60.Types.Invite
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


migrateEmailAddress (Evergreen.V59.EmailAddress.EmailAddress old) =
    Evergreen.V60.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V59.Id.SecretId a -> Evergreen.V60.Id.SecretId b
migrateSecretId (Evergreen.V59.Id.SecretId old) =
    Evergreen.V60.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V59.IdDict.IdDict a b -> Evergreen.V60.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V59.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V60.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V59.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V60.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V59.IdDict.NColor -> Evergreen.V60.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V59.IdDict.Red ->
            Evergreen.V60.IdDict.Red

        Evergreen.V59.IdDict.Black ->
            Evergreen.V60.IdDict.Black


migrateBackendUserData : Evergreen.V59.Types.BackendUserData -> Evergreen.V60.Types.BackendUserData
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


migrateEmailResult : Evergreen.V59.Types.EmailResult -> Evergreen.V60.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V59.Types.EmailSending ->
            Evergreen.V60.Types.EmailSending

        Evergreen.V59.Types.EmailSendFailed a ->
            Evergreen.V60.Types.EmailSendFailed a

        Evergreen.V59.Types.EmailSent a ->
            Evergreen.V60.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V59.Postmark.PostmarkSendResponse -> Evergreen.V60.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V59.Tile.Tile -> Evergreen.V60.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V59.Tile.EmptyTile ->
            Evergreen.V60.Tile.EmptyTile

        Evergreen.V59.Tile.HouseDown ->
            Evergreen.V60.Tile.HouseDown

        Evergreen.V59.Tile.HouseRight ->
            Evergreen.V60.Tile.HouseRight

        Evergreen.V59.Tile.HouseUp ->
            Evergreen.V60.Tile.HouseUp

        Evergreen.V59.Tile.HouseLeft ->
            Evergreen.V60.Tile.HouseLeft

        Evergreen.V59.Tile.RailHorizontal ->
            Evergreen.V60.Tile.RailHorizontal

        Evergreen.V59.Tile.RailVertical ->
            Evergreen.V60.Tile.RailVertical

        Evergreen.V59.Tile.RailBottomToRight ->
            Evergreen.V60.Tile.RailBottomToRight

        Evergreen.V59.Tile.RailBottomToLeft ->
            Evergreen.V60.Tile.RailBottomToLeft

        Evergreen.V59.Tile.RailTopToRight ->
            Evergreen.V60.Tile.RailTopToRight

        Evergreen.V59.Tile.RailTopToLeft ->
            Evergreen.V60.Tile.RailTopToLeft

        Evergreen.V59.Tile.RailBottomToRightLarge ->
            Evergreen.V60.Tile.RailBottomToRightLarge

        Evergreen.V59.Tile.RailBottomToLeftLarge ->
            Evergreen.V60.Tile.RailBottomToLeftLarge

        Evergreen.V59.Tile.RailTopToRightLarge ->
            Evergreen.V60.Tile.RailTopToRightLarge

        Evergreen.V59.Tile.RailTopToLeftLarge ->
            Evergreen.V60.Tile.RailTopToLeftLarge

        Evergreen.V59.Tile.RailCrossing ->
            Evergreen.V60.Tile.RailCrossing

        Evergreen.V59.Tile.RailStrafeDown ->
            Evergreen.V60.Tile.RailStrafeDown

        Evergreen.V59.Tile.RailStrafeUp ->
            Evergreen.V60.Tile.RailStrafeUp

        Evergreen.V59.Tile.RailStrafeLeft ->
            Evergreen.V60.Tile.RailStrafeLeft

        Evergreen.V59.Tile.RailStrafeRight ->
            Evergreen.V60.Tile.RailStrafeRight

        Evergreen.V59.Tile.TrainHouseRight ->
            Evergreen.V60.Tile.TrainHouseRight

        Evergreen.V59.Tile.TrainHouseLeft ->
            Evergreen.V60.Tile.TrainHouseLeft

        Evergreen.V59.Tile.RailStrafeDownSmall ->
            Evergreen.V60.Tile.RailStrafeDownSmall

        Evergreen.V59.Tile.RailStrafeUpSmall ->
            Evergreen.V60.Tile.RailStrafeUpSmall

        Evergreen.V59.Tile.RailStrafeLeftSmall ->
            Evergreen.V60.Tile.RailStrafeLeftSmall

        Evergreen.V59.Tile.RailStrafeRightSmall ->
            Evergreen.V60.Tile.RailStrafeRightSmall

        Evergreen.V59.Tile.Sidewalk ->
            Evergreen.V60.Tile.Sidewalk

        Evergreen.V59.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V60.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V59.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V60.Tile.SidewalkVerticalRailCrossing

        Evergreen.V59.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V60.Tile.RailBottomToRight_SplitLeft

        Evergreen.V59.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V60.Tile.RailBottomToLeft_SplitUp

        Evergreen.V59.Tile.RailTopToRight_SplitDown ->
            Evergreen.V60.Tile.RailTopToRight_SplitDown

        Evergreen.V59.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V60.Tile.RailTopToLeft_SplitRight

        Evergreen.V59.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V60.Tile.RailBottomToRight_SplitUp

        Evergreen.V59.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V60.Tile.RailBottomToLeft_SplitRight

        Evergreen.V59.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V60.Tile.RailTopToRight_SplitLeft

        Evergreen.V59.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V60.Tile.RailTopToLeft_SplitDown

        Evergreen.V59.Tile.PostOffice ->
            Evergreen.V60.Tile.PostOffice

        Evergreen.V59.Tile.MowedGrass1 ->
            Evergreen.V60.Tile.MowedGrass1

        Evergreen.V59.Tile.MowedGrass4 ->
            Evergreen.V60.Tile.MowedGrass4

        Evergreen.V59.Tile.LogCabinDown ->
            Evergreen.V60.Tile.LogCabinDown

        Evergreen.V59.Tile.LogCabinRight ->
            Evergreen.V60.Tile.LogCabinRight

        Evergreen.V59.Tile.LogCabinUp ->
            Evergreen.V60.Tile.LogCabinUp

        Evergreen.V59.Tile.LogCabinLeft ->
            Evergreen.V60.Tile.LogCabinLeft

        Evergreen.V59.Tile.RoadHorizontal ->
            Evergreen.V60.Tile.RoadHorizontal

        Evergreen.V59.Tile.RoadVertical ->
            Evergreen.V60.Tile.RoadVertical

        Evergreen.V59.Tile.RoadBottomToLeft ->
            Evergreen.V60.Tile.RoadBottomToLeft

        Evergreen.V59.Tile.RoadTopToLeft ->
            Evergreen.V60.Tile.RoadTopToLeft

        Evergreen.V59.Tile.RoadTopToRight ->
            Evergreen.V60.Tile.RoadTopToRight

        Evergreen.V59.Tile.RoadBottomToRight ->
            Evergreen.V60.Tile.RoadBottomToRight

        Evergreen.V59.Tile.Road4Way ->
            Evergreen.V60.Tile.Road4Way

        Evergreen.V59.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V60.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V59.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V60.Tile.RoadSidewalkCrossingVertical

        Evergreen.V59.Tile.Road3WayDown ->
            Evergreen.V60.Tile.Road3WayDown

        Evergreen.V59.Tile.Road3WayLeft ->
            Evergreen.V60.Tile.Road3WayLeft

        Evergreen.V59.Tile.Road3WayUp ->
            Evergreen.V60.Tile.Road3WayUp

        Evergreen.V59.Tile.Road3WayRight ->
            Evergreen.V60.Tile.Road3WayRight

        Evergreen.V59.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V60.Tile.RoadRailCrossingHorizontal

        Evergreen.V59.Tile.RoadRailCrossingVertical ->
            Evergreen.V60.Tile.RoadRailCrossingVertical

        Evergreen.V59.Tile.FenceHorizontal ->
            Evergreen.V60.Tile.FenceHorizontal

        Evergreen.V59.Tile.FenceVertical ->
            Evergreen.V60.Tile.FenceVertical

        Evergreen.V59.Tile.FenceDiagonal ->
            Evergreen.V60.Tile.FenceDiagonal

        Evergreen.V59.Tile.FenceAntidiagonal ->
            Evergreen.V60.Tile.FenceAntidiagonal

        Evergreen.V59.Tile.RoadDeadendUp ->
            Evergreen.V60.Tile.RoadDeadendUp

        Evergreen.V59.Tile.RoadDeadendDown ->
            Evergreen.V60.Tile.RoadDeadendDown

        Evergreen.V59.Tile.BusStopDown ->
            Evergreen.V60.Tile.BusStopDown

        Evergreen.V59.Tile.BusStopLeft ->
            Evergreen.V60.Tile.BusStopLeft

        Evergreen.V59.Tile.BusStopRight ->
            Evergreen.V60.Tile.BusStopRight

        Evergreen.V59.Tile.BusStopUp ->
            Evergreen.V60.Tile.BusStopUp

        Evergreen.V59.Tile.Hospital ->
            Evergreen.V60.Tile.Hospital

        Evergreen.V59.Tile.Statue ->
            Evergreen.V60.Tile.Statue

        Evergreen.V59.Tile.HedgeRowDown ->
            Evergreen.V60.Tile.HedgeRowDown

        Evergreen.V59.Tile.HedgeRowLeft ->
            Evergreen.V60.Tile.HedgeRowLeft

        Evergreen.V59.Tile.HedgeRowRight ->
            Evergreen.V60.Tile.HedgeRowRight

        Evergreen.V59.Tile.HedgeRowUp ->
            Evergreen.V60.Tile.HedgeRowUp

        Evergreen.V59.Tile.HedgeCornerDownLeft ->
            Evergreen.V60.Tile.HedgeCornerDownLeft

        Evergreen.V59.Tile.HedgeCornerDownRight ->
            Evergreen.V60.Tile.HedgeCornerDownRight

        Evergreen.V59.Tile.HedgeCornerUpLeft ->
            Evergreen.V60.Tile.HedgeCornerUpLeft

        Evergreen.V59.Tile.HedgeCornerUpRight ->
            Evergreen.V60.Tile.HedgeCornerUpRight

        Evergreen.V59.Tile.ApartmentDown ->
            Evergreen.V60.Tile.ApartmentDown

        Evergreen.V59.Tile.ApartmentLeft ->
            Evergreen.V60.Tile.ApartmentLeft

        Evergreen.V59.Tile.ApartmentRight ->
            Evergreen.V60.Tile.ApartmentRight

        Evergreen.V59.Tile.ApartmentUp ->
            Evergreen.V60.Tile.ApartmentUp

        Evergreen.V59.Tile.RockDown ->
            Evergreen.V60.Tile.RockDown

        Evergreen.V59.Tile.RockLeft ->
            Evergreen.V60.Tile.RockLeft

        Evergreen.V59.Tile.RockRight ->
            Evergreen.V60.Tile.RockRight

        Evergreen.V59.Tile.RockUp ->
            Evergreen.V60.Tile.RockUp

        Evergreen.V59.Tile.PineTree1 ->
            Evergreen.V60.Tile.PineTree1

        Evergreen.V59.Tile.PineTree2 ->
            Evergreen.V60.Tile.PineTree2

        Evergreen.V59.Tile.HedgePillarDownLeft ->
            Evergreen.V60.Tile.HedgePillarDownLeft

        Evergreen.V59.Tile.HedgePillarDownRight ->
            Evergreen.V60.Tile.HedgePillarDownRight

        Evergreen.V59.Tile.HedgePillarUpLeft ->
            Evergreen.V60.Tile.HedgePillarUpLeft

        Evergreen.V59.Tile.HedgePillarUpRight ->
            Evergreen.V60.Tile.HedgePillarUpRight

        Evergreen.V59.Tile.Flowers1 ->
            Evergreen.V60.Tile.Flowers1

        Evergreen.V59.Tile.Flowers2 ->
            Evergreen.V60.Tile.Flowers2

        Evergreen.V59.Tile.ElmTree ->
            Evergreen.V60.Tile.ElmTree

        Evergreen.V59.Tile.DirtPathHorizontal ->
            Evergreen.V60.Tile.DirtPathHorizontal

        Evergreen.V59.Tile.DirtPathVertical ->
            Evergreen.V60.Tile.DirtPathVertical

        Evergreen.V59.Tile.BigText char ->
            Evergreen.V60.Tile.BigText char

        Evergreen.V59.Tile.BigPineTree ->
            Evergreen.V60.Tile.BigPineTree

        Evergreen.V59.Tile.Hyperlink ->
            Evergreen.V60.Tile.Hyperlink


migrateTrain : Evergreen.V59.Train.Train -> Evergreen.V60.Train.Train
migrateTrain old =
    case old of
        Evergreen.V59.Train.Train a ->
            Evergreen.V60.Train.Train
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


migrateStatus : Evergreen.V59.Train.Status -> Evergreen.V60.Train.Status
migrateStatus old =
    case old of
        Evergreen.V59.Train.WaitingAtHome ->
            Evergreen.V60.Train.WaitingAtHome

        Evergreen.V59.Train.TeleportingHome a ->
            Evergreen.V60.Train.TeleportingHome (migratePosix a)

        Evergreen.V59.Train.Travelling ->
            Evergreen.V60.Train.Travelling

        Evergreen.V59.Train.StoppedAtPostOffice a ->
            Evergreen.V60.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V59.Tile.RailPath -> Evergreen.V60.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V59.Tile.RailPathHorizontal a ->
            Evergreen.V60.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V59.Tile.RailPathVertical a ->
            Evergreen.V60.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V59.Tile.RailPathBottomToRight ->
            Evergreen.V60.Tile.RailPathBottomToRight

        Evergreen.V59.Tile.RailPathBottomToLeft ->
            Evergreen.V60.Tile.RailPathBottomToLeft

        Evergreen.V59.Tile.RailPathTopToRight ->
            Evergreen.V60.Tile.RailPathTopToRight

        Evergreen.V59.Tile.RailPathTopToLeft ->
            Evergreen.V60.Tile.RailPathTopToLeft

        Evergreen.V59.Tile.RailPathBottomToRightLarge ->
            Evergreen.V60.Tile.RailPathBottomToRightLarge

        Evergreen.V59.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V60.Tile.RailPathBottomToLeftLarge

        Evergreen.V59.Tile.RailPathTopToRightLarge ->
            Evergreen.V60.Tile.RailPathTopToRightLarge

        Evergreen.V59.Tile.RailPathTopToLeftLarge ->
            Evergreen.V60.Tile.RailPathTopToLeftLarge

        Evergreen.V59.Tile.RailPathStrafeDown ->
            Evergreen.V60.Tile.RailPathStrafeDown

        Evergreen.V59.Tile.RailPathStrafeUp ->
            Evergreen.V60.Tile.RailPathStrafeUp

        Evergreen.V59.Tile.RailPathStrafeLeft ->
            Evergreen.V60.Tile.RailPathStrafeLeft

        Evergreen.V59.Tile.RailPathStrafeRight ->
            Evergreen.V60.Tile.RailPathStrafeRight

        Evergreen.V59.Tile.RailPathStrafeDownSmall ->
            Evergreen.V60.Tile.RailPathStrafeDownSmall

        Evergreen.V59.Tile.RailPathStrafeUpSmall ->
            Evergreen.V60.Tile.RailPathStrafeUpSmall

        Evergreen.V59.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V60.Tile.RailPathStrafeLeftSmall

        Evergreen.V59.Tile.RailPathStrafeRightSmall ->
            Evergreen.V60.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V59.Train.PreviousPath -> Evergreen.V60.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V59.MailEditor.Image -> Evergreen.V60.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V59.MailEditor.Stamp a ->
            Evergreen.V60.MailEditor.Stamp (migrateColors a)

        Evergreen.V59.MailEditor.SunglassesEmoji a ->
            Evergreen.V60.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V59.MailEditor.NormalEmoji a ->
            Evergreen.V60.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V59.MailEditor.SadEmoji a ->
            Evergreen.V60.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V59.MailEditor.Cow a ->
            Evergreen.V60.MailEditor.Cow (migrateColors a)

        Evergreen.V59.MailEditor.Man a ->
            Evergreen.V60.MailEditor.Man (migrateColors a)

        Evergreen.V59.MailEditor.TileImage a b c ->
            Evergreen.V60.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V59.MailEditor.Grass ->
            Evergreen.V60.MailEditor.Grass

        Evergreen.V59.MailEditor.DefaultCursor a ->
            Evergreen.V60.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V59.MailEditor.DragCursor a ->
            Evergreen.V60.MailEditor.DragCursor (migrateColors a)

        Evergreen.V59.MailEditor.PinchCursor a ->
            Evergreen.V60.MailEditor.PinchCursor (migrateColors a)

        Evergreen.V59.MailEditor.Line int color ->
            Evergreen.V60.MailEditor.Line int (migrateColor color)


migrateTileGroup : Evergreen.V59.Tile.TileGroup -> Evergreen.V60.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V59.Tile.EmptyTileGroup ->
            Evergreen.V60.Tile.EmptyTileGroup

        Evergreen.V59.Tile.HouseGroup ->
            Evergreen.V60.Tile.HouseGroup

        Evergreen.V59.Tile.RailStraightGroup ->
            Evergreen.V60.Tile.RailStraightGroup

        Evergreen.V59.Tile.RailTurnGroup ->
            Evergreen.V60.Tile.RailTurnGroup

        Evergreen.V59.Tile.RailTurnLargeGroup ->
            Evergreen.V60.Tile.RailTurnLargeGroup

        Evergreen.V59.Tile.RailStrafeGroup ->
            Evergreen.V60.Tile.RailStrafeGroup

        Evergreen.V59.Tile.RailStrafeSmallGroup ->
            Evergreen.V60.Tile.RailStrafeSmallGroup

        Evergreen.V59.Tile.RailCrossingGroup ->
            Evergreen.V60.Tile.RailCrossingGroup

        Evergreen.V59.Tile.TrainHouseGroup ->
            Evergreen.V60.Tile.TrainHouseGroup

        Evergreen.V59.Tile.SidewalkGroup ->
            Evergreen.V60.Tile.SidewalkGroup

        Evergreen.V59.Tile.SidewalkRailGroup ->
            Evergreen.V60.Tile.SidewalkRailGroup

        Evergreen.V59.Tile.RailTurnSplitGroup ->
            Evergreen.V60.Tile.RailTurnSplitGroup

        Evergreen.V59.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V60.Tile.RailTurnSplitMirrorGroup

        Evergreen.V59.Tile.PostOfficeGroup ->
            Evergreen.V60.Tile.PostOfficeGroup

        Evergreen.V59.Tile.PineTreeGroup ->
            Evergreen.V60.Tile.PineTreeGroup

        Evergreen.V59.Tile.LogCabinGroup ->
            Evergreen.V60.Tile.LogCabinGroup

        Evergreen.V59.Tile.RoadStraightGroup ->
            Evergreen.V60.Tile.RoadStraightGroup

        Evergreen.V59.Tile.RoadTurnGroup ->
            Evergreen.V60.Tile.RoadTurnGroup

        Evergreen.V59.Tile.Road4WayGroup ->
            Evergreen.V60.Tile.Road4WayGroup

        Evergreen.V59.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V60.Tile.RoadSidewalkCrossingGroup

        Evergreen.V59.Tile.Road3WayGroup ->
            Evergreen.V60.Tile.Road3WayGroup

        Evergreen.V59.Tile.RoadRailCrossingGroup ->
            Evergreen.V60.Tile.RoadRailCrossingGroup

        Evergreen.V59.Tile.RoadDeadendGroup ->
            Evergreen.V60.Tile.RoadDeadendGroup

        Evergreen.V59.Tile.FenceStraightGroup ->
            Evergreen.V60.Tile.FenceStraightGroup

        Evergreen.V59.Tile.BusStopGroup ->
            Evergreen.V60.Tile.BusStopGroup

        Evergreen.V59.Tile.HospitalGroup ->
            Evergreen.V60.Tile.HospitalGroup

        Evergreen.V59.Tile.StatueGroup ->
            Evergreen.V60.Tile.StatueGroup

        Evergreen.V59.Tile.HedgeRowGroup ->
            Evergreen.V60.Tile.HedgeRowGroup

        Evergreen.V59.Tile.HedgeCornerGroup ->
            Evergreen.V60.Tile.HedgeCornerGroup

        Evergreen.V59.Tile.ApartmentGroup ->
            Evergreen.V60.Tile.ApartmentGroup

        Evergreen.V59.Tile.RockGroup ->
            Evergreen.V60.Tile.RockGroup

        Evergreen.V59.Tile.FlowersGroup ->
            Evergreen.V60.Tile.FlowersGroup

        Evergreen.V59.Tile.HedgePillarGroup ->
            Evergreen.V60.Tile.HedgePillarGroup

        Evergreen.V59.Tile.ElmTreeGroup ->
            Evergreen.V60.Tile.ElmTreeGroup

        Evergreen.V59.Tile.DirtPathGroup ->
            Evergreen.V60.Tile.DirtPathGroup

        Evergreen.V59.Tile.BigTextGroup ->
            Evergreen.V60.Tile.BigTextGroup

        Evergreen.V59.Tile.BigPineTreeGroup ->
            Evergreen.V60.Tile.BigPineTreeGroup

        Evergreen.V59.Tile.HyperlinkGroup ->
            Evergreen.V60.Tile.HyperlinkGroup


migrateDisplayName : Evergreen.V59.DisplayName.DisplayName -> Evergreen.V60.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V59.DisplayName.DisplayName a ->
            Evergreen.V60.DisplayName.DisplayName a


migrateCursor : Evergreen.V59.Cursor.Cursor -> Evergreen.V60.Cursor.Cursor
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
        Evergreen.V60.Cursor.HandTool
    }


migrateContent : Evergreen.V59.MailEditor.Content -> Evergreen.V60.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, item = migrateImageOrText old.item }


migrateImageOrText : Evergreen.V59.MailEditor.ImageOrText -> Evergreen.V60.MailEditor.ImageOrText
migrateImageOrText old =
    case old of
        Evergreen.V59.MailEditor.ImageType imageType ->
            migrateImage imageType |> Evergreen.V60.MailEditor.ImageType

        Evergreen.V59.MailEditor.TextType string ->
            Evergreen.V60.MailEditor.TextType string


migrateColors : Evergreen.V59.Color.Colors -> Evergreen.V60.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V59.Color.Color -> Evergreen.V60.Color.Color
migrateColor old =
    case old of
        Evergreen.V59.Color.Color a ->
            Evergreen.V60.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V59.Types.ViewPoint -> Evergreen.V60.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V59.Types.NormalViewPoint a ->
            Evergreen.V60.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V59.Types.TrainViewPoint a ->
            Evergreen.V60.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V59.Geometry.Types.Point2d old) =
    Evergreen.V60.Geometry.Types.Point2d old


migrateId : Evergreen.V59.Id.Id a -> Evergreen.V60.Id.Id b
migrateId (Evergreen.V59.Id.Id old) =
    Evergreen.V60.Id.Id old
