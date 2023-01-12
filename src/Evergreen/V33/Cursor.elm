module Evergreen.V33.Cursor exposing (..)

import Evergreen.V33.Shaders
import WebGL


type alias CursorMeshes =
    { defaultSprite : WebGL.Mesh Evergreen.V33.Shaders.Vertex
    , pointerSprite : WebGL.Mesh Evergreen.V33.Shaders.Vertex
    , dragScreenSprite : WebGL.Mesh Evergreen.V33.Shaders.Vertex
    , pinchSprite : WebGL.Mesh Evergreen.V33.Shaders.Vertex
    , eyeDropperSprite : WebGL.Mesh Evergreen.V33.Shaders.Vertex
    }
