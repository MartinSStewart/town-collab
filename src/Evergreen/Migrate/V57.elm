module Evergreen.Migrate.V57 exposing (..)

import AssocList
import AssocSet
import Dict
import Effect.Time
import Evergreen.V56.Bounds
import Evergreen.V56.Change
import Evergreen.V56.Color
import Evergreen.V56.DisplayName
import Evergreen.V56.EmailAddress
import Evergreen.V56.Geometry.Types
import Evergreen.V56.Grid
import Evergreen.V56.GridCell
import Evergreen.V56.Id
import Evergreen.V56.IdDict
import Evergreen.V56.LocalGrid
import Evergreen.V56.MailEditor
import Evergreen.V56.Postmark
import Evergreen.V56.Tile
import Evergreen.V56.Train
import Evergreen.V56.Types
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
import IdDict
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Quantity


backendModel : Evergreen.V56.Types.BackendModel -> ModelMigration Evergreen.V57.Types.BackendModel Evergreen.V57.Types.BackendMsg
backendModel old =
    ModelMigrated ( migrateBackendModel old, Cmd.none )


frontendModel : Evergreen.V56.Types.FrontendModel -> ModelMigration Evergreen.V57.Types.FrontendModel Evergreen.V57.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V56.Types.FrontendMsg -> MsgMigration Evergreen.V57.Types.FrontendMsg Evergreen.V57.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V56.Types.BackendMsg -> MsgMigration Evergreen.V57.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V56.Types.BackendError -> Evergreen.V57.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V56.Types.PostmarkError a b ->
            Evergreen.V57.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V56.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V57.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V56.Types.BackendModel -> Evergreen.V57.Types.BackendModel
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


migrateRequestedBy : Evergreen.V56.Types.LoginRequestedBy -> Evergreen.V57.Types.LoginRequestedBy
migrateRequestedBy old =
    case old of
        Evergreen.V56.Types.LoginRequestedByBackend ->
            Evergreen.V57.Types.LoginRequestedByBackend

        Evergreen.V56.Types.LoginRequestedByFrontend sessionId ->
            Evergreen.V57.Types.LoginRequestedByFrontend sessionId


migrateGrid : Evergreen.V56.Grid.Grid -> Evergreen.V57.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V56.Grid.Grid a ->
            Evergreen.V57.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V56.GridCell.Cell -> Evergreen.V57.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V56.GridCell.Cell a ->
            Evergreen.V57.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateDict identity identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V56.GridCell.Value -> Evergreen.V57.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V56.Bounds.Bounds a -> Evergreen.V57.Bounds.Bounds b
migrateBounds (Evergreen.V56.Bounds.Bounds old) =
    Evergreen.V57.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V56.Change.Cow -> Evergreen.V57.Change.Cow
migrateCow old =
    { position = migratePoint2d old.position }


migrateBackendMail : Evergreen.V56.MailEditor.BackendMail -> Evergreen.V57.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V56.MailEditor.MailStatus -> Evergreen.V57.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V56.MailEditor.MailWaitingPickup ->
            Evergreen.V57.MailEditor.MailWaitingPickup

        Evergreen.V56.MailEditor.MailInTransit a ->
            Evergreen.V57.MailEditor.MailInTransit (migrateId a)

        Evergreen.V56.MailEditor.MailReceived a ->
            Evergreen.V57.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V56.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V57.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V56.Types.Invite -> Evergreen.V57.Types.Invite
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


migrateEmailAddress (Evergreen.V56.EmailAddress.EmailAddress old) =
    Evergreen.V57.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V56.Id.SecretId a -> Evergreen.V57.Id.SecretId b
migrateSecretId (Evergreen.V56.Id.SecretId old) =
    Evergreen.V57.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V56.IdDict.IdDict a b -> Evergreen.V57.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V56.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V57.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V56.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V57.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V56.IdDict.NColor -> Evergreen.V57.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V56.IdDict.Red ->
            Evergreen.V57.IdDict.Red

        Evergreen.V56.IdDict.Black ->
            Evergreen.V57.IdDict.Black


migrateBackendUserData : Evergreen.V56.Types.BackendUserData -> Evergreen.V57.Types.BackendUserData
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


