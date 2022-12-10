module Evergreen.Migrate.V28 exposing (..)

import AssocList
import Dict
import Evergreen.V27.Types
import Evergreen.V28.Grid
import Evergreen.V28.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V27.Types.BackendModel -> ModelMigration Evergreen.V28.Types.BackendModel Evergreen.V28.Types.BackendMsg
backendModel old =
    ModelMigrated
        ( { grid = Evergreen.V28.Grid.Grid Dict.empty
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


frontendModel : Evergreen.V27.Types.FrontendModel -> ModelMigration Evergreen.V28.Types.FrontendModel Evergreen.V28.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V27.Types.FrontendMsg -> MsgMigration Evergreen.V28.Types.FrontendMsg Evergreen.V28.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
