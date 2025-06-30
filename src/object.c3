module object;

import std::io;
import std::collections::list;
import ascii, ast, environment;

interface Object
{
    fn String inspect();
}

fn bool Object.is_err(&self) => self.type == Error.typeid;

struct Int32 (Object)
{
    int value;
}
fn String Int32.inspect(&self) @dynamic => string::tformat("%d", self.value);

struct Bool (Object)
{
    bool value;
}
fn String Bool.inspect(&self) @dynamic => string::tformat("%s", self.value);

struct Null (Object)
{
    void* value;
}
fn String Null.inspect(&self) @dynamic => string::tformat("null");

struct Return (Object)
{
    Object value;
}
fn String Return.inspect(&self) @dynamic => string::tformat("%s", self.value.inspect());

struct Error (Object)
{
    String message;
}
fn String Error.inspect(&self) @dynamic => string::tformat("%s: %s", ascii::colorize_red("ERROR"), self.message);

struct Fn (Object)
{
    List{Identifier} parameters;
    BlockStatement* body;
    Environment* env;
}
fn String Fn.inspect(&self) @dynamic {
    String[] params = allocator::alloc_array(allocator::temp(), String, self.parameters.len());
    foreach(i, p: self.parameters) params[i] = string::tformat("%s", p);
    return string::tformat("fn(%s) {\n%s\n}",
        string::join(allocator::temp(), params, ", "),
        self.body,
    );
}

macro type(Object o)
{
    switch (o.type)
    {
        case Int32: return "i32";
        case Bool: return "bool";
        case Null: return "null";
        case Return : return "return";
        case Error : return "error";
        case Fn : return "fn";
        default: return "object::type(o) is not exhaustive!";
    }
}
