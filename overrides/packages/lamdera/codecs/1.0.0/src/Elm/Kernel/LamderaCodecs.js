/*
import Result exposing (Ok)
*/

var wireRefs = (function () {
  var refs = new Map();
  var counter = 0; // uInt32 max
  var f = {}
  f.add = function(obj) {
    counter++;
    refs.set(counter, obj);
    return counter;
  }
  f.getFinal = function(k) {
    let v = refs.get(k);
    refs.delete(k);
    return v;
  }
  f.clear = function() {
    refs = new Map();
  };
  f.all = function() {
    return [refs.keys(), refs];
  }
  return f;
})();


var _LamderaCodecs_encodeWithRef = function(a) {
	return wireRefs.add(a);
}

var _LamderaCodecs_decodeWithRef = function(ref) {
	return wireRefs.getFinal(ref);
}

var _LamderaCodecs_debug = function(s) {
  console.log(s);
	return 0;
}


var _LamderaCodecs_encodeBytes = function(s) { return _Lamdera_Json_wrap(s); }
function _Lamdera_Json_wrap__DEBUG(value) { return { $: __0_JSON, a: value }; }
function _Lamdera_Json_wrap__PROD(value) { return value; }

function _LamderaCodecs_Json_decodePrim(decoder)
{
	return { $: __1_PRIM, __decoder: decoder };
}

var _LamderaCodecs_decodeBytes = _Json_decodePrim(function(value) {
	return (typeof value === 'object' && value instanceof DataView)
		? __Result_Ok(value)
		: console.log('error: expecting DataView, got', value) ;
});
