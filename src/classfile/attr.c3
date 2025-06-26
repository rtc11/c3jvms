module classfile::attr;

import classfile;
import assembler;
import std::collections::list;
import std::io;

struct Attribute
{
    usz depth;
    AttrType type;
    
    union {
        List{BootstrapMethod} bootstrap_methods;
        InnerClasses inner_classes;
        SourceFile source_file;
        Code code;
        String body;
    }
}

struct Code
{
    usz depth;
    usz length;
    ushort stack;
    ushort locals;
    List{Instruction} instructions;
    List{Exception} exceptions;
    List{Attribute} attrs;
}

fn Code new_code(Reader* r, ConstPool* cp, usz length, usz depth)
{
    ushort stack = r.u16();
    ushort locals = r.u16();
    List{Instruction} instructions = assembler::disassemble_code(r, cp, depth+1);

    ushort exception_len = r.u16();
    List{Exception} exceptions;
    exceptions.tinit(exception_len);
    for(int i; i<exception_len; i++) exceptions.push({ r.u16(), r.u16(), r.u16(), r.u16() });

    ushort attrs_len = r.u16();
    List{Attribute} attrs;
    attrs.tinit(attrs_len);
    for(int i; i<attrs_len; i++) attrs.push(new(r, cp, depth+1));

    return { 
        .depth = depth,
        .length = length,
        .stack = stack,
        .locals = locals,
        .instructions = instructions,
        .exceptions = exceptions,
        .attrs = attrs,
    };
}

fn usz? Code.to_format(&self, Formatter* f) @dynamic {
    usz n;
    n += f.printf("\n")!;
    n += f.printf("%*s.instructions\n", (self.depth+1)*assembler::INDENT, "")!;
    foreach (inst: self.instructions) {
        n += f.printf("%*s%s\n", (inst.depth)*assembler::INDENT, "", inst)!;
    }
    return n;
}

struct Exception
{
    ushort start_pc;
    ushort end_pc;
    ushort handler_pc;
    ushort catch_type;
}

struct BootstrapMethod
{
    usz depth;
    MethodHandleKind reference_kind;
    String class_name;
    String name;
    String descriptor;
    List{String} args;
}

fn BootstrapMethod new_bootstrap_method(Reader* r, ConstPool* cp, usz depth = 0) {

    ushort bm_idx = r.u16();
    BootstrapMethod bm ={
        .depth = depth,
            .reference_kind = cp.reference_kind(bm_idx)!!, 
            .class_name = cp.class_name(bm_idx)!!,
            .name = cp.name(bm_idx)!!,
            .descriptor = cp.descriptor(bm_idx)!!,
            .args = r.list(String, &read_string, cp),
    };
    return bm;
}

fn String read_string(Reader* r, ConstPool* cp)
{
    return cp.string(r.u16())!!;
}

fn usz? BootstrapMethod.to_format(&self, Formatter* f) @dynamic {
    usz n;
    n += f.printf("\n")!;
    n += f.printf("%*s.reference_kind %s\n", self.depth*assembler::INDENT, "", self.reference_kind)!;
    n += f.printf("%*s.class_name %s\n", self.depth*assembler::INDENT, "", self.class_name)!;
    n += f.printf("%*s.name %s\n", self.depth*assembler::INDENT, "", self.name)!;
    n += f.printf("%*s.descriptor %s\n", self.depth*assembler::INDENT, "", self.descriptor)!;
    n += f.printf("%*s.args\n", self.depth*assembler::INDENT, "")!;
    foreach(arg: self.args) {
        n += f.printf("%*s.arg %s", (self.depth+1)*assembler::INDENT, "", arg)!;
    }
    return n;
}

struct InnerClasses
{
    usz depth;
    String inner_class;
    String outer_class;
    String inner_class_name;
    List{AccessFlag} access;
}

fn InnerClasses new_inner_classes(Reader* r, ConstPool* cp, usz depth = 0) =>
{
    .depth = depth,
    .inner_class = cp.class_name(r.u16())!!,
    .outer_class = cp.class_name(r.u16())!!,
    .inner_class_name = cp.class_name(r.u16())!!,
    .access = assembler::flags(AccessFlag, r.u16()),
};

struct SourceFile
{
    usz depth;
    String filename;
}

fn SourceFile new_source_file(Reader* r, ConstPool* cp, usz depth = 0) =>
{
    .depth = depth,
    .filename = cp.class_name(r.u16())!!,
};

fn usz? SourceFile.to_format(&self, Formatter* f) @dynamic {
    usz n;
    n += f.printf("\n")!;
    n += f.printf("%*s.filename %s", self.depth*assembler::INDENT, "", self.filename)!;
    return n;
}

