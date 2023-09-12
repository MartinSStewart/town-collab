module Evergreen.Migrate.V85 exposing (..)

{-| This migration file was automatically generated by the lamdera compiler.

It includes:

  - A migration for each of the 6 Lamdera core types that has changed
  - A function named `migrate_ModuleName_TypeName` for each changed/custom type

Expect to see:

  - `Unimplementеd` values as placeholders wherever I was unable to figure out a clear migration path for you
  - `@NOTICE` comments for things you should know about, i.e. new custom type constructors that won't get any
    value mappings from the old type by default

You can edit this file however you wish! It won't be generated again.

See <https://dashboard.lamdera.app/docs/evergreen> for more info.

-}

import AssocList
import AssocSet
import Dict
import Evergreen.V84.Animal
import Evergreen.V84.Audio
import Evergreen.V84.Bounds
import Evergreen.V84.Change
import Evergreen.V84.Color
import Evergreen.V84.Coord
import Evergreen.V84.Cursor
import Evergreen.V84.DisplayName
import Evergreen.V84.EmailAddress
import Evergreen.V84.Geometry.Types
import Evergreen.V84.Grid
import Evergreen.V84.GridCell
import Evergreen.V84.Id
import Evergreen.V84.IdDict
import Evergreen.V84.Keyboard
import Evergreen.V84.LocalGrid
import Evergreen.V84.LocalModel
import Evergreen.V84.MailEditor
import Evergreen.V84.Point2d
import Evergreen.V84.Sound
import Evergreen.V84.TextInput
import Evergreen.V84.Tile
import Evergreen.V84.Tool
import Evergreen.V84.Train
import Evergreen.V84.Types
import Evergreen.V84.Ui
import Evergreen.V84.Units
import Evergreen.V84.User
import Evergreen.V85.Animal
import Evergreen.V85.Audio
import Evergreen.V85.Bounds
import Evergreen.V85.Change
import Evergreen.V85.Color
import Evergreen.V85.Coord
import Evergreen.V85.Cursor
import Evergreen.V85.DisplayName
import Evergreen.V85.EmailAddress
import Evergreen.V85.Geometry.Types
import Evergreen.V85.Grid
import Evergreen.V85.GridCell
import Evergreen.V85.Id
import Evergreen.V85.IdDict
import Evergreen.V85.Keyboard
import Evergreen.V85.LocalGrid
import Evergreen.V85.LocalModel
import Evergreen.V85.MailEditor
import Evergreen.V85.Point2d
import Evergreen.V85.Sound
import Evergreen.V85.TextInput
import Evergreen.V85.Tile
import Evergreen.V85.Tool
import Evergreen.V85.Train
import Evergreen.V85.Types
import Evergreen.V85.Ui
import Evergreen.V85.Units
import Evergreen.V85.User
import Lamdera.Migrations exposing (..)
import List
import List.Nonempty
import Maybe
import Quantity


frontendModel : Evergreen.V84.Types.FrontendModel -> ModelMigration Evergreen.V85.Types.FrontendModel Evergreen.V85.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


backendModel : Evergreen.V84.Types.BackendModel -> ModelMigration Evergreen.V85.Types.BackendModel Evergreen.V85.Types.BackendMsg
backendModel old =
    ModelUnchanged


frontendMsg : Evergreen.V84.Types.FrontendMsg -> MsgMigration Evergreen.V85.Types.FrontendMsg Evergreen.V85.Types.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend : Evergreen.V84.Types.ToBackend -> MsgMigration Evergreen.V85.Types.ToBackend Evergreen.V85.Types.BackendMsg
toBackend old =
    MsgUnchanged


backendMsg : Evergreen.V84.Types.BackendMsg -> MsgMigration Evergreen.V85.Types.BackendMsg Evergreen.V85.Types.BackendMsg
backendMsg old =
    MsgUnchanged


toFrontend : Evergreen.V84.Types.ToFrontend -> MsgMigration Evergreen.V85.Types.ToFrontend Evergreen.V85.Types.FrontendMsg
toFrontend old =
    MsgUnchanged
