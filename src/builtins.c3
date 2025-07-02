module evaluator::builtin;

import std::collections::list;
import std::io;
import object;

enum Builtins : (String literal, Builtin obj){
    LEN = { "len", { &builtin_len } },
}

fn Object builtin_len(List{Object} args)
{
    io::printfn("len.args: %d", args.len());
    if (args.len() != 1) return evaluator::err("wrong number of arguments: %d, expected: %d", args.len(), 1);
    switch (args[0].type)
    {
        case Str:
            Str* str = (Str*) args[0];
            int len = str.value.len;
            io::printfn("len: %d", len);
            return allocator::new(allocator::temp(), Int32, { .value = len });
        default: 
            return evaluator::err("argument to `len` is not supported: %s", args[0].name());
    }
}

