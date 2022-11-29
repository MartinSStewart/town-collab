module Evergreen.Migrate.V15 exposing (..)

import Evergreen.V14.Types
import Evergreen.V15.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V14.Types.BackendModel -> ModelMigration Evergreen.V15.Types.BackendModel Evergreen.V15.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V14.Types.FrontendModel -> ModelMigration Evergreen.V15.Types.FrontendModel Evergreen.V15.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V14.Types.FrontendMsg -> MsgMigration Evergreen.V15.Types.FrontendMsg Evergreen.V15.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
