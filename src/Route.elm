module Route exposing
    ( ConfirmEmailKey(..)
    , InviteToken(..)
    , LoginOrInviteToken(..)
    , LoginToken(..)
    , Route(..)
    , UnsubscribeEmailKey(..)
    , decode
    , encode
    , internalRoute
    , startPointAt
    , urlParser
    )

import Coord exposing (Coord)
import Id exposing (SecretId)
import Units exposing (WorldUnit)
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing ((<?>))
import Url.Parser.Query


type LoginToken
    = LoginToken Never


type InviteToken
    = InviteToken Never


type LoginOrInviteToken
    = LoginToken2 (SecretId LoginToken)
    | InviteToken2 (SecretId InviteToken)


startPointAt : Coord WorldUnit
startPointAt =
    Coord.tuple ( 183, 54 )


coordQueryParser : Url.Parser.Query.Parser Route
coordQueryParser =
    Url.Parser.Query.map5
        (\maybeX maybeY showInbox2 loginToken2 inviteToken2 ->
            InternalRoute
                { viewPoint =
                    ( Maybe.withDefault (Tuple.first startPointAt) (Maybe.map Units.tileUnit maybeX)
                    , Maybe.withDefault (Tuple.second startPointAt) (Maybe.map Units.tileUnit maybeY)
                    )
                , showInbox =
                    case showInbox2 of
                        Just "true" ->
                            True

                        _ ->
                            False
                , loginOrInviteToken =
                    case ( loginToken2, inviteToken2 ) of
                        ( _, Just inviteToken3 ) ->
                            Id.secretFromString inviteToken3 |> InviteToken2 |> Just

                        ( Just loginToken3, Nothing ) ->
                            Id.secretFromString loginToken3 |> LoginToken2 |> Just

                        ( Nothing, Nothing ) ->
                            Nothing
                }
        )
        (Url.Parser.Query.int "x")
        (Url.Parser.Query.int "y")
        (Url.Parser.Query.string showInbox)
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
                    :: (case internalRoute_.loginOrInviteToken of
                            Just (LoginToken2 loginToken2) ->
                                [ Url.Builder.string loginToken (Id.secretToString loginToken2) ]

                            Just (InviteToken2 inviteToken2) ->
                                [ Url.Builder.string inviteToken (Id.secretToString inviteToken2) ]

                            Nothing ->
                                []
                       )
                    ++ (if internalRoute_.showInbox then
                            [ Url.Builder.string showInbox "true" ]

                        else
                            []
                       )
                )


loginToken =
    "login-token"


showInbox =
    "show-inbox"


inviteToken =
    "invite-token"


type Route
    = InternalRoute { viewPoint : Coord WorldUnit, showInbox : Bool, loginOrInviteToken : Maybe LoginOrInviteToken }


type ConfirmEmailKey
    = ConfirmEmailKey String


type UnsubscribeEmailKey
    = UnsubscribeEmailKey String


internalRoute : Coord WorldUnit -> Route
internalRoute viewPoint =
    InternalRoute { viewPoint = viewPoint, showInbox = False, loginOrInviteToken = Nothing }
