module Evergreen.Migrate.V54 exposing (..)

import AssocList
import AssocSet
import Dict
import Effect.Time
import Evergreen.V52.Bounds
import Evergreen.V52.Change
import Evergreen.V52.Color
import Evergreen.V52.DisplayName
import Evergreen.V52.EmailAddress
import Evergreen.V52.Geometry.Types
import Evergreen.V52.Grid
import Evergreen.V52.GridCell
import Evergreen.V52.Id
import Evergreen.V52.IdDict
import Evergreen.V52.LocalGrid
import Evergreen.V52.MailEditor
import Evergreen.V52.Postmark
import Evergreen.V52.Tile
import Evergreen.V52.Train
import Evergreen.V52.Types
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
import IdDict
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Quantity


backendModel : Evergreen.V52.Types.BackendModel -> ModelMigration Evergreen.V54.Types.BackendModel Evergreen.V54.Types.BackendMsg
backendModel old =
    ModelMigrated ( migrateBackendModel old, Cmd.none )


frontendModel : Evergreen.V52.Types.FrontendModel -> ModelMigration Evergreen.V54.Types.FrontendModel Evergreen.V54.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V52.Types.FrontendMsg -> MsgMigration Evergreen.V54.Types.FrontendMsg Evergreen.V54.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V52.Types.BackendMsg -> MsgMigration Evergreen.V54.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V52.Types.BackendError -> Evergreen.V54.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V52.Types.PostmarkError a b ->
            Evergreen.V54.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V52.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V54.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V52.Types.BackendModel -> Evergreen.V54.Types.BackendModel
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


migrateRequestedBy : Evergreen.V52.Types.LoginRequestedBy -> Evergreen.V54.Types.LoginRequestedBy
migrateRequestedBy old =
    case old of
        Evergreen.V52.Types.LoginRequestedByBackend ->
            Evergreen.V54.Types.LoginRequestedByBackend

        Evergreen.V52.Types.LoginRequestedByFrontend sessionId ->
            Evergreen.V54.Types.LoginRequestedByFrontend sessionId


migrateGrid : Evergreen.V52.Grid.Grid -> Evergreen.V54.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V52.Grid.Grid a ->
            Evergreen.V54.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V52.GridCell.Cell -> Evergreen.V54.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V52.GridCell.Cell a ->
            Evergreen.V54.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateDict identity identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V52.GridCell.Value -> Evergreen.V54.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V52.Bounds.Bounds a -> Evergreen.V54.Bounds.Bounds b
migrateBounds (Evergreen.V52.Bounds.Bounds old) =
    Evergreen.V54.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V52.Change.Cow -> Evergreen.V54.Change.Cow
migrateCow old =
    { position = migratePoint2d old.position }


migrateBackendMail : Evergreen.V52.MailEditor.BackendMail -> Evergreen.V54.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V52.MailEditor.MailStatus -> Evergreen.V54.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V52.MailEditor.MailWaitingPickup ->
            Evergreen.V54.MailEditor.MailWaitingPickup

        Evergreen.V52.MailEditor.MailInTransit a ->
            Evergreen.V54.MailEditor.MailInTransit (migrateId a)

        Evergreen.V52.MailEditor.MailReceived a ->
            Evergreen.V54.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V52.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V54.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V52.Types.Invite -> Evergreen.V54.Types.Invite
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


migrateEmailAddress (Evergreen.V52.EmailAddress.EmailAddress old) =
    Evergreen.V54.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V52.Id.SecretId a -> Evergreen.V54.Id.SecretId b
migrateSecretId (Evergreen.V52.Id.SecretId old) =
    Evergreen.V54.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V52.IdDict.IdDict a b -> Evergreen.V54.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V52.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V54.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V52.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V54.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V52.IdDict.NColor -> Evergreen.V54.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V52.IdDict.Red ->
            Evergreen.V54.IdDict.Red

        Evergreen.V52.IdDict.Black ->
            Evergreen.V54.IdDict.Black


migrateBackendUserData : Evergreen.V52.Types.BackendUserData -> Evergreen.V54.Types.BackendUserData
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


