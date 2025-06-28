module evaluator;

import std::io;
import std::collections::list;
import object, ast;


const BoolObj TRUE = { .value = true };
const BoolObj FALSE = { .value = false };
const NullObj NULL = {};

faultdef UNKNOWN_NODE;

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
            return eval_expr_prefix(prefix_expr.operator, right, allocator);
        case InfixExpression:
            InfixExpression* infix_expr = (InfixExpression*) node;
            Object left = eval(infix_expr.left, allocator)!!;
            Object right = eval(infix_expr.right, allocator)!!;
            return eval_infix_expr(infix_expr.operator, left, right, allocator);
        case BlockStatement:
            BlockStatement* block = (BlockStatement*) node;
            return eval_stmts(block.statements, allocator);
        case If:
            If* if_expr = (If*) node;
            return eval_expr_if(if_expr, allocator);
        default: 
            io::printfn("ERROR: Unknown node %s", node);
            return UNKNOWN_NODE?;
    }
}

fn Object eval_stmts(List{Statement} stmts, Allocator allocator)
{
    Object res;
    foreach (stmt: stmts) res = eval(stmt, allocator)!!;
    return res;
}

fn Object? eval_expr_prefix(String operator, Object right, Allocator allocator)
{
    switch (operator)
    {
        case "!": return eval_expr_operator_bang(right);
        case "-": return eval_expr_operator_minus(right, allocator);
        default: return &NULL;
    }
}

fn Object? eval_infix_expr(String operator, Object left, Object right, Allocator allocator)
{
    switch 
    {
        case left.obj_type() == I32 && right.obj_type() == I32:
            return eval_expr_infix_i32(operator, left, right, allocator);
        case operator == "==":
            return left == right ? &TRUE : &FALSE;
        case operator == "!=":
            return left != right ? &TRUE : &FALSE;
        default: return &NULL;
    }
}

fn Object eval_expr_infix_i32(String operator, Object left, Object right, Allocator a)
{
    int lval = ((I32Obj*) left).value;
    int rval = ((I32Obj*) right).value;
    switch (operator)
    {
        case "+": return allocator::new(a, I32Obj, { .value = lval + rval });
        case "-": return allocator::new(a, I32Obj, { .value = lval - rval });
        case "*": return allocator::new(a, I32Obj, { .value = lval * rval });
        case "/": return allocator::new(a, I32Obj, { .value = lval / rval });
        case "<": return lval < rval ? &TRUE : &FALSE;
        case ">": return lval > rval ? &TRUE : &FALSE;
        case "==": return lval == rval  ? &TRUE : &FALSE;
        case "!=": return lval != rval ? &TRUE : &FALSE;
        default: return &NULL;
    }
}

fn Object eval_expr_operator_bang(Object right)
{
    switch (right.ptr)
    {
        case &TRUE: return &FALSE;
        case &FALSE: return &TRUE;
        case &NULL: return &TRUE;
        default: return &FALSE;
    }
}

fn Object eval_expr_operator_minus(Object right, Allocator allocator)
{
    if (right.obj_type() != I32) return &NULL;
    int value = ((I32Obj*) right).value;
    return allocator::new(allocator, I32Obj, { .value = -value });
}

fn Object? eval_expr_if(If* expr, Allocator allocator)
{
    Object condition = eval(expr.condition, allocator)!!;
    if (is_truthy(condition)) {
        return eval(expr.consequence, allocator);
    } else if (expr.alternative != null) {
        return eval(expr.alternative, allocator);
    } else {
        return &NULL;
    }
}

fn bool is_truthy(Object obj)
{
    switch (obj.ptr) 
    {
        case &NULL: return false;
        case &TRUE: return true;
        case &FALSE: return false;
        default: return true;
    }
}
