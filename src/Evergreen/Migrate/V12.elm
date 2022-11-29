module Evergreen.Migrate.V12 exposing (..)

import Evergreen.V11.Types
import Evergreen.V12.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V11.Types.BackendModel -> ModelMigration Evergreen.V12.Types.BackendModel Evergreen.V12.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V11.Types.FrontendModel -> ModelMigration Evergreen.V12.Types.FrontendModel Evergreen.V12.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V11.Types.FrontendMsg -> MsgMigration Evergreen.V12.Types.FrontendMsg Evergreen.V12.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
