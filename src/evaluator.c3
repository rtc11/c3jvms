module evaluator;

import std::io;
import std::collections::list;
import object, ast;

faultdef INVALID;

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

