module Evergreen.Migrate.V43 exposing (..)

import AssocList
import Dict
import Evergreen.V42.Types
import Evergreen.V43.Grid
import Evergreen.V43.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V42.Types.BackendModel -> ModelMigration Evergreen.V43.Types.BackendModel Evergreen.V43.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V42.Types.FrontendModel -> ModelMigration Evergreen.V43.Types.FrontendModel Evergreen.V43.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V42.Types.FrontendMsg -> MsgMigration Evergreen.V43.Types.FrontendMsg Evergreen.V43.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