migrateEmailResult : Evergreen.V56.Types.EmailResult -> Evergreen.V57.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V56.Types.EmailSending ->
            Evergreen.V57.Types.EmailSending

        Evergreen.V56.Types.EmailSendFailed a ->
            Evergreen.V57.Types.EmailSendFailed a

        Evergreen.V56.Types.EmailSent a ->
            Evergreen.V57.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V56.Postmark.PostmarkSendResponse -> Evergreen.V57.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V56.Tile.Tile -> Evergreen.V57.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V56.Tile.EmptyTile ->
            Evergreen.V57.Tile.EmptyTile

        Evergreen.V56.Tile.HouseDown ->
            Evergreen.V57.Tile.HouseDown

        Evergreen.V56.Tile.HouseRight ->
            Evergreen.V57.Tile.HouseRight

        Evergreen.V56.Tile.HouseUp ->
            Evergreen.V57.Tile.HouseUp

        Evergreen.V56.Tile.HouseLeft ->
            Evergreen.V57.Tile.HouseLeft

        Evergreen.V56.Tile.RailHorizontal ->
            Evergreen.V57.Tile.RailHorizontal

        Evergreen.V56.Tile.RailVertical ->
            Evergreen.V57.Tile.RailVertical

        Evergreen.V56.Tile.RailBottomToRight ->
            Evergreen.V57.Tile.RailBottomToRight

        Evergreen.V56.Tile.RailBottomToLeft ->
            Evergreen.V57.Tile.RailBottomToLeft

        Evergreen.V56.Tile.RailTopToRight ->
            Evergreen.V57.Tile.RailTopToRight

        Evergreen.V56.Tile.RailTopToLeft ->
            Evergreen.V57.Tile.RailTopToLeft

        Evergreen.V56.Tile.RailBottomToRightLarge ->
            Evergreen.V57.Tile.RailBottomToRightLarge

        Evergreen.V56.Tile.RailBottomToLeftLarge ->
            Evergreen.V57.Tile.RailBottomToLeftLarge

        Evergreen.V56.Tile.RailTopToRightLarge ->
            Evergreen.V57.Tile.RailTopToRightLarge

        Evergreen.V56.Tile.RailTopToLeftLarge ->
            Evergreen.V57.Tile.RailTopToLeftLarge

        Evergreen.V56.Tile.RailCrossing ->
            Evergreen.V57.Tile.RailCrossing

        Evergreen.V56.Tile.RailStrafeDown ->
            Evergreen.V57.Tile.RailStrafeDown

        Evergreen.V56.Tile.RailStrafeUp ->
            Evergreen.V57.Tile.RailStrafeUp

        Evergreen.V56.Tile.RailStrafeLeft ->
            Evergreen.V57.Tile.RailStrafeLeft

        Evergreen.V56.Tile.RailStrafeRight ->
            Evergreen.V57.Tile.RailStrafeRight

        Evergreen.V56.Tile.TrainHouseRight ->
            Evergreen.V57.Tile.TrainHouseRight

        Evergreen.V56.Tile.TrainHouseLeft ->
            Evergreen.V57.Tile.TrainHouseLeft

        Evergreen.V56.Tile.RailStrafeDownSmall ->
            Evergreen.V57.Tile.RailStrafeDownSmall

        Evergreen.V56.Tile.RailStrafeUpSmall ->
            Evergreen.V57.Tile.RailStrafeUpSmall

        Evergreen.V56.Tile.RailStrafeLeftSmall ->
            Evergreen.V57.Tile.RailStrafeLeftSmall

        Evergreen.V56.Tile.RailStrafeRightSmall ->
            Evergreen.V57.Tile.RailStrafeRightSmall

        Evergreen.V56.Tile.Sidewalk ->
            Evergreen.V57.Tile.Sidewalk

        Evergreen.V56.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V57.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V56.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V57.Tile.SidewalkVerticalRailCrossing

        Evergreen.V56.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V57.Tile.RailBottomToRight_SplitLeft

        Evergreen.V56.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V57.Tile.RailBottomToLeft_SplitUp

        Evergreen.V56.Tile.RailTopToRight_SplitDown ->
            Evergreen.V57.Tile.RailTopToRight_SplitDown

        Evergreen.V56.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V57.Tile.RailTopToLeft_SplitRight

        Evergreen.V56.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V57.Tile.RailBottomToRight_SplitUp

        Evergreen.V56.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V57.Tile.RailBottomToLeft_SplitRight

        Evergreen.V56.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V57.Tile.RailTopToRight_SplitLeft

        Evergreen.V56.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V57.Tile.RailTopToLeft_SplitDown

        Evergreen.V56.Tile.PostOffice ->
            Evergreen.V57.Tile.PostOffice

        Evergreen.V56.Tile.MowedGrass1 ->
            Evergreen.V57.Tile.MowedGrass1

        Evergreen.V56.Tile.MowedGrass4 ->
            Evergreen.V57.Tile.MowedGrass4

        Evergreen.V56.Tile.LogCabinDown ->
            Evergreen.V57.Tile.LogCabinDown

        Evergreen.V56.Tile.LogCabinRight ->
            Evergreen.V57.Tile.LogCabinRight

        Evergreen.V56.Tile.LogCabinUp ->
            Evergreen.V57.Tile.LogCabinUp

        Evergreen.V56.Tile.LogCabinLeft ->
            Evergreen.V57.Tile.LogCabinLeft

        Evergreen.V56.Tile.RoadHorizontal ->
            Evergreen.V57.Tile.RoadHorizontal

        Evergreen.V56.Tile.RoadVertical ->
            Evergreen.V57.Tile.RoadVertical

        Evergreen.V56.Tile.RoadBottomToLeft ->
            Evergreen.V57.Tile.RoadBottomToLeft

        Evergreen.V56.Tile.RoadTopToLeft ->
            Evergreen.V57.Tile.RoadTopToLeft

        Evergreen.V56.Tile.RoadTopToRight ->
            Evergreen.V57.Tile.RoadTopToRight

        Evergreen.V56.Tile.RoadBottomToRight ->
            Evergreen.V57.Tile.RoadBottomToRight

        Evergreen.V56.Tile.Road4Way ->
            Evergreen.V57.Tile.Road4Way

        Evergreen.V56.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V57.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V56.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V57.Tile.RoadSidewalkCrossingVertical

        Evergreen.V56.Tile.Road3WayDown ->
            Evergreen.V57.Tile.Road3WayDown

        Evergreen.V56.Tile.Road3WayLeft ->
            Evergreen.V57.Tile.Road3WayLeft

        Evergreen.V56.Tile.Road3WayUp ->
            Evergreen.V57.Tile.Road3WayUp

        Evergreen.V56.Tile.Road3WayRight ->
            Evergreen.V57.Tile.Road3WayRight

        Evergreen.V56.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V57.Tile.RoadRailCrossingHorizontal

        Evergreen.V56.Tile.RoadRailCrossingVertical ->
            Evergreen.V57.Tile.RoadRailCrossingVertical

        Evergreen.V56.Tile.FenceHorizontal ->
            Evergreen.V57.Tile.FenceHorizontal

        Evergreen.V56.Tile.FenceVertical ->
            Evergreen.V57.Tile.FenceVertical

        Evergreen.V56.Tile.FenceDiagonal ->
            Evergreen.V57.Tile.FenceDiagonal

        Evergreen.V56.Tile.FenceAntidiagonal ->
            Evergreen.V57.Tile.FenceAntidiagonal

        Evergreen.V56.Tile.RoadDeadendUp ->
            Evergreen.V57.Tile.RoadDeadendUp

        Evergreen.V56.Tile.RoadDeadendDown ->
            Evergreen.V57.Tile.RoadDeadendDown

        Evergreen.V56.Tile.BusStopDown ->
            Evergreen.V57.Tile.BusStopDown

        Evergreen.V56.Tile.BusStopLeft ->
            Evergreen.V57.Tile.BusStopLeft

        Evergreen.V56.Tile.BusStopRight ->
            Evergreen.V57.Tile.BusStopRight

        Evergreen.V56.Tile.BusStopUp ->
            Evergreen.V57.Tile.BusStopUp

        Evergreen.V56.Tile.Hospital ->
            Evergreen.V57.Tile.Hospital

        Evergreen.V56.Tile.Statue ->
            Evergreen.V57.Tile.Statue

        Evergreen.V56.Tile.HedgeRowDown ->
            Evergreen.V57.Tile.HedgeRowDown

        Evergreen.V56.Tile.HedgeRowLeft ->
            Evergreen.V57.Tile.HedgeRowLeft

        Evergreen.V56.Tile.HedgeRowRight ->
            Evergreen.V57.Tile.HedgeRowRight

        Evergreen.V56.Tile.HedgeRowUp ->
            Evergreen.V57.Tile.HedgeRowUp

        Evergreen.V56.Tile.HedgeCornerDownLeft ->
            Evergreen.V57.Tile.HedgeCornerDownLeft

        Evergreen.V56.Tile.HedgeCornerDownRight ->
            Evergreen.V57.Tile.HedgeCornerDownRight

        Evergreen.V56.Tile.HedgeCornerUpLeft ->
            Evergreen.V57.Tile.HedgeCornerUpLeft

        Evergreen.V56.Tile.HedgeCornerUpRight ->
            Evergreen.V57.Tile.HedgeCornerUpRight

        Evergreen.V56.Tile.ApartmentDown ->
            Evergreen.V57.Tile.ApartmentDown

        Evergreen.V56.Tile.ApartmentLeft ->
            Evergreen.V57.Tile.ApartmentLeft

        Evergreen.V56.Tile.ApartmentRight ->
            Evergreen.V57.Tile.ApartmentRight

        Evergreen.V56.Tile.ApartmentUp ->
            Evergreen.V57.Tile.ApartmentUp

        Evergreen.V56.Tile.RockDown ->
            Evergreen.V57.Tile.RockDown

        Evergreen.V56.Tile.RockLeft ->
            Evergreen.V57.Tile.RockLeft

        Evergreen.V56.Tile.RockRight ->
            Evergreen.V57.Tile.RockRight

        Evergreen.V56.Tile.RockUp ->
            Evergreen.V57.Tile.RockUp

        Evergreen.V56.Tile.PineTree1 ->
            Evergreen.V57.Tile.PineTree1

        Evergreen.V56.Tile.PineTree2 ->
            Evergreen.V57.Tile.PineTree2

        Evergreen.V56.Tile.HedgePillarDownLeft ->
            Evergreen.V57.Tile.HedgePillarDownLeft

        Evergreen.V56.Tile.HedgePillarDownRight ->
            Evergreen.V57.Tile.HedgePillarDownRight

        Evergreen.V56.Tile.HedgePillarUpLeft ->
            Evergreen.V57.Tile.HedgePillarUpLeft

        Evergreen.V56.Tile.HedgePillarUpRight ->
            Evergreen.V57.Tile.HedgePillarUpRight

        Evergreen.V56.Tile.Flowers1 ->
            Evergreen.V57.Tile.Flowers1

        Evergreen.V56.Tile.Flowers2 ->
            Evergreen.V57.Tile.Flowers2

        Evergreen.V56.Tile.ElmTree ->
            Evergreen.V57.Tile.ElmTree

        Evergreen.V56.Tile.DirtPathHorizontal ->
            Evergreen.V57.Tile.DirtPathHorizontal

        Evergreen.V56.Tile.DirtPathVertical ->
            Evergreen.V57.Tile.DirtPathVertical


