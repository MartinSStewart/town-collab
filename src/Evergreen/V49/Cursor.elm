module Evergreen.V49.Cursor exposing (..)

import Evergreen.V49.Shaders
import WebGL


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V49.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V49.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V49.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V49.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V49.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V49.Shaders.Vertex
    }
