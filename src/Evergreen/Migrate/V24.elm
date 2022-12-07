module Evergreen.Migrate.V24 exposing (..)

import Evergreen.V23.Types
import Evergreen.V24.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V23.Types.BackendModel -> ModelMigration Evergreen.V24.Types.BackendModel Evergreen.V24.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V23.Types.FrontendModel -> ModelMigration Evergreen.V24.Types.FrontendModel Evergreen.V24.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V23.Types.FrontendMsg -> MsgMigration Evergreen.V24.Types.FrontendMsg Evergreen.V24.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