migrateEmailResult : Evergreen.V52.Types.EmailResult -> Evergreen.V54.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V52.Types.EmailSending ->
            Evergreen.V54.Types.EmailSending

        Evergreen.V52.Types.EmailSendFailed a ->
            Evergreen.V54.Types.EmailSendFailed a

        Evergreen.V52.Types.EmailSent a ->
            Evergreen.V54.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V52.Postmark.PostmarkSendResponse -> Evergreen.V54.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V52.Tile.Tile -> Evergreen.V54.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V52.Tile.EmptyTile ->
            Evergreen.V54.Tile.EmptyTile

        Evergreen.V52.Tile.HouseDown ->
            Evergreen.V54.Tile.HouseDown

        Evergreen.V52.Tile.HouseRight ->
            Evergreen.V54.Tile.HouseRight

        Evergreen.V52.Tile.HouseUp ->
            Evergreen.V54.Tile.HouseUp

        Evergreen.V52.Tile.HouseLeft ->
            Evergreen.V54.Tile.HouseLeft

        Evergreen.V52.Tile.RailHorizontal ->
            Evergreen.V54.Tile.RailHorizontal

        Evergreen.V52.Tile.RailVertical ->
            Evergreen.V54.Tile.RailVertical

        Evergreen.V52.Tile.RailBottomToRight ->
            Evergreen.V54.Tile.RailBottomToRight

        Evergreen.V52.Tile.RailBottomToLeft ->
            Evergreen.V54.Tile.RailBottomToLeft

        Evergreen.V52.Tile.RailTopToRight ->
            Evergreen.V54.Tile.RailTopToRight

        Evergreen.V52.Tile.RailTopToLeft ->
            Evergreen.V54.Tile.RailTopToLeft

        Evergreen.V52.Tile.RailBottomToRightLarge ->
            Evergreen.V54.Tile.RailBottomToRightLarge

        Evergreen.V52.Tile.RailBottomToLeftLarge ->
            Evergreen.V54.Tile.RailBottomToLeftLarge

        Evergreen.V52.Tile.RailTopToRightLarge ->
            Evergreen.V54.Tile.RailTopToRightLarge

        Evergreen.V52.Tile.RailTopToLeftLarge ->
            Evergreen.V54.Tile.RailTopToLeftLarge

        Evergreen.V52.Tile.RailCrossing ->
            Evergreen.V54.Tile.RailCrossing

        Evergreen.V52.Tile.RailStrafeDown ->
            Evergreen.V54.Tile.RailStrafeDown

        Evergreen.V52.Tile.RailStrafeUp ->
            Evergreen.V54.Tile.RailStrafeUp

        Evergreen.V52.Tile.RailStrafeLeft ->
            Evergreen.V54.Tile.RailStrafeLeft

        Evergreen.V52.Tile.RailStrafeRight ->
            Evergreen.V54.Tile.RailStrafeRight

        Evergreen.V52.Tile.TrainHouseRight ->
            Evergreen.V54.Tile.TrainHouseRight

        Evergreen.V52.Tile.TrainHouseLeft ->
            Evergreen.V54.Tile.TrainHouseLeft

        Evergreen.V52.Tile.RailStrafeDownSmall ->
            Evergreen.V54.Tile.RailStrafeDownSmall

        Evergreen.V52.Tile.RailStrafeUpSmall ->
            Evergreen.V54.Tile.RailStrafeUpSmall

        Evergreen.V52.Tile.RailStrafeLeftSmall ->
            Evergreen.V54.Tile.RailStrafeLeftSmall

        Evergreen.V52.Tile.RailStrafeRightSmall ->
            Evergreen.V54.Tile.RailStrafeRightSmall

        Evergreen.V52.Tile.Sidewalk ->
            Evergreen.V54.Tile.Sidewalk

        Evergreen.V52.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V54.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V52.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V54.Tile.SidewalkVerticalRailCrossing

        Evergreen.V52.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V54.Tile.RailBottomToRight_SplitLeft

        Evergreen.V52.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V54.Tile.RailBottomToLeft_SplitUp

        Evergreen.V52.Tile.RailTopToRight_SplitDown ->
            Evergreen.V54.Tile.RailTopToRight_SplitDown

        Evergreen.V52.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V54.Tile.RailTopToLeft_SplitRight

        Evergreen.V52.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V54.Tile.RailBottomToRight_SplitUp

        Evergreen.V52.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V54.Tile.RailBottomToLeft_SplitRight

        Evergreen.V52.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V54.Tile.RailTopToRight_SplitLeft

        Evergreen.V52.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V54.Tile.RailTopToLeft_SplitDown

        Evergreen.V52.Tile.PostOffice ->
            Evergreen.V54.Tile.PostOffice

        Evergreen.V52.Tile.MowedGrass1 ->
            Evergreen.V54.Tile.MowedGrass1

        Evergreen.V52.Tile.MowedGrass4 ->
            Evergreen.V54.Tile.MowedGrass4

        Evergreen.V52.Tile.LogCabinDown ->
            Evergreen.V54.Tile.LogCabinDown

        Evergreen.V52.Tile.LogCabinRight ->
            Evergreen.V54.Tile.LogCabinRight

        Evergreen.V52.Tile.LogCabinUp ->
            Evergreen.V54.Tile.LogCabinUp

        Evergreen.V52.Tile.LogCabinLeft ->
            Evergreen.V54.Tile.LogCabinLeft

        Evergreen.V52.Tile.RoadHorizontal ->
            Evergreen.V54.Tile.RoadHorizontal

        Evergreen.V52.Tile.RoadVertical ->
            Evergreen.V54.Tile.RoadVertical

        Evergreen.V52.Tile.RoadBottomToLeft ->
            Evergreen.V54.Tile.RoadBottomToLeft

        Evergreen.V52.Tile.RoadTopToLeft ->
            Evergreen.V54.Tile.RoadTopToLeft

        Evergreen.V52.Tile.RoadTopToRight ->
            Evergreen.V54.Tile.RoadTopToRight

        Evergreen.V52.Tile.RoadBottomToRight ->
            Evergreen.V54.Tile.RoadBottomToRight

        Evergreen.V52.Tile.Road4Way ->
            Evergreen.V54.Tile.Road4Way

        Evergreen.V52.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V54.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V52.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V54.Tile.RoadSidewalkCrossingVertical

        Evergreen.V52.Tile.Road3WayDown ->
            Evergreen.V54.Tile.Road3WayDown

        Evergreen.V52.Tile.Road3WayLeft ->
            Evergreen.V54.Tile.Road3WayLeft

        Evergreen.V52.Tile.Road3WayUp ->
            Evergreen.V54.Tile.Road3WayUp

        Evergreen.V52.Tile.Road3WayRight ->
            Evergreen.V54.Tile.Road3WayRight

        Evergreen.V52.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V54.Tile.RoadRailCrossingHorizontal

        Evergreen.V52.Tile.RoadRailCrossingVertical ->
            Evergreen.V54.Tile.RoadRailCrossingVertical

        Evergreen.V52.Tile.FenceHorizontal ->
            Evergreen.V54.Tile.FenceHorizontal

        Evergreen.V52.Tile.FenceVertical ->
            Evergreen.V54.Tile.FenceVertical

        Evergreen.V52.Tile.FenceDiagonal ->
            Evergreen.V54.Tile.FenceDiagonal

        Evergreen.V52.Tile.FenceAntidiagonal ->
            Evergreen.V54.Tile.FenceAntidiagonal

        Evergreen.V52.Tile.RoadDeadendUp ->
            Evergreen.V54.Tile.RoadDeadendUp

        Evergreen.V52.Tile.RoadDeadendDown ->
            Evergreen.V54.Tile.RoadDeadendDown

        Evergreen.V52.Tile.BusStopDown ->
            Evergreen.V54.Tile.BusStopDown

        Evergreen.V52.Tile.BusStopLeft ->
            Evergreen.V54.Tile.BusStopLeft

        Evergreen.V52.Tile.BusStopRight ->
            Evergreen.V54.Tile.BusStopRight

        Evergreen.V52.Tile.BusStopUp ->
            Evergreen.V54.Tile.BusStopUp

        Evergreen.V52.Tile.Hospital ->
            Evergreen.V54.Tile.Hospital

        Evergreen.V52.Tile.Statue ->
            Evergreen.V54.Tile.Statue

        Evergreen.V52.Tile.HedgeRowDown ->
            Evergreen.V54.Tile.HedgeRowDown

        Evergreen.V52.Tile.HedgeRowLeft ->
            Evergreen.V54.Tile.HedgeRowLeft

        Evergreen.V52.Tile.HedgeRowRight ->
            Evergreen.V54.Tile.HedgeRowRight

        Evergreen.V52.Tile.HedgeRowUp ->
            Evergreen.V54.Tile.HedgeRowUp

        Evergreen.V52.Tile.HedgeCornerDownLeft ->
            Evergreen.V54.Tile.HedgeCornerDownLeft

        Evergreen.V52.Tile.HedgeCornerDownRight ->
            Evergreen.V54.Tile.HedgeCornerDownRight

        Evergreen.V52.Tile.HedgeCornerUpLeft ->
            Evergreen.V54.Tile.HedgeCornerUpLeft

        Evergreen.V52.Tile.HedgeCornerUpRight ->
            Evergreen.V54.Tile.HedgeCornerUpRight

        Evergreen.V52.Tile.ApartmentDown ->
            Evergreen.V54.Tile.ApartmentDown

        Evergreen.V52.Tile.ApartmentLeft ->
            Evergreen.V54.Tile.ApartmentLeft

        Evergreen.V52.Tile.ApartmentRight ->
            Evergreen.V54.Tile.ApartmentRight

        Evergreen.V52.Tile.ApartmentUp ->
            Evergreen.V54.Tile.ApartmentUp

        Evergreen.V52.Tile.RockDown ->
            Evergreen.V54.Tile.RockDown

        Evergreen.V52.Tile.RockLeft ->
            Evergreen.V54.Tile.RockLeft

        Evergreen.V52.Tile.RockRight ->
            Evergreen.V54.Tile.RockRight

        Evergreen.V52.Tile.RockUp ->
            Evergreen.V54.Tile.RockUp

        Evergreen.V52.Tile.PineTree1 ->
            Evergreen.V54.Tile.PineTree1

        Evergreen.V52.Tile.PineTree2 ->
            Evergreen.V54.Tile.PineTree2

        Evergreen.V52.Tile.HedgePillarDownLeft ->
            Evergreen.V54.Tile.HedgePillarDownLeft

        Evergreen.V52.Tile.HedgePillarDownRight ->
            Evergreen.V54.Tile.HedgePillarDownRight

        Evergreen.V52.Tile.HedgePillarUpLeft ->
            Evergreen.V54.Tile.HedgePillarUpLeft

        Evergreen.V52.Tile.HedgePillarUpRight ->
            Evergreen.V54.Tile.HedgePillarUpRight

        Evergreen.V52.Tile.Flowers1 ->
            Evergreen.V54.Tile.Flowers1

        Evergreen.V52.Tile.Flowers2 ->
            Evergreen.V54.Tile.Flowers2

        Evergreen.V52.Tile.ElmTree ->
            Evergreen.V54.Tile.ElmTree

        Evergreen.V52.Tile.DirtPathHorizontal ->
            Evergreen.V54.Tile.DirtPathHorizontal

        Evergreen.V52.Tile.DirtPathVertical ->
            Evergreen.V54.Tile.DirtPathVertical


