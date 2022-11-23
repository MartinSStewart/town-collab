module Evergreen.Migrate.V8 exposing (..)

import Evergreen.V6.Types
import Evergreen.V8.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V6.Types.BackendModel -> ModelMigration Evergreen.V8.Types.BackendModel Evergreen.V8.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V6.Types.FrontendModel -> ModelMigration Evergreen.V8.Types.FrontendModel Evergreen.V8.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V6.Types.FrontendMsg -> MsgMigration Evergreen.V8.Types.FrontendMsg Evergreen.V8.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
