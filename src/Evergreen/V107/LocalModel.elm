module Evergreen.V107.LocalModel exposing (..)


type LocalModel msg model
    = LocalModel
        { localMsgs : List msg
        , localModel : model
        , model : model
        }
