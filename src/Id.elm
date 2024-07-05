module Id exposing
    ( AnimalId(..)
    , EventId(..)
    , Id(..)
    , MailId(..)
    , NpcId(..)
    , OneTimePasswordId(..)
    , SecretId(..)
    , TrainId(..)
    , UserId(..)
    , equals
    , fromInt
    , increment
    , oneTimePasswordLength
    , secretFromString
    , secretIdEquals
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


type NpcId
    = PersonId Never


type OneTimePasswordId
    = OneTimePasswordId Never


oneTimePasswordLength : number
oneTimePasswordLength =
    6


equals : Id a -> Id a -> Bool
equals (Id a) (Id b) =
    a - b == 0


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


{-| Use this when testing equality for secret keys. It is less prone to timing attacks
-}
secretIdEquals : SecretId a -> SecretId a -> Bool
secretIdEquals (SecretId a) (SecretId b) =
    if String.length a == String.length b then
        List.map2 (\charA charB -> charA == charB) (String.toList a) (String.toList b) |> List.all identity

    else
        False
