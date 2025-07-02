module object;

import std::io;
import std::collections::list;
import ascii, ast, environment;

interface Object
{
    fn String inspect();
    fn String name();
}

fn bool Object.is_err(&self) => self.type == Error.typeid;

struct Int32 (Object)
{
    int value;
}
fn String Int32.inspect(&self) @dynamic => string::tformat("%d", self.value);
fn String Int32.name(&self) @dynamic => "i32";

struct Bool (Object)
{
    bool value;
}
fn String Bool.inspect(&self) @dynamic => string::tformat("%s", self.value);
fn String Bool.name(&self) @dynamic => "bool";

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

struct Str (Object)
{
    String value;
}
fn String Str.name(&self) @dynamic => "str";
fn String Str.inspect(&self) @dynamic => self.value;

alias BuiltinFn = fn Object(List{Object});

struct Builtin (Object)
{
    BuiltinFn fun;
}
fn String Builtin.name(&self) @dynamic => "builtin";
fn String Builtin.inspect(&self) @dynamic => "builtin fn";
