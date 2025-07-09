module classfile::cpool;

import std::io;
import std::collections::list;
import classfile::reader;

struct ConstPool
{
    List{Const} pool;
}

fn ConstPool new(Reader* r)
{
    ushort size = r.u16();
    List{Const} pool;
    pool.tinit(size);
    pool.push({ .tag = Tag.NULL });
    for (int i = 1; i<size; i++) pool.push(read_const(r)!!);
    return { .pool = pool };
}

faultdef INVALID_CONST_REF;

fn String? ConstPool.class_name(&self, usz idx)
{
    Const c = self.pool[idx];
    switch (c.tag) {
        case UTF8: return self.pool[idx].utf8_value;
        case CLASS: return self.class_name(self.pool[idx].class_index);
        case FIELD: return self.class_name(self.pool[idx].field.class_index);
        case METHOD: return self.class_name(self.pool[idx].method.class_index);
        case METHOD_HANDLE: return self.class_name(self.pool[idx].method_handle.descriptor_index);
        case INTERFACE_METHOD: return self.class_name(self.pool[idx].interface_method.class_index);
        default: 
            io::printfn("ERROR: Tag %s is not implemented for ConstPool.class_name(#%d)", c.tag, idx);
            return INVALID_CONST_REF?;
    }
}

fn String? ConstPool.name(&self, usz idx)
{
    Const c = self.pool[idx];
    switch (c.tag) {
        case UTF8: return self.pool[idx].utf8_value;
        case FIELD: return self.name(self.pool[idx].field.name_and_type_index);
        case METHOD: return self.name(self.pool[idx].method.name_and_type_index);
        case METHOD_HANDLE: return self.class_name(self.pool[idx].method_handle.descriptor_index);
        case INTERFACE_METHOD: return self.name(self.pool[idx].interface_method.name_and_type_index);
        case NAME_AND_TYPE: return self.name(self.pool[idx].name_and_type.name_index);
        case DYNAMIC: return self.name(self.pool[idx].dynamic.name_and_type_index);
        case INVOKE_DYNAMIC: return self.name(self.pool[idx].invoke_dynamic.name_and_type_index);
        default: 
            io::printfn("ERROR: Tag %s is not implemented for ConstPool.name(#%d)", c.tag, idx);
            return INVALID_CONST_REF?;
    }
}

fn String? ConstPool.descriptor(&self, usz idx)
{
    Const c = self.pool[idx];
    switch (c.tag) {
        case UTF8: return self.pool[idx].utf8_value;
        case FIELD: return self.name(self.pool[idx].field.name_and_type_index);
        case METHOD: return self.name(self.pool[idx].method.name_and_type_index);
        case METHOD_HANDLE: return self.class_name(self.pool[idx].method_handle.descriptor_index);
        case INTERFACE_METHOD: return self.name(self.pool[idx].interface_method.name_and_type_index);
        case NAME_AND_TYPE: return self.name(self.pool[idx].name_and_type.descriptor_index);
        case DYNAMIC: return self.name(self.pool[idx].dynamic.name_and_type_index);
        case INVOKE_DYNAMIC: return self.name(self.pool[idx].invoke_dynamic.name_and_type_index);
        default: 
            io::printfn("ERROR: Tag %s is not implemented for ConstPool.descriptor(#%d)", c.tag, idx);
            return INVALID_CONST_REF?;
    }
}

fn String? ConstPool.string(&self, usz idx)
{

    Const c = self.pool[idx];
    switch (c.tag) {
        case UTF8: return self.pool[idx].utf8_value;
        case STRING: return self.string(self.pool[idx].string_index);
        default: 
            io::printfn("ERROR: Tag %s is not implemented for ConstPool.string(#%d)", c.tag, idx);
            return INVALID_CONST_REF?;
    }
}

fn MethodHandleKind? ConstPool.reference_kind(&self, usz idx)
{
    Const c = self.pool[idx];
    switch (c.tag) {
        case METHOD_HANDLE: 
            char ref = self.pool[idx].method_handle.reference_kind;
            return MethodHandleKind.lookup_field(kind, ref); 
        default: 
            io::printfn("ERROR: Tag %s is not implemented for ConstPool.reference_kind(#%d)", c.tag, idx);
            return INVALID_CONST_REF?;
    }
}

enum MethodHandleKind: (char kind)
{
    GET_FIELD          = 1,
    GET_STATIC         = 2,
    PUT_FIELD          = 3,
    PUT_STATIC         = 4,
    INVOKE_VIRTUAL     = 5,
    INVOKE_STATIC      = 6,
    INVOKE_SPECIAL     = 7,
    NEW_INVOKE_SPECIAL = 8,
    INVOKE_INTERFACE   = 9,
}

fn usz? ConstPool.to_format(&self, Formatter* f) @dynamic {
    usz n;
    foreach (usz i, c: self.pool) n += f.printf("%-3d %s\n", i, c)!;
    return n;
}

enum Tag: (char tag)
{
    NULL             = 0, // unused
    UTF8             = 1,
    INTEGER          = 3,
    FLOAT            = 4,
    LONG             = 5,
    DOUBLE           = 6,
    CLASS            = 7,
    STRING           = 8,
    FIELD            = 9,
    METHOD           = 10,
    INTERFACE_METHOD = 11,
    NAME_AND_TYPE    = 12,
    METHOD_HANDLE    = 15,
    METHOD_TYPE      = 16,
    DYNAMIC          = 17,
    INVOKE_DYNAMIC   = 18,
    MODULE           = 19,
    PACKAGE          = 20,
}

