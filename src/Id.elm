module Id exposing (Id, MailId, TrainId, UserId, fromInt, toInt)


type Id a
    = Id Int


type MailId
    = MailId Never


type UserId
    = UserId Never


type TrainId
    = TrainId Never


fromInt : Int -> Id a
fromInt =
    Id


toInt : Id a -> Int
toInt (Id int) =
    int
