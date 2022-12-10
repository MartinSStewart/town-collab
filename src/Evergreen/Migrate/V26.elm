module Evergreen.Migrate.V26 exposing (..)

import AssocList
import Dict
import Evergreen.V25.Types
import Evergreen.V26.Grid
import Evergreen.V26.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V25.Types.BackendModel -> ModelMigration Evergreen.V26.Types.BackendModel Evergreen.V26.Types.BackendMsg
backendModel old =
    ModelMigrated
        ( { grid = Evergreen.V26.Grid.Grid Dict.empty
          , userSessions = Dict.empty
          , users = Dict.empty
          , usersHiddenRecently = []
          , secretLinkCounter = 0
          , errors = []
          , trains = AssocList.empty
          , lastWorldUpdateTrains = AssocList.empty
          , lastWorldUpdate = Nothing
          , mail = AssocList.empty
          }
        , Cmd.none
        )


frontendModel : Evergreen.V25.Types.FrontendModel -> ModelMigration Evergreen.V26.Types.FrontendModel Evergreen.V26.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V25.Types.FrontendMsg -> MsgMigration Evergreen.V26.Types.FrontendMsg Evergreen.V26.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
