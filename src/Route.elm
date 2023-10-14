module Route exposing
    ( ConfirmEmailKey(..)
    , InviteToken(..)
    , LoginOrInviteToken(..)
    , LoginToken(..)
    , PageRoute(..)
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
import List.Extra as List
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


type PageRoute
    = WorldRoute
    | MailEditorRoute
    | AdminRoute
    | InviteTreeRoute


startPointAt : Coord WorldUnit
startPointAt =
    Coord.tuple ( 183, 54 )


coordQueryParser : Url.Parser.Query.Parser Route
coordQueryParser =
    Url.Parser.Query.map5
        (\maybeX maybeY maybePage loginToken2 inviteToken2 ->
            InternalRoute
                { viewPoint =
                    ( Maybe.withDefault (Tuple.first startPointAt) (Maybe.map Units.tileUnit maybeX)
                    , Maybe.withDefault (Tuple.second startPointAt) (Maybe.map Units.tileUnit maybeY)
                    )
                , page =
                    case List.find (\( _, name ) -> Just name == maybePage) pages of
                        Just ( page, _ ) ->
                            page

                        Nothing ->
                            WorldRoute
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
        (Url.Parser.Query.string pageParameter)
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
                    ++ (case List.find (\( page, _ ) -> page == internalRoute_.page) pages of
                            Just ( _, name ) ->
                                [ Url.Builder.string "page" name ]

                            Nothing ->
                                []
                       )
                )


pages : List ( PageRoute, String )
pages =
    [ ( MailEditorRoute, "mail" )
    , ( AdminRoute, "admin" )
    , ( InviteTreeRoute, "users" )
    ]


loginToken =
    "login-token"


pageParameter =
    "page"


inviteToken =
    "invite-token"


type Route
    = InternalRoute
        { viewPoint : Coord WorldUnit
        , page : PageRoute
        , loginOrInviteToken : Maybe LoginOrInviteToken
        }


type ConfirmEmailKey
    = ConfirmEmailKey String


type UnsubscribeEmailKey
    = UnsubscribeEmailKey String


internalRoute : Coord WorldUnit -> Route
internalRoute viewPoint =
    InternalRoute { viewPoint = viewPoint, page = WorldRoute, loginOrInviteToken = Nothing }
