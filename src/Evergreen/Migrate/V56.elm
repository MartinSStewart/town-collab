module Evergreen.Migrate.V56 exposing (..)

import AssocList
import AssocSet
import Dict
import Effect.Time
import Evergreen.V54.Bounds
import Evergreen.V54.Change
import Evergreen.V54.Color
import Evergreen.V54.DisplayName
import Evergreen.V54.EmailAddress
import Evergreen.V54.Geometry.Types
import Evergreen.V54.Grid
import Evergreen.V54.GridCell
import Evergreen.V54.Id
import Evergreen.V54.IdDict
import Evergreen.V54.LocalGrid
import Evergreen.V54.MailEditor
import Evergreen.V54.Postmark
import Evergreen.V54.Tile
import Evergreen.V54.Train
import Evergreen.V54.Types
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
import IdDict
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Quantity


backendModel : Evergreen.V54.Types.BackendModel -> ModelMigration Evergreen.V56.Types.BackendModel Evergreen.V56.Types.BackendMsg
backendModel old =
    ModelMigrated ( migrateBackendModel old, Cmd.none )


frontendModel : Evergreen.V54.Types.FrontendModel -> ModelMigration Evergreen.V56.Types.FrontendModel Evergreen.V56.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V54.Types.FrontendMsg -> MsgMigration Evergreen.V56.Types.FrontendMsg Evergreen.V56.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V54.Types.BackendMsg -> MsgMigration Evergreen.V56.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V54.Types.BackendError -> Evergreen.V56.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V54.Types.PostmarkError a b ->
            Evergreen.V56.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V54.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V56.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V54.Types.BackendModel -> Evergreen.V56.Types.BackendModel
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


migrateRequestedBy : Evergreen.V54.Types.LoginRequestedBy -> Evergreen.V56.Types.LoginRequestedBy
migrateRequestedBy old =
    case old of
        Evergreen.V54.Types.LoginRequestedByBackend ->
            Evergreen.V56.Types.LoginRequestedByBackend

        Evergreen.V54.Types.LoginRequestedByFrontend sessionId ->
            Evergreen.V56.Types.LoginRequestedByFrontend sessionId


migrateGrid : Evergreen.V54.Grid.Grid -> Evergreen.V56.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V54.Grid.Grid a ->
            Evergreen.V56.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V54.GridCell.Cell -> Evergreen.V56.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V54.GridCell.Cell a ->
            Evergreen.V56.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateDict identity identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V54.GridCell.Value -> Evergreen.V56.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V54.Bounds.Bounds a -> Evergreen.V56.Bounds.Bounds b
migrateBounds (Evergreen.V54.Bounds.Bounds old) =
    Evergreen.V56.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V54.Change.Cow -> Evergreen.V56.Change.Cow
migrateCow old =
    { position = migratePoint2d old.position }


migrateBackendMail : Evergreen.V54.MailEditor.BackendMail -> Evergreen.V56.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V54.MailEditor.MailStatus -> Evergreen.V56.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V54.MailEditor.MailWaitingPickup ->
            Evergreen.V56.MailEditor.MailWaitingPickup

        Evergreen.V54.MailEditor.MailInTransit a ->
            Evergreen.V56.MailEditor.MailInTransit (migrateId a)

        Evergreen.V54.MailEditor.MailReceived a ->
            Evergreen.V56.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V54.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V56.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V54.Types.Invite -> Evergreen.V56.Types.Invite
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


migrateEmailAddress (Evergreen.V54.EmailAddress.EmailAddress old) =
    Evergreen.V56.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V54.Id.SecretId a -> Evergreen.V56.Id.SecretId b
migrateSecretId (Evergreen.V54.Id.SecretId old) =
    Evergreen.V56.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V54.IdDict.IdDict a b -> Evergreen.V56.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V54.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V56.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V54.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V56.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V54.IdDict.NColor -> Evergreen.V56.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V54.IdDict.Red ->
            Evergreen.V56.IdDict.Red

        Evergreen.V54.IdDict.Black ->
            Evergreen.V56.IdDict.Black


migrateBackendUserData : Evergreen.V54.Types.BackendUserData -> Evergreen.V56.Types.BackendUserData
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


