module Evergreen.Migrate.V50 exposing (..)

import AssocList
import AssocSet
import Dict
import Effect.Time
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
import IdDict
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))
import List.Nonempty
import Quantity


backendModel : Evergreen.V49.Types.BackendModel -> ModelMigration Evergreen.V50.Types.BackendModel Evergreen.V50.Types.BackendMsg
backendModel old =
    ModelMigrated ( migrateBackendModel old, Cmd.none )


frontendModel : Evergreen.V49.Types.FrontendModel -> ModelMigration Evergreen.V50.Types.FrontendModel Evergreen.V50.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V49.Types.FrontendMsg -> MsgMigration Evergreen.V50.Types.FrontendMsg Evergreen.V50.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg : Evergreen.V49.Types.BackendMsg -> MsgMigration Evergreen.V50.Types.BackendMsg msg
backendMsg old =
    MsgOldValueIgnored


migrateBackendError : Evergreen.V49.Types.BackendError -> Evergreen.V50.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V49.Types.PostmarkError a b ->
            Evergreen.V50.Types.PostmarkError (migrateEmailAddress a) b

        Evergreen.V49.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V50.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V49.Types.BackendModel -> Evergreen.V50.Types.BackendModel
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


migrateGrid : Evergreen.V49.Grid.Grid -> Evergreen.V50.Grid.Grid
migrateGrid old =
    case old of
        Evergreen.V49.Grid.Grid a ->
            Evergreen.V50.Grid.Grid (migrateDict identity migrateCell a)


migrateCell : Evergreen.V49.GridCell.Cell -> Evergreen.V50.GridCell.Cell
migrateCell old =
    case old of
        Evergreen.V49.GridCell.Cell a ->
            Evergreen.V50.GridCell.Cell
                { history = migrateList migrateValue a.history
                , undoPoint = migrateDict identity identity a.undoPoint
                , cache = migrateList migrateValue a.cache
                , railSplitToggled = migrateSet migrateCoord a.railSplitToggled
                }


migrateValue : Evergreen.V49.GridCell.Value -> Evergreen.V50.GridCell.Value
migrateValue old =
    { userId = migrateId old.userId
    , position = migrateCoord old.position
    , value = migrateTile old.value
    , colors = migrateColors old.colors
    }


migrateSet =
    AssocSet.map


migrateBounds : Evergreen.V49.Bounds.Bounds a -> Evergreen.V50.Bounds.Bounds b
migrateBounds (Evergreen.V49.Bounds.Bounds old) =
    Evergreen.V50.Bounds.Bounds
        { min = migrateCoord old.min
        , max = migrateCoord old.max
        }


migrateCow : Evergreen.V49.Change.Cow -> Evergreen.V50.Change.Cow
migrateCow old =
    { position = migratePoint2d old.position }


migrateBackendMail : Evergreen.V49.MailEditor.BackendMail -> Evergreen.V50.MailEditor.BackendMail
migrateBackendMail old =
    { content = migrateList migrateContent old.content
    , status = migrateMailStatus old.status
    , from = migrateId old.from
    , to = migrateId old.to
    }


migrateMailStatus : Evergreen.V49.MailEditor.MailStatus -> Evergreen.V50.MailEditor.MailStatus
migrateMailStatus old =
    case old of
        Evergreen.V49.MailEditor.MailWaitingPickup ->
            Evergreen.V50.MailEditor.MailWaitingPickup

        Evergreen.V49.MailEditor.MailInTransit a ->
            Evergreen.V50.MailEditor.MailInTransit (migrateId a)

        Evergreen.V49.MailEditor.MailReceived a ->
            Evergreen.V50.MailEditor.MailReceived { deliveryTime = migratePosix a.deliveryTime }

        Evergreen.V49.MailEditor.MailReceivedAndViewed a ->
            Evergreen.V50.MailEditor.MailReceivedAndViewed { deliveryTime = migratePosix a.deliveryTime }


migrateInvite : Evergreen.V49.Types.Invite -> Evergreen.V50.Types.Invite
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


migrateEmailAddress (Evergreen.V49.EmailAddress.EmailAddress old) =
    Evergreen.V50.EmailAddress.EmailAddress old


