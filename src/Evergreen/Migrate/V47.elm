module Evergreen.Migrate.V47 exposing (..)

import AssocList
import Dict
import Effect.Time
import Evergreen.V46.Bounds
import Evergreen.V46.Change
import Evergreen.V46.Color
import Evergreen.V46.DisplayName
import Evergreen.V46.EmailAddress
import Evergreen.V46.Geometry.Types
import Evergreen.V46.Grid
import Evergreen.V46.Id
import Evergreen.V46.IdDict
import Evergreen.V46.LocalGrid
import Evergreen.V46.MailEditor
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
import Evergreen.V47.Id
import Evergreen.V47.IdDict
import Evergreen.V47.LocalGrid
import Evergreen.V47.MailEditor
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
    MsgMigrated ( migrateBackendMsg old, Cmd.none )


migrateBackendError : Evergreen.V46.Types.BackendError -> Evergreen.V47.Types.BackendError
migrateBackendError old =
    case old of
        Evergreen.V46.Types.PostmarkError a b ->
            Evergreen.V47.Types.PostmarkError (migrateEmailAddress a) (migrateError b)

        Evergreen.V46.Types.UserNotFoundWhenLoggingIn a ->
            Evergreen.V47.Types.UserNotFoundWhenLoggingIn (migrateId a)


