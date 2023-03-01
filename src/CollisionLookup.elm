module CollisionLookup exposing (CollisionLookup, addItem, collisionCandidates, init)

import Dict exposing (Dict)
import List.Nonempty exposing (Nonempty)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity)


type CollisionLookup unit a
    = CollisionLookup { dict : Dict ( Int, Int ) (Nonempty a), collisionRadius : Float }


init : Quantity Float unit -> CollisionLookup unit a
init collisionRadius =
    CollisionLookup { dict = Dict.empty, collisionRadius = Quantity.unwrap collisionRadius }


addItem : Point2d unit coordinate -> a -> CollisionLookup unit a -> CollisionLookup unit a
addItem position value (CollisionLookup lookup) =
    let
        { x, y } =
            Point2d.unwrap position

        x2 =
            floor (x * lookup.collisionRadius)

        y2 =
            floor (y * lookup.collisionRadius)
    in
    { dict =
        List.foldl
            (\( offsetX, offsetY ) dict ->
                Dict.update ( x2 + offsetX, y2 + offsetY )
                    (\maybeList ->
                        (case maybeList of
                            Just nonempty ->
                                List.Nonempty.cons value nonempty

                            Nothing ->
                                List.Nonempty.singleton value
                        )
                            |> Just
                    )
                    dict
            )
            lookup.dict
            offsets
    , collisionRadius = lookup.collisionRadius
    }
        |> CollisionLookup


collisionCandidates : Point2d unit coordinate -> CollisionLookup unit a -> List a
collisionCandidates position (CollisionLookup lookup) =
    let
        { x, y } =
            Point2d.unwrap position

        x2 =
            floor (x * lookup.collisionRadius)

        y2 =
            floor (y * lookup.collisionRadius)
    in
    List.foldl
        (\( offsetX, offsetY ) items ->
            case Dict.get ( x2 + offsetX, y2 + offsetY ) lookup.dict of
                Just nonempty ->
                    List.Nonempty.toList nonempty ++ items

                Nothing ->
                    items
        )
        []
        offsets


offsets : List ( Int, Int )
offsets =
    [ ( -1, -1 )
    , ( 0, -1 )
    , ( 1, -1 )
    , ( -1, 0 )
    , ( 0, 0 )
    , ( 1, 0 )
    , ( -1, 1 )
    , ( 0, 1 )
    , ( 1, 1 )
    ]
