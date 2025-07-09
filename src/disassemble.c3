module assembler;

import std::io;
import std::collections::list;
import classfile;

const INDENT = 4;

fn void disassemble(Class* c)
{
    io::printfn(".version %d %d", c.version.second-44, c.version.first);

    List{AccessFlag} access = flags(AccessFlag, c.access);
    io::printfn(".class %s [%s]", access, c.cp.class_name(c.this)!!);
    io::printfn(".super [%s]", c.cp.class_name(c.super)!!);

    foreach(idx: c.interfaces) {
        io::printfn(".interface %s", c.cp.class_name(idx)!!);
    }

    foreach(f: c.fields) {
        io::printfn(".field %s", f);
    }

    foreach(m: c.methods) {
        io::printfn(".method %s", m);
    }

    // foreach(a: c.attrs) {
    //     io::printfn(".attr %s", a);
    // }
}

macro flags($Enum, ushort bytes)
{
    List{$Enum} flags;
    flags.tinit();
    $foreach $value : $Enum.values: 
        // expects all these enums to have associated "ushort flag"
        if (bytes & $value.flag) flags.push($value); 
    $endforeach
    return flags;
}

struct Instruction
{
    usz depth;
    usz line;
    String name;
    union {
        char u8;
        ushort u16;
        uint u32;
        ulong u64;
    }
}

fn usz? Instruction.to_format(&self, Formatter* f) @dynamic {
    switch (self.name)
    {
        case "aload": 
        case "dload":
        case "fload":
        case "iload":
        case "lload":
        case "bipush": // u8 sign-extended to an int value, pushed onto the operand stack
        case "newarray":
        case "ldc":
        case "ret":
        case "istore":
        case "astore": 
            return f.printf("%*s%s #%s", self.depth, "", self.name, self.u8); 
        case "anewarray": 
        case "getfield":
        case "getstatic":
        case "goto":
        case "ifnonnull":
        case "ifnull":
        case "instanceof":
        case "invokedynamic":
        case "invokespecial":
        case "invokestatic":
        case "invokevirtual":
        case "jsr":
        case "ldc_w":
        case "ldc2_w":
        case "new":
        case "putfield":
        case "putstatic":
        case "sipush":
        case "checkcast": 
            return f.printf("%*s%s #%s", self.depth, "", self.name, self.u16); 
        case "jsr_w":
        case "goto_w": 
            return f.printf("%*s%s #%s", self.depth, "", self.name, self.u32); 
        case "invokeinterface": 
        case "multianewarray": 
        case "iinc": 
            return f.printf("%*s%s #%s #%s", self.depth, "", self.name, self.u16, self.u8); 
        default: 
            return f.printf("%*s%s", self.depth, "", self.name);
    }
} 

fn List{Instruction} disassemble_code(Reader* r, ConstPool* cp, usz depth = 0)
{
    uint len = r.u32();
    List{Instruction} instructions;
    instructions.tinit(len);

    usz limit = r.offset+len;
    while(r.offset < limit) {
        Instruction inst = new_instr(r, cp)!!;
        inst.depth = depth;
        instructions.push(inst);
    }
    return instructions;
}