migrateResult mapErr mapOk old =
    case old of
        Ok ok ->
            mapOk ok |> Ok

        Err err ->
            mapErr err |> Err


migrateSecretId : Evergreen.V49.Id.SecretId a -> Evergreen.V50.Id.SecretId b
migrateSecretId (Evergreen.V49.Id.SecretId old) =
    Evergreen.V50.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue2 old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue2)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V49.IdDict.IdDict a b -> Evergreen.V50.IdDict.IdDict c d
migrateIdDict migrateValue2 old =
    case old of
        Evergreen.V49.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V50.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue2 v)
                (migrateIdDict migrateValue2 a)
                (migrateIdDict migrateValue2 b)

        Evergreen.V49.IdDict.RBEmpty_elm_builtin ->
            Evergreen.V50.IdDict.RBEmpty_elm_builtin


migrateNColor : Evergreen.V49.IdDict.NColor -> Evergreen.V50.IdDict.NColor
migrateNColor old =
    case old of
        Evergreen.V49.IdDict.Red ->
            Evergreen.V50.IdDict.Red

        Evergreen.V49.IdDict.Black ->
            Evergreen.V50.IdDict.Black


migrateBackendUserData : Evergreen.V49.Types.BackendUserData -> Evergreen.V50.Types.BackendUserData
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
    , allowEmailNotifications = old.sendEmailWhenReceivingALetter
    }


migrateRawCellCoord =
    identity


migrateEmailResult : Evergreen.V49.Types.EmailResult -> Evergreen.V50.Types.EmailResult
migrateEmailResult old =
    case old of
        Evergreen.V49.Types.EmailSending ->
            Evergreen.V50.Types.EmailSending

        Evergreen.V49.Types.EmailSendFailed a ->
            Evergreen.V50.Types.EmailSendFailed a

        Evergreen.V49.Types.EmailSent a ->
            Evergreen.V50.Types.EmailSent (migratePostmarkSendResponse a)


migratePostmarkSendResponse : Evergreen.V49.Postmark.PostmarkSendResponse -> Evergreen.V50.Postmark.PostmarkSendResponse
migratePostmarkSendResponse old =
    old


