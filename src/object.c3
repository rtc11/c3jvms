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
}

struct I32Obj (Object)
{
    int value;
}
fn String I32Obj.inspect(&self) @dynamic => string::tformat("%d", self.value);
fn ObjectType I32Obj.obj_type(&self) @dynamic => I32;

struct BoolObj (Object)
{
    bool value;
}
fn String BoolObj.inspect(&self) @dynamic => string::tformat("%s", self.value);
fn ObjectType BoolObj.obj_type(&self) @dynamic => BOOL;

struct NullObj (Object)
{
    void* value;
}
fn String NullObj.inspect(&self) @dynamic => string::tformat("null");
fn ObjectType NullObj.obj_type(&self) @dynamic => NULL;

