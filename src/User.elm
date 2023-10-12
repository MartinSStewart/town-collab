module User exposing (FrontendUser, InviteTree(..), drawInviteTree, nameAndHand)

import Color exposing (Colors)
import Coord
import Cursor exposing (Cursor)
import DisplayName exposing (DisplayName)
import Id exposing (Id, UserId)
import IdDict exposing (IdDict)
import List.Extra
import Sprite
import Ui exposing (BorderAndFill(..))


type alias FrontendUser =
    { name : DisplayName
    , handColor : Colors
    , cursor : Maybe Cursor
    }


type InviteTree
    = InviteTree
        { userId : Id UserId
        , invited : List InviteTree
        }


charScale =
    2


onlineColor =
    Color.rgb255 80 255 100


dotSize =
    Coord.xy 8 8


onlineIcon : Ui.Element id
onlineIcon =
    Ui.quads
        { size = Coord.scalar charScale Sprite.charSize
        , vertices =
            Sprite.rectangle onlineColor
                (Coord.scalar charScale Sprite.charSize |> Coord.minus dotSize |> Coord.divide (Coord.xy 2 2))
                dotSize
        }


nameAndHand : Maybe (Id UserId) -> Id UserId -> FrontendUser -> Ui.Element id
nameAndHand currentUserId userId user =
    Ui.row
        { spacing = 4 * charScale, padding = Ui.noPadding }
        [ Ui.row
            { spacing = 0, padding = Ui.noPadding }
            [ case user.cursor of
                Just _ ->
                    onlineIcon

                Nothing ->
                    Ui.none
            , Ui.colorScaledText Color.black charScale (DisplayName.nameAndId user.name userId)
            ]
        , Ui.center
            { size = Coord.xy 30 (charScale * Coord.yRaw Sprite.charSize) }
            (Ui.colorSprite
                { colors = user.handColor
                , size = Coord.xy 30 23
                , texturePosition = Coord.xy 533 28
                , textureSize = Coord.xy 30 23
                }
            )
        , if currentUserId == Just userId then
            Ui.text "(You)"

          else
            Ui.none
        ]


drawInviteTree : Maybe (Id UserId) -> IdDict UserId FrontendUser -> InviteTree -> Ui.Element id
drawInviteTree currentUserId dict (InviteTree tree) =
    let
        childNodes : List (Ui.Element id)
        childNodes =
            List.map
                (\child ->
                    Ui.row
                        { spacing = 2, padding = Ui.noPadding }
                        [ Ui.colorScaledText Color.outlineColor charScale "─"
                        , drawInviteTree currentUserId dict child
                        ]
                )
                tree.invited
    in
    Ui.column
        { spacing = 0, padding = Ui.noPadding }
        [ case IdDict.get tree.userId dict of
            Just user ->
                nameAndHand currentUserId tree.userId user

            Nothing ->
                Ui.colorScaledText Color.errorColor charScale "Not found"
        , Ui.row
            { spacing = 0
            , padding =
                { topLeft = Coord.xy (-1 + charScale * Coord.xRaw Sprite.charSize // 2) 0
                , bottomRight = Coord.origin
                }
            }
            [ case List.Extra.unconsLast childNodes of
                Just ( _, rest ) ->
                    Ui.el
                        { padding =
                            { topLeft =
                                Coord.xy 2
                                    (List.map (\element -> Ui.size element |> Coord.yRaw) rest
                                        |> List.sum
                                        |> (+) (charScale + charScale * Coord.yRaw Sprite.charSize // 2)
                                    )
                            , bottomRight = Coord.origin
                            }
                        , inFront = []
                        , borderAndFill = FillOnly Color.outlineColor
                        }
                        Ui.none

                Nothing ->
                    Ui.none
            , Ui.column
                { spacing = 0, padding = Ui.noPadding }
                childNodes
            ]
        ]
