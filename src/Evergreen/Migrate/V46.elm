module Evergreen.Migrate.V46 exposing (..)

import AssocList
import Dict
import Evergreen.V45.Types
import Evergreen.V46.Grid
import Evergreen.V46.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V45.Types.BackendModel -> ModelMigration Evergreen.V46.Types.BackendModel Evergreen.V46.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V45.Types.FrontendModel -> ModelMigration Evergreen.V46.Types.FrontendModel Evergreen.V46.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V45.Types.FrontendMsg -> MsgMigration Evergreen.V46.Types.FrontendMsg Evergreen.V46.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
