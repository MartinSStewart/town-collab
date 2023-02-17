module User exposing (FrontendUser, InviteTree(..), drawInviteTree)

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


drawInviteTree : IdDict UserId FrontendUser -> InviteTree -> Ui.Element id
drawInviteTree dict (InviteTree tree) =
    let
        childNodes : List (Ui.Element id)
        childNodes =
            List.map
                (\child ->
                    Ui.row
                        { spacing = 2, padding = Ui.noPadding }
                        [ Ui.colorScaledText Color.outlineColor charScale "─", drawInviteTree dict child ]
                )
                tree.invited
    in
    Ui.column
        { spacing = 0, padding = Ui.noPadding }
        [ case IdDict.get tree.userId dict of
            Just user ->
                Ui.row
                    { spacing = 4 * charScale, padding = Ui.noPadding }
                    [ Ui.scaledText charScale (DisplayName.nameAndId user.name tree.userId)
                    , Ui.center
                        { size = Coord.xy 30 (charScale * Coord.yRaw Sprite.charSize) }
                        (Ui.colorSprite
                            { colors = user.handColor
                            , size = Coord.xy 30 23
                            , texturePosition = Coord.xy 533 28
                            , textureSize = Coord.xy 30 23
                            }
                        )
                    ]

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
