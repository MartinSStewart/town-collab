module Evergreen.V45.Cursor exposing (..)

import Evergreen.V45.Shaders
import WebGL


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V45.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V45.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V45.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V45.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V45.Shaders.Vertex
    }
