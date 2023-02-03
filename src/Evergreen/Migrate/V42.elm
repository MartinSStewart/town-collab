module Evergreen.Migrate.V42 exposing (..)

import AssocList
import Dict
import Evergreen.V33.Types
import Evergreen.V42.Grid
import Evergreen.V42.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V33.Types.BackendModel -> ModelMigration Evergreen.V42.Types.BackendModel Evergreen.V42.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V33.Types.FrontendModel -> ModelMigration Evergreen.V42.Types.FrontendModel Evergreen.V42.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V33.Types.FrontendMsg -> MsgMigration Evergreen.V42.Types.FrontendMsg Evergreen.V42.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
