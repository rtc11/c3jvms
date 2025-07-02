module ast;

import lexer;
import std::io;
import std::collections::list;

interface Node
{
    fn String token_literal();
    fn usz? to_format(Formatter* f);
}

interface Statement: Node
{
    fn void statement_node();
}

interface Expression: Node
{
    fn void expression_node();
}

struct Program (Node)
{
    List{Statement} statements;
}

fn String Program.token_literal(&self) @dynamic {
    if (self.statements.size > 0) {
        return self.statements[0].token_literal();
    }
    return "";
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
fn void Identifier.expression_node(&self) @dynamic {}
fn String Identifier.token_literal(&self) @dynamic => self.token.literal;
fn usz? Identifier.to_format(&self, Formatter* f) @dynamic {
    return f.printf("%s", self.value);
}

struct I32Stmt (Statement)
{
    Token token;
    Identifier name;
    Expression value;
}
fn void I32Stmt.statement_node(&self) @dynamic {}
fn String I32Stmt.token_literal(&self) @dynamic => self.token.literal;
fn usz? I32Stmt.to_format(&self, Formatter* f) @dynamic {
    if (self.value == null) return f.printf("%s %s = null;", self.token_literal(), self.name);
    return f.printf("%s %s = %s;", self.token_literal(), self.name, self.value);
}

struct ReturnStatement (Statement)
{
    Token token;
    Expression return_value;
}
fn void ReturnStatement.statement_node(&self) @dynamic {}
fn String ReturnStatement.token_literal(&self) @dynamic => self.token.literal;
fn usz? ReturnStatement.to_format(&self, Formatter* f) @dynamic {
    if (self.return_value == null) return f.printf("%s;", self.token_literal());
    return f.printf("%s %s;", self.token_literal(), self.return_value);
}

struct ExpressionStatement (Statement)
{
    Token token;
    Expression expression;
}
fn void ExpressionStatement.statement_node(&self) @dynamic {}
fn String ExpressionStatement.token_literal(&self) @dynamic => self.token.literal;
fn usz? ExpressionStatement.to_format(&self, Formatter* f) @dynamic {
    if (self.expression == null) return f.printf("");
    return f.printf("%s", self.expression);
}

struct IntLiteral (Expression)
{
    Token token;
    int value; 
}
fn void IntLiteral.expression_node(&self) @dynamic {}
fn String IntLiteral.token_literal(&self) @dynamic => self.token.literal;
fn usz? IntLiteral.to_format(&self, Formatter* f) @dynamic {
    return f.printf("%s", self.token.literal);
}

struct PrefixExpression (Expression)
{
    Token token;
    String operator;
    Expression right;
}
fn void PrefixExpression.expression_node(&self) @dynamic {}
fn String PrefixExpression.token_literal(&self) @dynamic => self.token.literal;
fn usz? PrefixExpression.to_format(&self, Formatter* f) @dynamic {
    if (self.right == null) return f.printf("(%snull)", self.operator);
    return f.printf("(%s%s)", self.operator, self.right);
}

struct InfixExpression (Expression)
{
    Token token;
    Expression left;
    String operator;
    Expression right;
}
fn void InfixExpression.expression_node(&self) @dynamic {}
fn String InfixExpression.token_literal(&self) @dynamic => self.token.literal;
fn usz? InfixExpression.to_format(&self, Formatter* f) @dynamic {
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
fn void Bool.expression_node(&self) @dynamic {}
fn String Bool.token_literal(&self) @dynamic => self.token.literal;
fn usz? Bool.to_format(&self, Formatter* f) @dynamic {
    return f.printf("%s", self.token.literal);
}

struct If (Expression)
{
    Token token;
    Expression condition;
    BlockStatement* consequence;
    BlockStatement* alternative;
}
fn void If.expression_node(&self) @dynamic {}
fn String If.token_literal(&self) @dynamic => self.token.literal;
fn usz? If.to_format(&self, Formatter* f) @dynamic {
    usz out = f.printf("if%s %s", self.condition, self.consequence)!;
    if (self.alternative != null) out += f.printf("else %s", self.alternative)!;
    return out;
}

struct BlockStatement (Statement)
{
    Token token;
    List{Statement} statements;
}
fn void BlockStatement.statement_node(&self) @dynamic {}
fn String BlockStatement.token_literal(&self) @dynamic => self.token.literal;
fn usz? BlockStatement.to_format(&self, Formatter* f) @dynamic {
    usz out;
    foreach(stmt: self.statements) out += f.printf("%s", stmt)!; 
    return out;
}

struct Fn (Expression)
{
    Token token;
    List{Identifier} parameters;
    BlockStatement* body;
}
fn void Fn.expression_node(&self) @dynamic {}
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
fn void Call.expression_node(&self) @dynamic {}
fn String Call.token_literal(&self) @dynamic => self.token.literal;
fn usz? Call.to_format(&self, Formatter* f) @dynamic {
    usz out;
	String[] args = allocator::alloc_array(allocator::temp(), String, self.arguments.len());
    foreach(i, a: self.arguments) args[i] = string::tformat("%s", a);
    out += f.printf("%s", self.function)!;
    out += f.printf("(%s)", string::join(allocator::temp(), args, ", "))!;
    return out;
}

struct StrLiteral (Expression)
{
    Token token;
    String value;
}
fn void StrLiteral.expression_node(&self) @dynamic {}
fn String StrLiteral.token_literal(&self) @dynamic => self.token.literal;
fn usz? StrLiteral.to_format(&self, Formatter* f) @dynamic {
    return f.printf("%s", self.token.literal);
}

struct Array (Expression)
{
    Token token;
    List{Expression} elements;
}
fn void Array.expression_node(&self) @dynamic {}
fn String Array.token_literal(&self) @dynamic => self.token.literal;
fn usz? Array.to_format(&self, Formatter* f) @dynamic {
	String[] elems = allocator::alloc_array(allocator::temp(), String, self.elements.len());
    foreach(i, e: self.elements) elems[i] = string::tformat("%s", e);
    return f.printf("[%s]", string::join(allocator::temp(), elems, ", "));
}
