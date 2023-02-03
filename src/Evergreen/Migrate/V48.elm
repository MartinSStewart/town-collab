module Evergreen.Migrate.V48 exposing (..)

import AssocList
import AssocSet
import Dict
import Effect.Time
import Evergreen.V47.Bounds
import Evergreen.V47.Change
import Evergreen.V47.Color
import Evergreen.V47.DisplayName
import Evergreen.V47.EmailAddress
import Evergreen.V47.Geometry.Types
import Evergreen.V47.Grid
import Evergreen.V47.GridCell
import Evergreen.V47.Id
import Evergreen.V47.IdDict
import Evergreen.V47.LocalGrid
import Evergreen.V47.MailEditor
import Evergreen.V47.Postmark
import Evergreen.V47.Tile
import Evergreen.V47.Train
import Evergreen.V47.Types
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
import IdDict
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Quantity


backendModel : Evergreen.V47.Types.BackendModel -> ModelMigration Evergreen.V48.Types.BackendModel Evergreen.V48.Types.BackendMsg
backendModel old =
    ModelMigrated ( migrateBackendModel old, Cmd.none )


frontendModel : Evergreen.V47.Types.FrontendModel -> ModelMigration Evergreen.V48.Types.FrontendModel Evergreen.V48.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V47.Types.FrontendMsg -> MsgMigration Evergreen.V48.Types.FrontendMsg Evergreen.V48.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V47.Types.BackendMsg -> MsgMigration Evergreen.V48.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V47.Types.BackendError -> Evergreen.V48.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V47.Types.PostmarkError a b ->
            Evergreen.V48.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V47.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V48.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V47.Types.BackendModel -> Evergreen.V48.Types.BackendModel
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


migrateGrid : Evergreen.V47.Grid.Grid -> Evergreen.V48.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V47.Grid.Grid a ->
            Evergreen.V48.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V47.GridCell.Cell -> Evergreen.V48.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V47.GridCell.Cell a ->
            Evergreen.V48.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateDict identity identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V47.GridCell.Value -> Evergreen.V48.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V47.Bounds.Bounds a -> Evergreen.V48.Bounds.Bounds b
migrateBounds (Evergreen.V47.Bounds.Bounds old) =
    Evergreen.V48.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V47.Change.Cow -> Evergreen.V48.Change.Cow
migrateCow old =
    { position = migratePoint2d old.position }


migrateBackendMail : Evergreen.V47.MailEditor.BackendMail -> Evergreen.V48.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V47.MailEditor.MailStatus -> Evergreen.V48.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V47.MailEditor.MailWaitingPickup ->
            Evergreen.V48.MailEditor.MailWaitingPickup

        Evergreen.V47.MailEditor.MailInTransit a ->
            Evergreen.V48.MailEditor.MailInTransit (migrateId a)

        Evergreen.V47.MailEditor.MailReceived a ->
            Evergreen.V48.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V47.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V48.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V47.Types.Invite -> Evergreen.V48.Types.Invite
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


migrateEmailAddress (Evergreen.V47.EmailAddress.EmailAddress old) =
    Evergreen.V48.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V47.Id.SecretId a -> Evergreen.V48.Id.SecretId b
migrateSecretId (Evergreen.V47.Id.SecretId old) =
    Evergreen.V48.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V47.IdDict.IdDict a b -> Evergreen.V48.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V47.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V48.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V47.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V48.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V47.IdDict.NColor -> Evergreen.V48.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V47.IdDict.Red ->
            Evergreen.V48.IdDict.Red

        Evergreen.V47.IdDict.Black ->
            Evergreen.V48.IdDict.Black


migrateBackendUserData : Evergreen.V47.Types.BackendUserData -> Evergreen.V48.Types.BackendUserData
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


