module object;

import std::io;

interface Object
{
    fn ObjectType obj_type();
    fn String inspect();
}

enum ObjectType
{
    I32,
    BOOL,
    NULL,
    RETURN_VALUE,
}

struct Int32 (Object)
{
    int value;
}
fn String Int32.inspect(&self) @dynamic => string::tformat("%d", self.value);
fn ObjectType Int32.obj_type(&self) @dynamic => I32;

struct Bool (Object)
{
    bool value;
}
fn String Bool.inspect(&self) @dynamic => string::tformat("%s", self.value);
fn ObjectType Bool.obj_type(&self) @dynamic => BOOL;

struct Null (Object)
{
    void* value;
}
fn String Null.inspect(&self) @dynamic => string::tformat("null");
fn ObjectType Null.obj_type(&self) @dynamic => NULL;

struct Return (Object)
{
    Object value;
}
fn String Return.inspect(&self) @dynamic => string::tformat("%s", self.value.inspect());
fn ObjectType Return.obj_type(&self) @dynamic => RETURN_VALUE;
