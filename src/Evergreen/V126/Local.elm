module Evergreen.V126.Local exposing (..)


type Local msg model
    = Local
        { localMsgs : List msg
        , localModel : model
        , model : model
        }
