module classfile::field;

import classfile;
import assembler;
import std::collections::list;
import std::io;

struct Field
{
    usz depth;
    List{AccessFlag} access;
    String name;
    String desc;
    List{Attribute} attrs;
}

fn Field new(Reader* r, ConstPool* cp, usz depth = 0)
{
    return {
        .depth = depth,
        .access = assembler::flags(AccessFlag, r.u16()),
        .name = cp.class_name(r.u16())!!,
        .desc = cp.class_name(r.u16())!!,
        .attrs = r.list(Attribute, &attr::new, cp, depth + 1),
    };
}

fn usz? Field.to_format(&self, Formatter* f) @dynamic {
    usz n;
    n += f.printf("\n")!;
    n += f.printf("%*s.access %s\n", self.depth*assembler::INDENT, "", self.access)!;
    n += f.printf("%*s.name %s\n", self.depth*assembler::INDENT, "", self.name)!;
    n += f.printf("%*s.descriptor %s\n", self.depth*assembler::INDENT, "", self.desc)!;
    foreach (attr: self.attrs) {
        n += f.printf("%*s.attr %s\n", (attr.depth)*assembler::INDENT, "", attr)!;
    }

    return n;
}