migrateTrain : Evergreen.V56.Train.Train -> Evergreen.V57.Train.Train
migrateTrain old =
    case old of
        Evergreen.V56.Train.Train a ->
            Evergreen.V57.Train.Train
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


migrateStatus : Evergreen.V56.Train.Status -> Evergreen.V57.Train.Status
migrateStatus old =
    case old of
        Evergreen.V56.Train.WaitingAtHome ->
            Evergreen.V57.Train.WaitingAtHome

        Evergreen.V56.Train.TeleportingHome a ->
            Evergreen.V57.Train.TeleportingHome (migratePosix a)

        Evergreen.V56.Train.Travelling ->
            Evergreen.V57.Train.Travelling

        Evergreen.V56.Train.StoppedAtPostOffice a ->
            Evergreen.V57.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V56.Tile.RailPath -> Evergreen.V57.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V56.Tile.RailPathHorizontal a ->
            Evergreen.V57.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V56.Tile.RailPathVertical a ->
            Evergreen.V57.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V56.Tile.RailPathBottomToRight ->
            Evergreen.V57.Tile.RailPathBottomToRight

        Evergreen.V56.Tile.RailPathBottomToLeft ->
            Evergreen.V57.Tile.RailPathBottomToLeft

        Evergreen.V56.Tile.RailPathTopToRight ->
            Evergreen.V57.Tile.RailPathTopToRight

        Evergreen.V56.Tile.RailPathTopToLeft ->
            Evergreen.V57.Tile.RailPathTopToLeft

        Evergreen.V56.Tile.RailPathBottomToRightLarge ->
            Evergreen.V57.Tile.RailPathBottomToRightLarge

        Evergreen.V56.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V57.Tile.RailPathBottomToLeftLarge

        Evergreen.V56.Tile.RailPathTopToRightLarge ->
            Evergreen.V57.Tile.RailPathTopToRightLarge

        Evergreen.V56.Tile.RailPathTopToLeftLarge ->
            Evergreen.V57.Tile.RailPathTopToLeftLarge

        Evergreen.V56.Tile.RailPathStrafeDown ->
            Evergreen.V57.Tile.RailPathStrafeDown

        Evergreen.V56.Tile.RailPathStrafeUp ->
            Evergreen.V57.Tile.RailPathStrafeUp

        Evergreen.V56.Tile.RailPathStrafeLeft ->
            Evergreen.V57.Tile.RailPathStrafeLeft

        Evergreen.V56.Tile.RailPathStrafeRight ->
            Evergreen.V57.Tile.RailPathStrafeRight

        Evergreen.V56.Tile.RailPathStrafeDownSmall ->
            Evergreen.V57.Tile.RailPathStrafeDownSmall

        Evergreen.V56.Tile.RailPathStrafeUpSmall ->
            Evergreen.V57.Tile.RailPathStrafeUpSmall

        Evergreen.V56.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V57.Tile.RailPathStrafeLeftSmall

        Evergreen.V56.Tile.RailPathStrafeRightSmall ->
            Evergreen.V57.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V56.Train.PreviousPath -> Evergreen.V57.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V56.MailEditor.Image -> Evergreen.V57.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V56.MailEditor.Stamp a ->
            Evergreen.V57.MailEditor.Stamp (migrateColors a)

        Evergreen.V56.MailEditor.SunglassesEmoji a ->
            Evergreen.V57.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V56.MailEditor.NormalEmoji a ->
            Evergreen.V57.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V56.MailEditor.SadEmoji a ->
            Evergreen.V57.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V56.MailEditor.Cow a ->
            Evergreen.V57.MailEditor.Cow (migrateColors a)

        Evergreen.V56.MailEditor.Man a ->
            Evergreen.V57.MailEditor.Man (migrateColors a)

        Evergreen.V56.MailEditor.TileImage a b c ->
            Evergreen.V57.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V56.MailEditor.Grass ->
            Evergreen.V57.MailEditor.Grass

        Evergreen.V56.MailEditor.DefaultCursor a ->
            Evergreen.V57.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V56.MailEditor.DragCursor a ->
            Evergreen.V57.MailEditor.DragCursor (migrateColors a)

        Evergreen.V56.MailEditor.PinchCursor a ->
            Evergreen.V57.MailEditor.PinchCursor (migrateColors a)

        Evergreen.V56.MailEditor.Line int color ->
            Evergreen.V57.MailEditor.Line int (migrateColor color)


