module Evergreen.Migrate.V49 exposing (..)

import AssocList
import AssocSet
import Dict
import Effect.Time
import Evergreen.V48.Bounds
import Evergreen.V48.Change
import Evergreen.V48.Color
import Evergreen.V48.DisplayName
import Evergreen.V48.EmailAddress
import Evergreen.V48.Geometry.Types
import Evergreen.V48.Grid
import Evergreen.V48.GridCell
import Evergreen.V48.Id
import Evergreen.V48.IdDict
import Evergreen.V48.LocalGrid
import Evergreen.V48.MailEditor
import Evergreen.V48.Postmark
import Evergreen.V48.Tile
import Evergreen.V48.Train
import Evergreen.V48.Types
import Evergreen.V49.Bounds
import Evergreen.V49.Change
import Evergreen.V49.Color
import Evergreen.V49.DisplayName
import Evergreen.V49.EmailAddress
import Evergreen.V49.Geometry.Types
import Evergreen.V49.Grid
import Evergreen.V49.GridCell
import Evergreen.V49.Id
import Evergreen.V49.IdDict
import Evergreen.V49.LocalGrid
import Evergreen.V49.MailEditor
import Evergreen.V49.Postmark
import Evergreen.V49.Tile
import Evergreen.V49.Train
import Evergreen.V49.Types
import IdDict
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Quantity


backendModel : Evergreen.V48.Types.BackendModel -> ModelMigration Evergreen.V49.Types.BackendModel Evergreen.V49.Types.BackendMsg
backendModel old =
    ModelMigrated ( migrateBackendModel old, Cmd.none )


frontendModel : Evergreen.V48.Types.FrontendModel -> ModelMigration Evergreen.V49.Types.FrontendModel Evergreen.V49.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V48.Types.FrontendMsg -> MsgMigration Evergreen.V49.Types.FrontendMsg Evergreen.V49.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V48.Types.BackendMsg -> MsgMigration Evergreen.V49.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V48.Types.BackendError -> Evergreen.V49.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V48.Types.PostmarkError a b ->
            Evergreen.V49.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V48.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V49.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V48.Types.BackendModel -> Evergreen.V49.Types.BackendModel
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
                , requestedBy = a.requestedBy
                }
            )
            old.pendingLoginTokens
    , invites = migrateAssocList migrateSecretId migrateInvite old.invites
    }


migrateGrid : Evergreen.V48.Grid.Grid -> Evergreen.V49.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V48.Grid.Grid a ->
            Evergreen.V49.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V48.GridCell.Cell -> Evergreen.V49.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V48.GridCell.Cell a ->
            Evergreen.V49.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateDict identity identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V48.GridCell.Value -> Evergreen.V49.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V48.Bounds.Bounds a -> Evergreen.V49.Bounds.Bounds b
migrateBounds (Evergreen.V48.Bounds.Bounds old) =
    Evergreen.V49.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V48.Change.Cow -> Evergreen.V49.Change.Cow
migrateCow old =
    { position = migratePoint2d old.position }


migrateBackendMail : Evergreen.V48.MailEditor.BackendMail -> Evergreen.V49.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V48.MailEditor.MailStatus -> Evergreen.V49.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V48.MailEditor.MailWaitingPickup ->
            Evergreen.V49.MailEditor.MailWaitingPickup

        Evergreen.V48.MailEditor.MailInTransit a ->
            Evergreen.V49.MailEditor.MailInTransit (migrateId a)

        Evergreen.V48.MailEditor.MailReceived a ->
            Evergreen.V49.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V48.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V49.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V48.Types.Invite -> Evergreen.V49.Types.Invite
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


migrateEmailAddress (Evergreen.V48.EmailAddress.EmailAddress old) =
    Evergreen.V49.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V48.Id.SecretId a -> Evergreen.V49.Id.SecretId b
migrateSecretId (Evergreen.V48.Id.SecretId old) =
    Evergreen.V49.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V48.IdDict.IdDict a b -> Evergreen.V49.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V48.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V49.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V48.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V49.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V48.IdDict.NColor -> Evergreen.V49.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V48.IdDict.Red ->
            Evergreen.V49.IdDict.Red

        Evergreen.V48.IdDict.Black ->
            Evergreen.V49.IdDict.Black


migrateBackendUserData : Evergreen.V48.Types.BackendUserData -> Evergreen.V49.Types.BackendUserData
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
    , sendEmailWhenReceivingALetter = old.sendEmailWhenReceivingALetter
    }


