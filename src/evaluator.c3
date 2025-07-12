module evaluator;

import std::io;
import std::collections::list;
import std::collections::map;
import object, ast, environment, ascii;

const object::Bool TRUE = { .value = true };
const object::Bool FALSE = { .value = false };
const object::Null NULL = {};

const DEBUG = false;

faultdef UNKNOWN_NODE;

macro Error* err(String format, ...) => allocator::new(allocator::temp(), Error, { 
    .message = string::tformat(format, $vasplat), 
    .file = $$FILE,
    .line = $$LINE,
    .func = $$FUNC,
});

fn Object eval(Node node, Environment* env, Allocator alloc)
{
    switch (node.type)
    {
        case Program: 
            return eval_program(((Program*) node), env, alloc);
        case ExpressionStatement: 
            return eval(((ExpressionStatement*) node).expression, env, alloc);
        case ast::Int32: 
            return allocator::new(alloc, object::Int32, { .value = ((ast::Int32*) node).value });
        case LetStatement:
            LetStatement* stmt = (LetStatement*) node;
            Object i;
            if (stmt.value == null) {
                i = allocator::new(alloc, object::Int32, { .value = 0 });
            } else {
                i = eval(stmt.value, env, alloc);
                if (i.is_err()) return i;
            }
            env.set(stmt.name.value, i);
            return i;
        case I32Stmt:
            I32Stmt* stmt = (I32Stmt*) node;
            Object i = eval(stmt.value, env, alloc);
            if (i.is_err()) return i;
            if (i.type != object::Int32.typeid) return err("cannot assign value of %s to variable of %s", ascii::colorize(GOLD, i.name()), ascii::colorize(GOLD, "i32"));
            env.set(stmt.name.value, i);
            return i;
        case StrStmt:
            StrStmt* stmt = (StrStmt*) node;
            Object i = eval(stmt.value, env, alloc);
            if (i.is_err()) return i;
            if (i.type != object::Str.typeid) return err("cannot assign value of %s to variable of %s", ascii::colorize(GOLD, i.name()), ascii::colorize(GOLD, "str"));
            env.set(stmt.name.value, i);
            return i;
        case Identifier:
            return eval_identifier((Identifier*) node, env);
        case ast::Bool: 
            return ((ast::Bool*) node).value ? &TRUE : &FALSE;
        case PrefixExpression:
            PrefixExpression* prefix_expr = (PrefixExpression*) node;
            Object right = eval(prefix_expr.right, env, alloc);
            if (right.is_err()) return right;
            return eval_expr_prefix(prefix_expr.operator, right, alloc);
        case InfixExpression:
            InfixExpression* infix_expr = (InfixExpression*) node;
            Object left = eval(infix_expr.left, env, alloc);
            if (left.is_err()) return left;
            Object right = eval(infix_expr.right, env, alloc);
            if (right.is_err()) return right;
            return eval_infix_expr(infix_expr.operator, left, right, alloc);
        case BlockStatement: 
            return eval_stmt_block((BlockStatement*) node, env, alloc);
        case If: 
            return eval_expr_if((If*) node, env, alloc);
        case ReturnStatement:
            Object ret = eval(((ReturnStatement*) node).return_value, env, alloc);
            if (ret.is_err()) return ret;
            return allocator::new(alloc, Return, { .value = ret });
        case ast::Fn:
            ast::Fn* fun = (ast::Fn*) node;
            return allocator::new(alloc, object::Fn, { 
                .parameters = fun.parameters,
                .env = env,
                .body = fun.body, 
            });
        case ast::Call:
            Call* call = (Call*) node;
            return eval_expr_call(call, env, alloc);
        case StrLiteral:
            StrLiteral* str = (StrLiteral*) node;
            return allocator::new(alloc, Str, { .value = str.value });
        case ast::Array:
            ast::Array* array = (ast::Array*) node;
            List{Object} elements = eval_expressions(array.elements, env, alloc);
            if (elements.len() == 1 && elements[0].is_err()) return elements[0];
            return allocator::new(alloc, object::Array, { .elements = elements });
        case ast::Index:
            ast::Index* index = (ast::Index*) node;
            Object left = eval(index.left, env, alloc);
            if (left.is_err()) return left;
            Object idx = eval(index.index, env, alloc);
            if (idx.is_err()) return idx;
            return eval_expr_index(left, idx, alloc);
        case ast::HashMap:
            return eval_hashmap((ast::HashMap*) node, env, alloc);
        // case ast::Dot: atm only function calls is dotted, see ast::Call
        default: 
            return err("Unknown node %s", node);
    }
}

