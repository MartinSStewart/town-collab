module Evergreen.V54.MailEditor exposing (..)

import Effect.Time
import Effect.WebGL
import Evergreen.V54.Color
import Evergreen.V54.Coord
import Evergreen.V54.DisplayName
import Evergreen.V54.Id
import Evergreen.V54.Shaders
import Evergreen.V54.Tile
import Pixels


type Image
    = Stamp Evergreen.V54.Color.Colors
    | SunglassesEmoji Evergreen.V54.Color.Colors
    | NormalEmoji Evergreen.V54.Color.Colors
    | SadEmoji Evergreen.V54.Color.Colors
    | Cow Evergreen.V54.Color.Colors
    | Man Evergreen.V54.Color.Colors
    | TileImage Evergreen.V54.Tile.TileGroup Int Evergreen.V54.Color.Colors
    | Grass
    | DefaultCursor Evergreen.V54.Color.Colors
    | DragCursor Evergreen.V54.Color.Colors
    | PinchCursor Evergreen.V54.Color.Colors
    | Line Int Evergreen.V54.Color.Color


type alias Content =
    { position : Evergreen.V54.Coord.Coord Pixels.Pixels
    , image : Image
    }


type alias ReceivedMail =
    { content :
        List
            { position : Evergreen.V54.Coord.Coord Pixels.Pixels
            , image : Image
            }
    , isViewed : Bool
    , from : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    , deliveryTime : Effect.Time.Posix
    }


type MailStatus
    = MailWaitingPickup
    | MailInTransit (Evergreen.V54.Id.Id Evergreen.V54.Id.TrainId)
    | MailReceived
        { deliveryTime : Effect.Time.Posix
        }
    | MailReceivedAndViewed
        { deliveryTime : Effect.Time.Posix
        }


type alias FrontendMail =
    { status : MailStatus
    , from : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    , to : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    }


type Hover
    = BackgroundHover
    | ImageButton Int
    | MailButton
    | EraserButton
    | SendLetterButton
    | CloseSendLetterInstructionsButton
    | InboxRowButton (Evergreen.V54.Id.Id Evergreen.V54.Id.MailId)


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
    { currentImageMesh : Effect.WebGL.Mesh Evergreen.V54.Shaders.Vertex
    , currentTool : Tool
    , lastRotation : List Effect.Time.Posix
    , undo : List EditorState
    , current : EditorState
    , redo : List EditorState
    , lastPlacedImage : Maybe Effect.Time.Posix
    , lastErase : Maybe Effect.Time.Posix
    , submitStatus : SubmitStatus
    , to : Maybe ( Evergreen.V54.Id.Id Evergreen.V54.Id.UserId, Evergreen.V54.DisplayName.DisplayName )
    , inboxMailViewed : Maybe (Evergreen.V54.Id.Id Evergreen.V54.Id.MailId)
    }


type alias BackendMail =
    { content :
        List
            { position : Evergreen.V54.Coord.Coord Pixels.Pixels
            , image : Image
            }
    , status : MailStatus
    , from : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    , to : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    }