migrateRawCellCoord =
    identity


migrateEmailResult : Evergreen.V48.Types.EmailResult -> Evergreen.V49.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V48.Types.EmailSending ->
            Evergreen.V49.Types.EmailSending

        Evergreen.V48.Types.EmailSendFailed a ->
            Evergreen.V49.Types.EmailSendFailed a

        Evergreen.V48.Types.EmailSent a ->
            Evergreen.V49.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V48.Postmark.PostmarkSendResponse -> Evergreen.V49.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V48.Tile.Tile -> Evergreen.V49.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V48.Tile.EmptyTile ->
            Evergreen.V49.Tile.EmptyTile

        Evergreen.V48.Tile.HouseDown ->
            Evergreen.V49.Tile.HouseDown

        Evergreen.V48.Tile.HouseRight ->
            Evergreen.V49.Tile.HouseRight

        Evergreen.V48.Tile.HouseUp ->
            Evergreen.V49.Tile.HouseUp

        Evergreen.V48.Tile.HouseLeft ->
            Evergreen.V49.Tile.HouseLeft

        Evergreen.V48.Tile.RailHorizontal ->
            Evergreen.V49.Tile.RailHorizontal

        Evergreen.V48.Tile.RailVertical ->
            Evergreen.V49.Tile.RailVertical

        Evergreen.V48.Tile.RailBottomToRight ->
            Evergreen.V49.Tile.RailBottomToRight

        Evergreen.V48.Tile.RailBottomToLeft ->
            Evergreen.V49.Tile.RailBottomToLeft

        Evergreen.V48.Tile.RailTopToRight ->
            Evergreen.V49.Tile.RailTopToRight

        Evergreen.V48.Tile.RailTopToLeft ->
            Evergreen.V49.Tile.RailTopToLeft

        Evergreen.V48.Tile.RailBottomToRightLarge ->
            Evergreen.V49.Tile.RailBottomToRightLarge

        Evergreen.V48.Tile.RailBottomToLeftLarge ->
            Evergreen.V49.Tile.RailBottomToLeftLarge

        Evergreen.V48.Tile.RailTopToRightLarge ->
            Evergreen.V49.Tile.RailTopToRightLarge

        Evergreen.V48.Tile.RailTopToLeftLarge ->
            Evergreen.V49.Tile.RailTopToLeftLarge

        Evergreen.V48.Tile.RailCrossing ->
            Evergreen.V49.Tile.RailCrossing

        Evergreen.V48.Tile.RailStrafeDown ->
            Evergreen.V49.Tile.RailStrafeDown

        Evergreen.V48.Tile.RailStrafeUp ->
            Evergreen.V49.Tile.RailStrafeUp

        Evergreen.V48.Tile.RailStrafeLeft ->
            Evergreen.V49.Tile.RailStrafeLeft

        Evergreen.V48.Tile.RailStrafeRight ->
            Evergreen.V49.Tile.RailStrafeRight

        Evergreen.V48.Tile.TrainHouseRight ->
            Evergreen.V49.Tile.TrainHouseRight

        Evergreen.V48.Tile.TrainHouseLeft ->
            Evergreen.V49.Tile.TrainHouseLeft

        Evergreen.V48.Tile.RailStrafeDownSmall ->
            Evergreen.V49.Tile.RailStrafeDownSmall

        Evergreen.V48.Tile.RailStrafeUpSmall ->
            Evergreen.V49.Tile.RailStrafeUpSmall

        Evergreen.V48.Tile.RailStrafeLeftSmall ->
            Evergreen.V49.Tile.RailStrafeLeftSmall

        Evergreen.V48.Tile.RailStrafeRightSmall ->
            Evergreen.V49.Tile.RailStrafeRightSmall

        Evergreen.V48.Tile.Sidewalk ->
            Evergreen.V49.Tile.Sidewalk

        Evergreen.V48.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V49.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V48.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V49.Tile.SidewalkVerticalRailCrossing

        Evergreen.V48.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V49.Tile.RailBottomToRight_SplitLeft

        Evergreen.V48.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V49.Tile.RailBottomToLeft_SplitUp

        Evergreen.V48.Tile.RailTopToRight_SplitDown ->
            Evergreen.V49.Tile.RailTopToRight_SplitDown

        Evergreen.V48.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V49.Tile.RailTopToLeft_SplitRight

        Evergreen.V48.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V49.Tile.RailBottomToRight_SplitUp

        Evergreen.V48.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V49.Tile.RailBottomToLeft_SplitRight

        Evergreen.V48.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V49.Tile.RailTopToRight_SplitLeft

        Evergreen.V48.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V49.Tile.RailTopToLeft_SplitDown

        Evergreen.V48.Tile.PostOffice ->
            Evergreen.V49.Tile.PostOffice

        Evergreen.V48.Tile.MowedGrass1 ->
            Evergreen.V49.Tile.MowedGrass1

        Evergreen.V48.Tile.MowedGrass4 ->
            Evergreen.V49.Tile.MowedGrass4

        Evergreen.V48.Tile.PineTree ->
            Evergreen.V49.Tile.PineTree

        Evergreen.V48.Tile.LogCabinDown ->
            Evergreen.V49.Tile.LogCabinDown

        Evergreen.V48.Tile.LogCabinRight ->
            Evergreen.V49.Tile.LogCabinRight

        Evergreen.V48.Tile.LogCabinUp ->
            Evergreen.V49.Tile.LogCabinUp

        Evergreen.V48.Tile.LogCabinLeft ->
            Evergreen.V49.Tile.LogCabinLeft

        Evergreen.V48.Tile.RoadHorizontal ->
            Evergreen.V49.Tile.RoadHorizontal

        Evergreen.V48.Tile.RoadVertical ->
            Evergreen.V49.Tile.RoadVertical

        Evergreen.V48.Tile.RoadBottomToLeft ->
            Evergreen.V49.Tile.RoadBottomToLeft

        Evergreen.V48.Tile.RoadTopToLeft ->
            Evergreen.V49.Tile.RoadTopToLeft

        Evergreen.V48.Tile.RoadTopToRight ->
            Evergreen.V49.Tile.RoadTopToRight

        Evergreen.V48.Tile.RoadBottomToRight ->
            Evergreen.V49.Tile.RoadBottomToRight

        Evergreen.V48.Tile.Road4Way ->
            Evergreen.V49.Tile.Road4Way

        Evergreen.V48.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V49.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V48.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V49.Tile.RoadSidewalkCrossingVertical

        Evergreen.V48.Tile.Road3WayDown ->
            Evergreen.V49.Tile.Road3WayDown

        Evergreen.V48.Tile.Road3WayLeft ->
            Evergreen.V49.Tile.Road3WayLeft

        Evergreen.V48.Tile.Road3WayUp ->
            Evergreen.V49.Tile.Road3WayUp

        Evergreen.V48.Tile.Road3WayRight ->
            Evergreen.V49.Tile.Road3WayRight

        Evergreen.V48.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V49.Tile.RoadRailCrossingHorizontal

        Evergreen.V48.Tile.RoadRailCrossingVertical ->
            Evergreen.V49.Tile.RoadRailCrossingVertical

        Evergreen.V48.Tile.FenceHorizontal ->
            Evergreen.V49.Tile.FenceHorizontal

        Evergreen.V48.Tile.FenceVertical ->
            Evergreen.V49.Tile.FenceVertical

        Evergreen.V48.Tile.FenceDiagonal ->
            Evergreen.V49.Tile.FenceDiagonal

        Evergreen.V48.Tile.FenceAntidiagonal ->
            Evergreen.V49.Tile.FenceAntidiagonal

        Evergreen.V48.Tile.RoadDeadendUp ->
            Evergreen.V49.Tile.RoadDeadendUp

        Evergreen.V48.Tile.RoadDeadendDown ->
            Evergreen.V49.Tile.RoadDeadendDown

        Evergreen.V48.Tile.BusStopDown ->
            Evergreen.V49.Tile.BusStopDown

        Evergreen.V48.Tile.BusStopLeft ->
            Evergreen.V49.Tile.BusStopLeft

        Evergreen.V48.Tile.BusStopRight ->
            Evergreen.V49.Tile.BusStopRight

        Evergreen.V48.Tile.BusStopUp ->
            Evergreen.V49.Tile.BusStopUp

        Evergreen.V48.Tile.Hospital ->
            Evergreen.V49.Tile.Hospital

        Evergreen.V48.Tile.Statue ->
            Evergreen.V49.Tile.Statue


