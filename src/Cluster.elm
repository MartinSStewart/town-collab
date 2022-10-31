module Cluster exposing (cluster)

import Bounds exposing (Bounds)
import Coord exposing (Coord, RawCellCoord)
import List.Nonempty exposing (Nonempty(..))
import Quantity exposing (Quantity(..))
import Set exposing (Set)
import Units exposing (CellUnit)


maxSize : Coord units
maxSize =
    Coord.fromTuple ( 4, 3 )


cluster : Set RawCellCoord -> List ( Bounds CellUnit, Nonempty (Coord CellUnit) )
cluster coords =
    clusterHelper coords []
        |> List.map
            (\( _, inside ) ->
                ( Bounds.fromCoords inside, inside )
            )


clusterHelper :
    Set RawCellCoord
    -> List ( Bounds CellUnit, Nonempty (Coord CellUnit) )
    -> List ( Bounds CellUnit, Nonempty (Coord CellUnit) )
clusterHelper coords allBounds =
    case Set.toList coords of
        head :: _ ->
            let
                coord =
                    Coord.fromTuple head

                boundsMin =
                    toCoarseGrid coord

                bounds =
                    Bounds.bounds boundsMin (Coord.addTuple maxSize boundsMin)

                ( inside, outside ) =
                    Set.partition (\a -> Bounds.contains (Coord.fromTuple a) bounds) coords
            in
            clusterHelper
                outside
                (( bounds
                 , Nonempty (Coord.fromTuple head)
                    (Set.remove head inside
                        |> Set.toList
                        |> List.map Coord.fromTuple
                    )
                 )
                    :: allBounds
                )

        [] ->
            allBounds


toCoarseGrid : Coord Units.CellUnit -> Coord Units.CellUnit
toCoarseGrid ( Quantity x, Quantity y ) =
    let
        offset =
            1000000

        ( Quantity w, Quantity h ) =
            maxSize
    in
    ( (x + (w * offset)) // w - offset |> (*) w |> Quantity
    , (y + (h * offset)) // h - offset |> (*) h |> Quantity
    )