migrateEmailResult : Evergreen.V54.Types.EmailResult -> Evergreen.V56.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V54.Types.EmailSending ->
            Evergreen.V56.Types.EmailSending

        Evergreen.V54.Types.EmailSendFailed a ->
            Evergreen.V56.Types.EmailSendFailed a

        Evergreen.V54.Types.EmailSent a ->
            Evergreen.V56.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V54.Postmark.PostmarkSendResponse -> Evergreen.V56.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V54.Tile.Tile -> Evergreen.V56.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V54.Tile.EmptyTile ->
            Evergreen.V56.Tile.EmptyTile

        Evergreen.V54.Tile.HouseDown ->
            Evergreen.V56.Tile.HouseDown

        Evergreen.V54.Tile.HouseRight ->
            Evergreen.V56.Tile.HouseRight

        Evergreen.V54.Tile.HouseUp ->
            Evergreen.V56.Tile.HouseUp

        Evergreen.V54.Tile.HouseLeft ->
            Evergreen.V56.Tile.HouseLeft

        Evergreen.V54.Tile.RailHorizontal ->
            Evergreen.V56.Tile.RailHorizontal

        Evergreen.V54.Tile.RailVertical ->
            Evergreen.V56.Tile.RailVertical

        Evergreen.V54.Tile.RailBottomToRight ->
            Evergreen.V56.Tile.RailBottomToRight

        Evergreen.V54.Tile.RailBottomToLeft ->
            Evergreen.V56.Tile.RailBottomToLeft

        Evergreen.V54.Tile.RailTopToRight ->
            Evergreen.V56.Tile.RailTopToRight

        Evergreen.V54.Tile.RailTopToLeft ->
            Evergreen.V56.Tile.RailTopToLeft

        Evergreen.V54.Tile.RailBottomToRightLarge ->
            Evergreen.V56.Tile.RailBottomToRightLarge

        Evergreen.V54.Tile.RailBottomToLeftLarge ->
            Evergreen.V56.Tile.RailBottomToLeftLarge

        Evergreen.V54.Tile.RailTopToRightLarge ->
            Evergreen.V56.Tile.RailTopToRightLarge

        Evergreen.V54.Tile.RailTopToLeftLarge ->
            Evergreen.V56.Tile.RailTopToLeftLarge

        Evergreen.V54.Tile.RailCrossing ->
            Evergreen.V56.Tile.RailCrossing

        Evergreen.V54.Tile.RailStrafeDown ->
            Evergreen.V56.Tile.RailStrafeDown

        Evergreen.V54.Tile.RailStrafeUp ->
            Evergreen.V56.Tile.RailStrafeUp

        Evergreen.V54.Tile.RailStrafeLeft ->
            Evergreen.V56.Tile.RailStrafeLeft

        Evergreen.V54.Tile.RailStrafeRight ->
            Evergreen.V56.Tile.RailStrafeRight

        Evergreen.V54.Tile.TrainHouseRight ->
            Evergreen.V56.Tile.TrainHouseRight

        Evergreen.V54.Tile.TrainHouseLeft ->
            Evergreen.V56.Tile.TrainHouseLeft

        Evergreen.V54.Tile.RailStrafeDownSmall ->
            Evergreen.V56.Tile.RailStrafeDownSmall

        Evergreen.V54.Tile.RailStrafeUpSmall ->
            Evergreen.V56.Tile.RailStrafeUpSmall

        Evergreen.V54.Tile.RailStrafeLeftSmall ->
            Evergreen.V56.Tile.RailStrafeLeftSmall

        Evergreen.V54.Tile.RailStrafeRightSmall ->
            Evergreen.V56.Tile.RailStrafeRightSmall

        Evergreen.V54.Tile.Sidewalk ->
            Evergreen.V56.Tile.Sidewalk

        Evergreen.V54.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V56.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V54.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V56.Tile.SidewalkVerticalRailCrossing

        Evergreen.V54.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V56.Tile.RailBottomToRight_SplitLeft

        Evergreen.V54.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V56.Tile.RailBottomToLeft_SplitUp

        Evergreen.V54.Tile.RailTopToRight_SplitDown ->
            Evergreen.V56.Tile.RailTopToRight_SplitDown

        Evergreen.V54.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V56.Tile.RailTopToLeft_SplitRight

        Evergreen.V54.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V56.Tile.RailBottomToRight_SplitUp

        Evergreen.V54.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V56.Tile.RailBottomToLeft_SplitRight

        Evergreen.V54.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V56.Tile.RailTopToRight_SplitLeft

        Evergreen.V54.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V56.Tile.RailTopToLeft_SplitDown

        Evergreen.V54.Tile.PostOffice ->
            Evergreen.V56.Tile.PostOffice

        Evergreen.V54.Tile.MowedGrass1 ->
            Evergreen.V56.Tile.MowedGrass1

        Evergreen.V54.Tile.MowedGrass4 ->
            Evergreen.V56.Tile.MowedGrass4

        Evergreen.V54.Tile.LogCabinDown ->
            Evergreen.V56.Tile.LogCabinDown

        Evergreen.V54.Tile.LogCabinRight ->
            Evergreen.V56.Tile.LogCabinRight

        Evergreen.V54.Tile.LogCabinUp ->
            Evergreen.V56.Tile.LogCabinUp

        Evergreen.V54.Tile.LogCabinLeft ->
            Evergreen.V56.Tile.LogCabinLeft

        Evergreen.V54.Tile.RoadHorizontal ->
            Evergreen.V56.Tile.RoadHorizontal

        Evergreen.V54.Tile.RoadVertical ->
            Evergreen.V56.Tile.RoadVertical

        Evergreen.V54.Tile.RoadBottomToLeft ->
            Evergreen.V56.Tile.RoadBottomToLeft

        Evergreen.V54.Tile.RoadTopToLeft ->
            Evergreen.V56.Tile.RoadTopToLeft

        Evergreen.V54.Tile.RoadTopToRight ->
            Evergreen.V56.Tile.RoadTopToRight

        Evergreen.V54.Tile.RoadBottomToRight ->
            Evergreen.V56.Tile.RoadBottomToRight

        Evergreen.V54.Tile.Road4Way ->
            Evergreen.V56.Tile.Road4Way

        Evergreen.V54.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V56.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V54.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V56.Tile.RoadSidewalkCrossingVertical

        Evergreen.V54.Tile.Road3WayDown ->
            Evergreen.V56.Tile.Road3WayDown

        Evergreen.V54.Tile.Road3WayLeft ->
            Evergreen.V56.Tile.Road3WayLeft

        Evergreen.V54.Tile.Road3WayUp ->
            Evergreen.V56.Tile.Road3WayUp

        Evergreen.V54.Tile.Road3WayRight ->
            Evergreen.V56.Tile.Road3WayRight

        Evergreen.V54.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V56.Tile.RoadRailCrossingHorizontal

        Evergreen.V54.Tile.RoadRailCrossingVertical ->
            Evergreen.V56.Tile.RoadRailCrossingVertical

        Evergreen.V54.Tile.FenceHorizontal ->
            Evergreen.V56.Tile.FenceHorizontal

        Evergreen.V54.Tile.FenceVertical ->
            Evergreen.V56.Tile.FenceVertical

        Evergreen.V54.Tile.FenceDiagonal ->
            Evergreen.V56.Tile.FenceDiagonal

        Evergreen.V54.Tile.FenceAntidiagonal ->
            Evergreen.V56.Tile.FenceAntidiagonal

        Evergreen.V54.Tile.RoadDeadendUp ->
            Evergreen.V56.Tile.RoadDeadendUp

        Evergreen.V54.Tile.RoadDeadendDown ->
            Evergreen.V56.Tile.RoadDeadendDown

        Evergreen.V54.Tile.BusStopDown ->
            Evergreen.V56.Tile.BusStopDown

        Evergreen.V54.Tile.BusStopLeft ->
            Evergreen.V56.Tile.BusStopLeft

        Evergreen.V54.Tile.BusStopRight ->
            Evergreen.V56.Tile.BusStopRight

        Evergreen.V54.Tile.BusStopUp ->
            Evergreen.V56.Tile.BusStopUp

        Evergreen.V54.Tile.Hospital ->
            Evergreen.V56.Tile.Hospital

        Evergreen.V54.Tile.Statue ->
            Evergreen.V56.Tile.Statue

        Evergreen.V54.Tile.HedgeRowDown ->
            Evergreen.V56.Tile.HedgeRowDown

        Evergreen.V54.Tile.HedgeRowLeft ->
            Evergreen.V56.Tile.HedgeRowLeft

        Evergreen.V54.Tile.HedgeRowRight ->
            Evergreen.V56.Tile.HedgeRowRight

        Evergreen.V54.Tile.HedgeRowUp ->
            Evergreen.V56.Tile.HedgeRowUp

        Evergreen.V54.Tile.HedgeCornerDownLeft ->
            Evergreen.V56.Tile.HedgeCornerDownLeft

        Evergreen.V54.Tile.HedgeCornerDownRight ->
            Evergreen.V56.Tile.HedgeCornerDownRight

        Evergreen.V54.Tile.HedgeCornerUpLeft ->
            Evergreen.V56.Tile.HedgeCornerUpLeft

        Evergreen.V54.Tile.HedgeCornerUpRight ->
            Evergreen.V56.Tile.HedgeCornerUpRight

        Evergreen.V54.Tile.ApartmentDown ->
            Evergreen.V56.Tile.ApartmentDown

        Evergreen.V54.Tile.ApartmentLeft ->
            Evergreen.V56.Tile.ApartmentLeft

        Evergreen.V54.Tile.ApartmentRight ->
            Evergreen.V56.Tile.ApartmentRight

        Evergreen.V54.Tile.ApartmentUp ->
            Evergreen.V56.Tile.ApartmentUp

        Evergreen.V54.Tile.RockDown ->
            Evergreen.V56.Tile.RockDown

        Evergreen.V54.Tile.RockLeft ->
            Evergreen.V56.Tile.RockLeft

        Evergreen.V54.Tile.RockRight ->
            Evergreen.V56.Tile.RockRight

        Evergreen.V54.Tile.RockUp ->
            Evergreen.V56.Tile.RockUp

        Evergreen.V54.Tile.PineTree1 ->
            Evergreen.V56.Tile.PineTree1

        Evergreen.V54.Tile.PineTree2 ->
            Evergreen.V56.Tile.PineTree2

        Evergreen.V54.Tile.HedgePillarDownLeft ->
            Evergreen.V56.Tile.HedgePillarDownLeft

        Evergreen.V54.Tile.HedgePillarDownRight ->
            Evergreen.V56.Tile.HedgePillarDownRight

        Evergreen.V54.Tile.HedgePillarUpLeft ->
            Evergreen.V56.Tile.HedgePillarUpLeft

        Evergreen.V54.Tile.HedgePillarUpRight ->
            Evergreen.V56.Tile.HedgePillarUpRight

        Evergreen.V54.Tile.Flowers1 ->
            Evergreen.V56.Tile.Flowers1

        Evergreen.V54.Tile.Flowers2 ->
            Evergreen.V56.Tile.Flowers2

        Evergreen.V54.Tile.ElmTree ->
            Evergreen.V56.Tile.ElmTree

        Evergreen.V54.Tile.DirtPathHorizontal ->
            Evergreen.V56.Tile.DirtPathHorizontal

        Evergreen.V54.Tile.DirtPathVertical ->
            Evergreen.V56.Tile.DirtPathVertical


