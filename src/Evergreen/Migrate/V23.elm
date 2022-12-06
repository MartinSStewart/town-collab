module Evergreen.Migrate.V23 exposing (..)

import Evergreen.V20.Types
import Evergreen.V23.Types
import Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..))


backendModel : Evergreen.V20.Types.BackendModel -> ModelMigration Evergreen.V23.Types.BackendModel Evergreen.V23.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendModel : Evergreen.V20.Types.FrontendModel -> ModelMigration Evergreen.V23.Types.FrontendModel Evergreen.V23.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V20.Types.FrontendMsg -> MsgMigration Evergreen.V23.Types.FrontendMsg Evergreen.V23.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend old =
    MsgUnchanged


toFrontend old =
    MsgUnchanged


backendMsg old =
    MsgUnchanged