migrateTrain : Evergreen.V52.Train.Train -> Evergreen.V54.Train.Train
migrateTrain old =
    case old of
        Evergreen.V52.Train.Train a ->
            Evergreen.V54.Train.Train
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


migrateStatus : Evergreen.V52.Train.Status -> Evergreen.V54.Train.Status
migrateStatus old =
    case old of
        Evergreen.V52.Train.WaitingAtHome ->
            Evergreen.V54.Train.WaitingAtHome

        Evergreen.V52.Train.TeleportingHome a ->
            Evergreen.V54.Train.TeleportingHome (migratePosix a)

        Evergreen.V52.Train.Travelling ->
            Evergreen.V54.Train.Travelling

        Evergreen.V52.Train.StoppedAtPostOffice a ->
            Evergreen.V54.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V52.Tile.RailPath -> Evergreen.V54.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V52.Tile.RailPathHorizontal a ->
            Evergreen.V54.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V52.Tile.RailPathVertical a ->
            Evergreen.V54.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V52.Tile.RailPathBottomToRight ->
            Evergreen.V54.Tile.RailPathBottomToRight

        Evergreen.V52.Tile.RailPathBottomToLeft ->
            Evergreen.V54.Tile.RailPathBottomToLeft

        Evergreen.V52.Tile.RailPathTopToRight ->
            Evergreen.V54.Tile.RailPathTopToRight

        Evergreen.V52.Tile.RailPathTopToLeft ->
            Evergreen.V54.Tile.RailPathTopToLeft

        Evergreen.V52.Tile.RailPathBottomToRightLarge ->
            Evergreen.V54.Tile.RailPathBottomToRightLarge

        Evergreen.V52.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V54.Tile.RailPathBottomToLeftLarge

        Evergreen.V52.Tile.RailPathTopToRightLarge ->
            Evergreen.V54.Tile.RailPathTopToRightLarge

        Evergreen.V52.Tile.RailPathTopToLeftLarge ->
            Evergreen.V54.Tile.RailPathTopToLeftLarge

        Evergreen.V52.Tile.RailPathStrafeDown ->
            Evergreen.V54.Tile.RailPathStrafeDown

        Evergreen.V52.Tile.RailPathStrafeUp ->
            Evergreen.V54.Tile.RailPathStrafeUp

        Evergreen.V52.Tile.RailPathStrafeLeft ->
            Evergreen.V54.Tile.RailPathStrafeLeft

        Evergreen.V52.Tile.RailPathStrafeRight ->
            Evergreen.V54.Tile.RailPathStrafeRight

        Evergreen.V52.Tile.RailPathStrafeDownSmall ->
            Evergreen.V54.Tile.RailPathStrafeDownSmall

        Evergreen.V52.Tile.RailPathStrafeUpSmall ->
            Evergreen.V54.Tile.RailPathStrafeUpSmall

        Evergreen.V52.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V54.Tile.RailPathStrafeLeftSmall

        Evergreen.V52.Tile.RailPathStrafeRightSmall ->
            Evergreen.V54.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V52.Train.PreviousPath -> Evergreen.V54.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V52.MailEditor.Image -> Evergreen.V54.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V52.MailEditor.Stamp a ->
            Evergreen.V54.MailEditor.Stamp (migrateColors a)

        Evergreen.V52.MailEditor.SunglassesEmoji a ->
            Evergreen.V54.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V52.MailEditor.NormalEmoji a ->
            Evergreen.V54.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V52.MailEditor.SadEmoji a ->
            Evergreen.V54.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V52.MailEditor.Cow a ->
            Evergreen.V54.MailEditor.Cow (migrateColors a)

        Evergreen.V52.MailEditor.Man a ->
            Evergreen.V54.MailEditor.Man (migrateColors a)

        Evergreen.V52.MailEditor.TileImage a b c ->
            Evergreen.V54.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V52.MailEditor.Grass ->
            Evergreen.V54.MailEditor.Grass

        Evergreen.V52.MailEditor.DefaultCursor a ->
            Evergreen.V54.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V52.MailEditor.DragCursor a ->
            Evergreen.V54.MailEditor.DragCursor (migrateColors a)

        Evergreen.V52.MailEditor.PinchCursor a ->
            Evergreen.V54.MailEditor.PinchCursor (migrateColors a)

        Evergreen.V52.MailEditor.Line int color ->
            Evergreen.V54.MailEditor.Line int (migrateColor color)


