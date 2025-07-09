module test::object;

import std::io;
import std::collections::list;
import object;

fn void string_hash_key() @test
{
    Str hello1 = { "Hello World" };
    Str hello2 = { "Hello World" };
    Str diff1 = { "My name is johnny" };
    Str diff2 = { "My name is johnny" };
    test::eq(hello1.hash(), hello2.hash());
    test::eq(diff1.hash(), diff1.hash());
    test::ne(hello1.hash(), diff1.hash());
}

fn void i32_hash_key() @test
{
    Int32 int1 = { 1};
    Int32 int2 = { 1 };
    Int32 int3 = { 20 };
    Str str1 = { "Hello World" };
    test::eq(int1.hash(), int1.hash());
    test::eq(int1.hash(), int2.hash());
    test::ne(int1.hash(), int3.hash());
    test::ne(str1.hash(), int1.hash());
}

fn void bool_hash_key() @test
{
    Bool bt1 = { true };
    Bool bt2 = { true };
    Bool bf = { false };
    test::eq(bt1.hash(), bt1.hash());
    test::eq(bt1.hash(), bt2.hash());
    test::ne(bt1.hash(), bf.hash());
}

fn void i32_bool_hash_key() @test
{
    Bool t = { true };
    Bool f = { false };
    Int32 i1 = { 1 };
    Int32 i0 = { 0 };
    test::eq(t.hash(), i1.hash());
    test::eq(f.hash(), i0.hash());
}