migrateTrain : Evergreen.V48.Train.Train -> Evergreen.V49.Train.Train
migrateTrain old =
    case old of
        Evergreen.V48.Train.Train a ->
            Evergreen.V49.Train.Train
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


migrateStatus : Evergreen.V48.Train.Status -> Evergreen.V49.Train.Status
migrateStatus old =
    case old of
        Evergreen.V48.Train.WaitingAtHome ->
            Evergreen.V49.Train.WaitingAtHome

        Evergreen.V48.Train.TeleportingHome a ->
            Evergreen.V49.Train.TeleportingHome (migratePosix a)

        Evergreen.V48.Train.Travelling ->
            Evergreen.V49.Train.Travelling

        Evergreen.V48.Train.StoppedAtPostOffice a ->
            Evergreen.V49.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V48.Tile.RailPath -> Evergreen.V49.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V48.Tile.RailPathHorizontal a ->
            Evergreen.V49.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V48.Tile.RailPathVertical a ->
            Evergreen.V49.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V48.Tile.RailPathBottomToRight ->
            Evergreen.V49.Tile.RailPathBottomToRight

        Evergreen.V48.Tile.RailPathBottomToLeft ->
            Evergreen.V49.Tile.RailPathBottomToLeft

        Evergreen.V48.Tile.RailPathTopToRight ->
            Evergreen.V49.Tile.RailPathTopToRight

        Evergreen.V48.Tile.RailPathTopToLeft ->
            Evergreen.V49.Tile.RailPathTopToLeft

        Evergreen.V48.Tile.RailPathBottomToRightLarge ->
            Evergreen.V49.Tile.RailPathBottomToRightLarge

        Evergreen.V48.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V49.Tile.RailPathBottomToLeftLarge

        Evergreen.V48.Tile.RailPathTopToRightLarge ->
            Evergreen.V49.Tile.RailPathTopToRightLarge

        Evergreen.V48.Tile.RailPathTopToLeftLarge ->
            Evergreen.V49.Tile.RailPathTopToLeftLarge

        Evergreen.V48.Tile.RailPathStrafeDown ->
            Evergreen.V49.Tile.RailPathStrafeDown

        Evergreen.V48.Tile.RailPathStrafeUp ->
            Evergreen.V49.Tile.RailPathStrafeUp

        Evergreen.V48.Tile.RailPathStrafeLeft ->
            Evergreen.V49.Tile.RailPathStrafeLeft

        Evergreen.V48.Tile.RailPathStrafeRight ->
            Evergreen.V49.Tile.RailPathStrafeRight

        Evergreen.V48.Tile.RailPathStrafeDownSmall ->
            Evergreen.V49.Tile.RailPathStrafeDownSmall

        Evergreen.V48.Tile.RailPathStrafeUpSmall ->
            Evergreen.V49.Tile.RailPathStrafeUpSmall

        Evergreen.V48.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V49.Tile.RailPathStrafeLeftSmall

        Evergreen.V48.Tile.RailPathStrafeRightSmall ->
            Evergreen.V49.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V48.Train.PreviousPath -> Evergreen.V49.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V48.MailEditor.Image -> Evergreen.V49.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V48.MailEditor.Stamp a ->
            Evergreen.V49.MailEditor.Stamp (migrateColors a)

        Evergreen.V48.MailEditor.SunglassesEmoji a ->
            Evergreen.V49.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V48.MailEditor.NormalEmoji a ->
            Evergreen.V49.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V48.MailEditor.SadEmoji a ->
            Evergreen.V49.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V48.MailEditor.Cow a ->
            Evergreen.V49.MailEditor.Cow (migrateColors a)

        Evergreen.V48.MailEditor.Man a ->
            Evergreen.V49.MailEditor.Man (migrateColors a)

        Evergreen.V48.MailEditor.TileImage a b c ->
            Evergreen.V49.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V48.MailEditor.Grass ->
            Evergreen.V49.MailEditor.Grass

        Evergreen.V48.MailEditor.DefaultCursor a ->
            Evergreen.V49.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V48.MailEditor.DragCursor a ->
            Evergreen.V49.MailEditor.DragCursor (migrateColors a)

        Evergreen.V48.MailEditor.PinchCursor a ->
            Evergreen.V49.MailEditor.PinchCursor (migrateColors a)


