module Evergreen.Migrate.V59 exposing (..)

import AssocList
import AssocSet
import Dict
import Effect.Time
import Evergreen.V58.Bounds
import Evergreen.V58.Change
import Evergreen.V58.Color
import Evergreen.V58.Cursor
import Evergreen.V58.DisplayName
import Evergreen.V58.EmailAddress
import Evergreen.V58.Geometry.Types
import Evergreen.V58.Grid
import Evergreen.V58.GridCell
import Evergreen.V58.Id
import Evergreen.V58.IdDict
import Evergreen.V58.LocalGrid
import Evergreen.V58.MailEditor
import Evergreen.V58.Postmark
import Evergreen.V58.Tile
import Evergreen.V58.Train
import Evergreen.V58.Types
import Evergreen.V59.Bounds
import Evergreen.V59.Change
import Evergreen.V59.Color
import Evergreen.V59.Coord
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
import IdDict
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Process
import Quantity exposing (Quantity)
import Task
import Time


backendModel : Evergreen.V58.Types.BackendModel -> ModelMigration Evergreen.V59.Types.BackendModel Evergreen.V59.Types.BackendMsg
backendModel old =
    ModelMigrated
        ( migrateBackendModel old
        , Time.now |> Task.perform Evergreen.V59.Types.RegenerateCache
        )


frontendModel : Evergreen.V58.Types.FrontendModel -> ModelMigration Evergreen.V59.Types.FrontendModel Evergreen.V59.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V58.Types.FrontendMsg -> MsgMigration Evergreen.V59.Types.FrontendMsg Evergreen.V59.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V58.Types.BackendMsg -> MsgMigration Evergreen.V59.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V58.Types.BackendError -> Evergreen.V59.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V58.Types.PostmarkError a b ->
            Evergreen.V59.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V58.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V59.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V58.Types.BackendModel -> Evergreen.V59.Types.BackendModel
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


migrateRequestedBy : Evergreen.V58.Types.LoginRequestedBy -> Evergreen.V59.Types.LoginRequestedBy
migrateRequestedBy old =
    case old of
        Evergreen.V58.Types.LoginRequestedByBackend ->
            Evergreen.V59.Types.LoginRequestedByBackend

        Evergreen.V58.Types.LoginRequestedByFrontend sessionId ->
            Evergreen.V59.Types.LoginRequestedByFrontend sessionId


migrateGrid : Evergreen.V58.Grid.Grid -> Evergreen.V59.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V58.Grid.Grid a ->
            Evergreen.V59.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V58.GridCell.Cell -> Evergreen.V59.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V58.GridCell.Cell a ->
            Evergreen.V59.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateDict identity identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V58.GridCell.Value -> Evergreen.V59.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V58.Bounds.Bounds a -> Evergreen.V59.Bounds.Bounds b
migrateBounds (Evergreen.V58.Bounds.Bounds old) =
    Evergreen.V59.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V58.Change.Cow -> Evergreen.V59.Change.Cow
migrateCow old =
    { position = migratePoint2d old.position }


migrateBackendMail : Evergreen.V58.MailEditor.BackendMail -> Evergreen.V59.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V58.MailEditor.MailStatus -> Evergreen.V59.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V58.MailEditor.MailWaitingPickup ->
            Evergreen.V59.MailEditor.MailWaitingPickup

        Evergreen.V58.MailEditor.MailInTransit a ->
            Evergreen.V59.MailEditor.MailInTransit (migrateId a)

        Evergreen.V58.MailEditor.MailReceived a ->
            Evergreen.V59.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V58.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V59.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V58.Types.Invite -> Evergreen.V59.Types.Invite
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


migrateEmailAddress (Evergreen.V58.EmailAddress.EmailAddress old) =
    Evergreen.V59.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V58.Id.SecretId a -> Evergreen.V59.Id.SecretId b