migrateTileGroup : Evergreen.V56.Tile.TileGroup -> Evergreen.V57.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V56.Tile.EmptyTileGroup ->
            Evergreen.V57.Tile.EmptyTileGroup

        Evergreen.V56.Tile.HouseGroup ->
            Evergreen.V57.Tile.HouseGroup

        Evergreen.V56.Tile.RailStraightGroup ->
            Evergreen.V57.Tile.RailStraightGroup

        Evergreen.V56.Tile.RailTurnGroup ->
            Evergreen.V57.Tile.RailTurnGroup

        Evergreen.V56.Tile.RailTurnLargeGroup ->
            Evergreen.V57.Tile.RailTurnLargeGroup

        Evergreen.V56.Tile.RailStrafeGroup ->
            Evergreen.V57.Tile.RailStrafeGroup

        Evergreen.V56.Tile.RailStrafeSmallGroup ->
            Evergreen.V57.Tile.RailStrafeSmallGroup

        Evergreen.V56.Tile.RailCrossingGroup ->
            Evergreen.V57.Tile.RailCrossingGroup

        Evergreen.V56.Tile.TrainHouseGroup ->
            Evergreen.V57.Tile.TrainHouseGroup

        Evergreen.V56.Tile.SidewalkGroup ->
            Evergreen.V57.Tile.SidewalkGroup

        Evergreen.V56.Tile.SidewalkRailGroup ->
            Evergreen.V57.Tile.SidewalkRailGroup

        Evergreen.V56.Tile.RailTurnSplitGroup ->
            Evergreen.V57.Tile.RailTurnSplitGroup

        Evergreen.V56.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V57.Tile.RailTurnSplitMirrorGroup

        Evergreen.V56.Tile.PostOfficeGroup ->
            Evergreen.V57.Tile.PostOfficeGroup

        Evergreen.V56.Tile.PineTreeGroup ->
            Evergreen.V57.Tile.PineTreeGroup

        Evergreen.V56.Tile.LogCabinGroup ->
            Evergreen.V57.Tile.LogCabinGroup

        Evergreen.V56.Tile.RoadStraightGroup ->
            Evergreen.V57.Tile.RoadStraightGroup

        Evergreen.V56.Tile.RoadTurnGroup ->
            Evergreen.V57.Tile.RoadTurnGroup

        Evergreen.V56.Tile.Road4WayGroup ->
            Evergreen.V57.Tile.Road4WayGroup

        Evergreen.V56.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V57.Tile.RoadSidewalkCrossingGroup

        Evergreen.V56.Tile.Road3WayGroup ->
            Evergreen.V57.Tile.Road3WayGroup

        Evergreen.V56.Tile.RoadRailCrossingGroup ->
            Evergreen.V57.Tile.RoadRailCrossingGroup

        Evergreen.V56.Tile.RoadDeadendGroup ->
            Evergreen.V57.Tile.RoadDeadendGroup

        Evergreen.V56.Tile.FenceStraightGroup ->
            Evergreen.V57.Tile.FenceStraightGroup

        Evergreen.V56.Tile.BusStopGroup ->
            Evergreen.V57.Tile.BusStopGroup

        Evergreen.V56.Tile.HospitalGroup ->
            Evergreen.V57.Tile.HospitalGroup

        Evergreen.V56.Tile.StatueGroup ->
            Evergreen.V57.Tile.StatueGroup

        Evergreen.V56.Tile.HedgeRowGroup ->
            Evergreen.V57.Tile.HedgeRowGroup

        Evergreen.V56.Tile.HedgeCornerGroup ->
            Evergreen.V57.Tile.HedgeCornerGroup

        Evergreen.V56.Tile.ApartmentGroup ->
            Evergreen.V57.Tile.ApartmentGroup

        Evergreen.V56.Tile.RockGroup ->
            Evergreen.V57.Tile.RockGroup

        Evergreen.V56.Tile.FlowersGroup ->
            Evergreen.V57.Tile.FlowersGroup

        Evergreen.V56.Tile.HedgePillarGroup ->
            Evergreen.V57.Tile.HedgePillarGroup

        Evergreen.V56.Tile.ElmTreeGroup ->
            Evergreen.V57.Tile.ElmTreeGroup

        Evergreen.V56.Tile.DirtPathGroup ->
            Evergreen.V57.Tile.DirtPathGroup


