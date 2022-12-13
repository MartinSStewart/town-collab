module Evergreen.Migrate.V29 exposing (..)

import AssocList
import Dict
import Evergreen.V28.Types
import Evergreen.V29.Grid
import Evergreen.V29.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V28.Types.BackendModel -> ModelMigration Evergreen.V29.Types.BackendModel Evergreen.V29.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V28.Types.FrontendModel -> ModelMigration Evergreen.V29.Types.FrontendModel Evergreen.V29.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V28.Types.FrontendMsg -> MsgMigration Evergreen.V29.Types.FrontendMsg Evergreen.V29.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