migrateTile : Evergreen.V49.Tile.Tile -> Evergreen.V50.Tile.Tile
migrateTile old =
    case old of
        Evergreen.V49.Tile.EmptyTile ->
            Evergreen.V50.Tile.EmptyTile

        Evergreen.V49.Tile.HouseDown ->
            Evergreen.V50.Tile.HouseDown

        Evergreen.V49.Tile.HouseRight ->
            Evergreen.V50.Tile.HouseRight

        Evergreen.V49.Tile.HouseUp ->
            Evergreen.V50.Tile.HouseUp

        Evergreen.V49.Tile.HouseLeft ->
            Evergreen.V50.Tile.HouseLeft

        Evergreen.V49.Tile.RailHorizontal ->
            Evergreen.V50.Tile.RailHorizontal

        Evergreen.V49.Tile.RailVertical ->
            Evergreen.V50.Tile.RailVertical

        Evergreen.V49.Tile.RailBottomToRight ->
            Evergreen.V50.Tile.RailBottomToRight

        Evergreen.V49.Tile.RailBottomToLeft ->
            Evergreen.V50.Tile.RailBottomToLeft

        Evergreen.V49.Tile.RailTopToRight ->
            Evergreen.V50.Tile.RailTopToRight

        Evergreen.V49.Tile.RailTopToLeft ->
            Evergreen.V50.Tile.RailTopToLeft

        Evergreen.V49.Tile.RailBottomToRightLarge ->
            Evergreen.V50.Tile.RailBottomToRightLarge

        Evergreen.V49.Tile.RailBottomToLeftLarge ->
            Evergreen.V50.Tile.RailBottomToLeftLarge

        Evergreen.V49.Tile.RailTopToRightLarge ->
            Evergreen.V50.Tile.RailTopToRightLarge

        Evergreen.V49.Tile.RailTopToLeftLarge ->
            Evergreen.V50.Tile.RailTopToLeftLarge

        Evergreen.V49.Tile.RailCrossing ->
            Evergreen.V50.Tile.RailCrossing

        Evergreen.V49.Tile.RailStrafeDown ->
            Evergreen.V50.Tile.RailStrafeDown

        Evergreen.V49.Tile.RailStrafeUp ->
            Evergreen.V50.Tile.RailStrafeUp

        Evergreen.V49.Tile.RailStrafeLeft ->
            Evergreen.V50.Tile.RailStrafeLeft

        Evergreen.V49.Tile.RailStrafeRight ->
            Evergreen.V50.Tile.RailStrafeRight

        Evergreen.V49.Tile.TrainHouseRight ->
            Evergreen.V50.Tile.TrainHouseRight

        Evergreen.V49.Tile.TrainHouseLeft ->
            Evergreen.V50.Tile.TrainHouseLeft

        Evergreen.V49.Tile.RailStrafeDownSmall ->
            Evergreen.V50.Tile.RailStrafeDownSmall

        Evergreen.V49.Tile.RailStrafeUpSmall ->
            Evergreen.V50.Tile.RailStrafeUpSmall

        Evergreen.V49.Tile.RailStrafeLeftSmall ->
            Evergreen.V50.Tile.RailStrafeLeftSmall

        Evergreen.V49.Tile.RailStrafeRightSmall ->
            Evergreen.V50.Tile.RailStrafeRightSmall

        Evergreen.V49.Tile.Sidewalk ->
            Evergreen.V50.Tile.Sidewalk

        Evergreen.V49.Tile.SidewalkHorizontalRailCrossing ->
            Evergreen.V50.Tile.SidewalkHorizontalRailCrossing

        Evergreen.V49.Tile.SidewalkVerticalRailCrossing ->
            Evergreen.V50.Tile.SidewalkVerticalRailCrossing

        Evergreen.V49.Tile.RailBottomToRight_SplitLeft ->
            Evergreen.V50.Tile.RailBottomToRight_SplitLeft

        Evergreen.V49.Tile.RailBottomToLeft_SplitUp ->
            Evergreen.V50.Tile.RailBottomToLeft_SplitUp

        Evergreen.V49.Tile.RailTopToRight_SplitDown ->
            Evergreen.V50.Tile.RailTopToRight_SplitDown

        Evergreen.V49.Tile.RailTopToLeft_SplitRight ->
            Evergreen.V50.Tile.RailTopToLeft_SplitRight

        Evergreen.V49.Tile.RailBottomToRight_SplitUp ->
            Evergreen.V50.Tile.RailBottomToRight_SplitUp

        Evergreen.V49.Tile.RailBottomToLeft_SplitRight ->
            Evergreen.V50.Tile.RailBottomToLeft_SplitRight

        Evergreen.V49.Tile.RailTopToRight_SplitLeft ->
            Evergreen.V50.Tile.RailTopToRight_SplitLeft

        Evergreen.V49.Tile.RailTopToLeft_SplitDown ->
            Evergreen.V50.Tile.RailTopToLeft_SplitDown

        Evergreen.V49.Tile.PostOffice ->
            Evergreen.V50.Tile.PostOffice

        Evergreen.V49.Tile.MowedGrass1 ->
            Evergreen.V50.Tile.MowedGrass1

        Evergreen.V49.Tile.MowedGrass4 ->
            Evergreen.V50.Tile.MowedGrass4

        Evergreen.V49.Tile.PineTree ->
            Evergreen.V50.Tile.PineTree1

        Evergreen.V49.Tile.LogCabinDown ->
            Evergreen.V50.Tile.LogCabinDown

        Evergreen.V49.Tile.LogCabinRight ->
            Evergreen.V50.Tile.LogCabinRight

        Evergreen.V49.Tile.LogCabinUp ->
            Evergreen.V50.Tile.LogCabinUp

        Evergreen.V49.Tile.LogCabinLeft ->
            Evergreen.V50.Tile.LogCabinLeft

        Evergreen.V49.Tile.RoadHorizontal ->
            Evergreen.V50.Tile.RoadHorizontal

        Evergreen.V49.Tile.RoadVertical ->
            Evergreen.V50.Tile.RoadVertical

        Evergreen.V49.Tile.RoadBottomToLeft ->
            Evergreen.V50.Tile.RoadBottomToLeft

        Evergreen.V49.Tile.RoadTopToLeft ->
            Evergreen.V50.Tile.RoadTopToLeft

        Evergreen.V49.Tile.RoadTopToRight ->
            Evergreen.V50.Tile.RoadTopToRight

        Evergreen.V49.Tile.RoadBottomToRight ->
            Evergreen.V50.Tile.RoadBottomToRight

        Evergreen.V49.Tile.Road4Way ->
            Evergreen.V50.Tile.Road4Way

        Evergreen.V49.Tile.RoadSidewalkCrossingHorizontal ->
            Evergreen.V50.Tile.RoadSidewalkCrossingHorizontal

        Evergreen.V49.Tile.RoadSidewalkCrossingVertical ->
            Evergreen.V50.Tile.RoadSidewalkCrossingVertical

        Evergreen.V49.Tile.Road3WayDown ->
            Evergreen.V50.Tile.Road3WayDown

        Evergreen.V49.Tile.Road3WayLeft ->
            Evergreen.V50.Tile.Road3WayLeft

        Evergreen.V49.Tile.Road3WayUp ->
            Evergreen.V50.Tile.Road3WayUp

        Evergreen.V49.Tile.Road3WayRight ->
            Evergreen.V50.Tile.Road3WayRight

        Evergreen.V49.Tile.RoadRailCrossingHorizontal ->
            Evergreen.V50.Tile.RoadRailCrossingHorizontal

        Evergreen.V49.Tile.RoadRailCrossingVertical ->
            Evergreen.V50.Tile.RoadRailCrossingVertical

        Evergreen.V49.Tile.FenceHorizontal ->
            Evergreen.V50.Tile.FenceHorizontal

        Evergreen.V49.Tile.FenceVertical ->
            Evergreen.V50.Tile.FenceVertical

        Evergreen.V49.Tile.FenceDiagonal ->
            Evergreen.V50.Tile.FenceDiagonal

        Evergreen.V49.Tile.FenceAntidiagonal ->
            Evergreen.V50.Tile.FenceAntidiagonal

        Evergreen.V49.Tile.RoadDeadendUp ->
            Evergreen.V50.Tile.RoadDeadendUp

        Evergreen.V49.Tile.RoadDeadendDown ->
            Evergreen.V50.Tile.RoadDeadendDown

        Evergreen.V49.Tile.BusStopDown ->
            Evergreen.V50.Tile.BusStopDown

        Evergreen.V49.Tile.BusStopLeft ->
            Evergreen.V50.Tile.BusStopLeft

        Evergreen.V49.Tile.BusStopRight ->
            Evergreen.V50.Tile.BusStopRight

        Evergreen.V49.Tile.BusStopUp ->
            Evergreen.V50.Tile.BusStopUp

        Evergreen.V49.Tile.Hospital ->
            Evergreen.V50.Tile.Hospital

        Evergreen.V49.Tile.Statue ->
            Evergreen.V50.Tile.Statue

        Evergreen.V49.Tile.HedgeRowDown ->
            Evergreen.V50.Tile.HedgeRowDown

        Evergreen.V49.Tile.HedgeRowLeft ->
            Evergreen.V50.Tile.HedgeRowLeft

        Evergreen.V49.Tile.HedgeRowRight ->
            Evergreen.V50.Tile.HedgeRowRight

        Evergreen.V49.Tile.HedgeRowUp ->
            Evergreen.V50.Tile.HedgeRowUp

        Evergreen.V49.Tile.HedgeCornerDownLeft ->
            Evergreen.V50.Tile.HedgeCornerDownLeft

        Evergreen.V49.Tile.HedgeCornerDownRight ->
            Evergreen.V50.Tile.HedgeCornerDownRight

        Evergreen.V49.Tile.HedgeCornerUpLeft ->
            Evergreen.V50.Tile.HedgeCornerUpLeft

        Evergreen.V49.Tile.HedgeCornerUpRight ->
            Evergreen.V50.Tile.HedgeCornerUpRight

        Evergreen.V49.Tile.ApartmentDown ->
            Evergreen.V50.Tile.ApartmentDown

        Evergreen.V49.Tile.ApartmentLeft ->
            Evergreen.V50.Tile.ApartmentLeft

        Evergreen.V49.Tile.ApartmentRight ->
            Evergreen.V50.Tile.ApartmentRight

        Evergreen.V49.Tile.ApartmentUp ->
            Evergreen.V50.Tile.ApartmentUp

        Evergreen.V49.Tile.RockDown ->
            Evergreen.V50.Tile.RockDown

        Evergreen.V49.Tile.RockLeft ->
            Evergreen.V50.Tile.RockLeft

        Evergreen.V49.Tile.RockRight ->
            Evergreen.V50.Tile.RockRight

        Evergreen.V49.Tile.RockUp ->
            Evergreen.V50.Tile.RockUp

        Evergreen.V49.Tile.Flowers ->
            Evergreen.V50.Tile.Flowers1


