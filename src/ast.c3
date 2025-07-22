module ast;

import lexer;
import std::io;
import std::collections::list;
import std::collections::map;

interface Node
{
    fn String token_literal();
    fn usz? to_format(Formatter* f);
}

interface Statement: Node {}
interface Expression: Node {}

struct Program (Node)
{
    List{Statement} statements;
}

fn String Program.token_literal(&self) @dynamic {
    if (self.statements.size == 0) return "";
    return self.statements[0].token_literal();
}
fn usz? Program.to_format(&self, Formatter* f) @dynamic {
    usz out;
    foreach(stmt: self.statements) out += f.printf("%s", stmt)!; 
    return out;
}

struct Identifier (Expression)
{
    Token token;
    String value;
}
fn String Identifier.token_literal(&self) @dynamic => self.token.literal;
fn usz? Identifier.to_format(&self, Formatter* f) @dynamic {
    return f.printf("%s", self.value);
}
fn uint Identifier.hash(&self) => string::tformat("%s", self).hash(); // used for c3 hashmap
fn bool Identifier.equals(self, Identifier other) @operator(==) => self.value == other.value; // used for c3 hashmap

struct Let (Statement)
{
    Token token;
    TypeAnnotation type;
    Identifier name;
    Expression value;
}
fn String Let.token_literal(&self) @dynamic => self.token.literal;
fn usz? Let.to_format(&self, Formatter* f) @dynamic {
    if (self.value == null) return f.printf("%s %s = null;", self.token_literal(), self.name);
    return f.printf("%s %s = %s;", self.token_literal(), self.name, self.value);
}

enum TypeAnnotation
{
    INTEGER,
    STRING,
    LET,
    // IDENTIFIER, // e.g. 'User' or 'Person' 
    // ARRAY,
    // FUNCTION,
}

struct Return (Statement)
{
    Token token;
    Expression return_value;
}
fn String Return.token_literal(&self) @dynamic => self.token.literal;
fn usz? Return.to_format(&self, Formatter* f) @dynamic {
    if (self.return_value == null) return f.printf("%s;", self.token_literal());
    return f.printf("%s %s;", self.token_literal(), self.return_value);
}

struct ExpressionStatement (Statement)
{
    Token token;
    Expression expression;
}
fn String ExpressionStatement.token_literal(&self) @dynamic => self.token.literal;
fn usz? ExpressionStatement.to_format(&self, Formatter* f) @dynamic {
    if (self.expression == null) return f.printf("");
    return f.printf("%s", self.expression);
}

struct IntegerLiteral (Expression)
{
    Token token;
    int value; 
}
fn String IntegerLiteral.token_literal(&self) @dynamic => self.token.literal;
fn usz? IntegerLiteral.to_format(&self, Formatter* f) @dynamic {
    return f.printf("%s", self.token.literal);
}

struct Prefix(Expression)
{
    Token token;
    String operator;
    Expression right;
}
fn String Prefix.token_literal(&self) @dynamic => self.token.literal;
fn usz? Prefix.to_format(&self, Formatter* f) @dynamic {
    if (self.right == null) return f.printf("(%snull)", self.operator);
    return f.printf("(%s%s)", self.operator, self.right);
}

struct Infix (Expression)
{
    Token token;
    Expression left;
    String operator;
    Expression right;
}
fn String Infix.token_literal(&self) @dynamic => self.token.literal;
fn usz? Infix.to_format(&self, Formatter* f) @dynamic {
    usz out = f.printf("(")!;
    if (self.left != null) out += f.printf("%s ", self.left)!;
    out += f.printf("%s ", self.operator)!;
    if (self.right != null) out += f.printf("%s", self.right)!;
    out += f.printf(")")!;
    return out;
}

struct Bool (Expression)
{
    Token token;
    bool value;
}
fn String Bool.token_literal(&self) @dynamic => self.token.literal;
fn usz? Bool.to_format(&self, Formatter* f) @dynamic {
    return f.printf("%s", self.token.literal);
}

struct If (Expression)
{
    Token token;
    Expression condition;
    Block* consequence;
    Block* alternative;
}
fn String If.token_literal(&self) @dynamic => self.token.literal;
fn usz? If.to_format(&self, Formatter* f) @dynamic {
    usz out = f.printf("if%s %s", self.condition, self.consequence)!;
    if (self.alternative != null) out += f.printf("else %s", self.alternative)!;
    return out;
}

struct Block (Statement)
{
    Token token;
    List{Statement} statements;
}
fn String Block.token_literal(&self) @dynamic => self.token.literal;
fn usz? Block.to_format(&self, Formatter* f) @dynamic {
    usz out;
    foreach(stmt: self.statements) out += f.printf("%s", stmt)!; 
    return out;
}

