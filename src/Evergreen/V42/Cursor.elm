module Evergreen.V42.Cursor exposing (..)

import Evergreen.V42.Shaders
import WebGL


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V42.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V42.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V42.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V42.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V42.Shaders.Vertex
    }
