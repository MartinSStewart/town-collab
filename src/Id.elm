module Id exposing (CowId, EventId, Id, MailId, TrainId, UserId, fromInt, increment, nextId, toInt)

import AssocList


type Id a
    = Id Int


type MailId
    = MailId Never


type UserId
    = UserId Never


type TrainId
    = TrainId Never


type EventId
    = EventId Never


type CowId
    = CowId Never


fromInt : Int -> Id a
fromInt =
    Id


toInt : Id a -> Int
toInt (Id int) =
    int


increment : Id a -> Id a
increment (Id id) =
    Id (id + 1)


nextId : AssocList.Dict (Id a) b -> Id a
nextId ids =
    AssocList.toList ids
        |> List.map (Tuple.first >> toInt)
        |> List.maximum
        |> Maybe.withDefault 0
        |> (+) 1
        |> fromInt
