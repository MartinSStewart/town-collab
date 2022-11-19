module Evergreen.Migrate.V2 exposing (..)

import Evergreen.V1.Types
import Evergreen.V2.Types
import Lamdera.Migrations exposing (..)


backendModel : Evergreen.V1.Types.BackendModel -> ModelMigration Evergreen.V2.Types.BackendModel Evergreen.V2.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V1.Types.FrontendModel -> ModelMigration Evergreen.V2.Types.FrontendModel Evergreen.V2.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V1.Types.FrontendMsg -> MsgMigration Evergreen.V2.Types.FrontendMsg Evergreen.V2.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
