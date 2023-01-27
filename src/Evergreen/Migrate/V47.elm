module Evergreen.Migrate.V47 exposing (..)

import AssocList
import AssocSet
import Dict
import Effect.Time
import Evergreen.V46.Bounds
import Evergreen.V46.Change
import Evergreen.V46.Color
import Evergreen.V46.DisplayName
import Evergreen.V46.EmailAddress
import Evergreen.V46.Geometry.Types
import Evergreen.V46.Grid
import Evergreen.V46.GridCell
import Evergreen.V46.Id
import Evergreen.V46.IdDict
import Evergreen.V46.LocalGrid
import Evergreen.V46.MailEditor
import Evergreen.V46.Postmark
import Evergreen.V46.Tile
import Evergreen.V46.Train
import Evergreen.V46.Types
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
import IdDict
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Quantity


backendModel : Evergreen.V46.Types.BackendModel -> ModelMigration Evergreen.V47.Types.BackendModel Evergreen.V47.Types.BackendMsg
backendModel old =
    ModelMigrated ( migrateBackendModel old, Cmd.none )


frontendModel : Evergreen.V46.Types.FrontendModel -> ModelMigration Evergreen.V47.Types.FrontendModel Evergreen.V47.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V46.Types.FrontendMsg -> MsgMigration Evergreen.V47.Types.FrontendMsg Evergreen.V47.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V46.Types.BackendMsg -> MsgMigration Evergreen.V47.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V46.Types.BackendError -> Evergreen.V47.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V46.Types.PostmarkError a b ->
            Evergreen.V47.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V46.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V47.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V46.Types.BackendModel -> Evergreen.V47.Types.BackendModel
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


migrateGrid : Evergreen.V46.Grid.Grid -> Evergreen.V47.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V46.Grid.Grid a ->
            Evergreen.V47.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V46.GridCell.Cell -> Evergreen.V47.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V46.GridCell.Cell a ->
            Evergreen.V47.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateDict identity identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V46.GridCell.Value -> Evergreen.V47.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V46.Bounds.Bounds a -> Evergreen.V47.Bounds.Bounds b
migrateBounds (Evergreen.V46.Bounds.Bounds old) =
    Evergreen.V47.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V46.Change.Cow -> Evergreen.V47.Change.Cow
migrateCow old =
    { position = migratePoint2d old.position }


migrateBackendMail : Evergreen.V46.MailEditor.BackendMail -> Evergreen.V47.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V46.MailEditor.MailStatus -> Evergreen.V47.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V46.MailEditor.MailWaitingPickup ->
            Evergreen.V47.MailEditor.MailWaitingPickup

        Evergreen.V46.MailEditor.MailInTransit a ->
            Evergreen.V47.MailEditor.MailInTransit (migrateId a)

        Evergreen.V46.MailEditor.MailReceived a ->
            Evergreen.V47.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V46.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V47.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V46.Types.Invite -> Evergreen.V47.Types.Invite
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


migrateEmailAddress (Evergreen.V46.EmailAddress.EmailAddress old) =
    Evergreen.V47.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V46.Id.SecretId a -> Evergreen.V47.Id.SecretId b
migrateSecretId (Evergreen.V46.Id.SecretId old) =
    Evergreen.V47.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V46.IdDict.IdDict a b -> Evergreen.V47.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V46.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V47.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V46.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V47.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V46.IdDict.NColor -> Evergreen.V47.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V46.IdDict.Red ->
            Evergreen.V47.IdDict.Red

        Evergreen.V46.IdDict.Black ->
            Evergreen.V47.IdDict.Black


migrateBackendUserData : Evergreen.V46.Types.BackendUserData -> Evergreen.V47.Types.BackendUserData
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


