module Evergreen.V43.Cursor exposing (..)

import Evergreen.V43.Shaders
import WebGL


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V43.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V43.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V43.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V43.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V43.Shaders.Vertex
    }
