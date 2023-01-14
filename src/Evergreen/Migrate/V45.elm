module Evergreen.Migrate.V45 exposing (..)

import AssocList
import Dict
import Evergreen.V44.Types
import Evergreen.V45.Grid
import Evergreen.V45.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V44.Types.BackendModel -> ModelMigration Evergreen.V45.Types.BackendModel Evergreen.V45.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V44.Types.FrontendModel -> ModelMigration Evergreen.V45.Types.FrontendModel Evergreen.V45.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V44.Types.FrontendMsg -> MsgMigration Evergreen.V45.Types.FrontendMsg Evergreen.V45.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