migrateEmailResult : Evergreen.V47.Types.EmailResult -> Evergreen.V48.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V47.Types.EmailSending ->
            Evergreen.V48.Types.EmailSending

        Evergreen.V47.Types.EmailSendFailed a ->
            Evergreen.V48.Types.EmailSendFailed a

        Evergreen.V47.Types.EmailSent a ->
            Evergreen.V48.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V47.Postmark.PostmarkSendResponse -> Evergreen.V48.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V47.Tile.Tile -> Evergreen.V48.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V47.Tile.EmptyTile ->
            Evergreen.V48.Tile.EmptyTile

        Evergreen.V47.Tile.HouseDown ->
            Evergreen.V48.Tile.HouseDown

        Evergreen.V47.Tile.HouseRight ->
            Evergreen.V48.Tile.HouseRight

        Evergreen.V47.Tile.HouseUp ->
            Evergreen.V48.Tile.HouseUp

        Evergreen.V47.Tile.HouseLeft ->
            Evergreen.V48.Tile.HouseLeft

        Evergreen.V47.Tile.RailHorizontal ->
            Evergreen.V48.Tile.RailHorizontal

        Evergreen.V47.Tile.RailVertical ->
            Evergreen.V48.Tile.RailVertical

        Evergreen.V47.Tile.RailBottomToRight ->
            Evergreen.V48.Tile.RailBottomToRight

        Evergreen.V47.Tile.RailBottomToLeft ->
            Evergreen.V48.Tile.RailBottomToLeft

        Evergreen.V47.Tile.RailTopToRight ->
            Evergreen.V48.Tile.RailTopToRight

        Evergreen.V47.Tile.RailTopToLeft ->
            Evergreen.V48.Tile.RailTopToLeft

        Evergreen.V47.Tile.RailBottomToRightLarge ->
            Evergreen.V48.Tile.RailBottomToRightLarge

        Evergreen.V47.Tile.RailBottomToLeftLarge ->
            Evergreen.V48.Tile.RailBottomToLeftLarge

        Evergreen.V47.Tile.RailTopToRightLarge ->
            Evergreen.V48.Tile.RailTopToRightLarge

        Evergreen.V47.Tile.RailTopToLeftLarge ->
            Evergreen.V48.Tile.RailTopToLeftLarge

        Evergreen.V47.Tile.RailCrossing ->
            Evergreen.V48.Tile.RailCrossing

        Evergreen.V47.Tile.RailStrafeDown ->
            Evergreen.V48.Tile.RailStrafeDown

        Evergreen.V47.Tile.RailStrafeUp ->
            Evergreen.V48.Tile.RailStrafeUp

        Evergreen.V47.Tile.RailStrafeLeft ->
            Evergreen.V48.Tile.RailStrafeLeft

        Evergreen.V47.Tile.RailStrafeRight ->
            Evergreen.V48.Tile.RailStrafeRight

        Evergreen.V47.Tile.TrainHouseRight ->
            Evergreen.V48.Tile.TrainHouseRight

        Evergreen.V47.Tile.TrainHouseLeft ->
            Evergreen.V48.Tile.TrainHouseLeft

        Evergreen.V47.Tile.RailStrafeDownSmall ->
            Evergreen.V48.Tile.RailStrafeDownSmall

        Evergreen.V47.Tile.RailStrafeUpSmall ->
            Evergreen.V48.Tile.RailStrafeUpSmall

        Evergreen.V47.Tile.RailStrafeLeftSmall ->
            Evergreen.V48.Tile.RailStrafeLeftSmall

        Evergreen.V47.Tile.RailStrafeRightSmall ->
            Evergreen.V48.Tile.RailStrafeRightSmall

        Evergreen.V47.Tile.Sidewalk ->
            Evergreen.V48.Tile.Sidewalk

        Evergreen.V47.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V48.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V47.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V48.Tile.SidewalkVerticalRailCrossing

        Evergreen.V47.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V48.Tile.RailBottomToRight_SplitLeft

        Evergreen.V47.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V48.Tile.RailBottomToLeft_SplitUp

        Evergreen.V47.Tile.RailTopToRight_SplitDown ->
            Evergreen.V48.Tile.RailTopToRight_SplitDown

        Evergreen.V47.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V48.Tile.RailTopToLeft_SplitRight

        Evergreen.V47.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V48.Tile.RailBottomToRight_SplitUp

        Evergreen.V47.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V48.Tile.RailBottomToLeft_SplitRight

        Evergreen.V47.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V48.Tile.RailTopToRight_SplitLeft

        Evergreen.V47.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V48.Tile.RailTopToLeft_SplitDown

        Evergreen.V47.Tile.PostOffice ->
            Evergreen.V48.Tile.PostOffice

        Evergreen.V47.Tile.MowedGrass1 ->
            Evergreen.V48.Tile.MowedGrass1

        Evergreen.V47.Tile.MowedGrass4 ->
            Evergreen.V48.Tile.MowedGrass4

        Evergreen.V47.Tile.PineTree ->
            Evergreen.V48.Tile.PineTree

        Evergreen.V47.Tile.LogCabinDown ->
            Evergreen.V48.Tile.LogCabinDown

        Evergreen.V47.Tile.LogCabinRight ->
            Evergreen.V48.Tile.LogCabinRight

        Evergreen.V47.Tile.LogCabinUp ->
            Evergreen.V48.Tile.LogCabinUp

        Evergreen.V47.Tile.LogCabinLeft ->
            Evergreen.V48.Tile.LogCabinLeft

        Evergreen.V47.Tile.RoadHorizontal ->
            Evergreen.V48.Tile.RoadHorizontal

        Evergreen.V47.Tile.RoadVertical ->
            Evergreen.V48.Tile.RoadVertical

        Evergreen.V47.Tile.RoadBottomToLeft ->
            Evergreen.V48.Tile.RoadBottomToLeft

        Evergreen.V47.Tile.RoadTopToLeft ->
            Evergreen.V48.Tile.RoadTopToLeft

        Evergreen.V47.Tile.RoadTopToRight ->
            Evergreen.V48.Tile.RoadTopToRight

        Evergreen.V47.Tile.RoadBottomToRight ->
            Evergreen.V48.Tile.RoadBottomToRight

        Evergreen.V47.Tile.Road4Way ->
            Evergreen.V48.Tile.Road4Way

        Evergreen.V47.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V48.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V47.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V48.Tile.RoadSidewalkCrossingVertical

        Evergreen.V47.Tile.Road3WayDown ->
            Evergreen.V48.Tile.Road3WayDown

        Evergreen.V47.Tile.Road3WayLeft ->
            Evergreen.V48.Tile.Road3WayLeft

        Evergreen.V47.Tile.Road3WayUp ->
            Evergreen.V48.Tile.Road3WayUp

        Evergreen.V47.Tile.Road3WayRight ->
            Evergreen.V48.Tile.Road3WayRight

        Evergreen.V47.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V48.Tile.RoadRailCrossingHorizontal

        Evergreen.V47.Tile.RoadRailCrossingVertical ->
            Evergreen.V48.Tile.RoadRailCrossingVertical

        Evergreen.V47.Tile.FenceHorizontal ->
            Evergreen.V48.Tile.FenceHorizontal

        Evergreen.V47.Tile.FenceVertical ->
            Evergreen.V48.Tile.FenceVertical

        Evergreen.V47.Tile.FenceDiagonal ->
            Evergreen.V48.Tile.FenceDiagonal

        Evergreen.V47.Tile.FenceAntidiagonal ->
            Evergreen.V48.Tile.FenceAntidiagonal

        Evergreen.V47.Tile.RoadDeadendUp ->
            Evergreen.V48.Tile.RoadDeadendUp

        Evergreen.V47.Tile.RoadDeadendDown ->
            Evergreen.V48.Tile.RoadDeadendDown

        Evergreen.V47.Tile.BusStopDown ->
            Evergreen.V48.Tile.BusStopDown

        Evergreen.V47.Tile.BusStopLeft ->
            Evergreen.V48.Tile.BusStopLeft

        Evergreen.V47.Tile.BusStopRight ->
            Evergreen.V48.Tile.BusStopRight

        Evergreen.V47.Tile.BusStopUp ->
            Evergreen.V48.Tile.BusStopUp

        Evergreen.V47.Tile.Hospital ->
            Evergreen.V48.Tile.Hospital

        Evergreen.V47.Tile.Statue ->
            Evergreen.V48.Tile.Statue


