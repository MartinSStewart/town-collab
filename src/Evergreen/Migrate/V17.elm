module Evergreen.Migrate.V17 exposing (..)

import Evergreen.V16.Types
import Evergreen.V17.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V16.Types.BackendModel -> ModelMigration Evergreen.V17.Types.BackendModel Evergreen.V17.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V16.Types.FrontendModel -> ModelMigration Evergreen.V17.Types.FrontendModel Evergreen.V17.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V16.Types.FrontendMsg -> MsgMigration Evergreen.V17.Types.FrontendMsg Evergreen.V17.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
