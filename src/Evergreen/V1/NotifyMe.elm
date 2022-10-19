module Evergreen.V1.NotifyMe exposing (..)

import EmailAddress


type Frequency
    = Every3Hours
    | Every12Hours
    | Daily
    | Weekly
    | Monthly


type alias Validated =
    { email : EmailAddress.EmailAddress
    , frequency : Frequency
    }


type Status
    = Form
    | FormWithError
    | SendingToBackend
    | WaitingOnConfirmation


type alias InProgressModel =
    { status : Status
    , email : String
    , frequency : Maybe Frequency
    }


type Model
    = InProgress InProgressModel
    | Completed
    | BackendError
    | Unsubscribing
    | Unsubscribed


type ThreeHours
    = ThreeHours Never