fn usz? InnerClasses.to_format(&self, Formatter* f) @dynamic {
    usz n;
    n += f.printf("\n")!;
    n += f.printf("%*s.inner_class %s\n", self.depth*assembler::INDENT, "", self.inner_class)!;
    n += f.printf("%*s.outer_class %s\n", self.depth*assembler::INDENT, "", self.outer_class)!;
    n += f.printf("%*s.inner_class_name %s\n", self.depth*assembler::INDENT, "", self.inner_class_name)!;
    n += f.printf("%*s.access %s", self.depth*assembler::INDENT, "", self.access)!;
    return n;
}

faultdef NOT_IMPLEMENTED;

fn Attribute new(Reader* r, ConstPool* cp, usz depth = 0)
{
    ushort name_idx = r.u16();
    uint length = r.u32();
    String name = cp.class_name(name_idx)!!;

    switch (name) {
        case "AnnotationDefault": return { .depth = depth, .type = ANNOTATION_DEFAULT, .body = r.utf8(length) };
        case "BootstrapMethods": return { .depth = depth, .type = BOOTSTRAP_METHODS, .bootstrap_methods = r.list(BootstrapMethod, &new_bootstrap_method, cp, depth+1) };
        case "Code": return { .depth = depth, .type = CODE, .code = new_code(r, cp, length, depth) };
        case "ConstantValue": return { .depth = depth, .type = CONSTANT_VALUE, .body = r.utf8(length) };
        case "Deprecated": return { .depth = depth, .type = DEPRECATED, .body = r.utf8(length) };
        case "EnclosingMethod": return { .depth = depth, .type = ENCLOSING_METHOD, .body = r.utf8(length) };
        case "Exceptions": return { .depth = depth, .type = EXCEPTIONS, .body = r.utf8(length) };
        case "InnerClasses": return { .depth = depth, .type = INNER_CLASSES, .inner_classes = new_inner_classes(r, cp, depth+1) };
        case "LineNumberTable": return { .depth = depth, .type = LINE_NUMBER_TABLE, .body = r.utf8(length) };
        case "LocalVariableTable": return { .depth = depth, .type = LOCAL_VARIABLE_TABLE, .body = r.utf8(length) };
        case "LocalVariableTypeTable": return { .depth = depth, .type = LOCAL_VARIABLE_TYPE_TABLE, .body = r.utf8(length) };
        case "MethodParameters": return { .depth = depth, .type = METHOD_PARAMETERS, .body = r.utf8(length) };
        case "Module": return { .depth = depth, .type = MODULE, .body = r.utf8(length) };
        case "ModuleMainClass": return { .depth = depth, .type = MODULE_MAIN_CLASS, .body = r.utf8(length) };
        case "ModulePackages": return { .depth = depth, .type = MODULE_PACKAGES, .body = r.utf8(length) };
        case "NestHost": return { .depth = depth, .type = NEST_HOST, .body = r.utf8(length) };
        case "NestMembers": return { .depth = depth, .type = NEST_MEMBERS, .body = r.utf8(length) };
        case "PermittedSublasses": return { .depth = depth, .type = PERMITTED_SUBCLASSES, .body = r.utf8(length) };
        case "Record": return { .depth = depth, .type = RECORD, .body = r.utf8(length) };
        case "RuntimeInvisibleAnnotations": return { .depth = depth, .type = RUNTIME_INVISIBLE_ANNOTATIONS, .body = r.utf8(length) };
        case "RuntimeInvisibleParameterAnnotations": return { .depth = depth, .type = RUNTIME_INVISIBLE_PARAMETER_ANNOTATIONS, .body = r.utf8(length) };
        case "RuntimeInvisibleTypeAnnotations": return { .depth = depth, .type = RUNTIME_INVISIBLE_TYPE_ANNOTATIONS, .body = r.utf8(length) };
        case "RuntimeVisibleAnnotations": return { .depth = depth, .type = RUNTIME_VISIBLE_ANNOTATIONS, .body = r.utf8(length) };
        case "RuntimeVisibleParameterAnnotations": return { .depth = depth, .type = RUNTIME_VISIBLE_PARAMETER_ANNOTATIONS, .body = r.utf8(length) };
        case "RuntimeVisibleTypeAnnotations": return { .depth = depth, .type = RUNTIME_VISIBLE_TYPE_ANNOTATIONS, .body = r.utf8(length) };
        case "Signature": return { .depth = depth, .type = SIGNATURE, .body = r.utf8(length) };
        case "SourceDebugExtension": return { .depth = depth, .type = SOURCE_DEBUG_EXTENSION, .body = r.utf8(length) };
        case "SourceFile": return { .depth = depth, .type = SOURCE_FILE, .source_file = new_source_file(r, cp, depth+1) };
        case "StackMapTable": return { .depth = depth, .type = STACK_MAP_TABLE, .body = r.utf8(length) };
        case "Synthetic": return { .depth = depth, .type = SYNTHETIC, .body = r.utf8(length) };
        default: return { .depth = depth, .type = RAW, .body = r.utf8(length) };
    }
}