migrateBackendModel : Evergreen.V46.Types.BackendModel -> Evergreen.V47.Types.BackendModel
migrateBackendModel old =
    { grid = migrateGrid old.grid
    , userSessions =
        migrateDict
            identity
            (\a ->
                { clientIds = AssocList.map migrateBounds a.clientIds
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
    Debug.todo ""


migrateBounds : Evergreen.V46.Bounds.Bounds a -> Evergreen.V47.Bounds.Bounds b
migrateBounds =
    Debug.todo ""


migrateCow : Evergreen.V46.Change.Cow -> Evergreen.V47.Change.Cow
migrateCow =
    Debug.todo ""


migrateBackendMail : Evergreen.V46.MailEditor.BackendMail -> Evergreen.V47.MailEditor.BackendMail
migrateBackendMail =
    Debug.todo ""


migrateInvite : Evergreen.V46.Types.Invite -> Evergreen.V47.Types.Invite
migrateInvite =
    Debug.todo ""


migrateAssocList migrateKey migrateValue old =
    AssocList.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue)
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


migrateBackendMsg : Evergreen.V46.Types.BackendMsg -> Evergreen.V47.Types.BackendMsg
migrateBackendMsg old =
    case old of
        Evergreen.V46.Types.UserDisconnected a b ->
            Evergreen.V47.Types.UserDisconnected (migrateSessionId a) (migrateClientId b)

        Evergreen.V46.Types.NotifyAdminEmailSent ->
            Evergreen.V47.Types.NotifyAdminEmailSent

        Evergreen.V46.Types.SentLoginEmail a b c ->
            Evergreen.V47.Types.SentLoginEmail
                (migratePosix a)
                (migrateEmailAddress b)
                (migrateResult migrateError migratePostmarkSendResponse c)

        Evergreen.V46.Types.UpdateFromFrontend a b c d ->
            Evergreen.V47.Types.UpdateFromFrontend
                (migrateSessionId a)
                (migrateClientId b)
                (migrateToBackend c)
                (migratePosix d)

        Evergreen.V46.Types.WorldUpdateTimeElapsed a ->
            Evergreen.V47.Types.WorldUpdateTimeElapsed (migratePosix a)

        Evergreen.V46.Types.SentInviteEmail a b ->
            Evergreen.V47.Types.SentInviteEmail
                (migrateSecretId a)
                (migrateResult migrateError migratePostmarkSendResponse b)


migrateSecretId : Evergreen.V46.Id.SecretId a -> Evergreen.V47.Id.SecretId b
migrateSecretId (Evergreen.V46.Id.SecretId old) =
    Evergreen.V47.Id.SecretId old


migrateList =
    List.map


migrateDict migrateKey migrateValue old =
    Dict.toList old
        |> List.map (Tuple.mapBoth migrateKey migrateValue)
        |> Dict.fromList


migrateIdDict : (b -> d) -> Evergreen.V46.IdDict.IdDict a b -> Evergreen.V47.IdDict.IdDict c d
migrateIdDict migrateValue old =
    case old of
        Evergreen.V46.IdDict.RBNode_elm_builtin nColor int v a b ->
            Evergreen.V47.IdDict.RBNode_elm_builtin
                (migrateNColor nColor)
                int
                (migrateValue v)
                (migrateIdDict migrateValue a)
                (migrateIdDict migrateValue b)

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
    , acceptedInvites = migrateIdDict (Debug.todo "Can't handle this") old.acceptedInvites
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
            Evergreen.V47.Types.EmailSendFailed (migrateError a)

        Evergreen.V46.Types.EmailSent a ->
            Evergreen.V47.Types.EmailSent (migratePostmarkSendResponse a)


migrateTile : Evergreen.V46.Tile.Tile -> Evergreen.V47.Tile.Tile
migrateTile old =
    Debug.todo ""


migrateTrain : Evergreen.V46.Train.Train -> Evergreen.V47.Train.Train
migrateTrain old =
    Debug.todo ""


migrateDisplayName : Evergreen.V46.DisplayName.DisplayName -> Evergreen.V47.DisplayName.DisplayName
migrateDisplayName old =
    Debug.todo ""


migrateCursor : Evergreen.V46.LocalGrid.Cursor -> Evergreen.V47.LocalGrid.Cursor
migrateCursor old =
    Debug.todo ""


migrateContent : Evergreen.V46.MailEditor.Content -> Evergreen.V47.MailEditor.Content
migrateContent old =
    Debug.todo ""


migrateHover : Evergreen.V46.Types.Hover -> Evergreen.V47.Types.Hover
migrateHover old =
    case old of
        Evergreen.V46.Types.TileHover a ->
            Evergreen.V47.Types.TileHover
                { tile = migrateTile a.tile
                , userId = migrateId a.userId
                , position = migrateCoord a.position
                , colors = migrateColors a.colors
                }

        Evergreen.V46.Types.TrainHover a ->
            Evergreen.V47.Types.TrainHover
                { trainId = migrateId a.trainId, train = migrateTrain a.train }

        Evergreen.V46.Types.MapHover ->
            Evergreen.V47.Types.MapHover

        Evergreen.V46.Types.CowHover a ->
            Evergreen.V47.Types.CowHover { cowId = migrateId a.cowId, cow = migrateCow a.cow }

        Evergreen.V46.Types.UiBackgroundHover ->
            Evergreen.V47.Types.UiBackgroundHover

        Evergreen.V46.Types.UiHover a b ->
            Evergreen.V47.Types.UiHover (migrateUiHover a) { position = migrateCoord b.position }


migrateLoadedLocalModel_ : Evergreen.V46.Types.LoadedLocalModel_ -> Evergreen.V47.Types.LoadedLocalModel_
migrateLoadedLocalModel_ old =
    { localModel = migrateLocalModel migrateChange migrateLocalGrid old.localModel
    , trains = migrateIdDict migrateTrain old.trains
    , mail = migrateIdDict migrateFrontendMail old.mail
    }


migrateLoadingData_ : Evergreen.V46.Types.LoadingData_ -> Evergreen.V47.Types.LoadingData_
migrateLoadingData_ old =
    { grid = migrateGridData old.grid
    , userStatus = migrateUserStatus old.userStatus
    , viewBounds = migrateBounds migrateCellUnit old.viewBounds
    , trains = migrateIdDict migrateTrain old.trains
    , mail = migrateIdDict migrateFrontendMail old.mail
    , cows = migrateIdDict migrateCow old.cows
    , cursors = migrateIdDict migrateCursor old.cursors
    , users = migrateIdDict migrateFrontendUser old.users
    }


migrateLoadingLocalModel : Evergreen.V46.Types.LoadingLocalModel -> Evergreen.V47.Types.LoadingLocalModel
migrateLoadingLocalModel old =
    case old of
        Evergreen.V46.Types.LoadingLocalModel a ->
            Evergreen.V47.Types.LoadingLocalModel (migrateList migrateChange a)

        Evergreen.V46.Types.LoadedLocalModel a ->
            Evergreen.V47.Types.LoadedLocalModel (migrateLoadedLocalModel_ a)


migrateColors : Evergreen.V46.Color.Colors -> Evergreen.V47.Color.Colors
migrateColors old =
    Debug.todo ""


migrateColor : Evergreen.V46.Color.Color -> Evergreen.V47.Color.Color
migrateColor old =
    Debug.todo ""


migrateSubmitStatus : (a -> b) -> Evergreen.V46.Types.SubmitStatus a -> Evergreen.V47.Types.SubmitStatus b
migrateSubmitStatus migrateA old =
    Debug.todo ""


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
