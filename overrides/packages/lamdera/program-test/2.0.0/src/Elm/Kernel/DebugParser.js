/*

import Elm.Kernel.Utils exposing (Tuple2)
import Array exposing (toList)
import Dict exposing (toList)
import Set exposing (toList)
import DebugParser exposing (Plain, Expandable, ElmString, ElmChar, ElmNumber, ElmBool, ElmFunction, ElmInternals, ElmUnit, ElmFile, ElmBytes, ElmSequence, ElmType, ElmRecord, ElmDict, SeqSet, SeqList, SeqArray, SeqTuple)

*/

function _DebugParser_toString__PROD(value)
{
	return __DebugParser_Plain(__DebugParser_ElmString(""));
}

function _DebugParser_toString__DEBUG(value)
{
	return _DebugParser_toAnsiString(value);
}

function _DebugParser_toAnsiString(value)
{
	if (typeof value === 'function')
	{
		return __DebugParser_Plain(__DebugParser_ElmFunction);
	}

	if (typeof value === 'boolean')
	{
		return __DebugParser_Plain(__DebugParser_ElmBool(value));
	}

	if (typeof value === 'number')
	{
		return __DebugParser_Plain(__DebugParser_ElmNumber(value));
	}

	if (value instanceof String)
	{
		return __DebugParser_Plain(__DebugParser_ElmChar(value));
	}

	if (typeof value === 'string')
	{
		return __DebugParser_Plain(__DebugParser_ElmString(value));
	}

	if (typeof value === 'object' && '$' in value)
	{
		var tag = value.$;

		if (typeof tag === 'number')
		{
			return __DebugParser_Plain(__DebugParser_ElmInternals);
		}

		if (tag[0] === '#')
		{
			var output = [];
			for (var k in value)
			{
				if (k === '$') continue;
				output.push(_DebugParser_toAnsiString(value[k]));
			}
			return __DebugParser_Expandable(A2(__DebugParser_ElmSequence, __DebugParser_SeqTuple, _List_fromArray(output)));
		}

		if (tag === 'Set_elm_builtin')
		{
		    var value2 = __Set_toList(value);
		    var output = [];
            for (; value2.b; value2 = value2.b) // WHILE_CONS
            {
                output.push(_DebugParser_toAnsiString(value2.a));
            }
            return __DebugParser_Expandable(A2(__DebugParser_ElmSequence, __DebugParser_SeqSet, _List_fromArray(output)));
		}

		if (tag === 'RBNode_elm_builtin' || tag === 'RBEmpty_elm_builtin')
		{
            var value2 = __Dict_toList(value);
            var output = [];
            for (; value2.b; value2 = value2.b) // WHILE_CONS
            {
                output.push(__Utils_Tuple2(_DebugParser_toAnsiString(value2.a.a), _DebugParser_toAnsiString(value2.a.b)));
            }
            return __DebugParser_Expandable(__DebugParser_ElmDict(_List_fromArray(output)));
		}

		if (tag === 'Array_elm_builtin')
		{
            var listSet = __Array_toList(value);
            var output = [];
            for (var k in listSet)
            {
                if (k === '$') continue;
                output.push(_DebugParser_toAnsiString(value[k]));
            }
            return __DebugParser_Expandable(A2(__DebugParser_ElmSequence, __DebugParser_SeqArray, _List_fromArray(output)));
		}

		if (tag === '::' || tag === '[]')
		{
            var output = [];
            for (; value.b; value = value.b) // WHILE_CONS
            {
                output.push(_DebugParser_toAnsiString(value.a));
            }
            return __DebugParser_Expandable(A2(__DebugParser_ElmSequence, __DebugParser_SeqList, _List_fromArray(output)));
		}

        var output = [];
        for (var i in value)
        {
            if (i === '$') continue;
            output.push(_DebugParser_toAnsiString(value[i]));
        }
		return __DebugParser_Expandable(A2(__DebugParser_ElmType, tag, _List_fromArray(output)));
	}

	if (typeof DataView === 'function' && value instanceof DataView)
	{
		return __DebugParser_Plain(__DebugParser_ElmBytes(value.byteLength));
	}

	if (typeof File !== 'undefined' && value instanceof File)
	{
		return __DebugParser_Plain(__DebugParser_ElmFile(value.name));
	}

	if (typeof value === 'object')
	{
		var output = [];
		for (var key in value)
		{
			var field = key[0] === '_' ? key.slice(1) : key;
			output.push(__Utils_Tuple2(field, _DebugParser_toAnsiString(value[key])));
		}
		return __DebugParser_Expandable(__DebugParser_ElmRecord(_List_fromArray(output)));
	}

	return __DebugParser_Plain(__DebugParser_ElmInternals);
}

function _List_fromArray(arr)
{
	var out = _List_Nil;
	for (var i = arr.length; i--; )
	{
		out = _List_Cons(arr[i], out);
	}
	return out;
}

function _List_Cons(hd, tl) { return { $: '::', a: hd, b: tl }; }

var _List_Nil = { $: '[]' };