struct Fn (Expression)
{
    Token token;
    List{Identifier} parameters;
    Block* body;
}
fn String Fn.token_literal(&self) @dynamic => self.token.literal;
fn usz? Fn.to_format(&self, Formatter* f) @dynamic {
    usz out = f.printf("%s(", self.token_literal())!;
	String[] params = allocator::alloc_array(allocator::temp(), String, self.parameters.len());
    foreach(i, p: self.parameters) params[i] = string::tformat("%s", p);
    out += f.printf("%s", string::join(allocator::temp(), params, ", "))!;
    out += f.printf(")%s", self.body)!;
    return out;
}

struct Call (Expression)
{
    Token token;
    Expression function;
    List{Expression} arguments;
}
fn String Call.token_literal(&self) @dynamic => self.token.literal;
fn usz? Call.to_format(&self, Formatter* f) @dynamic {
    usz out;
	String[] args = allocator::alloc_array(allocator::temp(), String, self.arguments.len());
    foreach(i, a: self.arguments) args[i] = string::tformat("%s", a);
    out += f.printf("%s", self.function)!;
    out += f.printf("(%s)", string::join(allocator::temp(), args, ", "))!;
    return out;
}

struct StringLiteral (Expression)
{
    Token token;
    String value;
}
fn String StringLiteral.token_literal(&self) @dynamic => self.token.literal;
fn usz? StringLiteral.to_format(&self, Formatter* f) @dynamic {
    return f.printf("%s", self.token.literal);
}

struct Array (Expression)
{
    Token token;
    List{Expression} elements;
}
fn String Array.token_literal(&self) @dynamic => self.token.literal;
fn usz? Array.to_format(&self, Formatter* f) @dynamic {
	String[] elems = allocator::alloc_array(allocator::temp(), String, self.elements.len());
    foreach(i, e: self.elements) elems[i] = string::tformat("%s", e);
    return f.printf("[%s]", string::join(allocator::temp(), elems, ", "));
}

struct Index(Expression)
{
    Token token;
    Expression left;
    Expression index;
}
fn String Index.token_literal(&self) @dynamic => self.token.literal;
fn usz? Index.to_format(&self, Formatter* f) @dynamic {
	return f.printf("(%s[%s])", self.left, self.index);
}

struct HashMap (Expression)
{
    Token token;
    map::HashMap{Expression, Expression} pairs;
}
fn String HashMap.token_literal(&self) @dynamic => self.token.literal;
fn usz? HashMap.to_format(&self, Formatter* f) @dynamic {
	String[] pairs = allocator::alloc_array(allocator::temp(), String, self.pairs.len());
    int i;
    self.pairs.@each(; Expression k, Expression v) {
        pairs[i++] = string::tformat("%s:%s", k, v);
    };
	return f.printf("{%s}", string::join(allocator::temp(), pairs, ", "));
}
fn uint Expression.hash(&self) => string::tformat("%s", self).hash(); // used for c3 hashmap

struct Macro (Expression)
{
    Token token;
    List{Identifier} parameters;
    Block* body;
}
fn String Macro.token_literal(&self) @dynamic => self.token.literal;
fn usz? Macro.to_format(&self, Formatter* f) @dynamic {
	String[] params = allocator::alloc_array(allocator::temp(), String, self.parameters.len());
    foreach(i, p: self.parameters) params[i] = string::tformat("%s", p);
    return f.printf("%s(%s)%s", self.token_literal(), string::join(allocator::temp(), params, ", "), self.body);
}

struct Dot (Expression)
{
    Token token;
    Expression left;
    Identifier name;
}
fn String Dot.token_literal(&self) @dynamic => self.token.literal;
fn usz? Dot.to_format(&self, Formatter* f) @dynamic {
    return f.printf("(%s.%s)", self.left, self.name);
}

struct Struct (Statement)
{
    Token token; // struct
    Identifier name; 
    List{Statement} fields;
}
fn String Struct.token_literal(&self) @dynamic => self.token.literal;
fn usz? Struct.to_format(&self, Formatter* f) @dynamic {
	String[] fields = allocator::alloc_array(allocator::temp(), String, self.fields.len());
    foreach(i, field: self.fields) fields[i] = string::tformat("%s", field);
    return f.printf("%s{%s}", self.name, string::join(allocator::temp(), fields, ", "));
}

struct StructLiteral (Expression)
{
    Token token; // {
    Identifier struct_name;
    map::HashMap{Identifier, Expression} field_values;
}
fn String StructLiteral.token_literal(&self) @dynamic => self.token.literal;
fn usz? StructLiteral.to_format(&self, Formatter* f) @dynamic {
	String[] field_values = allocator::alloc_array(allocator::temp(), String, self.field_values.len());
    int i;
    self.field_values.@each(; Identifier k, Expression v) {
        field_values[i++] = string::tformat("%s:%s", k, v);
    };
    return f.printf("%s{%s}", self.struct_name, string::join(allocator::temp(), field_values, ", "));
}

