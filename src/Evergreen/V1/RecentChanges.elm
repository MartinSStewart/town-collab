module Evergreen.V1.RecentChanges exposing (..)

import AssocList
import Dict
import Evergreen.V1.Coord
import Evergreen.V1.GridCell
import Evergreen.V1.NotifyMe
import Quantity


type RecentChanges
    = RecentChanges
        { frequencies : AssocList.Dict Evergreen.V1.NotifyMe.Frequency (Dict.Dict Evergreen.V1.Coord.RawCellCoord Evergreen.V1.GridCell.Cell)
        , threeHoursElapsed : Quantity.Quantity Int Evergreen.V1.NotifyMe.ThreeHours
        }