migrateTrain : Evergreen.V47.Train.Train -> Evergreen.V48.Train.Train
migrateTrain old =
    case old of
        Evergreen.V47.Train.Train a ->
            Evergreen.V48.Train.Train
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


migrateStatus : Evergreen.V47.Train.Status -> Evergreen.V48.Train.Status
migrateStatus old =
    case old of
        Evergreen.V47.Train.WaitingAtHome ->
            Evergreen.V48.Train.WaitingAtHome

        Evergreen.V47.Train.TeleportingHome a ->
            Evergreen.V48.Train.TeleportingHome (migratePosix a)

        Evergreen.V47.Train.Travelling ->
            Evergreen.V48.Train.Travelling

        Evergreen.V47.Train.StoppedAtPostOffice a ->
            Evergreen.V48.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V47.Tile.RailPath -> Evergreen.V48.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V47.Tile.RailPathHorizontal a ->
            Evergreen.V48.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V47.Tile.RailPathVertical a ->
            Evergreen.V48.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V47.Tile.RailPathBottomToRight ->
            Evergreen.V48.Tile.RailPathBottomToRight

        Evergreen.V47.Tile.RailPathBottomToLeft ->
            Evergreen.V48.Tile.RailPathBottomToLeft

        Evergreen.V47.Tile.RailPathTopToRight ->
            Evergreen.V48.Tile.RailPathTopToRight

        Evergreen.V47.Tile.RailPathTopToLeft ->
            Evergreen.V48.Tile.RailPathTopToLeft

        Evergreen.V47.Tile.RailPathBottomToRightLarge ->
            Evergreen.V48.Tile.RailPathBottomToRightLarge

        Evergreen.V47.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V48.Tile.RailPathBottomToLeftLarge

        Evergreen.V47.Tile.RailPathTopToRightLarge ->
            Evergreen.V48.Tile.RailPathTopToRightLarge

        Evergreen.V47.Tile.RailPathTopToLeftLarge ->
            Evergreen.V48.Tile.RailPathTopToLeftLarge

        Evergreen.V47.Tile.RailPathStrafeDown ->
            Evergreen.V48.Tile.RailPathStrafeDown

        Evergreen.V47.Tile.RailPathStrafeUp ->
            Evergreen.V48.Tile.RailPathStrafeUp

        Evergreen.V47.Tile.RailPathStrafeLeft ->
            Evergreen.V48.Tile.RailPathStrafeLeft

        Evergreen.V47.Tile.RailPathStrafeRight ->
            Evergreen.V48.Tile.RailPathStrafeRight

        Evergreen.V47.Tile.RailPathStrafeDownSmall ->
            Evergreen.V48.Tile.RailPathStrafeDownSmall

        Evergreen.V47.Tile.RailPathStrafeUpSmall ->
            Evergreen.V48.Tile.RailPathStrafeUpSmall

        Evergreen.V47.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V48.Tile.RailPathStrafeLeftSmall

        Evergreen.V47.Tile.RailPathStrafeRightSmall ->
            Evergreen.V48.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V47.Train.PreviousPath -> Evergreen.V48.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V47.MailEditor.Image -> Evergreen.V48.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V47.MailEditor.Stamp a ->
            Evergreen.V48.MailEditor.Stamp (migrateColors a)

        Evergreen.V47.MailEditor.SunglassesEmoji a ->
            Evergreen.V48.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V47.MailEditor.NormalEmoji a ->
            Evergreen.V48.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V47.MailEditor.SadEmoji a ->
            Evergreen.V48.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V47.MailEditor.Cow a ->
            Evergreen.V48.MailEditor.Cow (migrateColors a)

        Evergreen.V47.MailEditor.Man a ->
            Evergreen.V48.MailEditor.Man (migrateColors a)

        Evergreen.V47.MailEditor.TileImage a b c ->
            Evergreen.V48.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V47.MailEditor.Grass ->
            Evergreen.V48.MailEditor.Grass

        Evergreen.V47.MailEditor.DefaultCursor a ->
            Evergreen.V48.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V47.MailEditor.DragCursor a ->
            Evergreen.V48.MailEditor.DragCursor (migrateColors a)

        Evergreen.V47.MailEditor.PinchCursor a ->
            Evergreen.V48.MailEditor.PinchCursor (migrateColors a)


