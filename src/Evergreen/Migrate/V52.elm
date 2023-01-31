module Evergreen.Migrate.V52 exposing (..)

import AssocList
import AssocSet
import Dict
import Effect.Time
import Evergreen.V50.Bounds
import Evergreen.V50.Change
import Evergreen.V50.Color
import Evergreen.V50.DisplayName
import Evergreen.V50.EmailAddress
import Evergreen.V50.Geometry.Types
import Evergreen.V50.Grid
import Evergreen.V50.GridCell
import Evergreen.V50.Id
import Evergreen.V50.IdDict
import Evergreen.V50.LocalGrid
import Evergreen.V50.MailEditor
import Evergreen.V50.Postmark
import Evergreen.V50.Tile
import Evergreen.V50.Train
import Evergreen.V50.Types
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
import IdDict
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Quantity


backendModel : Evergreen.V50.Types.BackendModel -> ModelMigration Evergreen.V52.Types.BackendModel Evergreen.V52.Types.BackendMsg
backendModel old =
    ModelMigrated ( migrateBackendModel old, Cmd.none )


frontendModel : Evergreen.V50.Types.FrontendModel -> ModelMigration Evergreen.V52.Types.FrontendModel Evergreen.V52.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V50.Types.FrontendMsg -> MsgMigration Evergreen.V52.Types.FrontendMsg Evergreen.V52.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V50.Types.BackendMsg -> MsgMigration Evergreen.V52.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V50.Types.BackendError -> Evergreen.V52.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V50.Types.PostmarkError a b ->
            Evergreen.V52.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V50.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V52.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V50.Types.BackendModel -> Evergreen.V52.Types.BackendModel
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
                , requestedBy = Evergreen.V52.Types.LoginRequestedByFrontend a.requestedBy
                }
            )
            old.pendingLoginTokens
    , invites = migrateAssocList migrateSecretId migrateInvite old.invites
    }


migrateGrid : Evergreen.V50.Grid.Grid -> Evergreen.V52.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V50.Grid.Grid a ->
            Evergreen.V52.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V50.GridCell.Cell -> Evergreen.V52.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V50.GridCell.Cell a ->
            Evergreen.V52.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateDict identity identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V50.GridCell.Value -> Evergreen.V52.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V50.Bounds.Bounds a -> Evergreen.V52.Bounds.Bounds b
migrateBounds (Evergreen.V50.Bounds.Bounds old) =
    Evergreen.V52.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V50.Change.Cow -> Evergreen.V52.Change.Cow
migrateCow old =
    { position = migratePoint2d old.position }


migrateBackendMail : Evergreen.V50.MailEditor.BackendMail -> Evergreen.V52.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V50.MailEditor.MailStatus -> Evergreen.V52.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V50.MailEditor.MailWaitingPickup ->
            Evergreen.V52.MailEditor.MailWaitingPickup

        Evergreen.V50.MailEditor.MailInTransit a ->
            Evergreen.V52.MailEditor.MailInTransit (migrateId a)

        Evergreen.V50.MailEditor.MailReceived a ->
            Evergreen.V52.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V50.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V52.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V50.Types.Invite -> Evergreen.V52.Types.Invite
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


migrateEmailAddress (Evergreen.V50.EmailAddress.EmailAddress old) =
    Evergreen.V52.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V50.Id.SecretId a -> Evergreen.V52.Id.SecretId b
migrateSecretId (Evergreen.V50.Id.SecretId old) =
    Evergreen.V52.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V50.IdDict.IdDict a b -> Evergreen.V52.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V50.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V52.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V50.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V52.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V50.IdDict.NColor -> Evergreen.V52.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V50.IdDict.Red ->
            Evergreen.V52.IdDict.Red

        Evergreen.V50.IdDict.Black ->
            Evergreen.V52.IdDict.Black


migrateBackendUserData : Evergreen.V50.Types.BackendUserData -> Evergreen.V52.Types.BackendUserData
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


