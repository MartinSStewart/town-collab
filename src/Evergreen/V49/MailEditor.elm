module Evergreen.V49.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V49.Color
import Evergreen.V49.Coord
import Evergreen.V49.DisplayName
import Evergreen.V49.Id
import Evergreen.V49.Shaders
import Evergreen.V49.Tile
import Pixels


type Image
    = Stamp Evergreen.V49.Color.Colors
    | SunglassesEmoji Evergreen.V49.Color.Colors
    | NormalEmoji Evergreen.V49.Color.Colors
    | SadEmoji Evergreen.V49.Color.Colors
    | Cow Evergreen.V49.Color.Colors
    | Man Evergreen.V49.Color.Colors
    | TileImage Evergreen.V49.Tile.TileGroup Int Evergreen.V49.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V49.Color.Colors
    | DragCursor Evergreen.V49.Color.Colors
    | PinchCursor Evergreen.V49.Color.Colors
    | Line Int Evergreen.V49.Color.Color


type alias Content =
    { position : Evergreen.V49.Coord.Coord Pixels.Pixels
    , image : Image
    }


type alias ReceivedMail =
    { content :
        List
            { position : Evergreen.V49.Coord.Coord Pixels.Pixels
            , image : Image
            }
    , isViewed : Bool
    , from : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V49.Id.Id Evergreen.V49.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , to : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V49.Id.Id Evergreen.V49.Id.MailId)


type alias ImagePlacer_ =
    { imageIndex : Int
    , rotationIndex : Int
    }


type Tool
    = ImagePlacer ImagePlacer_
    | ImagePicker
    | EraserTool


type alias EditorState =
    { content : List Content
    }


type SubmitStatus
    = NotSubmitted
    | Submitted


type alias Model =
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V49.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V49.Id.Id Evergreen.V49.Id.UserId, Evergreen.V49.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V49.Id.Id Evergreen.V49.Id.MailId)
    }


type alias BackendMail =
    { content :
        List
            { position : Evergreen.V49.Coord.Coord Pixels.Pixels
            , image : Image
            }
    , status : MailStatus
    , from : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , to : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    }