migrateSecretId (Evergreen.V58.Id.SecretId old) =
    Evergreen.V59.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V58.IdDict.IdDict a b -> Evergreen.V59.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V58.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V59.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V58.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V59.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V58.IdDict.NColor -> Evergreen.V59.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V58.IdDict.Red ->
            Evergreen.V59.IdDict.Red

        Evergreen.V58.IdDict.Black ->
            Evergreen.V59.IdDict.Black


migrateBackendUserData : Evergreen.V58.Types.BackendUserData -> Evergreen.V59.Types.BackendUserData
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


migrateEmailResult : Evergreen.V58.Types.EmailResult -> Evergreen.V59.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V58.Types.EmailSending ->
            Evergreen.V59.Types.EmailSending

        Evergreen.V58.Types.EmailSendFailed a ->
            Evergreen.V59.Types.EmailSendFailed a

        Evergreen.V58.Types.EmailSent a ->
            Evergreen.V59.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V58.Postmark.PostmarkSendResponse -> Evergreen.V59.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V58.Tile.Tile -> Evergreen.V59.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V58.Tile.EmptyTile ->
            Evergreen.V59.Tile.EmptyTile

        Evergreen.V58.Tile.HouseDown ->
            Evergreen.V59.Tile.HouseDown

        Evergreen.V58.Tile.HouseRight ->
            Evergreen.V59.Tile.HouseRight

        Evergreen.V58.Tile.HouseUp ->
            Evergreen.V59.Tile.HouseUp

        Evergreen.V58.Tile.HouseLeft ->
            Evergreen.V59.Tile.HouseLeft

        Evergreen.V58.Tile.RailHorizontal ->
            Evergreen.V59.Tile.RailHorizontal

        Evergreen.V58.Tile.RailVertical ->
            Evergreen.V59.Tile.RailVertical

        Evergreen.V58.Tile.RailBottomToRight ->
            Evergreen.V59.Tile.RailBottomToRight

        Evergreen.V58.Tile.RailBottomToLeft ->
            Evergreen.V59.Tile.RailBottomToLeft

        Evergreen.V58.Tile.RailTopToRight ->
            Evergreen.V59.Tile.RailTopToRight

        Evergreen.V58.Tile.RailTopToLeft ->
            Evergreen.V59.Tile.RailTopToLeft

        Evergreen.V58.Tile.RailBottomToRightLarge ->
            Evergreen.V59.Tile.RailBottomToRightLarge

        Evergreen.V58.Tile.RailBottomToLeftLarge ->
            Evergreen.V59.Tile.RailBottomToLeftLarge

        Evergreen.V58.Tile.RailTopToRightLarge ->
            Evergreen.V59.Tile.RailTopToRightLarge

        Evergreen.V58.Tile.RailTopToLeftLarge ->
            Evergreen.V59.Tile.RailTopToLeftLarge

        Evergreen.V58.Tile.RailCrossing ->
            Evergreen.V59.Tile.RailCrossing

        Evergreen.V58.Tile.RailStrafeDown ->
            Evergreen.V59.Tile.RailStrafeDown

        Evergreen.V58.Tile.RailStrafeUp ->
            Evergreen.V59.Tile.RailStrafeUp

        Evergreen.V58.Tile.RailStrafeLeft ->
            Evergreen.V59.Tile.RailStrafeLeft

        Evergreen.V58.Tile.RailStrafeRight ->
            Evergreen.V59.Tile.RailStrafeRight

        Evergreen.V58.Tile.TrainHouseRight ->
            Evergreen.V59.Tile.TrainHouseRight

        Evergreen.V58.Tile.TrainHouseLeft ->
            Evergreen.V59.Tile.TrainHouseLeft

        Evergreen.V58.Tile.RailStrafeDownSmall ->
            Evergreen.V59.Tile.RailStrafeDownSmall

        Evergreen.V58.Tile.RailStrafeUpSmall ->
            Evergreen.V59.Tile.RailStrafeUpSmall

        Evergreen.V58.Tile.RailStrafeLeftSmall ->
            Evergreen.V59.Tile.RailStrafeLeftSmall

        Evergreen.V58.Tile.RailStrafeRightSmall ->
            Evergreen.V59.Tile.RailStrafeRightSmall

        Evergreen.V58.Tile.Sidewalk ->
            Evergreen.V59.Tile.Sidewalk

        Evergreen.V58.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V59.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V58.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V59.Tile.SidewalkVerticalRailCrossing

        Evergreen.V58.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V59.Tile.RailBottomToRight_SplitLeft

        Evergreen.V58.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V59.Tile.RailBottomToLeft_SplitUp

        Evergreen.V58.Tile.RailTopToRight_SplitDown ->
            Evergreen.V59.Tile.RailTopToRight_SplitDown

        Evergreen.V58.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V59.Tile.RailTopToLeft_SplitRight

        Evergreen.V58.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V59.Tile.RailBottomToRight_SplitUp

        Evergreen.V58.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V59.Tile.RailBottomToLeft_SplitRight

        Evergreen.V58.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V59.Tile.RailTopToRight_SplitLeft

        Evergreen.V58.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V59.Tile.RailTopToLeft_SplitDown

        Evergreen.V58.Tile.PostOffice ->
            Evergreen.V59.Tile.PostOffice

        Evergreen.V58.Tile.MowedGrass1 ->
            Evergreen.V59.Tile.MowedGrass1

        Evergreen.V58.Tile.MowedGrass4 ->
            Evergreen.V59.Tile.MowedGrass4

        Evergreen.V58.Tile.LogCabinDown ->
            Evergreen.V59.Tile.LogCabinDown

        Evergreen.V58.Tile.LogCabinRight ->
            Evergreen.V59.Tile.LogCabinRight

        Evergreen.V58.Tile.LogCabinUp ->
            Evergreen.V59.Tile.LogCabinUp

        Evergreen.V58.Tile.LogCabinLeft ->
            Evergreen.V59.Tile.LogCabinLeft

        Evergreen.V58.Tile.RoadHorizontal ->
            Evergreen.V59.Tile.RoadHorizontal

        Evergreen.V58.Tile.RoadVertical ->
            Evergreen.V59.Tile.RoadVertical

        Evergreen.V58.Tile.RoadBottomToLeft ->
            Evergreen.V59.Tile.RoadBottomToLeft

        Evergreen.V58.Tile.RoadTopToLeft ->
            Evergreen.V59.Tile.RoadTopToLeft

        Evergreen.V58.Tile.RoadTopToRight ->
            Evergreen.V59.Tile.RoadTopToRight

        Evergreen.V58.Tile.RoadBottomToRight ->
            Evergreen.V59.Tile.RoadBottomToRight

        Evergreen.V58.Tile.Road4Way ->
            Evergreen.V59.Tile.Road4Way

        Evergreen.V58.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V59.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V58.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V59.Tile.RoadSidewalkCrossingVertical

        Evergreen.V58.Tile.Road3WayDown ->
            Evergreen.V59.Tile.Road3WayDown

        Evergreen.V58.Tile.Road3WayLeft ->
            Evergreen.V59.Tile.Road3WayLeft

        Evergreen.V58.Tile.Road3WayUp ->
            Evergreen.V59.Tile.Road3WayUp

        Evergreen.V58.Tile.Road3WayRight ->
            Evergreen.V59.Tile.Road3WayRight

        Evergreen.V58.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V59.Tile.RoadRailCrossingHorizontal

        Evergreen.V58.Tile.RoadRailCrossingVertical ->
            Evergreen.V59.Tile.RoadRailCrossingVertical

        Evergreen.V58.Tile.FenceHorizontal ->
            Evergreen.V59.Tile.FenceHorizontal

        Evergreen.V58.Tile.FenceVertical ->
            Evergreen.V59.Tile.FenceVertical

        Evergreen.V58.Tile.FenceDiagonal ->
            Evergreen.V59.Tile.FenceDiagonal

        Evergreen.V58.Tile.FenceAntidiagonal ->
            Evergreen.V59.Tile.FenceAntidiagonal

        Evergreen.V58.Tile.RoadDeadendUp ->
            Evergreen.V59.Tile.RoadDeadendUp

        Evergreen.V58.Tile.RoadDeadendDown ->
            Evergreen.V59.Tile.RoadDeadendDown

        Evergreen.V58.Tile.BusStopDown ->
            Evergreen.V59.Tile.BusStopDown

        Evergreen.V58.Tile.BusStopLeft ->
            Evergreen.V59.Tile.BusStopLeft

        Evergreen.V58.Tile.BusStopRight ->
            Evergreen.V59.Tile.BusStopRight

        Evergreen.V58.Tile.BusStopUp ->
            Evergreen.V59.Tile.BusStopUp

        Evergreen.V58.Tile.Hospital ->
            Evergreen.V59.Tile.Hospital

        Evergreen.V58.Tile.Statue ->
            Evergreen.V59.Tile.Statue

        Evergreen.V58.Tile.HedgeRowDown ->
            Evergreen.V59.Tile.HedgeRowDown

        Evergreen.V58.Tile.HedgeRowLeft ->
            Evergreen.V59.Tile.HedgeRowLeft

        Evergreen.V58.Tile.HedgeRowRight ->
            Evergreen.V59.Tile.HedgeRowRight

        Evergreen.V58.Tile.HedgeRowUp ->
            Evergreen.V59.Tile.HedgeRowUp

        Evergreen.V58.Tile.HedgeCornerDownLeft ->
            Evergreen.V59.Tile.HedgeCornerDownLeft

        Evergreen.V58.Tile.HedgeCornerDownRight ->
            Evergreen.V59.Tile.HedgeCornerDownRight

        Evergreen.V58.Tile.HedgeCornerUpLeft ->
            Evergreen.V59.Tile.HedgeCornerUpLeft

        Evergreen.V58.Tile.HedgeCornerUpRight ->
            Evergreen.V59.Tile.HedgeCornerUpRight

        Evergreen.V58.Tile.ApartmentDown ->
            Evergreen.V59.Tile.ApartmentDown

        Evergreen.V58.Tile.ApartmentLeft ->
            Evergreen.V59.Tile.ApartmentLeft

        Evergreen.V58.Tile.ApartmentRight ->
            Evergreen.V59.Tile.ApartmentRight

        Evergreen.V58.Tile.ApartmentUp ->
            Evergreen.V59.Tile.ApartmentUp

        Evergreen.V58.Tile.RockDown ->
            Evergreen.V59.Tile.RockDown

        Evergreen.V58.Tile.RockLeft ->
            Evergreen.V59.Tile.RockLeft

        Evergreen.V58.Tile.RockRight ->
            Evergreen.V59.Tile.RockRight

        Evergreen.V58.Tile.RockUp ->
            Evergreen.V59.Tile.RockUp

        Evergreen.V58.Tile.PineTree1 ->
            Evergreen.V59.Tile.PineTree1

        Evergreen.V58.Tile.PineTree2 ->
            Evergreen.V59.Tile.PineTree2

        Evergreen.V58.Tile.HedgePillarDownLeft ->
            Evergreen.V59.Tile.HedgePillarDownLeft

        Evergreen.V58.Tile.HedgePillarDownRight ->
            Evergreen.V59.Tile.HedgePillarDownRight

        Evergreen.V58.Tile.HedgePillarUpLeft ->
            Evergreen.V59.Tile.HedgePillarUpLeft

        Evergreen.V58.Tile.HedgePillarUpRight ->
            Evergreen.V59.Tile.HedgePillarUpRight

        Evergreen.V58.Tile.Flowers1 ->
            Evergreen.V59.Tile.Flowers1

        Evergreen.V58.Tile.Flowers2 ->
            Evergreen.V59.Tile.Flowers2

        Evergreen.V58.Tile.ElmTree ->
            Evergreen.V59.Tile.ElmTree

        Evergreen.V58.Tile.DirtPathHorizontal ->
            Evergreen.V59.Tile.DirtPathHorizontal

        Evergreen.V58.Tile.DirtPathVertical ->
            Evergreen.V59.Tile.DirtPathVertical

        Evergreen.V58.Tile.BigText char ->
            Evergreen.V59.Tile.BigText char

        Evergreen.V58.Tile.BigPineTree ->
            Evergreen.V59.Tile.BigPineTree

        Evergreen.V58.Tile.Hyperlink ->
            Evergreen.V59.Tile.Hyperlink