migrateDisplayName : Evergreen.V56.DisplayName.DisplayName -> Evergreen.V57.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V56.DisplayName.DisplayName a ->
            Evergreen.V57.DisplayName.DisplayName a


migrateCursor : Evergreen.V56.LocalGrid.Cursor -> Evergreen.V57.Cursor.Cursor
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
        -- TODO
        Evergreen.V57.Cursor.HandTool
    }


migrateContent : Evergreen.V56.MailEditor.Content -> Evergreen.V57.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, item = migrateImage old.image |> Evergreen.V57.MailEditor.ImageType }


migrateColors : Evergreen.V56.Color.Colors -> Evergreen.V57.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V56.Color.Color -> Evergreen.V57.Color.Color
migrateColor old =
    case old of
        Evergreen.V56.Color.Color a ->
            Evergreen.V57.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V56.Types.ViewPoint -> Evergreen.V57.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V56.Types.NormalViewPoint a ->
            Evergreen.V57.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V56.Types.TrainViewPoint a ->
            Evergreen.V57.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V56.Geometry.Types.Point2d old) =
    Evergreen.V57.Geometry.Types.Point2d old


migrateId : Evergreen.V56.Id.Id a -> Evergreen.V57.Id.Id b
migrateId (Evergreen.V56.Id.Id old) =
    Evergreen.V57.Id.Id old