fn usz? Attribute.to_format(&self, Formatter* f) @dynamic {
    usz n;
    n += f.printf("\n")!;
    switch (self.type) 
    {
        // case ANNOTATION_DEFAULT: n+= f.printf("%-16s", self.type)!;
        case BOOTSTRAP_METHODS: 
            n+= f.printf("%*s.bootstrap_methods", self.depth*assembler::INDENT, "")!;
            foreach(bm: self.bootstrap_methods) {
                n+= f.printf("%*s%s\n", bm.depth*assembler::INDENT, "", bm)!;
            }
        case CODE: n+= f.printf("%*s.code %s", self.depth*assembler::INDENT, "", self.code)!;
        // case CONSTANT_VALUE: n+= f.printf("%-16s", self.type)!;
        // case DEPRECATED: n+= f.printf("%-16s", self.type)!;
        // case ENCLOSING_METHOD: n+= f.printf("%-16s", self.type)!;
        // case EXCEPTIONS: n+= f.printf("%-16s", self.type)!;
        case INNER_CLASSES: n+= f.printf("%*s.inner_classes %s", self.depth*assembler::INDENT, "", self.inner_classes)!;
        // case LINE_NUMBER_TABLE: n+= f.printf("%-16s", self.type)!;
        // case LOCAL_VARIABLE_TABLE: n+= f.printf("%-16s", self.type)!;
        // case LOCAL_VARIABLE_TYPE_TABLE: n+= f.printf("%-16s", self.type)!;
        // case METHOD_PARAMETERS: n+= f.printf("%-16s", self.type)!;
        // case MODULE: n+= f.printf("%-16s", self.type)!;
        // case MODULE_MAIN_CLASS: n+= f.printf("%-16s", self.type)!;
        // case MODULE_PACKAGES: n+= f.printf("%-16s", self.type)!;
        // case NEST_HOST: n+= f.printf("%-16s", self.type)!;
        // case NEST_MEMBERS: n+= f.printf("%-16s", self.type)!;
        // case PERMITTED_SUBCLASSES: n+= f.printf("%-16s", self.type)!;
        // case RECORD: n+= f.printf("%-16s", self.type)!;
        // case RUNTIME_INVISIBLE_ANNOTATIONS: n+= f.printf("%-16s", self.type)!;
        // case RUNTIME_INVISIBLE_PARAMETER_ANNOTATIONS: n+= f.printf("%-16s", self.type)!;
        // case RUNTIME_INVISIBLE_TYPE_ANNOTATIONS: n+= f.printf("%-16s", self.type)!;
        // case RUNTIME_VISIBLE_ANNOTATIONS: n+= f.printf("%-16s", self.type)!;
        // case RUNTIME_VISIBLE_PARAMETER_ANNOTATIONS: n+= f.printf("%-16s", self.type)!;
        // case RUNTIME_VISIBLE_TYPE_ANNOTATIONS: n+= f.printf("%-16s", self.type)!;
        // case SIGNATURE: n+= f.printf("%-16s", self.type)!;
        // case SOURCE_DEBUG_EXTENSION: n+= f.printf("%-16s", self.type)!;
        case SOURCE_FILE: n+= f.printf("%*s.source_file %s", self.depth*assembler::INDENT, "", self.source_file)!;
        // case STACK_MAP_TABLE: n+= f.printf("%-16s", self.type)!;
        // case SYNTHETIC: n+= f.printf("%-16s", self.type)!;
        // case RAW: n+= f.printf("%-16s", self.type)!;
        default:
            io::printfn("ERROR: Attribute.to_format(%s) not implemented", self.type);
            return NOT_IMPLEMENTED?;
    }
    return n;
}

enum AttrType
{
    ANNOTATION_DEFAULT,
    BOOTSTRAP_METHODS,
    CODE,
    CONSTANT_VALUE,
    DEPRECATED,
    ENCLOSING_METHOD,
    EXCEPTIONS,
    INNER_CLASSES,
    LINE_NUMBER_TABLE,
    LOCAL_VARIABLE_TABLE,
    LOCAL_VARIABLE_TYPE_TABLE,
    METHOD_PARAMETERS,
    MODULE,
    MODULE_MAIN_CLASS,
    MODULE_PACKAGES,
    NEST_HOST,
    NEST_MEMBERS,
    PERMITTED_SUBCLASSES,
    RECORD,
    RUNTIME_INVISIBLE_ANNOTATIONS,
    RUNTIME_INVISIBLE_PARAMETER_ANNOTATIONS,
    RUNTIME_INVISIBLE_TYPE_ANNOTATIONS,
    RUNTIME_VISIBLE_ANNOTATIONS,
    RUNTIME_VISIBLE_PARAMETER_ANNOTATIONS,
    RUNTIME_VISIBLE_TYPE_ANNOTATIONS,
    SIGNATURE,
    SOURCE_DEBUG_EXTENSION,
    SOURCE_FILE,
    STACK_MAP_TABLE,
    SYNTHETIC,
    RAW,
}
