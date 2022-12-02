module Evergreen.Migrate.V16 exposing (..)

import Evergreen.V15.Types
import Evergreen.V16.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V15.Types.BackendModel -> ModelMigration Evergreen.V16.Types.BackendModel Evergreen.V16.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V15.Types.FrontendModel -> ModelMigration Evergreen.V16.Types.FrontendModel Evergreen.V16.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V15.Types.FrontendMsg -> MsgMigration Evergreen.V16.Types.FrontendMsg Evergreen.V16.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
