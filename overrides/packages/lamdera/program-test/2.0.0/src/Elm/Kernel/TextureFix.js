/*

import Elm.Kernel.Utils exposing (Tuple2)
import Elm.Kernel.Scheduler exposing (binding, succeed, fail)
import WebGLFix.Texture as TextureFix exposing (LoadError, SizeError)

*/

// eslint-disable-next-line no-unused-vars
var _TextureFix_load = F7(function (magnify, mininify, horizontalWrap, verticalWrap, flipY, premultiplyAlpha, url) {
  var isMipmap = mininify !== 9728 && mininify !== 9729;
  return __Scheduler_binding(function (callback) {
    var img = new Image();
    function createTexture(gl) {
      var texture = gl.createTexture();
      gl.bindTexture(gl.TEXTURE_2D, texture);
      gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, flipY);
      gl.pixelStorei(gl.UNPACK_COLORSPACE_CONVERSION_WEBGL, false);
      gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, premultiplyAlpha);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, img);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, magnify);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, mininify);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, horizontalWrap);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, verticalWrap);
      if (isMipmap) {
        gl.generateMipmap(gl.TEXTURE_2D);
      }
      gl.bindTexture(gl.TEXTURE_2D, null);
      return texture;
    }
    img.onload = function () {
      var width = img.width;
      var height = img.height;
      var widthPowerOfTwo = (width & (width - 1)) === 0;
      var heightPowerOfTwo = (height & (height - 1)) === 0;
      var isSizeValid = (widthPowerOfTwo && heightPowerOfTwo) || (
        !isMipmap
        && horizontalWrap === 33071 // clamp to edge
        && verticalWrap === 33071
      );
      if (isSizeValid) {
        callback(__Scheduler_succeed({
          $: __0_TEXTURE,
          __$createTexture: createTexture,
          __width: width,
          __height: height
        }));
      } else {
        callback(__Scheduler_fail(A2(
          __TextureFix_SizeError,
          width,
          height
        )));
      }
    };
    img.onerror = function () {
      callback(__Scheduler_fail(__TextureFix_LoadError));
    };
    if (url.slice(0, 5) !== 'data:') {
      img.crossOrigin = 'Anonymous';
    }
    img.src = url;
  });
});

// eslint-disable-next-line no-unused-vars
var _TextureFix_size = function (texture) {
  return __Utils_Tuple2(texture.__width, texture.__height);
};


//Texture Loading from Bytes

// eslint-disable-next-line no-unused-vars
var _TextureFix_loadBytes = F9(function (magnify, mininify, horizontalWrap, verticalWrap, flipY, width, height, tuple, bytes) {
  function createTexture(gl) {
    var texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, flipY);
    gl.pixelStorei(gl.UNPACK_COLORSPACE_CONVERSION_WEBGL, false);
    gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, tuple.b);
    gl.texImage2D(gl.TEXTURE_2D, 0, tuple.a, width, height, 0, tuple.a, gl.UNSIGNED_BYTE, new Uint8Array(bytes.buffer));
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, magnify);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, mininify);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, horizontalWrap);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, verticalWrap);
    if (mininify !== 9728 && mininify !== 9729) {
      gl.generateMipmap(gl.TEXTURE_2D);
    }
    gl.bindTexture(gl.TEXTURE_2D, null);
    return texture;
  }
  return {
    $: __0_TEXTURE,
    __$createTexture: createTexture,
    __width: width,
    __height: height
  };
});