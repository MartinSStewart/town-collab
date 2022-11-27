module Evergreen.Migrate.V10 exposing (..)

import Evergreen.V10.Types
import Evergreen.V9.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V9.Types.BackendModel -> ModelMigration Evergreen.V10.Types.BackendModel Evergreen.V10.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V9.Types.FrontendModel -> ModelMigration Evergreen.V10.Types.FrontendModel Evergreen.V10.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V9.Types.FrontendMsg -> MsgMigration Evergreen.V10.Types.FrontendMsg Evergreen.V10.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