migrateTrain : Evergreen.V49.Train.Train -> Evergreen.V50.Train.Train
migrateTrain old =
    case old of
        Evergreen.V49.Train.Train a ->
            Evergreen.V50.Train.Train
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


migrateStatus : Evergreen.V49.Train.Status -> Evergreen.V50.Train.Status
migrateStatus old =
    case old of
        Evergreen.V49.Train.WaitingAtHome ->
            Evergreen.V50.Train.WaitingAtHome

        Evergreen.V49.Train.TeleportingHome a ->
            Evergreen.V50.Train.TeleportingHome (migratePosix a)

        Evergreen.V49.Train.Travelling ->
            Evergreen.V50.Train.Travelling

        Evergreen.V49.Train.StoppedAtPostOffice a ->
            Evergreen.V50.Train.StoppedAtPostOffice
                { time = migratePosix a.time, userId = migrateId a.userId }


migrateRailPath : Evergreen.V49.Tile.RailPath -> Evergreen.V50.Tile.RailPath
migrateRailPath old =
    case old of
        Evergreen.V49.Tile.RailPathHorizontal a ->
            Evergreen.V50.Tile.RailPathHorizontal
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V49.Tile.RailPathVertical a ->
            Evergreen.V50.Tile.RailPathVertical
                { offsetX = identity a.offsetX, offsetY = identity a.offsetY, length = identity a.length }

        Evergreen.V49.Tile.RailPathBottomToRight ->
            Evergreen.V50.Tile.RailPathBottomToRight

        Evergreen.V49.Tile.RailPathBottomToLeft ->
            Evergreen.V50.Tile.RailPathBottomToLeft

        Evergreen.V49.Tile.RailPathTopToRight ->
            Evergreen.V50.Tile.RailPathTopToRight

        Evergreen.V49.Tile.RailPathTopToLeft ->
            Evergreen.V50.Tile.RailPathTopToLeft

        Evergreen.V49.Tile.RailPathBottomToRightLarge ->
            Evergreen.V50.Tile.RailPathBottomToRightLarge

        Evergreen.V49.Tile.RailPathBottomToLeftLarge ->
            Evergreen.V50.Tile.RailPathBottomToLeftLarge

        Evergreen.V49.Tile.RailPathTopToRightLarge ->
            Evergreen.V50.Tile.RailPathTopToRightLarge

        Evergreen.V49.Tile.RailPathTopToLeftLarge ->
            Evergreen.V50.Tile.RailPathTopToLeftLarge

        Evergreen.V49.Tile.RailPathStrafeDown ->
            Evergreen.V50.Tile.RailPathStrafeDown

        Evergreen.V49.Tile.RailPathStrafeUp ->
            Evergreen.V50.Tile.RailPathStrafeUp

        Evergreen.V49.Tile.RailPathStrafeLeft ->
            Evergreen.V50.Tile.RailPathStrafeLeft

        Evergreen.V49.Tile.RailPathStrafeRight ->
            Evergreen.V50.Tile.RailPathStrafeRight

        Evergreen.V49.Tile.RailPathStrafeDownSmall ->
            Evergreen.V50.Tile.RailPathStrafeDownSmall

        Evergreen.V49.Tile.RailPathStrafeUpSmall ->
            Evergreen.V50.Tile.RailPathStrafeUpSmall

        Evergreen.V49.Tile.RailPathStrafeLeftSmall ->
            Evergreen.V50.Tile.RailPathStrafeLeftSmall

        Evergreen.V49.Tile.RailPathStrafeRightSmall ->
            Evergreen.V50.Tile.RailPathStrafeRightSmall


