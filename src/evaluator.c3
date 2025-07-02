module evaluator;

import std::io;
import std::collections::list;
import std::collections::map;
import object, ast, environment;

const object::Bool TRUE = { .value = true };
const object::Bool FALSE = { .value = false };
const object::Null NULL = {};

faultdef UNKNOWN_NODE;

macro Error* err(String format, ...) => allocator::new(allocator::temp(), Error, { .message = string::tformat(format, $vasplat) });

fn Object? eval(Node node, Environment* env, Allocator allocator)
{
    switch (node.type)
    {
        case Program: 
            return eval_program(((Program*) node), env, allocator);
        case ExpressionStatement: 
            return eval(((ExpressionStatement*) node).expression, env, allocator);
        case IntLiteral: 
            return allocator::new(allocator, Int32, { .value = ((IntLiteral*) node).value });
        case I32Stmt:
            I32Stmt* stmt = (I32Stmt*) node;
            Object i = eval(stmt.value, env, allocator)!!;
            if (i.is_err()) return i;
            env.set(stmt.name.value, i);
            return i;
        case Identifier:
            return eval_identifier((Identifier*) node, env);
        case ast::Bool: 
            return ((ast::Bool*) node).value ? &TRUE : &FALSE;
        case PrefixExpression:
            PrefixExpression* prefix_expr = (PrefixExpression*) node;
            Object right = eval(prefix_expr.right, env, allocator)!!;
            if (right.is_err()) return right;
            return eval_expr_prefix(prefix_expr.operator, right, allocator);
        case InfixExpression:
            InfixExpression* infix_expr = (InfixExpression*) node;
            Object left = eval(infix_expr.left, env, allocator)!!;
            if (left.is_err()) return left;
            Object right = eval(infix_expr.right, env, allocator)!!;
            if (right.is_err()) return right;
            return eval_infix_expr(infix_expr.operator, left, right, allocator);
        case BlockStatement: 
            return eval_stmt_block((BlockStatement*) node, env, allocator);
        case If: 
            return eval_expr_if((If*) node, env, allocator);
        case ReturnStatement:
            Object ret = eval(((ReturnStatement*) node).return_value, env, allocator)!!;
            if (ret.is_err()) return ret;
            return allocator::new(allocator, Return, { .value = ret });
        case ast::Fn:
            ast::Fn* fun = (ast::Fn*) node;
            return allocator::new(allocator, object::Fn, { 
                .parameters = fun.parameters,
                .env = env,
                .body = fun.body, 
            });
        case ast::Call:
            Object fun = eval(((Call*)node).function, env, allocator)!!;
            if (fun.is_err()) return fun;
            List{Object} args = eval_expressions(((Call*)node).arguments, env, allocator);
            io::printfn("call with args.len: %d", args.len());
            if (args.len() == 1 && args[0].is_err()) return args[0];
            return apply_function(fun, args, allocator);
        case StrLiteral:
            StrLiteral* str = (StrLiteral*) node;
            return allocator::new(allocator, Str, { .value = str.value });
        default: 
            io::printfn("ERROR: Unknown node %s", node);
            return UNKNOWN_NODE?;
    }
}

fn Object eval_program(Program* prog, Environment* env, Allocator allocator)
{
    Object res;
    foreach (stmt: prog.statements) {
        res = eval(stmt, env, allocator)!!;
        switch (res.type)
        {
            case Return: return ((Return*) res).value;
            case Error: return res;
        }
    }
    return res;
}

fn Object eval_identifier(Identifier* ident, Environment* env)
{
    if (try obj = env.get(ident.value)) return obj;
    if (try builtin = Builtins.lookup_field(literal, ident.value)) return @tclone(builtin.obj);
    return err("identifier not found: %s", ident.value);
}

fn Object eval_stmt_block(BlockStatement* block, Environment* env, Allocator allocator)
{
    Object res;
    foreach (stmt: block.statements) {
        res = eval(stmt, env, allocator)!!;
        if (res != null && res.type == Return.typeid || res.type == Error.typeid) {
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
        default: return err("unknown operator: %s%s", operator, right.name());
    }
}

fn Object? eval_infix_expr(String operator, Object left, Object right, Allocator allocator)
{
    switch 
    {
        case left.type == Int32.typeid && right.type == Int32.typeid: return eval_expr_infix_i32(operator, left, right, allocator);
        case left.type != right.type: return err("type mismatch: %s %s %s", left.name(), operator, right.name());
        case left.type == Str.typeid && right.type == Str.typeid: return eval_expr_infix_str(operator, left, right, allocator);
        case operator == "==": return left == right ? &TRUE : &FALSE;
        case operator == "!=": return left != right ? &TRUE : &FALSE;
        default: return err("unknown operator: %s %s %s", left.name(), operator, right.name());
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
        default: return err("unknown operator: %s %s %s", left.name(), operator, right.name());
    }
}

fn Object eval_expr_infix_str(String operator, Object left, Object right, Allocator a)
{
    if (operator != "+") return err("unknown operator: %s %s %s", left.name(), operator, right.name());
    String lval = ((Str*) left).value;
    String rval = ((Str*) right).value;
    return allocator::new(a, Str, { .value = string::tformat("%s%s", lval, rval) });
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
    if (right.type != Int32.typeid) return err("unknown operator: -%s", right.name());
    int value = ((Int32*) right).value;
    return allocator::new(allocator, Int32, { .value = -value });
}

fn Object? eval_expr_if(If* expr, Environment* env, Allocator allocator)
{
    Object condition = eval(expr.condition, env, allocator)!!;
    if (condition.is_err()) return condition;
    if (is_truthy(condition)) {
        return eval(expr.consequence, env, allocator);
    } else if (expr.alternative != null) {
        return eval(expr.alternative, env, allocator);
    } else {
        return &NULL;
    }
}

fn List{Object} eval_expressions(List{Expression} exprs, Environment* env, Allocator allocator)
{
    List{Object} objs;
    objs.tinit();
    foreach (expr: exprs) {
        Object obj = eval(expr, env, allocator)!!;
        if (obj.is_err()) {
            List{Object} err_obj;
            err_obj.tinit();
            err_obj.push(obj);
            return err_obj;
        }
        objs.push(obj);
    }
    return objs;
}

fn Object apply_function(Object fun, List{Object} args, Allocator allocator)
{
    switch (fun.type)
    {
        case object::Fn:
            object::Fn* function = (object::Fn*) fun; 
            Environment* env_ext = extend_function_env(function, args, allocator);
            Object evaluated = eval(function.body, env_ext, allocator)!!;
            return unwrap_return_value(evaluated);
        case object::Builtin:
            object::Builtin* builtin = (object::Builtin*) fun;
            io::printfn("apply fun args: %d", args.len());
            return builtin.fun(args);
        default: 
            return err("not a function: %s", fun.name());
    }
}

fn Environment* extend_function_env(object::Fn* fun, List{Object} args, Allocator allocator)
{
    Environment* env = environment::new_enclosed(fun.env, allocator);
    foreach(i, param: fun.parameters) env.set(param.value, args[i]);
    return env;
}

fn Object unwrap_return_value(Object obj)
{
    if (obj.type == Return.typeid) return ((Return*) obj).value;
    return obj;
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
