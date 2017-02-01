## LuaJSON
JSON Parser/Constructor for Lua

### Author:
Thomas Harning Jr. <harningt@gmail.com>

### Source code:
http://repo.or.cz/luajson

### Bug reports:
http://github.com/harningt/luajson
harningt@gmail.com

### Requirements
Lua 5.1, 5.2, 5.3, LuaJIT 2.0, or LuaJIT 2.1
LPeg (Tested with 0.7, 0.8, 0.9, 0.10, 0.12rc2, 1.0.1)
For regressionTest:
	lfs (Tested with 1.6.3)
### For lunit-tests:
lunitx >= 0.8

### NOTE:
LPeg 0.11 may not work - it crashed during my initial tests,
it is not in the test matrix.

### Lua versions tested recently:
* Lua 5.1.5
* Lua 5.2.4
* Lua 5.3.4
* LuaJIT-2.0.4
* LuaJIT-2.1.0-beta2

### License
All-but tests: MIT-style, See LICENSE for details
tests/*:       Public Domain / MIT - whichever is least restrictive

### Module/Function overview:
### json.encode (callable module referencing json.encode.encode)
___encode ( value : ANY-valid )___

Takes in a JSON-encodable value and returns the JSON-encoded text
Valid input types:
* table
* array-like table (spec below)
* string
* number
* boolean
* 'null' - represented by json.util.null

Table keys (string,number,boolean) are encoded as strings, others are erroneus
Table values are any valid input-type
Array-like tables are converted into JSON arrays...
Position 1 maps to JSON Array position 0

### json.decode (callable module referencing json.decode.decode)
___decode (data : string, strict : optional boolean)___

Takes in a string of JSON data and converts it into a Lua object
If 'strict' is set, then the strict JSON rule-set is used

### json.util
#### Useful utilities
___null___

Reference value to represent 'null' in a well-defined way to
allow for null values to be inserted into an array/table

   undefined

Reference value to represent 'undefined' in a well-defined
way to allow for undefined values to be inserted into an
array/table.

   IsArray (t : ANY)

Checks if the passed in object is a plain-old-array based on
whether or not is has the LuaJSON array metatable attached
or the custom __is_luajson_array metadata key stored.

   InitArray(t: table)

Sets the 'array' marker metatable to guarantee the table is
represented as a LuaJSON array type.

   isCall (t : ANY)

Checks if the passed in object is a LuaJSON call object.

   buildCall(name : string, ... parameters)

Builds a call object with the given name and set of parameters.
The name is stored in the 'name' field and the parameters in
the 'parameters' field as an array.

#### Additional Utilities
   clone (t : table)

Shallow-clones a table by iterating using pairs and assigning.

___printValue (tab : ANY, name : string)

recursively prints out all object values - if duplicates found, reference printed

___merge (t : table, ... : tables)

Shallow-merges a sequence of tables onto table t by iterating over each using
pairs and assigning.

#### Internal Utilities - Not to Use
   decodeCall
   doOptionMerge

### Attribution
parsing test suite from JSON_checker project of http://www.json.org/
No listed license for these files in their package.
