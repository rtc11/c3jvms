module evaluator;

import std::io;
import std::collections::list;
import std::collections::map;
import runtime, ast, environment, ascii;

const runtime::Bool TRUE = { .value = true };
const runtime::Bool FALSE = { .value = false };
const runtime::Null NULL = {};

const DEBUG = false;

faultdef UNKNOWN_NODE;

macro Error* err(String format, ...) => allocator::new(allocator::temp(), Error, { 
    .message = string::tformat(format, $vasplat), 
    .file = $$FILE,
    .line = $$LINE,
    .func = $$FUNC,
});

fn RuntimeValue eval(Node node, Environment* env, Allocator alloc)
{
    switch (node.type)
    {
        case Program: 
            return eval_program(((Program*) node), env, alloc);
        case ExpressionStatement: 
            return eval(((ExpressionStatement*) node).expression, env, alloc);
        case ast::IntegerLiteral: 
            return allocator::new(alloc, runtime::Int32, { .value = ((ast::IntegerLiteral*) node).value });
        case Let:
            Let* stmt = (Let*) node;
            RuntimeValue i;
            switch (stmt.type) {
                case INTEGER:
                    if (stmt.value == null) {
                        i = allocator::new(alloc, runtime::Int32, { .value = 0 });
                    } else {
                        i = eval(stmt.value, env, alloc);
                        if (i.is_err()) return i;
                        // if (i.type != runtime::Int32.typeid) return err("cannot assign value of %s to variable of %s", ascii::colorize(GOLD, i.name()), ascii::colorize(GOLD, "i32"));
                    }
                case LET:
                    if (stmt.value == null) {
                        i = allocator::new(alloc, runtime::Int32, { .value = 0 });
                    } else { 
                        i = eval(stmt.value, env, alloc);
                        if (i.is_err()) return i;
                    }
                case STRING:
                    if (stmt.value == null) {
                        i = allocator::new(alloc, runtime::Str, { .value = "" });
                    } else {
                        i = eval(stmt.value, env, alloc);
                        if (i.is_err()) return i;
                        // if (i.type != runtime::Str.typeid) return err("cannot assign value of %s to variable of %s", ascii::colorize(GOLD, i.name()), ascii::colorize(GOLD, "str")); 
                    }
            }
            env.set(stmt.name.value, i);
            return i;
        case Identifier:
            return eval_identifier((Identifier*) node, env);
        case ast::Bool: 
            return ((ast::Bool*) node).value ? &TRUE : &FALSE;
        case Prefix:
            Prefix* prefix_expr = (Prefix*) node;
            RuntimeValue right = eval(prefix_expr.right, env, alloc);
            if (right.is_err()) return right;
            return eval_expr_prefix(prefix_expr.operator, right, alloc);
        case Infix:
            Infix* inf = (Infix*) node;

            if (inf.operator == "=") {
                if (inf.left.type != Identifier.typeid) return err("cannot assign to non-identifier");
                Identifier* ident = (Identifier*) inf.left;
                RuntimeValue val = eval(inf.right, env, alloc);
                if (val.is_err()) return val;
                env.set(ident.value, val);
                return val;
            }

            RuntimeValue left = eval(inf.left, env, alloc);
            if (left.is_err()) return left;
            RuntimeValue right = eval(inf.right, env, alloc);
            if (right.is_err()) return right;
            return eval_infix_expr(inf.operator, left, right, alloc);
        case Block: 
            return eval_stmt_block((Block*) node, env, alloc);
        case If: 
            return eval_expr_if((If*) node, env, alloc);
        case ast::Return:
            RuntimeValue ret = eval(((ast::Return*) node).return_value, env, alloc);
            if (ret.is_err()) return ret;
            return allocator::new(alloc, runtime::Return, { .value = ret });
        case ast::Fn:
            ast::Fn* fun = (ast::Fn*) node;
            return allocator::new(alloc, runtime::Fn, { 
                .parameters = fun.parameters,
                .env = env,
                .body = fun.body, 
            });
        case ast::Call:
            Call* call = (Call*) node;
            return eval_expr_call(call, env, alloc);
        case StringLiteral:
            StringLiteral* str = (StringLiteral*) node;
            return allocator::new(alloc, Str, { .value = str.value });
        case ast::Array:
            ast::Array* array = (ast::Array*) node;
            List{RuntimeValue} elements = eval_expressions(array.elements, env, alloc);
            if (elements.len() == 1 && elements[0].is_err()) return elements[0];
            return allocator::new(alloc, runtime::Array, { .elements = elements });
        case ast::Index:
            ast::Index* index = (ast::Index*) node;
            RuntimeValue left = eval(index.left, env, alloc);
            if (left.is_err()) return left;
            RuntimeValue idx = eval(index.index, env, alloc);
            if (idx.is_err()) return idx;
            return eval_expr_index(left, idx, alloc);
        case ast::HashMap:
            return eval_hashmap((ast::HashMap*) node, env, alloc);
        case StructLiteral:
            StructLiteral* lit = (StructLiteral*) node;
            RuntimeValue? struct_definition_name = env.get(lit.struct_name.value);
            if (catch struct_definition_name) return err("undefined struct: %s", lit.struct_name.value);
            if (struct_definition_name.type != StructDef.typeid) {
                return err("identifier %s is not a struct but %s", lit.struct_name.value, struct_definition_name.name());
            }
            map::HashMap{String, RuntimeValue} fields;
            fields.tinit();
            lit.field_values.@each(; Identifier field, Expression expr) {
                RuntimeValue val = eval(expr, env, alloc);
                if (val.is_err()) return val;
                fields[field.value] = val;
            };
            return allocator::new(alloc, StructInstance, {
                .instance_name = lit.struct_name.value,
                .fields = fields,
            });
        case Struct:
            Struct* def = (Struct*) node;
            RuntimeValue i = allocator::new(alloc, StructDef, {
                .struct_name = def.name.value,
                .fields = def.fields,
            });
            env.set(def.name.value, i);
            io::printfn("Defined struct %s", def.name.value);
            return &NULL;
        case Dot:
            Dot* access = (Dot*) node;
            RuntimeValue obj = eval(access.left, env, alloc);
            if (obj.is_err()) return obj;
            if (obj.type != StructInstance.typeid) return err("cannot access field on non-struct RuntimeValue");
            StructInstance* inst = (StructInstance*) obj;
            if (try val = inst.fields.get(access.name.value)) return val; 
            return err("field '%s' not found in struct '%s'", access.name.value, inst.instance_name);
        default: 
            return err("Unknown node %s", node);
    }
}