migrateEmailResult : Evergreen.V50.Types.EmailResult -> Evergreen.V52.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V50.Types.EmailSending ->
            Evergreen.V52.Types.EmailSending

        Evergreen.V50.Types.EmailSendFailed a ->
            Evergreen.V52.Types.EmailSendFailed a

        Evergreen.V50.Types.EmailSent a ->
            Evergreen.V52.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V50.Postmark.PostmarkSendResponse -> Evergreen.V52.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V50.Tile.Tile -> Evergreen.V52.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V50.Tile.EmptyTile ->
            Evergreen.V52.Tile.EmptyTile

        Evergreen.V50.Tile.HouseDown ->
            Evergreen.V52.Tile.HouseDown

        Evergreen.V50.Tile.HouseRight ->
            Evergreen.V52.Tile.HouseRight

        Evergreen.V50.Tile.HouseUp ->
            Evergreen.V52.Tile.HouseUp

        Evergreen.V50.Tile.HouseLeft ->
            Evergreen.V52.Tile.HouseLeft

        Evergreen.V50.Tile.RailHorizontal ->
            Evergreen.V52.Tile.RailHorizontal

        Evergreen.V50.Tile.RailVertical ->
            Evergreen.V52.Tile.RailVertical

        Evergreen.V50.Tile.RailBottomToRight ->
            Evergreen.V52.Tile.RailBottomToRight

        Evergreen.V50.Tile.RailBottomToLeft ->
            Evergreen.V52.Tile.RailBottomToLeft

        Evergreen.V50.Tile.RailTopToRight ->
            Evergreen.V52.Tile.RailTopToRight

        Evergreen.V50.Tile.RailTopToLeft ->
            Evergreen.V52.Tile.RailTopToLeft

        Evergreen.V50.Tile.RailBottomToRightLarge ->
            Evergreen.V52.Tile.RailBottomToRightLarge

        Evergreen.V50.Tile.RailBottomToLeftLarge ->
            Evergreen.V52.Tile.RailBottomToLeftLarge

        Evergreen.V50.Tile.RailTopToRightLarge ->
            Evergreen.V52.Tile.RailTopToRightLarge

        Evergreen.V50.Tile.RailTopToLeftLarge ->
            Evergreen.V52.Tile.RailTopToLeftLarge

        Evergreen.V50.Tile.RailCrossing ->
            Evergreen.V52.Tile.RailCrossing

        Evergreen.V50.Tile.RailStrafeDown ->
            Evergreen.V52.Tile.RailStrafeDown

        Evergreen.V50.Tile.RailStrafeUp ->
            Evergreen.V52.Tile.RailStrafeUp

        Evergreen.V50.Tile.RailStrafeLeft ->
            Evergreen.V52.Tile.RailStrafeLeft

        Evergreen.V50.Tile.RailStrafeRight ->
            Evergreen.V52.Tile.RailStrafeRight

        Evergreen.V50.Tile.TrainHouseRight ->
            Evergreen.V52.Tile.TrainHouseRight

        Evergreen.V50.Tile.TrainHouseLeft ->
            Evergreen.V52.Tile.TrainHouseLeft

        Evergreen.V50.Tile.RailStrafeDownSmall ->
            Evergreen.V52.Tile.RailStrafeDownSmall

        Evergreen.V50.Tile.RailStrafeUpSmall ->
            Evergreen.V52.Tile.RailStrafeUpSmall

        Evergreen.V50.Tile.RailStrafeLeftSmall ->
            Evergreen.V52.Tile.RailStrafeLeftSmall

        Evergreen.V50.Tile.RailStrafeRightSmall ->
            Evergreen.V52.Tile.RailStrafeRightSmall

        Evergreen.V50.Tile.Sidewalk ->
            Evergreen.V52.Tile.Sidewalk

        Evergreen.V50.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V52.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V50.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V52.Tile.SidewalkVerticalRailCrossing

        Evergreen.V50.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V52.Tile.RailBottomToRight_SplitLeft

        Evergreen.V50.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V52.Tile.RailBottomToLeft_SplitUp

        Evergreen.V50.Tile.RailTopToRight_SplitDown ->
            Evergreen.V52.Tile.RailTopToRight_SplitDown

        Evergreen.V50.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V52.Tile.RailTopToLeft_SplitRight

        Evergreen.V50.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V52.Tile.RailBottomToRight_SplitUp

        Evergreen.V50.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V52.Tile.RailBottomToLeft_SplitRight

        Evergreen.V50.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V52.Tile.RailTopToRight_SplitLeft

        Evergreen.V50.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V52.Tile.RailTopToLeft_SplitDown

        Evergreen.V50.Tile.PostOffice ->
            Evergreen.V52.Tile.PostOffice

        Evergreen.V50.Tile.MowedGrass1 ->
            Evergreen.V52.Tile.MowedGrass1

        Evergreen.V50.Tile.MowedGrass4 ->
            Evergreen.V52.Tile.MowedGrass4

        Evergreen.V50.Tile.LogCabinDown ->
            Evergreen.V52.Tile.LogCabinDown

        Evergreen.V50.Tile.LogCabinRight ->
            Evergreen.V52.Tile.LogCabinRight

        Evergreen.V50.Tile.LogCabinUp ->
            Evergreen.V52.Tile.LogCabinUp

        Evergreen.V50.Tile.LogCabinLeft ->
            Evergreen.V52.Tile.LogCabinLeft

        Evergreen.V50.Tile.RoadHorizontal ->
            Evergreen.V52.Tile.RoadHorizontal

        Evergreen.V50.Tile.RoadVertical ->
            Evergreen.V52.Tile.RoadVertical

        Evergreen.V50.Tile.RoadBottomToLeft ->
            Evergreen.V52.Tile.RoadBottomToLeft

        Evergreen.V50.Tile.RoadTopToLeft ->
            Evergreen.V52.Tile.RoadTopToLeft

        Evergreen.V50.Tile.RoadTopToRight ->
            Evergreen.V52.Tile.RoadTopToRight

        Evergreen.V50.Tile.RoadBottomToRight ->
            Evergreen.V52.Tile.RoadBottomToRight

        Evergreen.V50.Tile.Road4Way ->
            Evergreen.V52.Tile.Road4Way

        Evergreen.V50.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V52.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V50.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V52.Tile.RoadSidewalkCrossingVertical

        Evergreen.V50.Tile.Road3WayDown ->
            Evergreen.V52.Tile.Road3WayDown

        Evergreen.V50.Tile.Road3WayLeft ->
            Evergreen.V52.Tile.Road3WayLeft

        Evergreen.V50.Tile.Road3WayUp ->
            Evergreen.V52.Tile.Road3WayUp

        Evergreen.V50.Tile.Road3WayRight ->
            Evergreen.V52.Tile.Road3WayRight

        Evergreen.V50.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V52.Tile.RoadRailCrossingHorizontal

        Evergreen.V50.Tile.RoadRailCrossingVertical ->
            Evergreen.V52.Tile.RoadRailCrossingVertical

        Evergreen.V50.Tile.FenceHorizontal ->
            Evergreen.V52.Tile.FenceHorizontal

        Evergreen.V50.Tile.FenceVertical ->
            Evergreen.V52.Tile.FenceVertical

        Evergreen.V50.Tile.FenceDiagonal ->
            Evergreen.V52.Tile.FenceDiagonal

        Evergreen.V50.Tile.FenceAntidiagonal ->
            Evergreen.V52.Tile.FenceAntidiagonal

        Evergreen.V50.Tile.RoadDeadendUp ->
            Evergreen.V52.Tile.RoadDeadendUp

        Evergreen.V50.Tile.RoadDeadendDown ->
            Evergreen.V52.Tile.RoadDeadendDown

        Evergreen.V50.Tile.BusStopDown ->
            Evergreen.V52.Tile.BusStopDown

        Evergreen.V50.Tile.BusStopLeft ->
            Evergreen.V52.Tile.BusStopLeft

        Evergreen.V50.Tile.BusStopRight ->
            Evergreen.V52.Tile.BusStopRight

        Evergreen.V50.Tile.BusStopUp ->
            Evergreen.V52.Tile.BusStopUp

        Evergreen.V50.Tile.Hospital ->
            Evergreen.V52.Tile.Hospital

        Evergreen.V50.Tile.Statue ->
            Evergreen.V52.Tile.Statue

        Evergreen.V50.Tile.HedgeRowDown ->
            Evergreen.V52.Tile.HedgeRowDown

        Evergreen.V50.Tile.HedgeRowLeft ->
            Evergreen.V52.Tile.HedgeRowLeft

        Evergreen.V50.Tile.HedgeRowRight ->
            Evergreen.V52.Tile.HedgeRowRight

        Evergreen.V50.Tile.HedgeRowUp ->
            Evergreen.V52.Tile.HedgeRowUp

        Evergreen.V50.Tile.HedgeCornerDownLeft ->
            Evergreen.V52.Tile.HedgeCornerDownLeft

        Evergreen.V50.Tile.HedgeCornerDownRight ->
            Evergreen.V52.Tile.HedgeCornerDownRight

        Evergreen.V50.Tile.HedgeCornerUpLeft ->
            Evergreen.V52.Tile.HedgeCornerUpLeft

        Evergreen.V50.Tile.HedgeCornerUpRight ->
            Evergreen.V52.Tile.HedgeCornerUpRight

        Evergreen.V50.Tile.ApartmentDown ->
            Evergreen.V52.Tile.ApartmentDown

        Evergreen.V50.Tile.ApartmentLeft ->
            Evergreen.V52.Tile.ApartmentLeft

        Evergreen.V50.Tile.ApartmentRight ->
            Evergreen.V52.Tile.ApartmentRight

        Evergreen.V50.Tile.ApartmentUp ->
            Evergreen.V52.Tile.ApartmentUp

        Evergreen.V50.Tile.RockDown ->
            Evergreen.V52.Tile.RockDown

        Evergreen.V50.Tile.RockLeft ->
            Evergreen.V52.Tile.RockLeft

        Evergreen.V50.Tile.RockRight ->
            Evergreen.V52.Tile.RockRight

        Evergreen.V50.Tile.RockUp ->
            Evergreen.V52.Tile.RockUp

        Evergreen.V50.Tile.PineTree1 ->
            Evergreen.V52.Tile.PineTree1

        Evergreen.V50.Tile.PineTree2 ->
            Evergreen.V52.Tile.PineTree2

        Evergreen.V50.Tile.HedgePillarDownLeft ->
            Evergreen.V52.Tile.HedgePillarDownLeft

        Evergreen.V50.Tile.HedgePillarDownRight ->
            Evergreen.V52.Tile.HedgePillarDownRight

        Evergreen.V50.Tile.HedgePillarUpLeft ->
            Evergreen.V52.Tile.HedgePillarUpLeft

        Evergreen.V50.Tile.HedgePillarUpRight ->
            Evergreen.V52.Tile.HedgePillarUpRight

        Evergreen.V50.Tile.Flowers1 ->
            Evergreen.V52.Tile.Flowers1

        Evergreen.V50.Tile.Flowers2 ->
            Evergreen.V52.Tile.Flowers2

        Evergreen.V50.Tile.ElmTree ->
            Evergreen.V52.Tile.ElmTree

        Evergreen.V50.Tile.DirtPathHorizontal ->
            Evergreen.V52.Tile.DirtPathHorizontal

        Evergreen.V50.Tile.DirtPathVertical ->
            Evergreen.V52.Tile.DirtPathVertical


