module Evergreen.V47.Cursor exposing (..)

import Evergreen.V47.Shaders
import WebGL


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V47.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V47.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V47.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V47.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V47.Shaders.Vertex
    , eraserSprite : WebGL.Mesh Evergreen.V47.Shaders.Vertex
    }