faultdef NOT_IMPL;
fn Instruction? new_instr(Reader* r, ConstPool* cp)
{
    usz opcode = r.u8();
    switch (opcode)
    {
        // CONSTANTS
        case 0:   return { .name = "nop" };
        case 1:   return { .name = "aconst_null" };
        case 2:   return { .name = "iconst_m1" };
        case 3:   return { .name = "iconst_0" };
        case 4:   return { .name = "iconst_1" };
        case 5:   return { .name = "iconst_2" };
        case 6:   return { .name = "iconst_3" };
        case 7:   return { .name = "iconst_4" };
        case 8:   return { .name = "iconst_5" };
        case 9:   return { .name = "lconst_0" };
        case 10:  return { .name = "lconst_1" };
        case 11:  return { .name = "fconst_0" };
        case 12:  return { .name = "fconst_1" };
        case 13:  return { .name = "fconst_2" };
        case 14:  return { .name = "dconst_0" };
        case 15:  return { .name = "dconst_1" };
        case 16:  return { .name = "bipush", .u8 = r.u8() };
        case 17:  return { .name = "sipush", .u16 = r.u16() };
        case 18:  return { .name = "ldc", .u8 = r.u8() };
        case 19:  return { .name = "ldc_w", .u16 = r.u16() };
        case 20:  return { .name = "ldc2_w", .u16 = r.u16() };
        // LOADS
        case 21:  return { .name = "iload", .u8 = r.u8() };
        case 22:  return { .name = "lload", .u8 = r.u8() };
        case 23:  return { .name = "fload", .u8 = r.u8() };
        case 24:  return { .name = "dload", .u8 = r.u8() };
        case 25:  return { .name = "aload", .u8 = r.u8() };
        case 26:  return { .name = "iload_0" };
        case 27:  return { .name = "iload_1" };
        case 28:  return { .name = "iload_2" };
        case 29:  return { .name = "iload_3" };
        case 30:  return { .name = "lload_0" };
        case 31:  return { .name = "lload_1" };
        case 32:  return { .name = "lload_2" };
        case 33:  return { .name = "lload_3" };
        case 34:  return { .name = "fload_0" };
        case 35:  return { .name = "fload_1" };
        case 36:  return { .name = "fload_2" };
        case 37:  return { .name = "fload_3" };
        case 38:  return { .name = "dload_0" };
        case 39:  return { .name = "dload_1" };
        case 40:  return { .name = "dload_2" };
        case 41:  return { .name = "dload_3" };
        case 42:  return { .name = "aload_0" };
        case 43:  return { .name = "aload_1" };
        case 44:  return { .name = "aload_2" };
        case 45:  return { .name = "aload_3" };
        case 46:  return { .name = "iload" };
        case 47:  return { .name = "laload" };
        case 48:  return { .name = "faload" };
        case 49:  return { .name = "daload" };
        case 50:  return { .name = "aaload" };
        case 51:  return { .name = "baload" };
        case 52:  return { .name = "caload" };
        case 53:  return { .name = "saload" };
        // STORES
        case 54:  return { .name = "istore", .u8 = r.u8() };
        case 55:  return { .name = "lstore", .u8 = r.u8() };
        case 56:  return { .name = "fstore", .u8 = r.u8() };
        case 57:  return { .name = "dstore", .u8 = r.u8() };
        case 58:  return { .name = "astore", .u8 = r.u8() };
        case 59:  return { .name = "istore_0" };
        case 60:  return { .name = "istore_1" };
        case 61:  return { .name = "istore_2" };
        case 62:  return { .name = "istore_3" };
        case 63:  return { .name = "lstore_0" };
        case 64:  return { .name = "lstore_1" };
        case 65:  return { .name = "lstore_2" };
        case 66:  return { .name = "lstore_3" };
        case 67:  return { .name = "fstore_0" };
        case 68:  return { .name = "fstore_1" };
        case 69:  return { .name = "fstore_2" };
        case 70:  return { .name = "fstore_3" };
        case 71:  return { .name = "dstore_0" };
        case 72:  return { .name = "dstore_1" };
        case 73:  return { .name = "dstore_2" };
        case 74:  return { .name = "dstore_3" };
        case 75:  return { .name = "astore_0" };
        case 76:  return { .name = "astore_1" };
        case 77:  return { .name = "astore_2" };
        case 78:  return { .name = "astore_3" };
        case 79:  return { .name = "istore"  };
        case 80:  return { .name = "lastore" };
        case 81:  return { .name = "fastore" };
        case 82:  return { .name = "dastore" };
        case 83:  return { .name = "aastore" };
        case 84:  return { .name = "bastore" };
        case 85:  return { .name = "castore" };
        case 86:  return { .name = "sastore" };
        // STAK
        case 87:  return { .name = "pop" };
        case 88:  return { .name = "pop2" };
        case 89:  return { .name = "dup" };
        case 90:  return { .name = "dup_x1" };
        case 91:  return { .name = "dup_x2" };
        case 92:  return { .name = "dup2" };
        case 93:  return { .name = "dup2_x1" };
        case 94:  return { .name = "dup2_x2" };
        case 95:  return { .name = "swap" };
        // MATH
        case 96:  return { .name = "iadd" };
        case 97:  return { .name = "ladd" };
        case 98:  return { .name = "fadd" };
        case 99:  return { .name = "dadd" };
        case 100: return { .name = "isub" };
        case 101: return { .name = "lsub" };
        case 102: return { .name = "fsub" };
        case 103: return { .name = "dsub" };
        case 104: return { .name = "imul" };
        case 105: return { .name = "lmul" };
        case 106: return { .name = "fmul" };
        case 107: return { .name = "dmul" };
        case 108: return { .name = "idiv" };
        case 109: return { .name = "ldiv" };
        case 110: return { .name = "fdiv" };
        case 111: return { .name = "ddiv" };
        case 112: return { .name = "irem" };
        case 113: return { .name = "lrm", };
        case 114: return { .name = "frem" };
        case 115: return { .name = "drem" };
        case 116: return { .name = "ineg" };
        case 117: return { .name = "lneg" };
        case 118: return { .name = "fneg" };
        case 119: return { .name = "dneg" };
        case 120: return { .name = "ishl" };
        case 121: return { .name = "lshl" };
        case 122: return { .name = "ishr" };
        case 123: return { .name = "lshr" };
        case 124: return { .name = "iushr" };
        case 125: return { .name = "lushr" };
        case 126: return { .name = "iand" };
        case 127: return { .name = "land" };
        case 128: return { .name = "ior" };
        case 129: return { .name = "lor" };
        case 130: return { .name = "ixor" };
        case 131: return { .name = "lxor" };
        case 132: return { .name = "iinc", .u16 = r.u16() };
        // CONVERSIONS
        case 133: return { .name = "i2l" };
        case 134: return { .name = "i2f" };
        case 135: return { .name = "i2d" };
        case 136: return { .name = "l2i" };
        case 137: return { .name = "l2f" };
        case 138: return { .name = "l2d" };
        case 139: return { .name = "f2i" };
        case 140: return { .name = "f2l" };
        case 141: return { .name = "f2d" };
        case 142: return { .name = "d2i" };
        case 143: return { .name = "d2l" };
        case 144: return { .name = "d2f" };
        case 145: return { .name = "i2b" };
        case 146: return { .name = "i2c" };
        case 147: return { .name = "ics" };
        // COMPARISON
        case 148: return { .name = "lcmp" };
        case 149: return { .name = "fcmpl" };
        case 150: return { .name = "fcmpg" };
        case 151: return { .name = "dcmpl" };
        case 152: return { .name = "dcmpg" };
        case 153: return { .name = "ifeq" };
        case 154: return { .name = "ifne" };
        case 155: return { .name = "iflt" };
        case 156: return { .name = "ifge" };
        case 157: return { .name = "ifgt" };
        case 158: return { .name = "ifle" };
        case 159: return { .name = "if_icmpeq" };
        case 160: return { .name = "if_icmpne" };
        case 161: return { .name = "if_icmplt" };
        case 162: return { .name = "if_icmpge" };
        case 163: return { .name = "if_icmpgt" };
        case 164: return { .name = "if_icmple" };
        case 165: return { .name = "if_acmpeq" };
        case 166: return { .name = "if_acmpne" };
        // CONTROL
        case 167: return { .name = "goto", .u16 = r.u16() };
        case 168: return { .name = "jsr", .u16 = r.u16() };
        case 169: return { .name = "ret", .u8 = r.u8() };
        case 170:              
            usz padding = (4 - (r.offset + 1 % 4)) % 4;
            r.offset+=padding; // align memory skew by adding padding between 0 and 3
            int switch_default = r.u32();
            int low = r.u32();
            int high = r.u32();
            for (int n; n<(high - low + 1); n++) {
                int jump = r.u32();
                io::printfn("jump: #%d", jump); // TODO: add to instruction
            }
            return { .name = "tableswitch" };
        case 171:
            usz padding = (4 - (r.offset + 1 % 4) % 4);
            r.offset+=padding; // align memory skew by adding padding between 0 and 3
            int switch_default = r.u32();
            int npairs = r.u32();
            for (int npair; npair < npairs; npair++) {
                int switch_match = r.u32();
                int switch_offset = r.u32();
                io::printfn("match:   %d", switch_match);
                io::printfn("offset:  %d", switch_offset);
            }
            io::printfn("default: %d", switch_default);
            return { .name = "lookupswitch" };  // TODO: add to instruction
        case 172: return { .name = "ireturn" };
        case 173: return { .name = "lreturn" };
        case 174: return { .name = "freturn" };
        case 175: return { .name = "dreturn" };
        case 176: return { .name = "areturn" };
        case 177: return { .name = "return" };
        // REFERENCES
        case 178: return { .name = "getstatic", .u16 = r.u16() };
        case 179: return { .name = "putstatic", .u16 = r.u16() };
        case 180: return { .name = "getfield", .u16 = r.u16() };
        case 181: return { .name = "putfield", .u16 = r.u16() };
        case 182: return { .name = "invokevirtual", .u16 = r.u16() };
        case 183: return { .name = "invokespecial", .u16 = r.u16() };
        case 184: return { .name = "invokestatic", .u16 = r.u16() };
        case 185: return { .name = "invokeinterface", .u32 = r.u32() };
        case 186: return { .name = "invokedynamic", .u32 = r.u32() };
        case 187: return { .name = "new", .u16 = r.u16() };
        case 188: return { .name = "newarray", .u8 = r.u8() };
        case 189: return { .name = "anewarray", .u16 = r.u16() };
        case 190: return { .name = "arraylength" };
        case 191: return { .name = "athrow" };
        case 192: return { .name = "checkcast", .u16 = r.u16() };
        case 193: return { .name = "instanceof", .u16 = r.u16() };
        case 194: return { .name = "monitorenter" };
        case 195: return { .name = "monitorexit" };
        // EXTENDED
        case 196:              
            if ((usz) r.u8() == 132) { // iinc
                return { .name = "wide", .u32 = r.u32() };
            } else {
                return { .name = "wide", .u16 = r.u16() };
            }
        case 197: return { .name = "multianewarray", .u16 = r.u16(), .u8 = r.u8() };
        case 198: return { .name = "ifnull", .u16 = r.u16() };
        case 199: return { .name = "ifnonnull", .u16 = r.u16() };
        case 200: return { .name = "goto_w", .u32 = r.u32() };
        case 201: return { .name = "jsr_w", .u32 = r.u32() };
        // RESERVED
        case 202: return { .name = "breakpoint" };
        case 254: return { .name = "impdep1" };
        case 255: return { .name = "impdep2" };
        default:
            io::printfn("opcode %s not implemented", opcode);
            return NOT_IMPL?;
    }
}