migrateTrain : Evergreen.V50.Train.Train -> Evergreen.V52.Train.Train
migrateTrain old =
    case old of
        Evergreen.V50.Train.Train a ->
            Evergreen.V52.Train.Train
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


migrateStatus : Evergreen.V50.Train.Status -> Evergreen.V52.Train.Status
migrateStatus old =
    case old of
        Evergreen.V50.Train.WaitingAtHome ->
            Evergreen.V52.Train.WaitingAtHome

        Evergreen.V50.Train.TeleportingHome a ->
            Evergreen.V52.Train.TeleportingHome (migratePosix a)

        Evergreen.V50.Train.Travelling ->
            Evergreen.V52.Train.Travelling

        Evergreen.V50.Train.StoppedAtPostOffice a ->
            Evergreen.V52.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V50.Tile.RailPath -> Evergreen.V52.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V50.Tile.RailPathHorizontal a ->
            Evergreen.V52.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V50.Tile.RailPathVertical a ->
            Evergreen.V52.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V50.Tile.RailPathBottomToRight ->
            Evergreen.V52.Tile.RailPathBottomToRight

        Evergreen.V50.Tile.RailPathBottomToLeft ->
            Evergreen.V52.Tile.RailPathBottomToLeft

        Evergreen.V50.Tile.RailPathTopToRight ->
            Evergreen.V52.Tile.RailPathTopToRight

        Evergreen.V50.Tile.RailPathTopToLeft ->
            Evergreen.V52.Tile.RailPathTopToLeft

        Evergreen.V50.Tile.RailPathBottomToRightLarge ->
            Evergreen.V52.Tile.RailPathBottomToRightLarge

        Evergreen.V50.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V52.Tile.RailPathBottomToLeftLarge

        Evergreen.V50.Tile.RailPathTopToRightLarge ->
            Evergreen.V52.Tile.RailPathTopToRightLarge

        Evergreen.V50.Tile.RailPathTopToLeftLarge ->
            Evergreen.V52.Tile.RailPathTopToLeftLarge

        Evergreen.V50.Tile.RailPathStrafeDown ->
            Evergreen.V52.Tile.RailPathStrafeDown

        Evergreen.V50.Tile.RailPathStrafeUp ->
            Evergreen.V52.Tile.RailPathStrafeUp

        Evergreen.V50.Tile.RailPathStrafeLeft ->
            Evergreen.V52.Tile.RailPathStrafeLeft

        Evergreen.V50.Tile.RailPathStrafeRight ->
            Evergreen.V52.Tile.RailPathStrafeRight

        Evergreen.V50.Tile.RailPathStrafeDownSmall ->
            Evergreen.V52.Tile.RailPathStrafeDownSmall

        Evergreen.V50.Tile.RailPathStrafeUpSmall ->
            Evergreen.V52.Tile.RailPathStrafeUpSmall

        Evergreen.V50.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V52.Tile.RailPathStrafeLeftSmall

        Evergreen.V50.Tile.RailPathStrafeRightSmall ->
            Evergreen.V52.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V50.Train.PreviousPath -> Evergreen.V52.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V50.MailEditor.Image -> Evergreen.V52.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V50.MailEditor.Stamp a ->
            Evergreen.V52.MailEditor.Stamp (migrateColors a)

        Evergreen.V50.MailEditor.SunglassesEmoji a ->
            Evergreen.V52.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V50.MailEditor.NormalEmoji a ->
            Evergreen.V52.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V50.MailEditor.SadEmoji a ->
            Evergreen.V52.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V50.MailEditor.Cow a ->
            Evergreen.V52.MailEditor.Cow (migrateColors a)

        Evergreen.V50.MailEditor.Man a ->
            Evergreen.V52.MailEditor.Man (migrateColors a)

        Evergreen.V50.MailEditor.TileImage a b c ->
            Evergreen.V52.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V50.MailEditor.Grass ->
            Evergreen.V52.MailEditor.Grass

        Evergreen.V50.MailEditor.DefaultCursor a ->
            Evergreen.V52.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V50.MailEditor.DragCursor a ->
            Evergreen.V52.MailEditor.DragCursor (migrateColors a)

        Evergreen.V50.MailEditor.PinchCursor a ->
            Evergreen.V52.MailEditor.PinchCursor (migrateColors a)

        Evergreen.V50.MailEditor.Line int color ->
            Evergreen.V52.MailEditor.Line int (migrateColor color)