fn RuntimeValue eval_expr_call(Call* call, Environment* env, Allocator alloc)
{
    if (call.function.token_literal() == "quote") return quote(call.arguments[0], env, alloc);
    if (call.function.type == ast::Dot.typeid) {
        Dot* dot = (Dot*) call.function;
        RuntimeValue left = eval(dot.left, env, alloc);
        if (left.is_err()) return left;
        if (try builtin = Builtins.lookup_field(literal, dot.name.value)) {
            List{RuntimeValue} args;
            args.tinit();
            args.push(left);
            foreach (arg: call.arguments) {
                RuntimeValue evaluated = eval(arg, env, alloc);
                if (evaluated.is_err()) return evaluated;
                args.push(evaluated);
            }
            return builtin.obj.fun(args, alloc);
        }
        return err("method not found: %s", dot.name.value);
    }
    RuntimeValue fun = eval(call.function, env, alloc);
    if (fun.is_err()) return fun;
    List{RuntimeValue} args = eval_expressions(call.arguments, env, alloc);
    if (args.len() == 1 && args[0].is_err()) return args[0];
    return apply_function(fun, args, alloc);
}

fn RuntimeValue eval_program(Program* prog, Environment* env, Allocator alloc)
{
    RuntimeValue res;
    foreach (stmt: prog.statements) {
        res = eval(stmt, env, alloc);
        switch (res.type)
        {
            case runtime::Return: return ((runtime::Return*) res).value;
            case Error: return res;
        }
    }
    return res;
}