migrateTrain : Evergreen.V58.Train.Train -> Evergreen.V59.Train.Train
migrateTrain old =
    case old of
        Evergreen.V58.Train.Train a ->
            Evergreen.V59.Train.Train
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


migrateStatus : Evergreen.V58.Train.Status -> Evergreen.V59.Train.Status
migrateStatus old =
    case old of
        Evergreen.V58.Train.WaitingAtHome ->
            Evergreen.V59.Train.WaitingAtHome

        Evergreen.V58.Train.TeleportingHome a ->
            Evergreen.V59.Train.TeleportingHome (migratePosix a)

        Evergreen.V58.Train.Travelling ->
            Evergreen.V59.Train.Travelling

        Evergreen.V58.Train.StoppedAtPostOffice a ->
            Evergreen.V59.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V58.Tile.RailPath -> Evergreen.V59.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V58.Tile.RailPathHorizontal a ->
            Evergreen.V59.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V58.Tile.RailPathVertical a ->
            Evergreen.V59.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V58.Tile.RailPathBottomToRight ->
            Evergreen.V59.Tile.RailPathBottomToRight

        Evergreen.V58.Tile.RailPathBottomToLeft ->
            Evergreen.V59.Tile.RailPathBottomToLeft

        Evergreen.V58.Tile.RailPathTopToRight ->
            Evergreen.V59.Tile.RailPathTopToRight

        Evergreen.V58.Tile.RailPathTopToLeft ->
            Evergreen.V59.Tile.RailPathTopToLeft

        Evergreen.V58.Tile.RailPathBottomToRightLarge ->
            Evergreen.V59.Tile.RailPathBottomToRightLarge

        Evergreen.V58.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V59.Tile.RailPathBottomToLeftLarge

        Evergreen.V58.Tile.RailPathTopToRightLarge ->
            Evergreen.V59.Tile.RailPathTopToRightLarge

        Evergreen.V58.Tile.RailPathTopToLeftLarge ->
            Evergreen.V59.Tile.RailPathTopToLeftLarge

        Evergreen.V58.Tile.RailPathStrafeDown ->
            Evergreen.V59.Tile.RailPathStrafeDown

        Evergreen.V58.Tile.RailPathStrafeUp ->
            Evergreen.V59.Tile.RailPathStrafeUp

        Evergreen.V58.Tile.RailPathStrafeLeft ->
            Evergreen.V59.Tile.RailPathStrafeLeft

        Evergreen.V58.Tile.RailPathStrafeRight ->
            Evergreen.V59.Tile.RailPathStrafeRight

        Evergreen.V58.Tile.RailPathStrafeDownSmall ->
            Evergreen.V59.Tile.RailPathStrafeDownSmall

        Evergreen.V58.Tile.RailPathStrafeUpSmall ->
            Evergreen.V59.Tile.RailPathStrafeUpSmall

        Evergreen.V58.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V59.Tile.RailPathStrafeLeftSmall

        Evergreen.V58.Tile.RailPathStrafeRightSmall ->
            Evergreen.V59.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V58.Train.PreviousPath -> Evergreen.V59.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V58.MailEditor.Image -> Evergreen.V59.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V58.MailEditor.Stamp a ->
            Evergreen.V59.MailEditor.Stamp (migrateColors a)

        Evergreen.V58.MailEditor.SunglassesEmoji a ->
            Evergreen.V59.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V58.MailEditor.NormalEmoji a ->
            Evergreen.V59.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V58.MailEditor.SadEmoji a ->
            Evergreen.V59.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V58.MailEditor.Cow a ->
            Evergreen.V59.MailEditor.Cow (migrateColors a)

        Evergreen.V58.MailEditor.Man a ->
            Evergreen.V59.MailEditor.Man (migrateColors a)

        Evergreen.V58.MailEditor.TileImage a b c ->
            Evergreen.V59.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V58.MailEditor.Grass ->
            Evergreen.V59.MailEditor.Grass

        Evergreen.V58.MailEditor.DefaultCursor a ->
            Evergreen.V59.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V58.MailEditor.DragCursor a ->
            Evergreen.V59.MailEditor.DragCursor (migrateColors a)

        Evergreen.V58.MailEditor.PinchCursor a ->
            Evergreen.V59.MailEditor.PinchCursor (migrateColors a)

        Evergreen.V58.MailEditor.Line int color ->
            Evergreen.V59.MailEditor.Line int (migrateColor color)