migrateEmailResult : Evergreen.V46.Types.EmailResult -> Evergreen.V47.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V46.Types.EmailSending ->
            Evergreen.V47.Types.EmailSending

        Evergreen.V46.Types.EmailSendFailed a ->
            Evergreen.V47.Types.EmailSendFailed a

        Evergreen.V46.Types.EmailSent a ->
            Evergreen.V47.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V46.Postmark.PostmarkSendResponse -> Evergreen.V47.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V46.Tile.Tile -> Evergreen.V47.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V46.Tile.EmptyTile ->
            Evergreen.V47.Tile.EmptyTile

        Evergreen.V46.Tile.HouseDown ->
            Evergreen.V47.Tile.HouseDown

        Evergreen.V46.Tile.HouseRight ->
            Evergreen.V47.Tile.HouseRight

        Evergreen.V46.Tile.HouseUp ->
            Evergreen.V47.Tile.HouseUp

        Evergreen.V46.Tile.HouseLeft ->
            Evergreen.V47.Tile.HouseLeft

        Evergreen.V46.Tile.RailHorizontal ->
            Evergreen.V47.Tile.RailHorizontal

        Evergreen.V46.Tile.RailVertical ->
            Evergreen.V47.Tile.RailVertical

        Evergreen.V46.Tile.RailBottomToRight ->
            Evergreen.V47.Tile.RailBottomToRight

        Evergreen.V46.Tile.RailBottomToLeft ->
            Evergreen.V47.Tile.RailBottomToLeft

        Evergreen.V46.Tile.RailTopToRight ->
            Evergreen.V47.Tile.RailTopToRight

        Evergreen.V46.Tile.RailTopToLeft ->
            Evergreen.V47.Tile.RailTopToLeft

        Evergreen.V46.Tile.RailBottomToRightLarge ->
            Evergreen.V47.Tile.RailBottomToRightLarge

        Evergreen.V46.Tile.RailBottomToLeftLarge ->
            Evergreen.V47.Tile.RailBottomToLeftLarge

        Evergreen.V46.Tile.RailTopToRightLarge ->
            Evergreen.V47.Tile.RailTopToRightLarge

        Evergreen.V46.Tile.RailTopToLeftLarge ->
            Evergreen.V47.Tile.RailTopToLeftLarge

        Evergreen.V46.Tile.RailCrossing ->
            Evergreen.V47.Tile.RailCrossing

        Evergreen.V46.Tile.RailStrafeDown ->
            Evergreen.V47.Tile.RailStrafeDown

        Evergreen.V46.Tile.RailStrafeUp ->
            Evergreen.V47.Tile.RailStrafeUp

        Evergreen.V46.Tile.RailStrafeLeft ->
            Evergreen.V47.Tile.RailStrafeLeft

        Evergreen.V46.Tile.RailStrafeRight ->
            Evergreen.V47.Tile.RailStrafeRight

        Evergreen.V46.Tile.TrainHouseRight ->
            Evergreen.V47.Tile.TrainHouseRight

        Evergreen.V46.Tile.TrainHouseLeft ->
            Evergreen.V47.Tile.TrainHouseLeft

        Evergreen.V46.Tile.RailStrafeDownSmall ->
            Evergreen.V47.Tile.RailStrafeDownSmall

        Evergreen.V46.Tile.RailStrafeUpSmall ->
            Evergreen.V47.Tile.RailStrafeUpSmall

        Evergreen.V46.Tile.RailStrafeLeftSmall ->
            Evergreen.V47.Tile.RailStrafeLeftSmall

        Evergreen.V46.Tile.RailStrafeRightSmall ->
            Evergreen.V47.Tile.RailStrafeRightSmall

        Evergreen.V46.Tile.Sidewalk ->
            Evergreen.V47.Tile.Sidewalk

        Evergreen.V46.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V47.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V46.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V47.Tile.SidewalkVerticalRailCrossing

        Evergreen.V46.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V47.Tile.RailBottomToRight_SplitLeft

        Evergreen.V46.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V47.Tile.RailBottomToLeft_SplitUp

        Evergreen.V46.Tile.RailTopToRight_SplitDown ->
            Evergreen.V47.Tile.RailTopToRight_SplitDown

        Evergreen.V46.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V47.Tile.RailTopToLeft_SplitRight

        Evergreen.V46.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V47.Tile.RailBottomToRight_SplitUp

        Evergreen.V46.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V47.Tile.RailBottomToLeft_SplitRight

        Evergreen.V46.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V47.Tile.RailTopToRight_SplitLeft

        Evergreen.V46.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V47.Tile.RailTopToLeft_SplitDown

        Evergreen.V46.Tile.PostOffice ->
            Evergreen.V47.Tile.PostOffice

        Evergreen.V46.Tile.MowedGrass1 ->
            Evergreen.V47.Tile.MowedGrass1

        Evergreen.V46.Tile.MowedGrass4 ->
            Evergreen.V47.Tile.MowedGrass4

        Evergreen.V46.Tile.PineTree ->
            Evergreen.V47.Tile.PineTree

        Evergreen.V46.Tile.LogCabinDown ->
            Evergreen.V47.Tile.LogCabinDown

        Evergreen.V46.Tile.LogCabinRight ->
            Evergreen.V47.Tile.LogCabinRight

        Evergreen.V46.Tile.LogCabinUp ->
            Evergreen.V47.Tile.LogCabinUp

        Evergreen.V46.Tile.LogCabinLeft ->
            Evergreen.V47.Tile.LogCabinLeft

        Evergreen.V46.Tile.RoadHorizontal ->
            Evergreen.V47.Tile.RoadHorizontal

        Evergreen.V46.Tile.RoadVertical ->
            Evergreen.V47.Tile.RoadVertical

        Evergreen.V46.Tile.RoadBottomToLeft ->
            Evergreen.V47.Tile.RoadBottomToLeft

        Evergreen.V46.Tile.RoadTopToLeft ->
            Evergreen.V47.Tile.RoadTopToLeft

        Evergreen.V46.Tile.RoadTopToRight ->
            Evergreen.V47.Tile.RoadTopToRight

        Evergreen.V46.Tile.RoadBottomToRight ->
            Evergreen.V47.Tile.RoadBottomToRight

        Evergreen.V46.Tile.Road4Way ->
            Evergreen.V47.Tile.Road4Way

        Evergreen.V46.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V47.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V46.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V47.Tile.RoadSidewalkCrossingVertical

        Evergreen.V46.Tile.Road3WayDown ->
            Evergreen.V47.Tile.Road3WayDown

        Evergreen.V46.Tile.Road3WayLeft ->
            Evergreen.V47.Tile.Road3WayLeft

        Evergreen.V46.Tile.Road3WayUp ->
            Evergreen.V47.Tile.Road3WayUp

        Evergreen.V46.Tile.Road3WayRight ->
            Evergreen.V47.Tile.Road3WayRight

        Evergreen.V46.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V47.Tile.RoadRailCrossingHorizontal

        Evergreen.V46.Tile.RoadRailCrossingVertical ->
            Evergreen.V47.Tile.RoadRailCrossingVertical

        Evergreen.V46.Tile.FenceHorizontal ->
            Evergreen.V47.Tile.FenceHorizontal

        Evergreen.V46.Tile.FenceVertical ->
            Evergreen.V47.Tile.FenceVertical

        Evergreen.V46.Tile.FenceDiagonal ->
            Evergreen.V47.Tile.FenceDiagonal

        Evergreen.V46.Tile.FenceAntidiagonal ->
            Evergreen.V47.Tile.FenceAntidiagonal

        Evergreen.V46.Tile.RoadDeadendUp ->
            Evergreen.V47.Tile.RoadDeadendUp

        Evergreen.V46.Tile.RoadDeadendDown ->
            Evergreen.V47.Tile.RoadDeadendDown

        Evergreen.V46.Tile.BusStopDown ->
            Evergreen.V47.Tile.BusStopDown

        Evergreen.V46.Tile.BusStopLeft ->
            Evergreen.V47.Tile.BusStopLeft

        Evergreen.V46.Tile.BusStopRight ->
            Evergreen.V47.Tile.BusStopRight

        Evergreen.V46.Tile.BusStopUp ->
            Evergreen.V47.Tile.BusStopUp

        Evergreen.V46.Tile.Hospital ->
            Evergreen.V47.Tile.Hospital

        Evergreen.V46.Tile.Statue ->
            Evergreen.V47.Tile.Statue


