module UrlHelper exposing (ConfirmEmailKey(..), InternalRoute(..), UnsubscribeEmailKey(..), coordQueryParser, encodeUrl, internalRoute, notifyMe, startPointAt, urlParser)

import Coord exposing (Coord)
import Env
import Units exposing (WorldUnit)
import Url.Builder
import Url.Parser exposing ((</>), (<?>))
import Url.Parser.Query


startPointAt : Coord WorldUnit
startPointAt =
    Coord.fromTuple ( 0, 0 )


coordQueryParser : Url.Parser.Query.Parser (Coord WorldUnit)
coordQueryParser =
    Url.Parser.Query.map2
        (\maybeX maybeY ->
            ( Maybe.withDefault (Tuple.first startPointAt) (Maybe.map Units.tileUnit maybeX)
            , Maybe.withDefault (Tuple.second startPointAt) (Maybe.map Units.tileUnit maybeY)
            )
        )
        (Url.Parser.Query.int "x")
        (Url.Parser.Query.int "y")


urlParser : Url.Parser.Parser (InternalRoute -> b) b
urlParser =
    Url.Parser.oneOf
        [ Url.Parser.top
            <?> coordQueryParser
            |> Url.Parser.map internalRoute
        , Url.Parser.s notifyMeConfirmation
            </> Url.Parser.string
            |> Url.Parser.map (ConfirmEmailKey >> EmailConfirmationRoute)
        , Url.Parser.s unsubscribe
            </> Url.Parser.string
            |> Url.Parser.map (UnsubscribeEmailKey >> EmailUnsubscribeRoute)
        ]


encodeUrl : InternalRoute -> String
encodeUrl route =
    case route of
        InternalRoute internalRoute_ ->
            let
                ( x, y ) =
                    Coord.toTuple internalRoute_.viewPoint
            in
            Url.Builder.relative
                [ "/" ]
                [ Url.Builder.int "x" x, Url.Builder.int "y" y ]

        EmailConfirmationRoute (ConfirmEmailKey key) ->
            Url.Builder.relative [ notifyMeConfirmation, key ] []

        EmailUnsubscribeRoute (UnsubscribeEmailKey key) ->
            Url.Builder.relative [ unsubscribe, key ] []


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
    = InternalRoute { viewPoint : Coord WorldUnit }
    | EmailConfirmationRoute ConfirmEmailKey
    | EmailUnsubscribeRoute UnsubscribeEmailKey


type ConfirmEmailKey
    = ConfirmEmailKey String


type UnsubscribeEmailKey
    = UnsubscribeEmailKey String


internalRoute : Coord WorldUnit -> InternalRoute
internalRoute viewPoint =
    InternalRoute { viewPoint = viewPoint }
