module Direction4 exposing (Direction4(..), Turn(..), turn)


type Turn
    = TurnLeft
    | TurnRight
    | NoTurn
    | TurnAround


type Direction4
    = North
    | South
    | West
    | East


turn : Turn -> Direction4 -> Direction4
turn turn2 direction =
    case turn2 of
        NoTurn ->
            direction

        TurnLeft ->
            case direction of
                North ->
                    West

                South ->
                    East

                West ->
                    South

                East ->
                    North

        TurnRight ->
            case direction of
                North ->
                    East

                South ->
                    West

                West ->
                    North

                East ->
                    South

        TurnAround ->
            case direction of
                North ->
                    South

                South ->
                    North

                West ->
                    East

                East ->
                    West
