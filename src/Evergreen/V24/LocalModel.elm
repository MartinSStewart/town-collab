module Evergreen.V24.LocalModel exposing (..)


type LocalModel msg model
    = LocalModel
        { localMsgs : List msg
        , localModel : model
        , model : model
        }
