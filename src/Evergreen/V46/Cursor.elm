module Evergreen.V46.Cursor exposing (..)

import Evergreen.V46.Shaders
import WebGL


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V46.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V46.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V46.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V46.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V46.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V46.Shaders.Vertex
    }
