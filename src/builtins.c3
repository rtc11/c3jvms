module evaluator::builtin;

import std::collections::list;
import std::io;
import object;

enum Builtins : (String literal, Builtin obj){
    LEN = { "len", { &builtin_len } },
    PUSH = { "push", { &builtin_push } },
    FIRST = { "first", { &builtin_first } },
    LAST = { "last", { &builtin_last } },
    REST = { "rest", { &builtin_rest } },
    SLICE = { "slice", { &builtin_slice } },
    PRINT = { "print", { &builtin_print } },
}

fn Object builtin_len(List{Object} args)
{
    if (args.len() != 1) return evaluator::err("wrong number of arguments: %d, expected: %d", args.len(), 1);
    switch (args[0].type)
    {
        case Str:
            Str* str = (Str*) args[0];
            int len = str.value.len;
            return allocator::new(allocator::temp(), Int32, { .value = len });
        case Array:
            Array* array = (Array*) args[0];
            int len = (int) array.elements.len();
            return allocator::new(allocator::temp(), Int32, { .value = len });
        default: 
            return evaluator::err("argument to `len` is not supported: %s", args[0].name());
    }
}

fn Object builtin_push(List{Object} args)
{
    if (args.len() != 2) return evaluator::err("wrong number of arguments: %d, expected: %d", args.len(), 2);
    if (args[0].type != Array.typeid) return evaluator::err("argument to 'push' must be array, got: %s", args[0].name());
    Array* array = (Array*) args[0];
    usz len = array.elements.len();
    List{Object} new = *@tclone(array.elements);
    new.push(args[1]);
    return allocator::new(allocator::temp(), Array, { .elements = new });
}

fn Object builtin_first(List{Object} args)
{
    if (args.len() != 1) return evaluator::err("wrong number of arguments: %d, expected: %d", args.len(), 1);
    if (args[0].type != Array.typeid) return evaluator::err("argument to 'first' must be array, got: %s", args[0].name());
    Array* array = (Array*) args[0];
    if (array.elements.len() > 0) return array.elements[0];
    return &evaluator::NULL;
}

fn Object builtin_last(List{Object} args)
{
    if (args.len() != 1) return evaluator::err("wrong number of arguments: %d, expected: %d", args.len(), 1);
    if (args[0].type != Array.typeid) return evaluator::err("argument to 'last' must be array, got: %s", args[0].name());
    Array* array = (Array*) args[0];
    usz len = array.elements.len();
    if (len > 0) return array.elements[len - 1];
    return &evaluator::NULL;
}

fn Object builtin_rest(List{Object} args)
{
    if (args.len() != 1) return evaluator::err("wrong number of arguments: %d, expected: %d", args.len(), 1);
    if (args[0].type != Array.typeid) return evaluator::err("argument to 'rest' must be array, got: %s", args[0].name());
    Array* array = (Array*) args[0];
    usz len = array.elements.len();
    if (len > 0) {
        List{Object} rest;
        rest.tinit();
        foreach(e: array.elements.to_tarray()[1..]) rest.push(e);
        return allocator::new(allocator::temp(), Array, { .elements = rest });
    }
    return &evaluator::NULL;
}

fn Object builtin_slice(List{Object} args)
{
    if (args.len() != 3) return evaluator::err("wrong number of arguments: %d, expected: %d", args.len(), 3);
    if (args[0].type != Array.typeid) return evaluator::err("1st arg to 'slice' must be array, got: %s", args[0].name());
    if (args[1].type != Int32.typeid) return evaluator::err("2nd arg to 'slice' must be i32, got: %s", args[1].name());
    if (args[2].type != Int32.typeid) return evaluator::err("3rd arg to 'slice' must be i32, got: %s", args[2].name());
    Array* array = (Array*) args[0];
    usz len = array.elements.len();
    int from = ((Int32*) args[1]).value;
    int to = ((Int32*) args[2]).value;
    if (to >= len) to = (int) len - 1;
    if (from < 0) from = 0;
    if (from <= to && from >= 0) {
        List{Object} slice;
        slice.tinit();
        foreach(e: array.elements.to_tarray()[from .. to]) slice.push(e);
        return allocator::new(allocator::temp(), Array, { .elements = slice });
    }
    return array;
}

fn Object builtin_print(List{Object} args)
{
    foreach(arg: args) io::printfn("%s", arg.inspect());
    return &evaluator::NULL;
}