migratePreviousPath : Evergreen.V49.Train.PreviousPath -> Evergreen.V50.Train.PreviousPath
migratePreviousPath old =
    { position = migrateCoord old.position, path = migrateRailPath old.path, reversed = old.reversed }


migrateImage : Evergreen.V49.MailEditor.Image -> Evergreen.V50.MailEditor.Image
migrateImage old =
    case old of
        Evergreen.V49.MailEditor.Stamp a ->
            Evergreen.V50.MailEditor.Stamp (migrateColors a)

        Evergreen.V49.MailEditor.SunglassesEmoji a ->
            Evergreen.V50.MailEditor.SunglassesEmoji (migrateColors a)

        Evergreen.V49.MailEditor.NormalEmoji a ->
            Evergreen.V50.MailEditor.NormalEmoji (migrateColors a)

        Evergreen.V49.MailEditor.SadEmoji a ->
            Evergreen.V50.MailEditor.SadEmoji (migrateColors a)

        Evergreen.V49.MailEditor.Cow a ->
            Evergreen.V50.MailEditor.Cow (migrateColors a)

        Evergreen.V49.MailEditor.Man a ->
            Evergreen.V50.MailEditor.Man (migrateColors a)

        Evergreen.V49.MailEditor.TileImage a b c ->
            Evergreen.V50.MailEditor.TileImage (migrateTileGroup a) b (migrateColors c)

        Evergreen.V49.MailEditor.Grass ->
            Evergreen.V50.MailEditor.Grass

        Evergreen.V49.MailEditor.DefaultCursor a ->
            Evergreen.V50.MailEditor.DefaultCursor (migrateColors a)

        Evergreen.V49.MailEditor.DragCursor a ->
            Evergreen.V50.MailEditor.DragCursor (migrateColors a)

        Evergreen.V49.MailEditor.PinchCursor a ->
            Evergreen.V50.MailEditor.PinchCursor (migrateColors a)

        Evergreen.V49.MailEditor.Line int color ->
            Evergreen.V50.MailEditor.Line int (migrateColor color)


