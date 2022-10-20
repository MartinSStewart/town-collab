module UrlHelper exposing (ConfirmEmailKey(..), InternalRoute(..), UnsubscribeEmailKey(..), coordQueryParser, encodeUrl, internalRoute, notifyMe, startPointAt, urlParser)

import Coord exposing (Coord)
import Env
import Units exposing (TileUnit)
import Url.Builder
import Url.Parser exposing ((</>), (<?>))
import Url.Parser.Query


startPointAt : Coord TileUnit
startPointAt =
    Coord.fromRawCoord ( 0, 0 )


coordQueryParser : Url.Parser.Query.Parser (Coord TileUnit)
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
            |> Url.Parser.map (internalRoute False)
        , Url.Parser.s notifyMe
            <?> coordQueryParser
            |> Url.Parser.map (internalRoute True)
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
                    Coord.toRawCoord internalRoute_.viewPoint
            in
            Url.Builder.relative
                (if internalRoute_.showNotifyMe then
                    [ notifyMe ]

                 else
                    [ "/" ]
                )
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
    = InternalRoute { showNotifyMe : Bool, viewPoint : Coord TileUnit }
    | EmailConfirmationRoute ConfirmEmailKey
    | EmailUnsubscribeRoute UnsubscribeEmailKey


type ConfirmEmailKey
    = ConfirmEmailKey String


type UnsubscribeEmailKey
    = UnsubscribeEmailKey String


internalRoute : Bool -> Coord TileUnit -> InternalRoute
internalRoute showNotifyMe viewPoint =
    InternalRoute { showNotifyMe = showNotifyMe, viewPoint = viewPoint }