struct Const
{
    Tag tag;
    union {
        String utf8_value;
        uint int_value;
        uint float_value;
        ulong long_value;
        ulong double_value;
        ushort class_index;
        ushort string_index;
        struct field
        {
            ushort class_index;
            ushort name_and_type_index;
        }
        struct method
        {
            ushort class_index;
            ushort name_and_type_index;
        }
        struct interface_method
        {
            ushort class_index;
            ushort name_and_type_index;
        }
        struct name_and_type
        {
            ushort name_index;
            ushort descriptor_index;
        }
        struct method_handle
        {
            char reference_kind;
            ushort descriptor_index;
        }
        ushort method_type_index;
        struct dynamic
        {
            ushort bootstrap_method_attr_index;
            ushort name_and_type_index;
        }
        struct invoke_dynamic
        {
            ushort bootstrap_method_attr_index;
            ushort name_and_type_index;
        }
        ushort module_index;
        ushort package_index;
    }
}

faultdef UNKNOWN_TAG;

fn Const? read_const(Reader* r)
{
    Tag tag = Tag.lookup_field(tag, r.u8())!!;
    switch (tag) {
        case NULL: return { .tag = tag };
        case UTF8: return { .tag = tag, .utf8_value = r.utf8(r.u16()) };
        case INTEGER: return { .tag = tag, .int_value = r.u32() };
        case FLOAT: return { .tag = tag, .float_value = r.u32() };
        case LONG: return { .tag = tag, .long_value = r.u64() };
        case DOUBLE: return { .tag = tag, .double_value = r.u64() };
        case CLASS: return { .tag = tag, .class_index = r.u16() };
        case STRING: return { .tag = tag, .string_index = r.u16() };
        case FIELD: return { .tag = tag, .field = { .class_index = r.u16(), .name_and_type_index = r.u16() } };
        case METHOD: return { .tag = tag, .method = { .class_index = r.u16(), .name_and_type_index = r.u16() } };
        case INTERFACE_METHOD: return { .tag = tag, .interface_method = { .class_index = r.u16(), .name_and_type_index = r.u16() } };
        case NAME_AND_TYPE: return { .tag = tag, .name_and_type = { .name_index = r.u16(), .descriptor_index = r.u16() } };
        case METHOD_HANDLE: return { .tag = tag, .method_handle = { .reference_kind = r.u8(), .descriptor_index = r.u16() } };
        case METHOD_TYPE: return { .tag = tag, .method_type_index = r.u16() };
        case DYNAMIC: return { .tag = tag, .dynamic = { .bootstrap_method_attr_index = r.u16(), .name_and_type_index = r.u16() } };
        case INVOKE_DYNAMIC: return { .tag = tag, .invoke_dynamic = { .bootstrap_method_attr_index = r.u16(), .name_and_type_index = r.u16() } };
        case MODULE: return { .tag = tag, .module_index = r.u16() };
        case PACKAGE: return { .tag = tag, .package_index = r.u16() };
        default: 
            io::printfn("ERROR: UNKNOWN TAG %s", tag);
            return UNKNOWN_TAG?;
    }
}

fn usz? Const.to_format(&self, Formatter* f) @dynamic {
    switch (self.tag) {
        case NULL: return f.printf("%-16s", self.tag);
        case UTF8: return f.printf("%-16s %s", self.tag, self.utf8_value);
        case INTEGER: return f.printf("%-16s %d", self.tag, self.int_value);
        case FLOAT: return f.printf("%-16s %d", self.tag, self.float_value);
        case LONG: return f.printf("%-16s %d", self.tag, self.long_value);
        case DOUBLE: return f.printf("%-16s %d", self.tag, self.double_value);
        case CLASS: return f.printf("%-16s [%d]", self.tag, self.class_index);
        case STRING: return f.printf("%-16s [%d]", self.tag, self.string_index);
        case FIELD: return f.printf("%-16s [%d,%d]", self.tag, self.field.class_index, self.field.name_and_type_index);
        case METHOD: return f.printf("%-16s [%d,%d]", self.tag, self.method.class_index, self.field.name_and_type_index);
        case INTERFACE_METHOD: return f.printf("%-16s [%d,Td]", self.tag, self.interface_method.class_index, self.interface_method.name_and_type_index);
        case NAME_AND_TYPE: return f.printf("%-16s [%d,%d]", self.tag, self.name_and_type.name_index, self.name_and_type.descriptor_index);
        case METHOD_HANDLE: return f.printf("%-16s [%d] kind(%s)", self.tag, self.method_handle.descriptor_index, self.method_handle.reference_kind);
        case METHOD_TYPE: return f.printf("%-16s [%d]", self.tag, self.method_type_index);
        case DYNAMIC: return f.printf("%-16s [%d,%d]" , self.tag, self.dynamic.bootstrap_method_attr_index, self.dynamic.name_and_type_index);
        case INVOKE_DYNAMIC: return f.printf("%-16s [%d,%d]", self.tag, self.invoke_dynamic.bootstrap_method_attr_index, self.invoke_dynamic.name_and_type_index);
        case MODULE: return f.printf("%-16s [%d]", self.tag, self.module_index);
        case PACKAGE: return f.printf("%-16s [%d]", self.tag, self.package_index);
    }
}
