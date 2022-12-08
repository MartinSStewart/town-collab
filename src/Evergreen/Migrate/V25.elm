module Evergreen.Migrate.V25 exposing (..)

import AssocList
import Dict
import Evergreen.V24.Types
import Evergreen.V25.Grid
import Evergreen.V25.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V24.Types.BackendModel -> ModelMigration Evergreen.V25.Types.BackendModel Evergreen.V25.Types.BackendMsg
backendModel old =
    ModelMigrated
        ( { grid = Evergreen.V25.Grid.Grid Dict.empty
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


frontendModel : Evergreen.V24.Types.FrontendModel -> ModelMigration Evergreen.V25.Types.FrontendModel Evergreen.V25.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V24.Types.FrontendMsg -> MsgMigration Evergreen.V25.Types.FrontendMsg Evergreen.V25.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