migrateTileGroup : Evergreen.V48.Tile.TileGroup -> Evergreen.V49.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V48.Tile.EmptyTileGroup ->
            Evergreen.V49.Tile.EmptyTileGroup

        Evergreen.V48.Tile.HouseGroup ->
            Evergreen.V49.Tile.HouseGroup

        Evergreen.V48.Tile.RailStraightGroup ->
            Evergreen.V49.Tile.RailStraightGroup

        Evergreen.V48.Tile.RailTurnGroup ->
            Evergreen.V49.Tile.RailTurnGroup

        Evergreen.V48.Tile.RailTurnLargeGroup ->
            Evergreen.V49.Tile.RailTurnLargeGroup

        Evergreen.V48.Tile.RailStrafeGroup ->
            Evergreen.V49.Tile.RailStrafeGroup

        Evergreen.V48.Tile.RailStrafeSmallGroup ->
            Evergreen.V49.Tile.RailStrafeSmallGroup

        Evergreen.V48.Tile.RailCrossingGroup ->
            Evergreen.V49.Tile.RailCrossingGroup

        Evergreen.V48.Tile.TrainHouseGroup ->
            Evergreen.V49.Tile.TrainHouseGroup

        Evergreen.V48.Tile.SidewalkGroup ->
            Evergreen.V49.Tile.SidewalkGroup

        Evergreen.V48.Tile.SidewalkRailGroup ->
            Evergreen.V49.Tile.SidewalkRailGroup

        Evergreen.V48.Tile.RailTurnSplitGroup ->
            Evergreen.V49.Tile.RailTurnSplitGroup

        Evergreen.V48.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V49.Tile.RailTurnSplitMirrorGroup

        Evergreen.V48.Tile.PostOfficeGroup ->
            Evergreen.V49.Tile.PostOfficeGroup

        Evergreen.V48.Tile.PineTreeGroup ->
            Evergreen.V49.Tile.PineTreeGroup

        Evergreen.V48.Tile.LogCabinGroup ->
            Evergreen.V49.Tile.LogCabinGroup

        Evergreen.V48.Tile.RoadStraightGroup ->
            Evergreen.V49.Tile.RoadStraightGroup

        Evergreen.V48.Tile.RoadTurnGroup ->
            Evergreen.V49.Tile.RoadTurnGroup

        Evergreen.V48.Tile.Road4WayGroup ->
            Evergreen.V49.Tile.Road4WayGroup

        Evergreen.V48.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V49.Tile.RoadSidewalkCrossingGroup

        Evergreen.V48.Tile.Road3WayGroup ->
            Evergreen.V49.Tile.Road3WayGroup

        Evergreen.V48.Tile.RoadRailCrossingGroup ->
            Evergreen.V49.Tile.RoadRailCrossingGroup

        Evergreen.V48.Tile.RoadDeadendGroup ->
            Evergreen.V49.Tile.RoadDeadendGroup

        Evergreen.V48.Tile.FenceStraightGroup ->
            Evergreen.V49.Tile.FenceStraightGroup

        Evergreen.V48.Tile.BusStopGroup ->
            Evergreen.V49.Tile.BusStopGroup

        Evergreen.V48.Tile.HospitalGroup ->
            Evergreen.V49.Tile.HospitalGroup

        Evergreen.V48.Tile.StatueGroup ->
            Evergreen.V49.Tile.StatueGroup


migrateDisplayName : Evergreen.V48.DisplayName.DisplayName -> Evergreen.V49.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V48.DisplayName.DisplayName a ->
            Evergreen.V49.DisplayName.DisplayName a


migrateCursor : Evergreen.V48.LocalGrid.Cursor -> Evergreen.V49.LocalGrid.Cursor
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


migrateContent : Evergreen.V48.MailEditor.Content -> Evergreen.V49.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, image = migrateImage old.image }


migrateColors : Evergreen.V48.Color.Colors -> Evergreen.V49.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V48.Color.Color -> Evergreen.V49.Color.Color
migrateColor old =
    case old of
        Evergreen.V48.Color.Color a ->
            Evergreen.V49.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V48.Types.ViewPoint -> Evergreen.V49.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V48.Types.NormalViewPoint a ->
            Evergreen.V49.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V48.Types.TrainViewPoint a ->
            Evergreen.V49.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V48.Geometry.Types.Point2d old) =
    Evergreen.V49.Geometry.Types.Point2d old


migrateId : Evergreen.V48.Id.Id a -> Evergreen.V49.Id.Id b
migrateId (Evergreen.V48.Id.Id old) =
    Evergreen.V49.Id.Id old