migrateTileGroup : Evergreen.V50.Tile.TileGroup -> Evergreen.V52.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V50.Tile.EmptyTileGroup ->
            Evergreen.V52.Tile.EmptyTileGroup

        Evergreen.V50.Tile.HouseGroup ->
            Evergreen.V52.Tile.HouseGroup

        Evergreen.V50.Tile.RailStraightGroup ->
            Evergreen.V52.Tile.RailStraightGroup

        Evergreen.V50.Tile.RailTurnGroup ->
            Evergreen.V52.Tile.RailTurnGroup

        Evergreen.V50.Tile.RailTurnLargeGroup ->
            Evergreen.V52.Tile.RailTurnLargeGroup

        Evergreen.V50.Tile.RailStrafeGroup ->
            Evergreen.V52.Tile.RailStrafeGroup

        Evergreen.V50.Tile.RailStrafeSmallGroup ->
            Evergreen.V52.Tile.RailStrafeSmallGroup

        Evergreen.V50.Tile.RailCrossingGroup ->
            Evergreen.V52.Tile.RailCrossingGroup

        Evergreen.V50.Tile.TrainHouseGroup ->
            Evergreen.V52.Tile.TrainHouseGroup

        Evergreen.V50.Tile.SidewalkGroup ->
            Evergreen.V52.Tile.SidewalkGroup

        Evergreen.V50.Tile.SidewalkRailGroup ->
            Evergreen.V52.Tile.SidewalkRailGroup

        Evergreen.V50.Tile.RailTurnSplitGroup ->
            Evergreen.V52.Tile.RailTurnSplitGroup

        Evergreen.V50.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V52.Tile.RailTurnSplitMirrorGroup

        Evergreen.V50.Tile.PostOfficeGroup ->
            Evergreen.V52.Tile.PostOfficeGroup

        Evergreen.V50.Tile.PineTreeGroup ->
            Evergreen.V52.Tile.PineTreeGroup

        Evergreen.V50.Tile.LogCabinGroup ->
            Evergreen.V52.Tile.LogCabinGroup

        Evergreen.V50.Tile.RoadStraightGroup ->
            Evergreen.V52.Tile.RoadStraightGroup

        Evergreen.V50.Tile.RoadTurnGroup ->
            Evergreen.V52.Tile.RoadTurnGroup

        Evergreen.V50.Tile.Road4WayGroup ->
            Evergreen.V52.Tile.Road4WayGroup

        Evergreen.V50.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V52.Tile.RoadSidewalkCrossingGroup

        Evergreen.V50.Tile.Road3WayGroup ->
            Evergreen.V52.Tile.Road3WayGroup

        Evergreen.V50.Tile.RoadRailCrossingGroup ->
            Evergreen.V52.Tile.RoadRailCrossingGroup

        Evergreen.V50.Tile.RoadDeadendGroup ->
            Evergreen.V52.Tile.RoadDeadendGroup

        Evergreen.V50.Tile.FenceStraightGroup ->
            Evergreen.V52.Tile.FenceStraightGroup

        Evergreen.V50.Tile.BusStopGroup ->
            Evergreen.V52.Tile.BusStopGroup

        Evergreen.V50.Tile.HospitalGroup ->
            Evergreen.V52.Tile.HospitalGroup

        Evergreen.V50.Tile.StatueGroup ->
            Evergreen.V52.Tile.StatueGroup

        Evergreen.V50.Tile.HedgeRowGroup ->
            Evergreen.V52.Tile.HedgeRowGroup

        Evergreen.V50.Tile.HedgeCornerGroup ->
            Evergreen.V52.Tile.HedgeCornerGroup

        Evergreen.V50.Tile.ApartmentGroup ->
            Evergreen.V52.Tile.ApartmentGroup

        Evergreen.V50.Tile.RockGroup ->
            Evergreen.V52.Tile.RockGroup

        Evergreen.V50.Tile.FlowersGroup ->
            Evergreen.V52.Tile.FlowersGroup

        Evergreen.V50.Tile.HedgePillarGroup ->
            Evergreen.V52.Tile.HedgePillarGroup

        Evergreen.V50.Tile.ElmTreeGroup ->
            Evergreen.V52.Tile.ElmTreeGroup

        Evergreen.V50.Tile.DirtPathGroup ->
            Evergreen.V52.Tile.DirtPathGroup


migrateDisplayName : Evergreen.V50.DisplayName.DisplayName -> Evergreen.V52.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V50.DisplayName.DisplayName a ->
            Evergreen.V52.DisplayName.DisplayName a


migrateCursor : Evergreen.V50.LocalGrid.Cursor -> Evergreen.V52.LocalGrid.Cursor
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


migrateContent : Evergreen.V50.MailEditor.Content -> Evergreen.V52.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, image = migrateImage old.image }


migrateColors : Evergreen.V50.Color.Colors -> Evergreen.V52.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V50.Color.Color -> Evergreen.V52.Color.Color
migrateColor old =
    case old of
        Evergreen.V50.Color.Color a ->
            Evergreen.V52.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V50.Types.ViewPoint -> Evergreen.V52.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V50.Types.NormalViewPoint a ->
            Evergreen.V52.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V50.Types.TrainViewPoint a ->
            Evergreen.V52.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V50.Geometry.Types.Point2d old) =
    Evergreen.V52.Geometry.Types.Point2d old


migrateId : Evergreen.V50.Id.Id a -> Evergreen.V52.Id.Id b
migrateId (Evergreen.V50.Id.Id old) =
    Evergreen.V52.Id.Id old
