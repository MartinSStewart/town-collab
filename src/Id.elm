module Id exposing
    ( AnimalId(..)
    , EventId(..)
    , Id(..)
    , MailId(..)
    , OneTimePassword(..)
    , PersonId(..)
    , SecretId(..)
    , TrainId(..)
    , UserId(..)
    , fromInt
    , increment
    , secretFromString
    , secretToString
    , toInt
    )


type SecretId a
    = SecretId String


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


type AnimalId
    = CowId Never


type PersonId
    = PersonId Never


type OneTimePassword
    = OneTimePassword Never


fromInt : Int -> Id a
fromInt =
    Id


toInt : Id a -> Int
toInt (Id int) =
    int


increment : Id a -> Id a
increment (Id id) =
    Id (id + 1)


secretToString : SecretId a -> String
secretToString (SecretId secretId) =
    secretId


secretFromString : String -> SecretId a
secretFromString =
    SecretId