migrateTrain : Evergreen.V54.Train.Train -> Evergreen.V56.Train.Train
migrateTrain old =
    case old of
        Evergreen.V54.Train.Train a ->
            Evergreen.V56.Train.Train
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


migrateStatus : Evergreen.V54.Train.Status -> Evergreen.V56.Train.Status
migrateStatus old =
    case old of
        Evergreen.V54.Train.WaitingAtHome ->
            Evergreen.V56.Train.WaitingAtHome

        Evergreen.V54.Train.TeleportingHome a ->
            Evergreen.V56.Train.TeleportingHome (migratePosix a)

        Evergreen.V54.Train.Travelling ->
            Evergreen.V56.Train.Travelling

        Evergreen.V54.Train.StoppedAtPostOffice a ->
            Evergreen.V56.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V54.Tile.RailPath -> Evergreen.V56.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V54.Tile.RailPathHorizontal a ->
            Evergreen.V56.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V54.Tile.RailPathVertical a ->
            Evergreen.V56.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V54.Tile.RailPathBottomToRight ->
            Evergreen.V56.Tile.RailPathBottomToRight

        Evergreen.V54.Tile.RailPathBottomToLeft ->
            Evergreen.V56.Tile.RailPathBottomToLeft

        Evergreen.V54.Tile.RailPathTopToRight ->
            Evergreen.V56.Tile.RailPathTopToRight

        Evergreen.V54.Tile.RailPathTopToLeft ->
            Evergreen.V56.Tile.RailPathTopToLeft

        Evergreen.V54.Tile.RailPathBottomToRightLarge ->
            Evergreen.V56.Tile.RailPathBottomToRightLarge

        Evergreen.V54.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V56.Tile.RailPathBottomToLeftLarge

        Evergreen.V54.Tile.RailPathTopToRightLarge ->
            Evergreen.V56.Tile.RailPathTopToRightLarge

        Evergreen.V54.Tile.RailPathTopToLeftLarge ->
            Evergreen.V56.Tile.RailPathTopToLeftLarge

        Evergreen.V54.Tile.RailPathStrafeDown ->
            Evergreen.V56.Tile.RailPathStrafeDown

        Evergreen.V54.Tile.RailPathStrafeUp ->
            Evergreen.V56.Tile.RailPathStrafeUp

        Evergreen.V54.Tile.RailPathStrafeLeft ->
            Evergreen.V56.Tile.RailPathStrafeLeft

        Evergreen.V54.Tile.RailPathStrafeRight ->
            Evergreen.V56.Tile.RailPathStrafeRight

        Evergreen.V54.Tile.RailPathStrafeDownSmall ->
            Evergreen.V56.Tile.RailPathStrafeDownSmall

        Evergreen.V54.Tile.RailPathStrafeUpSmall ->
            Evergreen.V56.Tile.RailPathStrafeUpSmall

        Evergreen.V54.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V56.Tile.RailPathStrafeLeftSmall

        Evergreen.V54.Tile.RailPathStrafeRightSmall ->
            Evergreen.V56.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V54.Train.PreviousPath -> Evergreen.V56.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V54.MailEditor.Image -> Evergreen.V56.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V54.MailEditor.Stamp a ->
            Evergreen.V56.MailEditor.Stamp (migrateColors a)

        Evergreen.V54.MailEditor.SunglassesEmoji a ->
            Evergreen.V56.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V54.MailEditor.NormalEmoji a ->
            Evergreen.V56.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V54.MailEditor.SadEmoji a ->
            Evergreen.V56.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V54.MailEditor.Cow a ->
            Evergreen.V56.MailEditor.Cow (migrateColors a)

        Evergreen.V54.MailEditor.Man a ->
            Evergreen.V56.MailEditor.Man (migrateColors a)

        Evergreen.V54.MailEditor.TileImage a b c ->
            Evergreen.V56.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V54.MailEditor.Grass ->
            Evergreen.V56.MailEditor.Grass

        Evergreen.V54.MailEditor.DefaultCursor a ->
            Evergreen.V56.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V54.MailEditor.DragCursor a ->
            Evergreen.V56.MailEditor.DragCursor (migrateColors a)

        Evergreen.V54.MailEditor.PinchCursor a ->
            Evergreen.V56.MailEditor.PinchCursor (migrateColors a)

        Evergreen.V54.MailEditor.Line int color ->
            Evergreen.V56.MailEditor.Line int (migrateColor color)


