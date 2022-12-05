module Evergreen.Migrate.V18 exposing (..)

import Evergreen.V17.Types
import Evergreen.V18.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V17.Types.BackendModel -> ModelMigration Evergreen.V18.Types.BackendModel Evergreen.V18.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V17.Types.FrontendModel -> ModelMigration Evergreen.V18.Types.FrontendModel Evergreen.V18.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V17.Types.FrontendMsg -> MsgMigration Evergreen.V18.Types.FrontendMsg Evergreen.V18.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
