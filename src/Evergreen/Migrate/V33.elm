module Evergreen.Migrate.V33 exposing (..)

import AssocList
import Dict
import Evergreen.V30.Types
import Evergreen.V33.Grid
import Evergreen.V33.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V30.Types.BackendModel -> ModelMigration Evergreen.V33.Types.BackendModel Evergreen.V33.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V30.Types.FrontendModel -> ModelMigration Evergreen.V33.Types.FrontendModel Evergreen.V33.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V30.Types.FrontendMsg -> MsgMigration Evergreen.V33.Types.FrontendMsg Evergreen.V33.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