migrateTileGroup : Evergreen.V52.Tile.TileGroup -> Evergreen.V54.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V52.Tile.EmptyTileGroup ->
            Evergreen.V54.Tile.EmptyTileGroup

        Evergreen.V52.Tile.HouseGroup ->
            Evergreen.V54.Tile.HouseGroup

        Evergreen.V52.Tile.RailStraightGroup ->
            Evergreen.V54.Tile.RailStraightGroup

        Evergreen.V52.Tile.RailTurnGroup ->
            Evergreen.V54.Tile.RailTurnGroup

        Evergreen.V52.Tile.RailTurnLargeGroup ->
            Evergreen.V54.Tile.RailTurnLargeGroup

        Evergreen.V52.Tile.RailStrafeGroup ->
            Evergreen.V54.Tile.RailStrafeGroup

        Evergreen.V52.Tile.RailStrafeSmallGroup ->
            Evergreen.V54.Tile.RailStrafeSmallGroup

        Evergreen.V52.Tile.RailCrossingGroup ->
            Evergreen.V54.Tile.RailCrossingGroup

        Evergreen.V52.Tile.TrainHouseGroup ->
            Evergreen.V54.Tile.TrainHouseGroup

        Evergreen.V52.Tile.SidewalkGroup ->
            Evergreen.V54.Tile.SidewalkGroup

        Evergreen.V52.Tile.SidewalkRailGroup ->
            Evergreen.V54.Tile.SidewalkRailGroup

        Evergreen.V52.Tile.RailTurnSplitGroup ->
            Evergreen.V54.Tile.RailTurnSplitGroup

        Evergreen.V52.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V54.Tile.RailTurnSplitMirrorGroup

        Evergreen.V52.Tile.PostOfficeGroup ->
            Evergreen.V54.Tile.PostOfficeGroup

        Evergreen.V52.Tile.PineTreeGroup ->
            Evergreen.V54.Tile.PineTreeGroup

        Evergreen.V52.Tile.LogCabinGroup ->
            Evergreen.V54.Tile.LogCabinGroup

        Evergreen.V52.Tile.RoadStraightGroup ->
            Evergreen.V54.Tile.RoadStraightGroup

        Evergreen.V52.Tile.RoadTurnGroup ->
            Evergreen.V54.Tile.RoadTurnGroup

        Evergreen.V52.Tile.Road4WayGroup ->
            Evergreen.V54.Tile.Road4WayGroup

        Evergreen.V52.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V54.Tile.RoadSidewalkCrossingGroup

        Evergreen.V52.Tile.Road3WayGroup ->
            Evergreen.V54.Tile.Road3WayGroup

        Evergreen.V52.Tile.RoadRailCrossingGroup ->
            Evergreen.V54.Tile.RoadRailCrossingGroup

        Evergreen.V52.Tile.RoadDeadendGroup ->
            Evergreen.V54.Tile.RoadDeadendGroup

        Evergreen.V52.Tile.FenceStraightGroup ->
            Evergreen.V54.Tile.FenceStraightGroup

        Evergreen.V52.Tile.BusStopGroup ->
            Evergreen.V54.Tile.BusStopGroup

        Evergreen.V52.Tile.HospitalGroup ->
            Evergreen.V54.Tile.HospitalGroup

        Evergreen.V52.Tile.StatueGroup ->
            Evergreen.V54.Tile.StatueGroup

        Evergreen.V52.Tile.HedgeRowGroup ->
            Evergreen.V54.Tile.HedgeRowGroup

        Evergreen.V52.Tile.HedgeCornerGroup ->
            Evergreen.V54.Tile.HedgeCornerGroup

        Evergreen.V52.Tile.ApartmentGroup ->
            Evergreen.V54.Tile.ApartmentGroup

        Evergreen.V52.Tile.RockGroup ->
            Evergreen.V54.Tile.RockGroup

        Evergreen.V52.Tile.FlowersGroup ->
            Evergreen.V54.Tile.FlowersGroup

        Evergreen.V52.Tile.HedgePillarGroup ->
            Evergreen.V54.Tile.HedgePillarGroup

        Evergreen.V52.Tile.ElmTreeGroup ->
            Evergreen.V54.Tile.ElmTreeGroup

        Evergreen.V52.Tile.DirtPathGroup ->
            Evergreen.V54.Tile.DirtPathGroup


migrateDisplayName : Evergreen.V52.DisplayName.DisplayName -> Evergreen.V54.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V52.DisplayName.DisplayName a ->
            Evergreen.V54.DisplayName.DisplayName a


migrateCursor : Evergreen.V52.LocalGrid.Cursor -> Evergreen.V54.LocalGrid.Cursor
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


migrateContent : Evergreen.V52.MailEditor.Content -> Evergreen.V54.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, image = migrateImage old.image }


migrateColors : Evergreen.V52.Color.Colors -> Evergreen.V54.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V52.Color.Color -> Evergreen.V54.Color.Color
migrateColor old =
    case old of
        Evergreen.V52.Color.Color a ->
            Evergreen.V54.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V52.Types.ViewPoint -> Evergreen.V54.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V52.Types.NormalViewPoint a ->
            Evergreen.V54.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V52.Types.TrainViewPoint a ->
            Evergreen.V54.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V52.Geometry.Types.Point2d old) =
    Evergreen.V54.Geometry.Types.Point2d old


migrateId : Evergreen.V52.Id.Id a -> Evergreen.V54.Id.Id b
migrateId (Evergreen.V52.Id.Id old) =
    Evergreen.V54.Id.Id old
