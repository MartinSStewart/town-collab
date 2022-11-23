module Evergreen.Migrate.V9 exposing (..)

import Evergreen.V8.Types
import Evergreen.V9.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V8.Types.BackendModel -> ModelMigration Evergreen.V9.Types.BackendModel Evergreen.V9.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V8.Types.FrontendModel -> ModelMigration Evergreen.V9.Types.FrontendModel Evergreen.V9.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V8.Types.FrontendMsg -> MsgMigration Evergreen.V9.Types.FrontendMsg Evergreen.V9.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
