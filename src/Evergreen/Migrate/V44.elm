module Evergreen.Migrate.V44 exposing (..)

import AssocList
import Dict
import Evergreen.V43.Types
import Evergreen.V44.Grid
import Evergreen.V44.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V43.Types.BackendModel -> ModelMigration Evergreen.V44.Types.BackendModel Evergreen.V44.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V43.Types.FrontendModel -> ModelMigration Evergreen.V44.Types.FrontendModel Evergreen.V44.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V43.Types.FrontendMsg -> MsgMigration Evergreen.V44.Types.FrontendMsg Evergreen.V44.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