migrateTileGroup : Evergreen.V58.Tile.TileGroup -> Evergreen.V59.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V58.Tile.EmptyTileGroup ->
            Evergreen.V59.Tile.EmptyTileGroup

        Evergreen.V58.Tile.HouseGroup ->
            Evergreen.V59.Tile.HouseGroup

        Evergreen.V58.Tile.RailStraightGroup ->
            Evergreen.V59.Tile.RailStraightGroup

        Evergreen.V58.Tile.RailTurnGroup ->
            Evergreen.V59.Tile.RailTurnGroup

        Evergreen.V58.Tile.RailTurnLargeGroup ->
            Evergreen.V59.Tile.RailTurnLargeGroup

        Evergreen.V58.Tile.RailStrafeGroup ->
            Evergreen.V59.Tile.RailStrafeGroup

        Evergreen.V58.Tile.RailStrafeSmallGroup ->
            Evergreen.V59.Tile.RailStrafeSmallGroup

        Evergreen.V58.Tile.RailCrossingGroup ->
            Evergreen.V59.Tile.RailCrossingGroup

        Evergreen.V58.Tile.TrainHouseGroup ->
            Evergreen.V59.Tile.TrainHouseGroup

        Evergreen.V58.Tile.SidewalkGroup ->
            Evergreen.V59.Tile.SidewalkGroup

        Evergreen.V58.Tile.SidewalkRailGroup ->
            Evergreen.V59.Tile.SidewalkRailGroup

        Evergreen.V58.Tile.RailTurnSplitGroup ->
            Evergreen.V59.Tile.RailTurnSplitGroup

        Evergreen.V58.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V59.Tile.RailTurnSplitMirrorGroup

        Evergreen.V58.Tile.PostOfficeGroup ->
            Evergreen.V59.Tile.PostOfficeGroup

        Evergreen.V58.Tile.PineTreeGroup ->
            Evergreen.V59.Tile.PineTreeGroup

        Evergreen.V58.Tile.LogCabinGroup ->
            Evergreen.V59.Tile.LogCabinGroup

        Evergreen.V58.Tile.RoadStraightGroup ->
            Evergreen.V59.Tile.RoadStraightGroup

        Evergreen.V58.Tile.RoadTurnGroup ->
            Evergreen.V59.Tile.RoadTurnGroup

        Evergreen.V58.Tile.Road4WayGroup ->
            Evergreen.V59.Tile.Road4WayGroup

        Evergreen.V58.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V59.Tile.RoadSidewalkCrossingGroup

        Evergreen.V58.Tile.Road3WayGroup ->
            Evergreen.V59.Tile.Road3WayGroup

        Evergreen.V58.Tile.RoadRailCrossingGroup ->
            Evergreen.V59.Tile.RoadRailCrossingGroup

        Evergreen.V58.Tile.RoadDeadendGroup ->
            Evergreen.V59.Tile.RoadDeadendGroup

        Evergreen.V58.Tile.FenceStraightGroup ->
            Evergreen.V59.Tile.FenceStraightGroup

        Evergreen.V58.Tile.BusStopGroup ->
            Evergreen.V59.Tile.BusStopGroup

        Evergreen.V58.Tile.HospitalGroup ->
            Evergreen.V59.Tile.HospitalGroup

        Evergreen.V58.Tile.StatueGroup ->
            Evergreen.V59.Tile.StatueGroup

        Evergreen.V58.Tile.HedgeRowGroup ->
            Evergreen.V59.Tile.HedgeRowGroup

        Evergreen.V58.Tile.HedgeCornerGroup ->
            Evergreen.V59.Tile.HedgeCornerGroup

        Evergreen.V58.Tile.ApartmentGroup ->
            Evergreen.V59.Tile.ApartmentGroup

        Evergreen.V58.Tile.RockGroup ->
            Evergreen.V59.Tile.RockGroup

        Evergreen.V58.Tile.FlowersGroup ->
            Evergreen.V59.Tile.FlowersGroup

        Evergreen.V58.Tile.HedgePillarGroup ->
            Evergreen.V59.Tile.HedgePillarGroup

        Evergreen.V58.Tile.ElmTreeGroup ->
            Evergreen.V59.Tile.ElmTreeGroup

        Evergreen.V58.Tile.DirtPathGroup ->
            Evergreen.V59.Tile.DirtPathGroup

        Evergreen.V58.Tile.BigTextGroup ->
            Evergreen.V59.Tile.BigTextGroup

        Evergreen.V58.Tile.BigPineTreeGroup ->
            Evergreen.V59.Tile.BigPineTreeGroup

        Evergreen.V58.Tile.HyperlinkGroup ->
            Evergreen.V59.Tile.HyperlinkGroup


