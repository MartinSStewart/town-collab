module Evergreen.Migrate.V20 exposing (..)

import Evergreen.V18.Types
import Evergreen.V20.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V18.Types.BackendModel -> ModelMigration Evergreen.V20.Types.BackendModel Evergreen.V20.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V18.Types.FrontendModel -> ModelMigration Evergreen.V20.Types.FrontendModel Evergreen.V20.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V18.Types.FrontendMsg -> MsgMigration Evergreen.V20.Types.FrontendMsg Evergreen.V20.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