migrateTileGroup : Evergreen.V49.Tile.TileGroup -> Evergreen.V50.Tile.TileGroup
migrateTileGroup old =
    case old of
        Evergreen.V49.Tile.EmptyTileGroup ->
            Evergreen.V50.Tile.EmptyTileGroup

        Evergreen.V49.Tile.HouseGroup ->
            Evergreen.V50.Tile.HouseGroup

        Evergreen.V49.Tile.RailStraightGroup ->
            Evergreen.V50.Tile.RailStraightGroup

        Evergreen.V49.Tile.RailTurnGroup ->
            Evergreen.V50.Tile.RailTurnGroup

        Evergreen.V49.Tile.RailTurnLargeGroup ->
            Evergreen.V50.Tile.RailTurnLargeGroup

        Evergreen.V49.Tile.RailStrafeGroup ->
            Evergreen.V50.Tile.RailStrafeGroup

        Evergreen.V49.Tile.RailStrafeSmallGroup ->
            Evergreen.V50.Tile.RailStrafeSmallGroup

        Evergreen.V49.Tile.RailCrossingGroup ->
            Evergreen.V50.Tile.RailCrossingGroup

        Evergreen.V49.Tile.TrainHouseGroup ->
            Evergreen.V50.Tile.TrainHouseGroup

        Evergreen.V49.Tile.SidewalkGroup ->
            Evergreen.V50.Tile.SidewalkGroup

        Evergreen.V49.Tile.SidewalkRailGroup ->
            Evergreen.V50.Tile.SidewalkRailGroup

        Evergreen.V49.Tile.RailTurnSplitGroup ->
            Evergreen.V50.Tile.RailTurnSplitGroup

        Evergreen.V49.Tile.RailTurnSplitMirrorGroup ->
            Evergreen.V50.Tile.RailTurnSplitMirrorGroup

        Evergreen.V49.Tile.PostOfficeGroup ->
            Evergreen.V50.Tile.PostOfficeGroup

        Evergreen.V49.Tile.PineTreeGroup ->
            Evergreen.V50.Tile.PineTreeGroup

        Evergreen.V49.Tile.LogCabinGroup ->
            Evergreen.V50.Tile.LogCabinGroup

        Evergreen.V49.Tile.RoadStraightGroup ->
            Evergreen.V50.Tile.RoadStraightGroup

        Evergreen.V49.Tile.RoadTurnGroup ->
            Evergreen.V50.Tile.RoadTurnGroup

        Evergreen.V49.Tile.Road4WayGroup ->
            Evergreen.V50.Tile.Road4WayGroup

        Evergreen.V49.Tile.RoadSidewalkCrossingGroup ->
            Evergreen.V50.Tile.RoadSidewalkCrossingGroup

        Evergreen.V49.Tile.Road3WayGroup ->
            Evergreen.V50.Tile.Road3WayGroup

        Evergreen.V49.Tile.RoadRailCrossingGroup ->
            Evergreen.V50.Tile.RoadRailCrossingGroup

        Evergreen.V49.Tile.RoadDeadendGroup ->
            Evergreen.V50.Tile.RoadDeadendGroup

        Evergreen.V49.Tile.FenceStraightGroup ->
            Evergreen.V50.Tile.FenceStraightGroup

        Evergreen.V49.Tile.BusStopGroup ->
            Evergreen.V50.Tile.BusStopGroup

        Evergreen.V49.Tile.HospitalGroup ->
            Evergreen.V50.Tile.HospitalGroup

        Evergreen.V49.Tile.StatueGroup ->
            Evergreen.V50.Tile.StatueGroup

        Evergreen.V49.Tile.HedgeRowGroup ->
            Evergreen.V50.Tile.HedgeRowGroup

        Evergreen.V49.Tile.HedgeCornerGroup ->
            Evergreen.V50.Tile.HedgeCornerGroup

        Evergreen.V49.Tile.ApartmentGroup ->
            Evergreen.V50.Tile.ApartmentGroup

        Evergreen.V49.Tile.RockGroup ->
            Evergreen.V50.Tile.RockGroup

        Evergreen.V49.Tile.FlowersGroup ->
            Evergreen.V50.Tile.FlowersGroup


