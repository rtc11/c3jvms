module evaluator;

import std::io;
import std::collections::list;
import object, ast;

faultdef INVALID;

const BoolObj TRUE = { .value = true };
const BoolObj FALSE = { .value = false };
const NullObj NULL = {};

fn Object? eval(Node node, Allocator allocator)
{
    switch (node.type)
    {
        case Program: 
        	return eval_stmts(((Program*) node).statements, allocator);
        case ExpressionStatement: 
            return eval(((ExpressionStatement*) node).expression, allocator);
        case IntLiteral: 
            return allocator::new(allocator, I32Obj, { .value = ((IntLiteral*) node).value });
        case Bool:
            return ((Bool*) node).value ? &TRUE : &FALSE;
        default: 
            return INVALID?;
    }
}

fn Object eval_stmts(List{Statement} stmts, Allocator allocator)
{
    Object res;
    foreach (stmt: stmts) res = eval(stmt, allocator)!!;
    return res;
}

