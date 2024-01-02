module WebGLFix exposing
    ( Shader
    , Entity, entity
    , toHtml
    , entityWith, toHtmlWith, Option, alpha, depth, stencil, antialias
    , clearColor, preserveDrawingBuffer
    )

{-| The WebGL API is for high performance rendering. Definitely read about
[how WebGL works](https://package.elm-lang.org/packages/elm-explorations/webgl/latest)
and look at [some examples](https://github.com/elm-explorations/webgl/tree/main/examples)
before trying to do too much with just the documentation provided here.


# Shaders

@docs Shader


# Entities

@docs Entity, entity


# WebGL Html

@docs toHtml


# Advanced Usage

@docs entityWith, toHtmlWith, Option, alpha, depth, stencil, antialias
@docs clearColor, preserveDrawingBuffer

-}

import Elm.Kernel.WebGLFix
import Html exposing (Attribute, Html)
import WebGL
import WebGLFix.Internal as I
import WebGLFix.Settings exposing (Setting)
import WebGLFix.Settings.DepthTest as DepthTest


{-| Shaders are programs for running many computations on the GPU in parallel.
They are written in a language called
[GLSL](https://en.wikipedia.org/wiki/OpenGL_Shading_Language). Read more about
shaders [here](https://github.com/elm-explorations/webgl/blob/main/README.md).

Normally you specify a shader with a `[glsl| |]` block. Elm compiler will parse
the shader code block and derive the type signature for your shader.

  - `attributes` define vertices in the [mesh](#Mesh);
  - `uniforms` allow you to pass scene parameters like
    transformation matrix, texture, screen size, etc.;
  - `varyings` define the output from the vertex shader.

`attributes`, `uniforms` and `varyings` are records with the fields of the
following types: `Int`, `Float`, [`Texture`](#Texture) and `Vec2`, `Vec3`, `Vec4`,
`Mat4` from the
[linear-algebra](https://package.elm-lang.org/packages/elm-explorations/linear-algebra/latest)
package.

-}
type alias Shader attributes uniforms varyings =
    WebGL.Shader attributes uniforms varyings


{-| Conceptually, an encapsulation of the instructions to render something.
-}
type alias Entity =
    WebGL.Entity


{-| Packages a vertex shader, a fragment shader, a mesh, and uniforms
as an `Entity`. This specifies a full rendering pipeline to be run
on the GPU. You can read more about the pipeline
[here](https://github.com/elm-explorations/webgl/blob/main/README.md).

The vertex shader receives `attributes` and `uniforms` and returns `varyings`
and `gl_Position`—the position of the vertex on the screen, defined as
`vec4(x, y, z, w)`, that means `(x/w, y/w, z/w)` in the clip space coordinates:

    --   (-1,1,1) +================+ (1,1,1)
    --           /|               /|
    --          / |     |        / |
    --(-1,1,-1)+================+ (1,1,-1)
    --         |  |     | /     |  |
    --         |  |     |/      |  |
    --         |  |     +-------|->|
    -- (-1,-1,1|) +--(0,0,0)----|--+ (1,-1,1)
    --         | /              | /
    --         |/               |/
    --         +================+
    --   (-1,-1,-1)         (1,-1,-1)



The fragment shader is called for each pixel inside the clip space with
`varyings` and `uniforms` and returns `gl_FragColor`—the color of
the pixel, defined as `vec4(r, g, b, a)` where each color component is a float
from 0 to 1.

Shaders and a mesh are cached so that they do not get resent to the GPU.
It should be relatively cheap to create new entities out of existing
values.

By default, [depth test](WebGL-Settings-DepthTest#default) is enabled for you.
If you need more [settings](WebGL-Settings), like
[blending](WebGL-Settings-Blend) or [stencil test](WebG-Settings-StencilTest),
then use [`entityWith`](#entityWith).

    entity =
        entityWith [ DepthTest.default ]

-}
entity :
    Shader attributes uniforms varyings
    -> Shader {} uniforms varyings
    -> WebGL.Mesh attributes
    -> uniforms
    -> Entity
entity =
    entityWith [ DepthTest.default ]


{-| The same as [`entity`](#entity), but allows to configure an entity with
[settings](WebGL-Settings).
-}
entityWith :
    List Setting
    -> Shader attributes uniforms varyings
    -> Shader {} uniforms varyings
    -> WebGL.Mesh attributes
    -> uniforms
    -> Entity
entityWith =
    Elm.Kernel.WebGLFix.entity


{-| Render a WebGL scene with the given html attributes, and entities.

`width` and `height` html attributes resize the drawing buffer, while
the corresponding css properties scale the canvas element.

To prevent blurriness on retina screens, you may want the drawing buffer
to be twice the size of the canvas element.

To remove an extra whitespace around the canvas, set `display: block`.

By default, alpha channel with premultiplied alpha, antialias and depth buffer
are enabled. Use [`toHtmlWith`](#toHtmlWith) for custom options.

    toHtml =
        toHtmlWith [ alpha True, antialias, depth 1 ]

-}
toHtml : List (Attribute msg) -> List Entity -> Html msg
toHtml =
    toHtmlWith [ alpha True, antialias, depth 1 ]


{-| Render a WebGL scene with the given options, html attributes, and entities.

Due to browser limitations, options will be applied only once,
when the canvas is created for the first time.

-}
toHtmlWith : List Option -> List (Attribute msg) -> List Entity -> Html msg
toHtmlWith options attributes entities =
    Elm.Kernel.WebGLFix.toHtml options attributes entities


{-| Provides a way to enable features and change the scene behavior
in [`toHtmlWith`](#toHtmlWith).
-}
type alias Option =
    I.Option


{-| Enable alpha channel in the drawing buffer. If the argument is `True`, then
the page compositor will assume the drawing buffer contains colors with
premultiplied alpha `(r * a, g * a, b * a, a)`.
-}
alpha : Bool -> Option
alpha =
    I.Alpha


{-| Enable the depth buffer, and prefill it with given value each time before
the scene is rendered. The value is clamped between 0 and 1.
-}
depth : Float -> Option
depth =
    I.Depth


{-| Enable the stencil buffer, specifying the index used to fill the
stencil buffer before we render the scene. The index is masked with 2^m - 1,
where m >= 8 is the number of bits in the stencil buffer. The default is 0.
-}
stencil : Int -> Option
stencil =
    I.Stencil


{-| Enable multisample antialiasing of the drawing buffer, if supported by
the platform. Useful when you need to have smooth lines and smooth edges of
triangles at a lower cost than supersampling (rendering to larger dimensions and
then scaling down with CSS transform).
-}
antialias : Option
antialias =
    I.Antialias


{-| Set the red, green, blue and alpha channels, that will be used to
fill the drawing buffer every time before drawing the scene. The values are
clamped between 0 and 1. The default is all 0's.
-}
clearColor : Float -> Float -> Float -> Float -> Option
clearColor =
    I.ClearColor


{-| By default, WebGL canvas swaps the drawing and display buffers.
This option forces it to copy the drawing buffer into the display buffer.

Even though this slows down the rendering, it allows you to extract an image
from the canvas element using `canvas.toBlob()` in JavaScript without having
to worry about synchronization between frames.

-}
preserveDrawingBuffer : Option
preserveDrawingBuffer =
    I.PreserveDrawingBuffer
