module evaluator;

import std::io;
import std::collections::list;
import object, ast;


const object::Bool TRUE = { .value = true };
const object::Bool FALSE = { .value = false };
const object::Null NULL = {};

faultdef UNKNOWN_NODE;

macro Error* err(String format, ...) => allocator::new(allocator::temp(), Error, { .message = string::tformat(format, $vasplat) });

fn Object? eval(Node node, Allocator allocator)
{
    switch (node.type)
    {
        case Program: 
            return eval_program(((Program*) node), allocator);
        case ExpressionStatement: 
            return eval(((ExpressionStatement*) node).expression, allocator);
        case IntLiteral: 
            return allocator::new(allocator, Int32, { 
                .value = ((IntLiteral*) node).value 
            });
        case ast::Bool: 
            return ((ast::Bool*) node).value ? &TRUE : &FALSE;
        case PrefixExpression:
            PrefixExpression* prefix_expr = (PrefixExpression*) node;
            Object right = eval(prefix_expr.right, allocator)!!;
            if (right.is_err()) return right;
            return eval_expr_prefix(prefix_expr.operator, right, allocator);
        case InfixExpression:
            InfixExpression* infix_expr = (InfixExpression*) node;
            Object left = eval(infix_expr.left, allocator)!!;
            if (left.is_err()) return left;
            Object right = eval(infix_expr.right, allocator)!!;
            if (right.is_err()) return right;
            return eval_infix_expr(infix_expr.operator, left, right, allocator);
        case BlockStatement: 
            return eval_stmt_block((BlockStatement*) node, allocator);
        case If: 
            return eval_expr_if((If*) node, allocator);
        case ReturnStatement:
            Object ret = eval(((ReturnStatement*) node).return_value, allocator)!!;
            if (ret.is_err()) return ret;
            return allocator::new(allocator, Return, { .value = ret });
        default: 
            io::printfn("ERROR: Unknown node %s", node);
            return UNKNOWN_NODE?;
    }
}

fn Object eval_program(Program* prog, Allocator allocator)
{
    Object res;
    foreach (stmt: prog.statements) {
        res = eval(stmt, allocator)!!;
        switch (res.type)
        {
            case Return: return ((Return*) res).value;
            case Error: return res;
        }
    }
    return res;
}

fn Object eval_stmt_block(BlockStatement* block, Allocator allocator)
{
    Object res;
    foreach (stmt: block.statements) {
        res = eval(stmt, allocator)!!;
        if (res != null && res.obj_type() == RETURN_VALUE || res.obj_type() == ERROR) {
            return res;
        }
    }
    return res;
}

fn Object? eval_expr_prefix(String operator, Object right, Allocator allocator)
{
    switch (operator)
    {
        case "!": return eval_expr_operator_bang(right);
        case "-": return eval_expr_operator_minus(right, allocator);
        default: return err("unknown operator: %s%s", operator, right.obj_type());
    }
}

fn Object? eval_infix_expr(String operator, Object left, Object right, Allocator allocator)
{
    switch 
    {
        case left.obj_type() == I32 && right.obj_type() == I32: return eval_expr_infix_i32(operator, left, right, allocator);
        case left.obj_type() != right.obj_type(): return err("type mismatch: %s %s %s", left.obj_type(), operator, right.obj_type());
        case operator == "==": return left == right ? &TRUE : &FALSE;
        case operator == "!=": return left != right ? &TRUE : &FALSE;
        default: return err("unknown operator: %s %s %s", left.obj_type(), operator, right.obj_type());
    }
}

fn Object eval_expr_infix_i32(String operator, Object left, Object right, Allocator a)
{
    int lval = ((Int32*) left).value;
    int rval = ((Int32*) right).value;
    switch (operator)
    {
        case "+": return allocator::new(a, Int32, { .value = lval + rval });
        case "-": return allocator::new(a, Int32, { .value = lval - rval });
        case "*": return allocator::new(a, Int32, { .value = lval * rval });
        case "/": return allocator::new(a, Int32, { .value = lval / rval });
        case "<": return lval < rval ? &TRUE : &FALSE;
        case ">": return lval > rval ? &TRUE : &FALSE;
        case "==": return lval == rval  ? &TRUE : &FALSE;
        case "!=": return lval != rval ? &TRUE : &FALSE;
        default: return err("unknown operator: %s %s %s", left.obj_type(), operator, right.obj_type());
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
    if (right.obj_type() != I32) return err("unknown operator: -%s", right.obj_type());
    int value = ((Int32*) right).value;
    return allocator::new(allocator, Int32, { .value = -value });
}

fn Object? eval_expr_if(If* expr, Allocator allocator)
{
    Object condition = eval(expr.condition, allocator)!!;
    if (condition.is_err()) return condition;
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
