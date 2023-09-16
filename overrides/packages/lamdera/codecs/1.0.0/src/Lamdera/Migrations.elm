module Lamdera.Migrations exposing (ModelMigration(..), MsgMigration(..), UnimplementedMigration(..))

{-|

@docs ModelMigration, MsgMigration, UnimplementedMigration

-}


{-| -}
type ModelMigration model msg
    = ModelUnchanged
    | ModelMigrated ( model, Cmd msg )


{-| -}
type MsgMigration msg cmdMsg
    = MsgUnchanged
    | MsgMigrated ( msg, Cmd cmdMsg )
    | MsgOldValueIgnored


{-| -}
type UnimplementedMigration
    = Unimplemented
