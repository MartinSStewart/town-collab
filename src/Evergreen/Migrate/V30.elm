module Evergreen.Migrate.V30 exposing (..)

import AssocList
import Dict
import Evergreen.V29.Types
import Evergreen.V30.Grid
import Evergreen.V30.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V29.Types.BackendModel -> ModelMigration Evergreen.V30.Types.BackendModel Evergreen.V30.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V29.Types.FrontendModel -> ModelMigration Evergreen.V30.Types.FrontendModel Evergreen.V30.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V29.Types.FrontendMsg -> MsgMigration Evergreen.V30.Types.FrontendMsg Evergreen.V30.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