migrateTrain : Evergreen.V46.Train.Train -> Evergreen.V47.Train.Train
migrateTrain old =
    case old of
        Evergreen.V46.Train.Train a ->
            Evergreen.V47.Train.Train
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


migrateStatus : Evergreen.V46.Train.Status -> Evergreen.V47.Train.Status
migrateStatus old =
    case old of
        Evergreen.V46.Train.WaitingAtHome ->
            Evergreen.V47.Train.WaitingAtHome

        Evergreen.V46.Train.TeleportingHome a ->
            Evergreen.V47.Train.TeleportingHome (migratePosix a)

        Evergreen.V46.Train.Travelling ->
            Evergreen.V47.Train.Travelling

        Evergreen.V46.Train.StoppedAtPostOffice a ->
            Evergreen.V47.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V46.Tile.RailPath -> Evergreen.V47.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V46.Tile.RailPathHorizontal a ->
            Evergreen.V47.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V46.Tile.RailPathVertical a ->
            Evergreen.V47.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V46.Tile.RailPathBottomToRight ->
            Evergreen.V47.Tile.RailPathBottomToRight

        Evergreen.V46.Tile.RailPathBottomToLeft ->
            Evergreen.V47.Tile.RailPathBottomToLeft

        Evergreen.V46.Tile.RailPathTopToRight ->
            Evergreen.V47.Tile.RailPathTopToRight

        Evergreen.V46.Tile.RailPathTopToLeft ->
            Evergreen.V47.Tile.RailPathTopToLeft

        Evergreen.V46.Tile.RailPathBottomToRightLarge ->
            Evergreen.V47.Tile.RailPathBottomToRightLarge

        Evergreen.V46.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V47.Tile.RailPathBottomToLeftLarge

        Evergreen.V46.Tile.RailPathTopToRightLarge ->
            Evergreen.V47.Tile.RailPathTopToRightLarge

        Evergreen.V46.Tile.RailPathTopToLeftLarge ->
            Evergreen.V47.Tile.RailPathTopToLeftLarge

        Evergreen.V46.Tile.RailPathStrafeDown ->
            Evergreen.V47.Tile.RailPathStrafeDown

        Evergreen.V46.Tile.RailPathStrafeUp ->
            Evergreen.V47.Tile.RailPathStrafeUp

        Evergreen.V46.Tile.RailPathStrafeLeft ->
            Evergreen.V47.Tile.RailPathStrafeLeft

        Evergreen.V46.Tile.RailPathStrafeRight ->
            Evergreen.V47.Tile.RailPathStrafeRight

        Evergreen.V46.Tile.RailPathStrafeDownSmall ->
            Evergreen.V47.Tile.RailPathStrafeDownSmall

        Evergreen.V46.Tile.RailPathStrafeUpSmall ->
            Evergreen.V47.Tile.RailPathStrafeUpSmall

        Evergreen.V46.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V47.Tile.RailPathStrafeLeftSmall

        Evergreen.V46.Tile.RailPathStrafeRightSmall ->
            Evergreen.V47.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V46.Train.PreviousPath -> Evergreen.V47.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V46.MailEditor.Image -> Evergreen.V47.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V46.MailEditor.Stamp a ->
            Evergreen.V47.MailEditor.Stamp (migrateColors a)

        Evergreen.V46.MailEditor.SunglassesEmoji a ->
            Evergreen.V47.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V46.MailEditor.NormalEmoji a ->
            Evergreen.V47.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V46.MailEditor.SadEmoji a ->
            Evergreen.V47.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V46.MailEditor.Cow a ->
            Evergreen.V47.MailEditor.Cow (migrateColors a)

        Evergreen.V46.MailEditor.Man a ->
            Evergreen.V47.MailEditor.Man (migrateColors a)

        Evergreen.V46.MailEditor.TileImage a b c ->
            Evergreen.V47.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V46.MailEditor.Grass ->
            Evergreen.V47.MailEditor.Grass

        Evergreen.V46.MailEditor.DefaultCursor a ->
            Evergreen.V47.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V46.MailEditor.DragCursor a ->
            Evergreen.V47.MailEditor.DragCursor (migrateColors a)

        Evergreen.V46.MailEditor.PinchCursor a ->
            Evergreen.V47.MailEditor.PinchCursor (migrateColors a)