fn Object eval_expr_call(Call* call, Environment* env, Allocator alloc)
{
    if (call.function.token_literal() == "quote") return quote(call.arguments[0], env, alloc);
    if (call.function.type == ast::Dot.typeid) {
        Dot* dot = (Dot*) call.function;
        Object left = eval(dot.left, env, alloc);
        if (left.is_err()) return left;
        if (try builtin = Builtins.lookup_field(literal, dot.name.value)) {
            List{Object} args;
            args.tinit();
            args.push(left);
            foreach (arg: call.arguments) {
                Object evaluated = eval(arg, env, alloc);
                if (evaluated.is_err()) return evaluated;
                args.push(evaluated);
            }
            return builtin.obj.fun(args, alloc);
        }
        return err("method not found: %s", dot.name.value);
    }
    Object fun = eval(call.function, env, alloc);
    if (fun.is_err()) return fun;
    List{Object} args = eval_expressions(call.arguments, env, alloc);
    if (args.len() == 1 && args[0].is_err()) return args[0];
    return apply_function(fun, args, alloc);
}

fn Object eval_program(Program* prog, Environment* env, Allocator alloc)
{
    Object res;
    foreach (stmt: prog.statements) {
        res = eval(stmt, env, alloc);
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
    if (try builtin = Builtins.lookup_field(literal, ident.value)) {
        return err("unknown identifier %s, perhaps you ment the method .%s()", ascii::str(ident.value), ascii::colorize(GOLD, ident.value));
    }
    return err("unknown identifier %s", ascii::str(ident.value));
}

fn Object eval_stmt_block(BlockStatement* block, Environment* env, Allocator alloc)
{
    Object res;
    foreach (stmt: block.statements) {
        res = eval(stmt, env, alloc);
        if (res != null && res.type == Return.typeid || res.type == Error.typeid) {
            return res;
        }
    }
    return res;
}

fn Object eval_expr_prefix(String operator, Object right, Allocator alloc)
{
    switch (operator)
    {
        case "!": return eval_expr_operator_bang(right);
        case "-": return eval_expr_operator_minus(right, alloc);
        default: return err("unknown operator: %s%s", operator, right.name());
    }
}

fn Object eval_infix_expr(String operator, Object left, Object right, Allocator alloc)
{
    switch 
    {
        case left.type == object::Int32.typeid && right.type == object::Int32.typeid: return eval_expr_infix_i32(operator, left, right, alloc);
        case left.type != right.type: return err("type mismatch: %s %s %s", left.name(), operator, right.name());
        case left.type == Str.typeid && right.type == Str.typeid: return eval_expr_infix_str(operator, left, right, alloc);
        case operator == "==": return left == right ? &TRUE : &FALSE;
        case operator == "!=": return left != right ? &TRUE : &FALSE;
        default: return err("unknown operator: %s %s %s", left.name(), operator, right.name());
    }
}

fn Object eval_expr_infix_i32(String operator, Object left, Object right, Allocator alloc)
{
    int lval = ((object::Int32*) left).value;
    int rval = ((object::Int32*) right).value;

    if (DEBUG) io::printfn("%s %s %s", lval, operator, rval);

    switch (operator)
    {
        case "+": return allocator::new(alloc, object::Int32, { .value = lval + rval });
        case "-": return allocator::new(alloc, object::Int32, { .value = lval - rval });
        case "*": return allocator::new(alloc, object::Int32, { .value = lval * rval });
        case "/": return allocator::new(alloc, object::Int32, { .value = lval / rval });
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

fn Object eval_expr_operator_minus(Object right, Allocator alloc)
{
    if (right.type != object::Int32.typeid) return err("unknown operator: -%s", right.name());
    int value = ((object::Int32*) right).value;
    return allocator::new(alloc, object::Int32, { .value = -value });
}

fn Object eval_expr_if(If* expr, Environment* env, Allocator alloc)
{
    Object condition = eval(expr.condition, env, alloc);
    if (condition.is_err()) return condition;
    if (is_truthy(condition)) {
        return eval(expr.consequence, env, alloc);
    } else if (expr.alternative != null) {
        return eval(expr.alternative, env, alloc);
    } else {
        return &NULL;
    }
}

fn List{Object} eval_expressions(List{Expression} exprs, Environment* env, Allocator alloc)
{
    List{Object} objs;
    objs.tinit();
    foreach (expr: exprs) {
        Object obj = eval(expr, env, alloc);
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

fn Object eval_expr_index(Object left, Object index, Allocator alloc)
{
    switch
    {
        case left.type == object::Array.typeid && index.type == object::Int32.typeid:
            return eval_expr_array_index((object::Array*)left, (object::Int32*)index, alloc);
        case left.type == object::HashMap.typeid:
            return eval_expr_hash_index((object::HashMap*)left, index, alloc);
        default:
            return err("index operator %s not supported", left.name());
    }
}

fn Object eval_expr_array_index(object::Array* array, object::Int32* index, Allocator alloc)
{
    int idx = index.value;
    usz max = array.elements.len() - 1;
    if (idx < 0 || idx > max) return &NULL;
    return array.elements[idx];
}

fn Object eval_expr_hash_index(object::HashMap* hashmap, Object index, Allocator alloc)
{
    if (try hash = hashable(index)) {
        Hash hash_key = hash.hash();
        if (try pair = hashmap.pairs[hash_key]) return pair.value;
        return &NULL;
    }
    return err("unusable as hash key: %s", index.name()); 
}

fn Object eval_hashmap(ast::HashMap* node, Environment* env, Allocator alloc)
{
    map::HashMap{Hash, HashPair} pairs;
    pairs.tinit();
    node.pairs.@each(; Expression k, Expression v) {
        Object key = eval(k, env, alloc);
        if (key.is_err()) return key;
        if (try hashable = hashable(key)) {
            Hash hash = hashable.hash();
            Object value = eval(v, env, alloc);
            if (value.is_err()) return value;
            pairs[hash] = *allocator::new(alloc, HashPair, { key, value });
        } else {
            return err("unusable as hash key: %s", key.name()); 
        }
    };
    return allocator::new(alloc, object::HashMap, { pairs });
}

faultdef UNUSABLE_AS_HASH_KEY;

fn Hashable? hashable(Object key)
{
    switch (key.type)
    {
        case object::Bool.typeid: return ((object::Bool*) key);
        case object::Int32.typeid: return ((object::Int32*) key);
        case object::Str.typeid: return ((object::Str*) key);
        default: return UNUSABLE_AS_HASH_KEY?; 
    }
}

fn Object apply_function(Object fun, List{Object} args, Allocator alloc)
{
    switch (fun.type)
    {
        case object::Fn:
            object::Fn* function = (object::Fn*) fun; 
            Environment* env_ext = extend_function_env(function, args, alloc);
            Object evaluated = eval(function.body, env_ext, alloc);
            return unwrap_return_value(evaluated);
        // case object::Builtin:
        //     object::Builtin* builtin = (object::Builtin*) fun;
        //     return builtin.fun(args, alloc);
        default: 
            return err("not a function: %s", fun.inspect());
    }
}

fn Environment* extend_function_env(object::Fn* fun, List{Object} args, Allocator alloc)
{
    Environment* env = environment::new_enclosed(fun.env, alloc);
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
