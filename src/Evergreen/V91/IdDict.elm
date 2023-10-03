module Evergreen.V91.IdDict exposing (..)


type NColor
    = Red
    | Black


type IdDict k v
    = RBNode_elm_builtin NColor Int v (IdDict k v) (IdDict k v)
    | RBEmpty_elm_builtin