migrateTileGroup : Evergreen.V46.Tile.TileGroup -> Evergreen.V47.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V46.Tile.EmptyTileGroup ->
            Evergreen.V47.Tile.EmptyTileGroup

        Evergreen.V46.Tile.HouseGroup ->
            Evergreen.V47.Tile.HouseGroup

        Evergreen.V46.Tile.RailStraightGroup ->
            Evergreen.V47.Tile.RailStraightGroup

        Evergreen.V46.Tile.RailTurnGroup ->
            Evergreen.V47.Tile.RailTurnGroup

        Evergreen.V46.Tile.RailTurnLargeGroup ->
            Evergreen.V47.Tile.RailTurnLargeGroup

        Evergreen.V46.Tile.RailStrafeGroup ->
            Evergreen.V47.Tile.RailStrafeGroup

        Evergreen.V46.Tile.RailStrafeSmallGroup ->
            Evergreen.V47.Tile.RailStrafeSmallGroup

        Evergreen.V46.Tile.RailCrossingGroup ->
            Evergreen.V47.Tile.RailCrossingGroup

        Evergreen.V46.Tile.TrainHouseGroup ->
            Evergreen.V47.Tile.TrainHouseGroup

        Evergreen.V46.Tile.SidewalkGroup ->
            Evergreen.V47.Tile.SidewalkGroup

        Evergreen.V46.Tile.SidewalkRailGroup ->
            Evergreen.V47.Tile.SidewalkRailGroup

        Evergreen.V46.Tile.RailTurnSplitGroup ->
            Evergreen.V47.Tile.RailTurnSplitGroup

        Evergreen.V46.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V47.Tile.RailTurnSplitMirrorGroup

        Evergreen.V46.Tile.PostOfficeGroup ->
            Evergreen.V47.Tile.PostOfficeGroup

        Evergreen.V46.Tile.PineTreeGroup ->
            Evergreen.V47.Tile.PineTreeGroup

        Evergreen.V46.Tile.LogCabinGroup ->
            Evergreen.V47.Tile.LogCabinGroup

        Evergreen.V46.Tile.RoadStraightGroup ->
            Evergreen.V47.Tile.RoadStraightGroup

        Evergreen.V46.Tile.RoadTurnGroup ->
            Evergreen.V47.Tile.RoadTurnGroup

        Evergreen.V46.Tile.Road4WayGroup ->
            Evergreen.V47.Tile.Road4WayGroup

        Evergreen.V46.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V47.Tile.RoadSidewalkCrossingGroup

        Evergreen.V46.Tile.Road3WayGroup ->
            Evergreen.V47.Tile.Road3WayGroup

        Evergreen.V46.Tile.RoadRailCrossingGroup ->
            Evergreen.V47.Tile.RoadRailCrossingGroup

        Evergreen.V46.Tile.RoadDeadendGroup ->
            Evergreen.V47.Tile.RoadDeadendGroup

        Evergreen.V46.Tile.FenceStraightGroup ->
            Evergreen.V47.Tile.FenceStraightGroup

        Evergreen.V46.Tile.BusStopGroup ->
            Evergreen.V47.Tile.BusStopGroup

        Evergreen.V46.Tile.HospitalGroup ->
            Evergreen.V47.Tile.HospitalGroup

        Evergreen.V46.Tile.StatueGroup ->
            Evergreen.V47.Tile.StatueGroup


migrateDisplayName : Evergreen.V46.DisplayName.DisplayName -> Evergreen.V47.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V46.DisplayName.DisplayName a ->
            Evergreen.V47.DisplayName.DisplayName a


migrateCursor : Evergreen.V46.LocalGrid.Cursor -> Evergreen.V47.LocalGrid.Cursor
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


migrateContent : Evergreen.V46.MailEditor.Content -> Evergreen.V47.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, image = migrateImage old.image }


migrateColors : Evergreen.V46.Color.Colors -> Evergreen.V47.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V46.Color.Color -> Evergreen.V47.Color.Color
migrateColor old =
    case old of
        Evergreen.V46.Color.Color a ->
            Evergreen.V47.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V46.Types.ViewPoint -> Evergreen.V47.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V46.Types.NormalViewPoint a ->
            Evergreen.V47.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V46.Types.TrainViewPoint a ->
            Evergreen.V47.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V46.Geometry.Types.Point2d old) =
    Evergreen.V47.Geometry.Types.Point2d old


migrateId : Evergreen.V46.Id.Id a -> Evergreen.V47.Id.Id b
migrateId (Evergreen.V46.Id.Id old) =
    Evergreen.V47.Id.Id old
