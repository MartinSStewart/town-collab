module Id exposing (EventId, Id, MailId, TrainId, UserId, fromInt, increment, toInt)


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


fromInt : Int -> Id a
fromInt =
    Id


toInt : Id a -> Int
toInt (Id int) =
    int


increment : Id a -> Id a
increment (Id id) =
    Id (id + 1)
