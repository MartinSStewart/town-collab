module Evergreen.Migrate.V11 exposing (..)

import Evergreen.V10.Types
import Evergreen.V11.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V10.Types.BackendModel -> ModelMigration Evergreen.V11.Types.BackendModel Evergreen.V11.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V10.Types.FrontendModel -> ModelMigration Evergreen.V11.Types.FrontendModel Evergreen.V11.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V10.Types.FrontendMsg -> MsgMigration Evergreen.V11.Types.FrontendMsg Evergreen.V11.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
