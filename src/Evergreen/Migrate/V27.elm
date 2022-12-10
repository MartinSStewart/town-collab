module Evergreen.Migrate.V27 exposing (..)

import AssocList
import Dict
import Evergreen.V26.Types
import Evergreen.V27.Grid
import Evergreen.V27.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V26.Types.BackendModel -> ModelMigration Evergreen.V27.Types.BackendModel Evergreen.V27.Types.BackendMsg
backendModel old =
    ModelMigrated
        ( { grid = Evergreen.V27.Grid.Grid Dict.empty
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


frontendModel : Evergreen.V26.Types.FrontendModel -> ModelMigration Evergreen.V27.Types.FrontendModel Evergreen.V27.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V26.Types.FrontendMsg -> MsgMigration Evergreen.V27.Types.FrontendMsg Evergreen.V27.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
