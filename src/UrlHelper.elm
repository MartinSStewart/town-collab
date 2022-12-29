module UrlHelper exposing
    ( ConfirmEmailKey(..)
    , InternalRoute(..)
    , LoginToken(..)
    , UnsubscribeEmailKey(..)
    , coordQueryParser
    , encodeUrl
    , internalRoute
    , notifyMe
    , startPointAt
    , urlParser
    )

import Coord exposing (Coord)
import Units exposing (WorldUnit)
import Url.Builder
import Url.Parser exposing ((</>), (<?>))
import Url.Parser.Query


type LoginToken
    = LoginToken String


startPointAt : Coord WorldUnit
startPointAt =
    Coord.tuple ( 0, 0 )


coordQueryParser : Url.Parser.Query.Parser InternalRoute
coordQueryParser =
    Url.Parser.Query.map3
        (\maybeX maybeY loginToken2 ->
            InternalRoute
                { viewPoint =
                    ( Maybe.withDefault (Tuple.first startPointAt) (Maybe.map Units.tileUnit maybeX)
                    , Maybe.withDefault (Tuple.second startPointAt) (Maybe.map Units.tileUnit maybeY)
                    )
                , loginToken = Maybe.map LoginToken loginToken2
                }
        )
        (Url.Parser.Query.int "x")
        (Url.Parser.Query.int "y")
        (Url.Parser.Query.string loginToken)


urlParser : Url.Parser.Parser (InternalRoute -> b) b
urlParser =
    Url.Parser.top <?> coordQueryParser


encodeUrl : InternalRoute -> String
encodeUrl route =
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
                            Just (LoginToken loginToken2) ->
                                [ Url.Builder.string loginToken loginToken2 ]

                            Nothing ->
                                []
                       )
                )


loginToken =
    "login-token"


notifyMe : String
notifyMe =
    "notify-me"


notifyMeConfirmation : String
notifyMeConfirmation =
    "a"


unsubscribe : String
unsubscribe =
    "b"


type InternalRoute
    = InternalRoute { viewPoint : Coord WorldUnit, loginToken : Maybe LoginToken }


type ConfirmEmailKey
    = ConfirmEmailKey String


type UnsubscribeEmailKey
    = UnsubscribeEmailKey String


internalRoute : Coord WorldUnit -> InternalRoute
internalRoute viewPoint =
    InternalRoute { viewPoint = viewPoint, loginToken = Nothing }
