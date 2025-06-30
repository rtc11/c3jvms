module object;

import std::io;
import std::collections::list;
import ascii, ast, environment;

interface Object
{
    fn ObjectType obj_type();
    fn String inspect();
}

fn bool Object.is_err(&self) => self.obj_type() == ERROR;

enum ObjectType
{
    I32,
    BOOL,
    NULL,
    RETURN_VALUE,
    ERROR,
    FN,
}

struct Int32 (Object)
{
    int value;
}
fn ObjectType Int32.obj_type(&self) @dynamic => I32;
fn String Int32.inspect(&self) @dynamic => string::tformat("%d", self.value);

struct Bool (Object)
{
    bool value;
}
fn ObjectType Bool.obj_type(&self) @dynamic => BOOL;
fn String Bool.inspect(&self) @dynamic => string::tformat("%s", self.value);

struct Null (Object)
{
    void* value;
}
fn ObjectType Null.obj_type(&self) @dynamic => NULL;
fn String Null.inspect(&self) @dynamic => string::tformat("null");

struct Return (Object)
{
    Object value;
}
fn ObjectType Return.obj_type(&self) @dynamic => RETURN_VALUE;
fn String Return.inspect(&self) @dynamic => string::tformat("%s", self.value.inspect());

struct Error (Object)
{
    String message;
}
fn ObjectType Error.obj_type(&self) @dynamic => ERROR;
fn String Error.inspect(&self) @dynamic => string::tformat("%s: %s", ascii::colorize_red("ERROR"), self.message);

struct Fn (Object)
{
    List{Identifier} parameters;
    BlockStatement* body;
    Environment* env;
}
fn ObjectType Fn.obj_type(&self) @dynamic => FN;
fn String Fn.inspect(&self) @dynamic {
    String[] params = allocator::alloc_array(allocator::temp(), String, self.parameters.len());
    foreach(i, p: self.parameters) params[i] = string::tformat("%s", p);
    return string::tformat("fn(%s) {\n%s\n}",
        string::join(allocator::temp(), params, ", "),
        self.body,
    );
}
