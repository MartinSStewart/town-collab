module Effect.WebGL.Settings.StencilTest exposing
    ( test
    , Test, always, equal, never, less, greater, notEqual
    , lessOrEqual, greaterOrEqual
    , Operation, replace, keep, zero, increment, decrement, invert
    , incrementWrap, decrementWrap
    , testSeparate
    )

{-| You can read more about stencil-testing in the
[OpenGL wiki](https://www.khronos.org/opengl/wiki/Stencil_Test)
or [OpenGL docs](https://www.opengl.org/sdk/docs/man2/xhtml/glStencilFunc.xml).


# Stencil Test

@docs test


## Tests

@docs Test, always, equal, never, less, greater, notEqual
@docs lessOrEqual, greaterOrEqual


## Operations

@docs Operation, replace, keep, zero, increment, decrement, invert
@docs incrementWrap, decrementWrap


# Separate Test

@docs testSeparate

-}

import WebGL.Settings exposing (Setting)
import WebGL.Settings.StencilTest


{-| When you need to draw an intercection of two entities, e.g. a reflection in
the mirror, you can test against the stencil buffer, that has to be enabled
with [`stencil`](WebGL#stencil) option in [`toHtmlWith`](WebGL#toHtmlWith).

Stencil test decides if the pixel should be drawn on the screen.
Depending on the results, it performs one of the following
[operations](#Operation) on the stencil buffer:

  - `fail`—the operation to use when the stencil test fails;
  - `zfail`—the operation to use when the stencil test passes, but the depth
    test fails;
  - `zpass`—the operation to use when both the stencil test and the depth test
    pass, or when the stencil test passes and there is no depth buffer or depth
    testing is disabled.

For example, draw the mirror `Entity` on the screen and fill the stencil buffer
with all 1's:

    test
        { ref = 1
        , mask = 0xFF
        , test = always -- pass for each pixel
        , fail = keep -- noop
        , zfail = keep -- noop
        , zpass = replace -- write ref to the stencil buffer
        , writeMask = 0xFF -- enable all stencil bits for writing
        }

Crop the reflection `Entity` using the values from the stencil buffer:

    test
        { ref = 1
        , mask = 0xFF
        , test = equal -- pass when the stencil value is equal to ref = 1
        , fail = keep -- noop
        , zfail = keep -- noop
        , zpass = keep -- noop
        , writeMask = 0 -- disable writing to the stencil buffer
        }

You can see the complete example
[here](https://github.com/elm-explorations/webgl/blob/main/examples/Crate.elm).

-}
test :
    { ref : Int
    , mask : Int
    , test : Test
    , fail : Operation
    , zfail : Operation
    , zpass : Operation
    , writeMask : Int
    }
    -> Setting
test =
    WebGL.Settings.StencilTest.test


{-| The `Test` allows you to define how to compare the reference value
with the stencil buffer value, in order to set the conditions under which
the pixel will be drawn.

    always -- Always pass

    equal -- ref & mask == stencil & mask

    never -- Never pass

    less -- ref & mask < stencil & mask

    greater -- ref & mask > stencil & mask

    notEqual -- ref & mask != stencil & mask

    lessOrEqual -- ref & mask <= stencil & mask

    greaterOrEqual -- ref & mask >= stencil & mask

-}
type alias Test =
    WebGL.Settings.StencilTest.Test


{-| -}
always : Test
always =
    WebGL.Settings.StencilTest.always


{-| -}
equal : Test
equal =
    WebGL.Settings.StencilTest.equal


{-| -}
never : Test
never =
    WebGL.Settings.StencilTest.never


{-| -}
less : Test
less =
    WebGL.Settings.StencilTest.less


{-| -}
greater : Test
greater =
    WebGL.Settings.StencilTest.greater


{-| -}
notEqual : Test
notEqual =
    WebGL.Settings.StencilTest.notEqual


{-| -}
lessOrEqual : Test
lessOrEqual =
    WebGL.Settings.StencilTest.lessOrEqual


{-| -}
greaterOrEqual : Test
greaterOrEqual =
    WebGL.Settings.StencilTest.greaterOrEqual


{-| Defines how to update the value in the stencil buffer.
-}
type alias Operation =
    WebGL.Settings.StencilTest.Operation


{-| Sets the stencil buffer value to `ref` from the stencil test.
-}
replace : Operation
replace =
    WebGL.Settings.StencilTest.replace


{-| Keeps the current stencil buffer value. Use this as a noop.
-}
keep : Operation
keep =
    WebGL.Settings.StencilTest.keep


{-| Sets the stencil buffer value to 0.
-}
zero : Operation
zero =
    WebGL.Settings.StencilTest.zero


{-| Increments the current stencil buffer value. Clamps to the maximum
representable unsigned value.
-}
increment : Operation
increment =
    WebGL.Settings.StencilTest.increment


{-| Decrements the current stencil buffer value. Clamps to 0.
-}
decrement : Operation
decrement =
    WebGL.Settings.StencilTest.decrement


{-| Bitwise inverts the current stencil buffer value.
-}
invert : Operation
invert =
    WebGL.Settings.StencilTest.invert


{-| Increments the current stencil buffer value. Wraps stencil buffer value to
zero when incrementing the maximum representable unsigned value.
-}
incrementWrap : Operation
incrementWrap =
    WebGL.Settings.StencilTest.incrementWrap


{-| Decrements the current stencil buffer value.
Wraps stencil buffer value to the maximum representable unsigned
value when decrementing a stencil buffer value of zero.
-}
decrementWrap : Operation
decrementWrap =
    WebGL.Settings.StencilTest.decrementWrap


{-| Different options for front and back facing polygons.
-}
testSeparate :
    { ref : Int, mask : Int, writeMask : Int }
    -> { test : Test, fail : Operation, zfail : Operation, zpass : Operation }
    -> { test : Test, fail : Operation, zfail : Operation, zpass : Operation }
    -> Setting
testSeparate =
    WebGL.Settings.StencilTest.testSeparate