migrateTileGroup : Evergreen.V54.Tile.TileGroup -> Evergreen.V56.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V54.Tile.EmptyTileGroup ->
            Evergreen.V56.Tile.EmptyTileGroup

        Evergreen.V54.Tile.HouseGroup ->
            Evergreen.V56.Tile.HouseGroup

        Evergreen.V54.Tile.RailStraightGroup ->
            Evergreen.V56.Tile.RailStraightGroup

        Evergreen.V54.Tile.RailTurnGroup ->
            Evergreen.V56.Tile.RailTurnGroup

        Evergreen.V54.Tile.RailTurnLargeGroup ->
            Evergreen.V56.Tile.RailTurnLargeGroup

        Evergreen.V54.Tile.RailStrafeGroup ->
            Evergreen.V56.Tile.RailStrafeGroup

        Evergreen.V54.Tile.RailStrafeSmallGroup ->
            Evergreen.V56.Tile.RailStrafeSmallGroup

        Evergreen.V54.Tile.RailCrossingGroup ->
            Evergreen.V56.Tile.RailCrossingGroup

        Evergreen.V54.Tile.TrainHouseGroup ->
            Evergreen.V56.Tile.TrainHouseGroup

        Evergreen.V54.Tile.SidewalkGroup ->
            Evergreen.V56.Tile.SidewalkGroup

        Evergreen.V54.Tile.SidewalkRailGroup ->
            Evergreen.V56.Tile.SidewalkRailGroup

        Evergreen.V54.Tile.RailTurnSplitGroup ->
            Evergreen.V56.Tile.RailTurnSplitGroup

        Evergreen.V54.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V56.Tile.RailTurnSplitMirrorGroup

        Evergreen.V54.Tile.PostOfficeGroup ->
            Evergreen.V56.Tile.PostOfficeGroup

        Evergreen.V54.Tile.PineTreeGroup ->
            Evergreen.V56.Tile.PineTreeGroup

        Evergreen.V54.Tile.LogCabinGroup ->
            Evergreen.V56.Tile.LogCabinGroup

        Evergreen.V54.Tile.RoadStraightGroup ->
            Evergreen.V56.Tile.RoadStraightGroup

        Evergreen.V54.Tile.RoadTurnGroup ->
            Evergreen.V56.Tile.RoadTurnGroup

        Evergreen.V54.Tile.Road4WayGroup ->
            Evergreen.V56.Tile.Road4WayGroup

        Evergreen.V54.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V56.Tile.RoadSidewalkCrossingGroup

        Evergreen.V54.Tile.Road3WayGroup ->
            Evergreen.V56.Tile.Road3WayGroup

        Evergreen.V54.Tile.RoadRailCrossingGroup ->
            Evergreen.V56.Tile.RoadRailCrossingGroup

        Evergreen.V54.Tile.RoadDeadendGroup ->
            Evergreen.V56.Tile.RoadDeadendGroup

        Evergreen.V54.Tile.FenceStraightGroup ->
            Evergreen.V56.Tile.FenceStraightGroup

        Evergreen.V54.Tile.BusStopGroup ->
            Evergreen.V56.Tile.BusStopGroup

        Evergreen.V54.Tile.HospitalGroup ->
            Evergreen.V56.Tile.HospitalGroup

        Evergreen.V54.Tile.StatueGroup ->
            Evergreen.V56.Tile.StatueGroup

        Evergreen.V54.Tile.HedgeRowGroup ->
            Evergreen.V56.Tile.HedgeRowGroup

        Evergreen.V54.Tile.HedgeCornerGroup ->
            Evergreen.V56.Tile.HedgeCornerGroup

        Evergreen.V54.Tile.ApartmentGroup ->
            Evergreen.V56.Tile.ApartmentGroup

        Evergreen.V54.Tile.RockGroup ->
            Evergreen.V56.Tile.RockGroup

        Evergreen.V54.Tile.FlowersGroup ->
            Evergreen.V56.Tile.FlowersGroup

        Evergreen.V54.Tile.HedgePillarGroup ->
            Evergreen.V56.Tile.HedgePillarGroup

        Evergreen.V54.Tile.ElmTreeGroup ->
            Evergreen.V56.Tile.ElmTreeGroup

        Evergreen.V54.Tile.DirtPathGroup ->
            Evergreen.V56.Tile.DirtPathGroup


migrateDisplayName : Evergreen.V54.DisplayName.DisplayName -> Evergreen.V56.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V54.DisplayName.DisplayName a ->
            Evergreen.V56.DisplayName.DisplayName a


migrateCursor : Evergreen.V54.LocalGrid.Cursor -> Evergreen.V56.LocalGrid.Cursor
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
    }


migrateContent : Evergreen.V54.MailEditor.Content -> Evergreen.V56.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, image = migrateImage old.image }


migrateColors : Evergreen.V54.Color.Colors -> Evergreen.V56.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V54.Color.Color -> Evergreen.V56.Color.Color
migrateColor old =
    case old of
        Evergreen.V54.Color.Color a ->
            Evergreen.V56.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V54.Types.ViewPoint -> Evergreen.V56.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V54.Types.NormalViewPoint a ->
            Evergreen.V56.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V54.Types.TrainViewPoint a ->
            Evergreen.V56.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V54.Geometry.Types.Point2d old) =
    Evergreen.V56.Geometry.Types.Point2d old


migrateId : Evergreen.V54.Id.Id a -> Evergreen.V56.Id.Id b
migrateId (Evergreen.V54.Id.Id old) =
    Evergreen.V56.Id.Id old
