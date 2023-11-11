module NonemptyExtra exposing (maximumBy, minimumBy)

import List.Extra as List
import List.Nonempty exposing (Nonempty)


maximumBy : (a -> comparable) -> Nonempty a -> a
maximumBy by nonempty =
    List.maximumBy by (List.Nonempty.toList nonempty) |> Maybe.withDefault (List.Nonempty.head nonempty)


minimumBy : (a -> comparable) -> Nonempty a -> a
minimumBy by nonempty =
    List.minimumBy by (List.Nonempty.toList nonempty) |> Maybe.withDefault (List.Nonempty.head nonempty)
