module Evergreen.Migrate.V6 exposing (..)

import Evergreen.V2.Types
import Evergreen.V6.Types
import Lamdera.Migrations exposing (..)


backendModel : Evergreen.V2.Types.BackendModel -> ModelMigration Evergreen.V6.Types.BackendModel Evergreen.V6.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V2.Types.FrontendModel -> ModelMigration Evergreen.V6.Types.FrontendModel Evergreen.V6.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V2.Types.FrontendMsg -> MsgMigration Evergreen.V6.Types.FrontendMsg Evergreen.V6.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
