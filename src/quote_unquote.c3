module evaluator;

import std::io;
import ast, runtime, environment;

fn RuntimeValue quote(Node node, Environment* env, Allocator alloc)
{
    node = eval_unquote_calls(node, env, alloc);
    return allocator::new(alloc, runtime::Quote, { 
        .node = node, 
    });
}

fn Node eval_unquote_calls(Node quoted, Environment* env, Allocator alloc)
{
    return ast::modify(quoted, &replace_calls, env, alloc); 
}

fn Node replace_calls(Node node, Environment* env, Allocator alloc)
{
    if (!is_unquote_call(node)) return node;
    if (node.type != Call.typeid) return node;
    Call* call = (Call*) node;
    if(call.arguments.len() != 1) return node;
    RuntimeValue unquoted = eval(call.arguments[0], env, alloc);
    return convert_object_to_ast_node(unquoted, alloc);
}

fn bool is_unquote_call(Node node)
{
    if (node.type == Call.typeid) {
        return ((Call*) node).function.token_literal() == "unquote";
    }
    return false;
}

fn Node convert_object_to_ast_node(RuntimeValue obj, Allocator alloc)
{
    switch (obj.type)
    {
        case runtime::Int32:
            runtime::Int32* i32 = (runtime::Int32*) obj;
            return allocator::new(alloc, ast::IntegerLiteral, {
                .token = { INT_LITERAL, string::tformat("%d", i32.value) },
                .value = i32.value,
            });
        case runtime::Str:
            runtime::Str* str = (runtime::Str*) obj;
            return allocator::new(alloc, ast::StringLiteral, {
                .token = { STR_LITERAL, string::tformat("%s", str.value) },
                .value = str.value,
            });
        case runtime::Bool:
            runtime::Bool* b = (runtime::Bool*) obj;
            return allocator::new(alloc, ast::Bool, {
                .token = b.value ? { TRUE, "true" } : { FALSE, "false" },
                .value = b.value,
            });
        case Quote:
            return ((Quote*) obj).node;
        default:
            return null;
    }
}