migrateDisplayName : Evergreen.V49.DisplayName.DisplayName -> Evergreen.V50.DisplayName.DisplayName
migrateDisplayName old =
    case old of
        Evergreen.V49.DisplayName.DisplayName a ->
            Evergreen.V50.DisplayName.DisplayName a


migrateCursor : Evergreen.V49.LocalGrid.Cursor -> Evergreen.V50.LocalGrid.Cursor
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


migrateContent : Evergreen.V49.MailEditor.Content -> Evergreen.V50.MailEditor.Content
migrateContent old =
    { position = migrateCoord old.position, image = migrateImage old.image }


migrateColors : Evergreen.V49.Color.Colors -> Evergreen.V50.Color.Colors
migrateColors old =
    { primaryColor = migrateColor old.primaryColor, secondaryColor = migrateColor old.secondaryColor }


migrateColor : Evergreen.V49.Color.Color -> Evergreen.V50.Color.Color
migrateColor old =
    case old of
        Evergreen.V49.Color.Color a ->
            Evergreen.V50.Color.Color a


migrateNonempty =
    List.Nonempty.map


migrateCoord ( x, y ) =
    ( migrateQuantity x, migrateQuantity y )


migrateQuantity =
    Quantity.unwrap >> Quantity.unsafe


migrateMaybe =
    Maybe.map


migrateViewPoint : Evergreen.V49.Types.ViewPoint -> Evergreen.V50.Types.ViewPoint
migrateViewPoint old =
    case old of
        Evergreen.V49.Types.NormalViewPoint a ->
            Evergreen.V50.Types.NormalViewPoint (migratePoint2d a)

        Evergreen.V49.Types.TrainViewPoint a ->
            Evergreen.V50.Types.TrainViewPoint
                { trainId = migrateId a.trainId
                , startViewPoint = migratePoint2d a.startViewPoint
                , startTime = migratePosix a.startTime
                }


migratePosix : Effect.Time.Posix -> Effect.Time.Posix
migratePosix =
    identity


migratePoint2d (Evergreen.V49.Geometry.Types.Point2d old) =
    Evergreen.V50.Geometry.Types.Point2d old


migrateId : Evergreen.V49.Id.Id a -> Evergreen.V50.Id.Id b
migrateId (Evergreen.V49.Id.Id old) =
    Evergreen.V50.Id.Id old