migrateDisplayName : Evergreen.V58.DisplayName.DisplayName -> Evergreen.V59.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V58.DisplayName.DisplayName a ->
            Evergreen.V59.DisplayName.DisplayName a


migrateCursor : Evergreen.V58.Cursor.Cursor -> Evergreen.V59.Cursor.Cursor
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
        Evergreen.V59.Cursor.HandTool
    }


migrateContent : Evergreen.V58.MailEditor.Content -> Evergreen.V59.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, item = migrateImageOrText old.item }


migrateImageOrText : Evergreen.V58.MailEditor.ImageOrText -> Evergreen.V59.MailEditor.ImageOrText
migrateImageOrText old =
    case old of
        Evergreen.V58.MailEditor.ImageType imageType ->
            migrateImage imageType |> Evergreen.V59.MailEditor.ImageType

        Evergreen.V58.MailEditor.TextType string ->
            Evergreen.V59.MailEditor.TextType string


migrateColors : Evergreen.V58.Color.Colors -> Evergreen.V59.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V58.Color.Color -> Evergreen.V59.Color.Color
migrateColor old =
    case old of
        Evergreen.V58.Color.Color a ->
            Evergreen.V59.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V58.Types.ViewPoint -> Evergreen.V59.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V58.Types.NormalViewPoint a ->
            Evergreen.V59.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V58.Types.TrainViewPoint a ->
            Evergreen.V59.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V58.Geometry.Types.Point2d old) =
    Evergreen.V59.Geometry.Types.Point2d old


migrateId : Evergreen.V58.Id.Id a -> Evergreen.V59.Id.Id b
migrateId (Evergreen.V58.Id.Id old) =
    Evergreen.V59.Id.Id old