fn RuntimeValue eval_identifier(Identifier* ident, Environment* env)
{
    if (try obj = env.get(ident.value)) return obj;
    if (try builtin = Builtins.lookup_field(literal, ident.value)) {
        if (builtin.literal == "printn") return @tclone(builtin.obj);
        if (builtin.literal == "print") return @tclone(builtin.obj);
        return err("unknown identifier %s, perhaps you ment the method .%s()", ascii::str(ident.value), ascii::colorize(GOLD, ident.value));
    }
    return err("unknown identifier %s", ascii::str(ident.value));
}

fn RuntimeValue eval_stmt_block(Block* block, Environment* env, Allocator alloc)
{
    RuntimeValue res;
    foreach (stmt: block.statements) {
        res = eval(stmt, env, alloc);
        if (res != null && res.type == runtime::Return.typeid || res.type == Error.typeid) {
            return res;
        }
    }
    return res;
}

fn RuntimeValue eval_expr_prefix(String operator, RuntimeValue right, Allocator alloc)
{
    switch (operator)
    {
        case "!": return eval_expr_operator_bang(right);
        case "-": return eval_expr_operator_minus(right, alloc);
        default: return err("unknown operator: %s%s", operator, right.name());
    }
}

fn RuntimeValue eval_infix_expr(String operator, RuntimeValue left, RuntimeValue right, Allocator alloc)
{
    switch 
    {
        case left.type == runtime::Int32.typeid && right.type == runtime::Int32.typeid: return eval_expr_infix_i32(operator, left, right, alloc);
        case left.type != right.type: return err("type mismatch: %s %s %s", left.name(), operator, right.name());
        case left.type == Str.typeid && right.type == Str.typeid: return eval_expr_infix_str(operator, left, right, alloc);
        case operator == "==": return left == right ? &TRUE : &FALSE;
        case operator == "!=": return left != right ? &TRUE : &FALSE;
        default: return err("unknown operator: %s %s %s", left.name(), operator, right.name());
    }
}

fn RuntimeValue eval_expr_infix_i32(String operator, RuntimeValue left, RuntimeValue right, Allocator alloc)
{
    int lval = ((runtime::Int32*) left).value;
    int rval = ((runtime::Int32*) right).value;

    if (DEBUG) io::printfn("%s %s %s", lval, operator, rval);

    switch (operator)
    {
        case "+": return allocator::new(alloc, runtime::Int32, { .value = lval + rval });
        case "-": return allocator::new(alloc, runtime::Int32, { .value = lval - rval });
        case "*": return allocator::new(alloc, runtime::Int32, { .value = lval * rval });
        case "/": return allocator::new(alloc, runtime::Int32, { .value = lval / rval });
        case "<": return lval < rval ? &TRUE : &FALSE;
        case ">": return lval > rval ? &TRUE : &FALSE;
        case "==": return lval == rval  ? &TRUE : &FALSE;
        case "!=": return lval != rval ? &TRUE : &FALSE;
        default: return err("unknown operator: %s %s %s", left.name(), operator, right.name());
    }
}

fn RuntimeValue eval_expr_infix_str(String operator, RuntimeValue left, RuntimeValue right, Allocator a)
{
    if (operator != "+") return err("unknown operator: %s %s %s", left.name(), operator, right.name());
    String lval = ((Str*) left).value;
    String rval = ((Str*) right).value;
    return allocator::new(a, Str, { .value = string::tformat("%s%s", lval, rval) });
}

fn RuntimeValue eval_expr_operator_bang(RuntimeValue right)
{
    switch (right.ptr)
    {
        case &TRUE: return &FALSE;
        case &FALSE: return &TRUE;
        case &NULL: return &TRUE;
        default: return &FALSE;
    }
}

fn RuntimeValue eval_expr_operator_minus(RuntimeValue right, Allocator alloc)
{
    if (right.type != runtime::Int32.typeid) return err("unknown operator: -%s", right.name());
    int value = ((runtime::Int32*) right).value;
    return allocator::new(alloc, runtime::Int32, { .value = -value });
}

fn RuntimeValue eval_expr_if(If* expr, Environment* env, Allocator alloc)
{
    RuntimeValue condition = eval(expr.condition, env, alloc);
    if (condition.is_err()) return condition;
    if (is_truthy(condition)) {
        return eval(expr.consequence, env, alloc);
    } else if (expr.alternative != null) {
        return eval(expr.alternative, env, alloc);
    } else {
        return &NULL;
    }
}

