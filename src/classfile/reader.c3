module classfile::reader;

import std::io::file;
import std::collections::list;

struct Reader
{
    File* f;
    usz offset;
}

fn Reader new(File* f) => { .f = f };

fn String Reader.utf8(&self, usz len)
{
    self.offset+=len;
    DString string;
    for(int i; i<len; i++) string.append(self.f.read_byte()!!);
    return string.str_view();
}

fn char Reader.u8(&self)
{
    self.offset++;
    return self.f.read_byte()!!;
}

fn ushort Reader.u16(&self)
{
    self.offset+=2;
    ushort[2] bytes;
    for (int i; i<2; i++) bytes[i] = self.f.read_byte()!!;
    return (bytes[0] << 8) | bytes[1];
}

fn uint Reader.u32(&self)
{
    self.offset+=4;
    uint[4] bytes;
    for (int i; i<4; i++) bytes[i] = self.f.read_byte()!!;
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
}

fn ulong Reader.u64(&self)
{
    self.offset+=8;
    ulong[8] bytes;
    for (int i; i<8; i++) bytes[i] = self.f.read_byte()!!;
    return (bytes[0] << 56) | (bytes[1] << 48) | (bytes[2] << 40) | bytes[3] << 32 | bytes[4] << 24 | bytes[5] << 16 | bytes[6] << 8 | bytes[7];
}

macro Reader.list(&self, $Type, map, ...)
{
    self.offset+=2;
    ushort size = self.u16();
    List{$Type} list;
    list.tinit(size);
    for(int i; i<size; i++) list.push(map(self, $vasplat));
    return list;
}

macro Reader.slice(&self, $Type, usz size, map, ...)
{
    List{$Type} list;
    list.tinit(size);
    for(int i; i<size; i++) list.push(map(self, $vasplat));
    return list;
}

