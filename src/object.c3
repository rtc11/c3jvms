module object;

import std::io;
import std::collections::list;
import std::collections::map;
import ascii, ast, environment;

interface Object
{
    fn String inspect();
    fn String name();
}

fn bool Object.is_err(&self) => self.type == Error.typeid;

struct Int32 (Object, Hashable)
{
    int value;
}
fn String Int32.inspect(&self) @dynamic => string::tformat("%d", self.value);
fn String Int32.name(&self) @dynamic => "i32";
fn Hash Int32.hash(&self) @dynamic => { self.name(), self.value };

struct Bool (Object, Hashable)
{
    bool value;
}
fn String Bool.inspect(&self) @dynamic => string::tformat("%s", self.value);
fn String Bool.name(&self) @dynamic => "bool";
fn Hash Bool.hash(&self) @dynamic => { self.name(), self.value ? 1 : 0 };

struct Null (Object)
{
    void* value;
}
fn String Null.inspect(&self) @dynamic => string::tformat("null");
fn String Null.name(&self) @dynamic => "null";

struct Return (Object)
{
    Object value;
}
fn String Return.inspect(&self) @dynamic => string::tformat("%s", self.value.inspect());
fn String Return.name(&self) @dynamic => "return";

struct Error (Object)
{
    String message;
}
fn String Error.inspect(&self) @dynamic => string::tformat("%s: %s", ascii::colorize_red("ERROR"), self.message);
fn String Error.name(&self) @dynamic => "error";

struct Fn (Object)
{
    List{Identifier} parameters;
    BlockStatement* body;
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

struct Str (Object, Hashable)
{
    String value;
}
fn String Str.name(&self) @dynamic => "str";
fn String Str.inspect(&self) @dynamic => self.value;
fn Hash Str.hash(&self) @dynamic => { self.name(), self.value.hash() };

alias BuiltinFn = fn Object(List{Object});

struct Builtin (Object)
{
    BuiltinFn fun;
}
fn String Builtin.name(&self) @dynamic => "builtin";
fn String Builtin.inspect(&self) @dynamic => "builtin fn";

struct Array (Object)
{
    List{Object} elements;
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
    Object key;
    Object value;
}

struct HashMap (Object)
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

struct Quote (Object)
{
    Node node;
}
fn String Quote.name(&self) @dynamic => "quote";
fn String Quote.inspect(&self) @dynamic => string::tformat("QUOTE(%s)", self.node);

struct Macro (Object)
{
    List{Identifier} parameters;
    BlockStatement* body;
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
