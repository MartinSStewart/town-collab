module Effect.WebGL.Settings.Blend exposing
    ( add, subtract, reverseSubtract
    , Factor, zero, one, srcColor, oneMinusSrcColor, dstColor
    , oneMinusDstColor, srcAlpha, oneMinusSrcAlpha, dstAlpha
    , oneMinusDstAlpha, srcAlphaSaturate
    , custom, Blender, customAdd, customSubtract, customReverseSubtract
    , constantColor, oneMinusConstantColor, constantAlpha
    , oneMinusConstantAlpha
    )

{-|


# Blenders

@docs add, subtract, reverseSubtract


# Blend Factors

@docs Factor, zero, one, srcColor, oneMinusSrcColor, dstColor
@docs oneMinusDstColor, srcAlpha, oneMinusSrcAlpha, dstAlpha
@docs oneMinusDstAlpha, srcAlphaSaturate


# Custom Blenders

@docs custom, Blender, customAdd, customSubtract, customReverseSubtract
@docs constantColor, oneMinusConstantColor, constantAlpha
@docs oneMinusConstantAlpha

-}

import WebGLFix.Settings exposing (Setting)
import WebGLFix.Settings.Blend


{-| Add the color of the current `Renderable` (the source color)
with whatever is behind it (the destination color). For example,
here is the “default” blender:

    add one zero

The resulting color will be `(src * 1) + (dest * 0)`, which means
we do not use the destination color at all!
You can get a feel for all the different blending factors
[here](https://threejs.org/examples/webgl_materials_blending_custom.html).

-}
add : Factor -> Factor -> Setting
add =
    WebGLFix.Settings.Blend.add


{-| Similar to [`add`](#add), but it does `(src * factor1) - (dest * factor2)`.
For example:

    subtract one one

This would do `(src * 1) - (dest * 1)` so you would take away colors
based on the background.

-}
subtract : Factor -> Factor -> Setting
subtract =
    WebGLFix.Settings.Blend.subtract


{-| Similar to [`add`](#add), but it does `(dest * factor2) - (src * factor1)`.
This one is weird.
-}
reverseSubtract : Factor -> Factor -> Setting
reverseSubtract =
    WebGLFix.Settings.Blend.reverseSubtract


{-| -}
type alias Factor =
    WebGLFix.Settings.Blend.Factor


{-| -}
zero : Factor
zero =
    WebGLFix.Settings.Blend.zero


{-| -}
one : Factor
one =
    WebGLFix.Settings.Blend.one


{-| -}
srcColor : Factor
srcColor =
    WebGLFix.Settings.Blend.srcColor


{-| -}
oneMinusSrcColor : Factor
oneMinusSrcColor =
    WebGLFix.Settings.Blend.oneMinusSrcColor


{-| -}
dstColor : Factor
dstColor =
    WebGLFix.Settings.Blend.dstColor


{-| -}
oneMinusDstColor : Factor
oneMinusDstColor =
    WebGLFix.Settings.Blend.oneMinusDstColor


{-| -}
srcAlpha : Factor
srcAlpha =
    WebGLFix.Settings.Blend.srcAlpha


{-| -}
oneMinusSrcAlpha : Factor
oneMinusSrcAlpha =
    WebGLFix.Settings.Blend.oneMinusSrcAlpha


{-| -}
dstAlpha : Factor
dstAlpha =
    WebGLFix.Settings.Blend.dstAlpha


{-| -}
oneMinusDstAlpha : Factor
oneMinusDstAlpha =
    WebGLFix.Settings.Blend.oneMinusDstAlpha


{-| -}
srcAlphaSaturate : Factor
srcAlphaSaturate =
    WebGLFix.Settings.Blend.srcAlphaSaturate



-- BLENDING WITH CONSTANT COLORS


{-| It is possible to do some very fancy blending with
`custom`. For example, you can blend the color value and
the alpha values separately:

    myBlender : Float -> Setting
    myBlender alpha =
        custom
            { r = 0
            , g = 0
            , b = 0
            , a = alpha
            , color = customAdd one zero
            , alpha = customAdd one constantAlpha
            }

-}
custom :
    { r : Float
    , g : Float
    , b : Float
    , a : Float
    , color : Blender
    , alpha : Blender
    }
    -> Setting
custom =
    WebGLFix.Settings.Blend.custom


{-| A `Blender` mixes the color of the current `Entity` (the source color)
with whatever is behind it (the destination color).
You can get a feel for all the options [here](https://threejs.org/examples/webgl_materials_blending_custom.html).
-}
type alias Blender =
    WebGLFix.Settings.Blend.Blender


{-| -}
customAdd : Factor -> Factor -> Blender
customAdd =
    WebGLFix.Settings.Blend.customAdd


{-| -}
customSubtract : Factor -> Factor -> Blender
customSubtract =
    WebGLFix.Settings.Blend.customSubtract


{-| -}
customReverseSubtract : Factor -> Factor -> Blender
customReverseSubtract =
    WebGLFix.Settings.Blend.customReverseSubtract


{-| This uses the constant `r`, `g`, `b`, and `a` values
given to [`custom`](#custom). If you use this `Factor` with
[`add`](#add), the constant color will default to black.

Because of
[restriction in WebGL](https://www.khronos.org/registry/webgl/specs/latest/1.0/#6.13),
you cannot create a `Blender`, that has one factor set to
`constantColor` or `oneMinusConstantColor` and another set to
`constantAlpha` or `oneMinusConstantAlpha`.

-}
constantColor : Factor
constantColor =
    WebGLFix.Settings.Blend.constantColor


{-| -}
oneMinusConstantColor : Factor
oneMinusConstantColor =
    WebGLFix.Settings.Blend.oneMinusConstantColor


{-| -}
constantAlpha : Factor
constantAlpha =
    WebGLFix.Settings.Blend.constantAlpha


{-| -}
oneMinusConstantAlpha : Factor
oneMinusConstantAlpha =
    WebGLFix.Settings.Blend.oneMinusConstantAlpha