migrateTileGroup : Evergreen.V47.Tile.TileGroup -> Evergreen.V48.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V47.Tile.EmptyTileGroup ->
            Evergreen.V48.Tile.EmptyTileGroup

        Evergreen.V47.Tile.HouseGroup ->
            Evergreen.V48.Tile.HouseGroup

        Evergreen.V47.Tile.RailStraightGroup ->
            Evergreen.V48.Tile.RailStraightGroup

        Evergreen.V47.Tile.RailTurnGroup ->
            Evergreen.V48.Tile.RailTurnGroup

        Evergreen.V47.Tile.RailTurnLargeGroup ->
            Evergreen.V48.Tile.RailTurnLargeGroup

        Evergreen.V47.Tile.RailStrafeGroup ->
            Evergreen.V48.Tile.RailStrafeGroup

        Evergreen.V47.Tile.RailStrafeSmallGroup ->
            Evergreen.V48.Tile.RailStrafeSmallGroup

        Evergreen.V47.Tile.RailCrossingGroup ->
            Evergreen.V48.Tile.RailCrossingGroup

        Evergreen.V47.Tile.TrainHouseGroup ->
            Evergreen.V48.Tile.TrainHouseGroup

        Evergreen.V47.Tile.SidewalkGroup ->
            Evergreen.V48.Tile.SidewalkGroup

        Evergreen.V47.Tile.SidewalkRailGroup ->
            Evergreen.V48.Tile.SidewalkRailGroup

        Evergreen.V47.Tile.RailTurnSplitGroup ->
            Evergreen.V48.Tile.RailTurnSplitGroup

        Evergreen.V47.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V48.Tile.RailTurnSplitMirrorGroup

        Evergreen.V47.Tile.PostOfficeGroup ->
            Evergreen.V48.Tile.PostOfficeGroup

        Evergreen.V47.Tile.PineTreeGroup ->
            Evergreen.V48.Tile.PineTreeGroup

        Evergreen.V47.Tile.LogCabinGroup ->
            Evergreen.V48.Tile.LogCabinGroup

        Evergreen.V47.Tile.RoadStraightGroup ->
            Evergreen.V48.Tile.RoadStraightGroup

        Evergreen.V47.Tile.RoadTurnGroup ->
            Evergreen.V48.Tile.RoadTurnGroup

        Evergreen.V47.Tile.Road4WayGroup ->
            Evergreen.V48.Tile.Road4WayGroup

        Evergreen.V47.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V48.Tile.RoadSidewalkCrossingGroup

        Evergreen.V47.Tile.Road3WayGroup ->
            Evergreen.V48.Tile.Road3WayGroup

        Evergreen.V47.Tile.RoadRailCrossingGroup ->
            Evergreen.V48.Tile.RoadRailCrossingGroup

        Evergreen.V47.Tile.RoadDeadendGroup ->
            Evergreen.V48.Tile.RoadDeadendGroup

        Evergreen.V47.Tile.FenceStraightGroup ->
            Evergreen.V48.Tile.FenceStraightGroup

        Evergreen.V47.Tile.BusStopGroup ->
            Evergreen.V48.Tile.BusStopGroup

        Evergreen.V47.Tile.HospitalGroup ->
            Evergreen.V48.Tile.HospitalGroup

        Evergreen.V47.Tile.StatueGroup ->
            Evergreen.V48.Tile.StatueGroup


migrateDisplayName : Evergreen.V47.DisplayName.DisplayName -> Evergreen.V48.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V47.DisplayName.DisplayName a ->
            Evergreen.V48.DisplayName.DisplayName a


migrateCursor : Evergreen.V47.LocalGrid.Cursor -> Evergreen.V48.LocalGrid.Cursor
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


migrateContent : Evergreen.V47.MailEditor.Content -> Evergreen.V48.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, image = migrateImage old.image }


migrateColors : Evergreen.V47.Color.Colors -> Evergreen.V48.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V47.Color.Color -> Evergreen.V48.Color.Color
migrateColor old =
    case old of
        Evergreen.V47.Color.Color a ->
            Evergreen.V48.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V47.Types.ViewPoint -> Evergreen.V48.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V47.Types.NormalViewPoint a ->
            Evergreen.V48.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V47.Types.TrainViewPoint a ->
            Evergreen.V48.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V47.Geometry.Types.Point2d old) =
    Evergreen.V48.Geometry.Types.Point2d old


migrateId : Evergreen.V47.Id.Id a -> Evergreen.V48.Id.Id b
migrateId (Evergreen.V47.Id.Id old) =
    Evergreen.V48.Id.Id old
