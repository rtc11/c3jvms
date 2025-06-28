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
        case PrefixExpression:
            PrefixExpression* prefix_expr = (PrefixExpression*) node;
            Object right = eval(prefix_expr.right, allocator)!!;
            return eval_prefix_expr(prefix_expr.operator, right, allocator)!!;
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

fn Object? eval_prefix_expr(String operator, Object right, Allocator allocator)
{
    switch (operator)
    {
        case "!": return eval_operator_bang_expr(right);
        case "-": return eval_operator_minus_expr(right, allocator);
        default: return INVALID?;
    }
}

fn Object eval_operator_bang_expr(Object right)
{
    switch (right.ptr)
    {
        case &TRUE: return &FALSE;
        case &FALSE: return &TRUE;
        case &NULL: return &TRUE;
        default: return &FALSE;
    }
}

fn Object? eval_operator_minus_expr(Object right, Allocator allocator)
{
    if (right.obj_type() != I32) return INVALID?;
    int value = ((I32Obj*) right).value;
    return allocator::new(allocator, I32Obj, { .value = -value });
}
