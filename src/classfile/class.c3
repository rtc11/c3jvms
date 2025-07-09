module classfile;

import std::io;
import std::collections::tuple;
import std::collections::list;

struct Class 
{
    Tuple{ushort, ushort} version;
    ConstPool cp;
    ushort access;
    ushort this;
    ushort super;
    List{ushort} interfaces;
    List{Field} fields;
    List{Field} methods;
    List{Attribute} attrs;
}

faultdef FILE_NOT_A_CLASS;

fn Class? new(Reader* r)
{
    if (r.u32() != 0xCAFEBABE) return FILE_NOT_A_CLASS?; 
    Class class = {
        .version = { .first = r.u16(), .second = r.u16() },
        .cp = cpool::new(r),
        .access = r.u16(),
        .this = r.u16(),
        .super = r.u16(),
        .interfaces = r.list(ushort, &Reader.u16),
        .fields = r.list(Field, &field::new, &class.cp, 1),
        .methods = r.list(Field, &field::new, &class.cp, 1),
        .attrs = r.list(Attribute, &attr::new, &class.cp, 1),

    };
    return class;
}

enum AccessFlag: (ushort flag)
{
    PUBLIC     = 0x0001,
    PRIVATE    = 0x0002,
    PROTECTED  = 0x0004,
    STATIC     = 0x0008,
    FINAL      = 0x0010,
    SUPER      = 0x0020,
    VOLATILE   = 0x0040,
    TRANSIENT  = 0x0080,
    INTERFACE  = 0x0200,
    ABSTRACT   = 0x0400,
    SYNTHETIC  = 0x1000,
    ANNOTATION = 0x2000,
    ENUM       = 0x4000,
    MODULE     = 0x8000,
}

enum MethodAccessFlag: (ushort flag)
{
    PUBLIC       = 0x0001,
    PRIVATE      = 0x0002,
    PROTECTED    = 0x0004,
    STATIC       = 0x0008,
    FINAL        = 0x0010,
    SYNCHRONIZED = 0x0020,
    BRIDGE       = 0x0040,
    VARARGS      = 0x0080,
    NATIVE       = 0x0100,
    ABSTRACT     = 0x0400,
    STRICT       = 0x0800,
    SYNTHETIC    = 0x1000,
}
