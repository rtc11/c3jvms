module runtime;

import std::io;
import std::collections::list;
import std::collections::map;
import ascii, ast, environment;

interface RuntimeValue
{
    fn String inspect();
    fn String name();
}

fn bool RuntimeValue.is_err(&self) => self.type == Error.typeid;

struct Int32 (RuntimeValue, Hashable)
{
    int value;
}
fn String Int32.name(&self) @dynamic => "i32";
fn String Int32.inspect(&self) @dynamic => string::tformat("%d", self.value);
fn Hash Int32.hash(&self) @dynamic => { self.name(), self.value };

struct Bool (RuntimeValue, Hashable)
{
    bool value;
}
fn String Bool.name(&self) @dynamic => "bool";
fn String Bool.inspect(&self) @dynamic => string::tformat("%s", self.value);
fn Hash Bool.hash(&self) @dynamic => { self.name(), self.value ? 1 : 0 };

struct Null (RuntimeValue)
{
    void* value;
}
fn String Null.name(&self) @dynamic => "null";
fn String Null.inspect(&self) @dynamic => string::tformat("null");

struct Return (RuntimeValue)
{
    RuntimeValue value;
}
fn String Return.name(&self) @dynamic => "return";
fn String Return.inspect(&self) @dynamic => string::tformat("%s", self.value.inspect());

struct Error (RuntimeValue)
{
    String message;
    String file;
    isz line;
    String func;
}
fn String Error.name(&self) @dynamic => "error";
fn String Error.inspect(&self) @dynamic
{
    return string::tformat("%s:%s %s: %s (in %s)", 
       self.file,
       ascii::colorize(PINK, self.line),
       ascii::colorize(RED, "ERROR"),
       self.message,
       self.func);
} 

struct Fn (RuntimeValue)
{
    List{Identifier} parameters;
    Block* body;
    Environment* env;
}
fn String Fn.name(&self) @dynamic => "fn";
fn String Fn.inspect(&self) @dynamic {
    String[] params = allocator::alloc_array(allocator::temp(), String, self.parameters.len());
    foreach(i, p: self.parameters) params[i] = string::tformat("%s", p);
    return string::tformat("fn(%s) {\n%s\n}",
        string::join(allocator::temp(), params, ", "),
        self.body,
    );
}

struct Str (RuntimeValue, Hashable)
{
    String value;
}
fn String Str.name(&self) @dynamic => "str";
fn String Str.inspect(&self) @dynamic => self.value;
fn Hash Str.hash(&self) @dynamic => { self.name(), self.value.hash() };

alias BuiltinFn = fn RuntimeValue(List{RuntimeValue}, Allocator);

struct Builtin (RuntimeValue)
{
    BuiltinFn fun;
}
fn String Builtin.name(&self) @dynamic => "builtin";
fn String Builtin.inspect(&self) @dynamic => "builtin fn";

struct Array (RuntimeValue)
{
    List{RuntimeValue} elements;
}
fn String Array.name(&self) @dynamic => "array";
fn String Array.inspect(&self) @dynamic {
    String[] elems = allocator::alloc_array(allocator::temp(), String, self.elements.len());
    foreach(i, e: self.elements) elems[i] = string::tformat("%s", e.inspect());
    return string::tformat("[%s]", string::join(allocator::temp(), elems, ", "));
}

struct Hash
{
    String type; 
    uint value;
}
fn bool Hash.equals(self, Hash other) @operator(==) => self.value == other.value;
fn uint Hash.hash(&self) => self.value; // used for c3 hashmap

struct HashPair 
{
    RuntimeValue key;
    RuntimeValue value;
}

struct HashMap (RuntimeValue)
{
    map::HashMap{Hash, HashPair} pairs;
}
fn String HashMap.name(&self) @dynamic => "hash";
fn String HashMap.inspect(&self) @dynamic {
	String[] pairs = allocator::alloc_array(allocator::temp(), String, self.pairs.len());
    int i;
    self.pairs.@each(; Hash k, HashPair v) {
        pairs[i++] = string::tformat("%s: %s", v.key.inspect(), v.value.inspect());
    };
	return string::tformat("{%s}", string::join(allocator::temp(), pairs, ", "));
}

interface Hashable {
     fn Hash hash();
}

struct Quote (RuntimeValue)
{
    Node node;
}
fn String Quote.name(&self) @dynamic => "quote";
fn String Quote.inspect(&self) @dynamic => string::tformat("QUOTE(%s)", self.node);

struct Macro (RuntimeValue)
{
    List{Identifier} parameters;
    Block* body;
    Environment* env;
}
fn String Macro.name(&self) @dynamic => "macro";
fn String Macro.inspect(&self) @dynamic {
    String[] params = allocator::alloc_array(allocator::temp(), String, self.parameters.len());
    return string::tformat("macro(%s){\n%s\n}", 
        string::join(allocator::temp(), params, ", "),
        self.body,
    );
}

struct StructInstance (RuntimeValue)
{
    String instance_name;
    map::HashMap{String, RuntimeValue} fields;
}
fn String StructInstance.name(&self) @dynamic => self.instance_name;
fn String StructInstance.inspect(&self) @dynamic {
	String[] fields = allocator::alloc_array(allocator::temp(), String, self.fields.len());
    int i;
    self.fields.@each(; String key, RuntimeValue val) {
        fields[i++] = string::tformat("%s: %s", key, val.inspect());
    };
	return string::tformat("%s{%s}", self.instance_name, string::join(allocator::temp(), fields, ", "));
}

struct StructDef (RuntimeValue)
{
    String struct_name;
    List{Statement} fields;
}
fn String StructDef.name(&self) @dynamic => self.struct_name;
fn String StructDef.inspect(&self) @dynamic {
    String[] fields = allocator::alloc_array(allocator::temp(), String, self.fields.len());
    return string::tformat("%s{%s}", self.struct_name, string::join(allocator::temp(), fields, ", "));
}
