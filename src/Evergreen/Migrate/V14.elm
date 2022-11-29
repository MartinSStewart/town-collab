module Evergreen.Migrate.V14 exposing (..)

import Evergreen.V12.Types
import Evergreen.V14.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V12.Types.BackendModel -> ModelMigration Evergreen.V14.Types.BackendModel Evergreen.V14.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V12.Types.FrontendModel -> ModelMigration Evergreen.V14.Types.FrontendModel Evergreen.V14.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V12.Types.FrontendMsg -> MsgMigration Evergreen.V14.Types.FrontendMsg Evergreen.V14.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
