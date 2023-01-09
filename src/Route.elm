module Route exposing
    ( ConfirmEmailKey(..)
    , InviteToken
    , LoginToken
    , Route(..)
    , UnsubscribeEmailKey(..)
    , coordQueryParser
    , decode
    , encode
    , internalRoute
    , notifyMe
    , startPointAt
    , urlParser
    )

import Coord exposing (Coord)
import Id exposing (SecretId)
import Units exposing (WorldUnit)
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing ((</>), (<?>))
import Url.Parser.Query


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


startPointAt : Coord WorldUnit
startPointAt =
    Coord.tuple ( 0, 0 )


coordQueryParser : Url.Parser.Query.Parser Route
coordQueryParser =
    Url.Parser.Query.map4
        (\maybeX maybeY loginToken2 inviteToken2 ->
            InternalRoute
                { viewPoint =
                    ( Maybe.withDefault (Tuple.first startPointAt) (Maybe.map Units.tileUnit maybeX)
                    , Maybe.withDefault (Tuple.second startPointAt) (Maybe.map Units.tileUnit maybeY)
                    )
                , loginToken = Maybe.map Id.secretFromString loginToken2
                , inviteToken = Maybe.map Id.secretFromString inviteToken2
                }
        )
        (Url.Parser.Query.int "x")
        (Url.Parser.Query.int "y")
        (Url.Parser.Query.string loginToken)
        (Url.Parser.Query.string inviteToken)


urlParser : Url.Parser.Parser (Route -> b) b
urlParser =
    Url.Parser.top <?> coordQueryParser


decode : Url -> Maybe Route
decode =
    Url.Parser.parse urlParser


encode : Route -> String
encode route =
    case route of
        InternalRoute internalRoute_ ->
            let
                ( x, y ) =
                    Coord.toTuple internalRoute_.viewPoint
            in
            Url.Builder.absolute
                []
                (Url.Builder.int "x" x
                    :: Url.Builder.int "y" y
                    :: (case internalRoute_.loginToken of
                            Just loginToken2 ->
                                [ Url.Builder.string loginToken (Id.secretToString loginToken2) ]

                            Nothing ->
                                []
                       )
                )


loginToken =
    "login-token"


inviteToken =
    "invite-token"


notifyMe : String
notifyMe =
    "notify-me"


notifyMeConfirmation : String
notifyMeConfirmation =
    "a"


unsubscribe : String
unsubscribe =
    "b"


type Route
    = InternalRoute { viewPoint : Coord WorldUnit, loginToken : Maybe (SecretId LoginToken), inviteToken : Maybe (SecretId InviteToken) }


type ConfirmEmailKey
    = ConfirmEmailKey String


type UnsubscribeEmailKey
    = UnsubscribeEmailKey String


internalRoute : Coord WorldUnit -> Route
internalRoute viewPoint =
    InternalRoute { viewPoint = viewPoint, loginToken = Nothing, inviteToken = Nothing }