fn List{RuntimeValue} eval_expressions(List{Expression} exprs, Environment* env, Allocator alloc)
{
    List{RuntimeValue} objs;
    objs.tinit();
    foreach (expr: exprs) {
        RuntimeValue obj = eval(expr, env, alloc);
        if (obj.is_err()) {
            List{RuntimeValue} err_obj;
            err_obj.tinit();
            err_obj.push(obj);
            return err_obj;
        }
        objs.push(obj);
    }
    return objs;
}

fn RuntimeValue eval_expr_index(RuntimeValue left, RuntimeValue index, Allocator alloc)
{
    switch
    {
        case left.type == runtime::Array.typeid && index.type == runtime::Int32.typeid:
            return eval_expr_array_index((runtime::Array*)left, (runtime::Int32*)index, alloc);
        case left.type == runtime::HashMap.typeid:
            return eval_expr_hash_index((runtime::HashMap*)left, index, alloc);
        default:
            return err("index operator %s not supported", left.name());
    }
}

fn RuntimeValue eval_expr_array_index(runtime::Array* array, runtime::Int32* index, Allocator alloc)
{
    int idx = index.value;
    usz max = array.elements.len() - 1;
    if (idx < 0 || idx > max) return &NULL;
    return array.elements[idx];
}

fn RuntimeValue eval_expr_hash_index(runtime::HashMap* hashmap, RuntimeValue index, Allocator alloc)
{
    if (try hash = hashable(index)) {
        Hash hash_key = hash.hash();
        if (try pair = hashmap.pairs[hash_key]) return pair.value;
        return &NULL;
    }
    return err("unusable as hash key: %s", index.name()); 
}

fn RuntimeValue eval_hashmap(ast::HashMap* node, Environment* env, Allocator alloc)
{
    map::HashMap{Hash, HashPair} pairs;
    pairs.tinit();
    node.pairs.@each(; Expression k, Expression v) {
        RuntimeValue key = eval(k, env, alloc);
        if (key.is_err()) return key;
        if (try hashable = hashable(key)) {
            Hash hash = hashable.hash();
            RuntimeValue value = eval(v, env, alloc);
            if (value.is_err()) return value;
            pairs[hash] = *allocator::new(alloc, HashPair, { key, value });
        } else {
            return err("unusable as hash key: %s", key.name()); 
        }
    };
    return allocator::new(alloc, runtime::HashMap, { pairs });
}

faultdef UNUSABLE_AS_HASH_KEY;

fn Hashable? hashable(RuntimeValue key)
{
    switch (key.type)
    {
        case runtime::Bool.typeid: return ((runtime::Bool*) key);
        case runtime::Int32.typeid: return ((runtime::Int32*) key);
        case runtime::Str.typeid: return ((runtime::Str*) key);
        default: return UNUSABLE_AS_HASH_KEY?; 
    }
}

fn RuntimeValue apply_function(RuntimeValue fun, List{RuntimeValue} args, Allocator alloc)
{
    switch (fun.type)
    {
        case runtime::Fn:
            runtime::Fn* function = (runtime::Fn*) fun; 
            Environment* env_ext = extend_function_env(function, args, alloc);
            RuntimeValue evaluated = eval(function.body, env_ext, alloc);
            return unwrap_return_value(evaluated);
        case runtime::Builtin:
            runtime::Builtin* builtin = (runtime::Builtin*) fun;
        return builtin.fun(args, alloc);
        default: 
            return err("not a function: %s", fun.inspect());
    }
}

fn Environment* extend_function_env(runtime::Fn* fun, List{RuntimeValue} args, Allocator alloc)
{
    Environment* env = environment::new_enclosed(fun.env, alloc);
    foreach(i, param: fun.parameters) env.set(param.value, args[i]);
    return env;
}

fn RuntimeValue unwrap_return_value(RuntimeValue obj)
{
    if (obj.type == runtime::Return.typeid) return ((runtime::Return*) obj).value;
    return obj;
}

fn bool is_truthy(RuntimeValue obj)
{
    switch (obj.ptr) 
    {
        case &NULL: return false;
        case &TRUE: return true;
        case &FALSE: return false;
        default: return true;
    }
}
