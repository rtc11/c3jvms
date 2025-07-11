module evaluator;

import std::collections::list;
import std::io;
import ast, object, environment;

fn void define_macro(Program* prog, Environment* env, Allocator alloc)
{
    List{usz} definitions;
    definitions.tinit();
    foreach(i, stmt: prog.statements) {
        if(is_macro(stmt)) {
            add_macro(stmt, env, alloc);
            definitions.push(i);
        }
    }
    for (int i = (int) definitions.len() - 1; i >= 0; i--) {
        prog.statements.remove_at(definitions[i]);
    }
}

fn Node expand_macro(Program* program, Environment* env, Allocator alloc)
{
    return ast::modify(program, &expand, env, alloc);
}

fn Node expand(Node node, Environment* env, Allocator alloc) @private
{
    if(node.type != Call.typeid) return node;
    Call* call = (Call*) node;
    if (call.function.type != Identifier.typeid) return node;
    Identifier* ident = (Identifier*) call.function;
    Object? obj = env.get(ident.value);
    if (catch obj) return node;
    object::Macro* mac = (object::Macro*) obj;
    List{Quote} args = quote_args(call, alloc);
    Environment* eval_env = extend_macro_env(mac, args, alloc);
    Object evaluated = evaluator::eval(mac.body, eval_env, alloc); 
    if (evaluated.type != Quote.typeid) unreachable("we only support AST-node from macros");
    Quote* quote = (Quote*) evaluated;
    return quote.node;
}

fn List{Quote} quote_args(Call* expr, Allocator alloc)
{
    List{Quote} args;
    args.tinit();
    foreach(a: expr.arguments) {
        args.push(*allocator::new(alloc, Quote, { .node = a }));
    }
    return args;
}

fn Environment* extend_macro_env(object::Macro* mac, List{Quote} args, Allocator alloc)
{
    Environment* extended = environment::new_enclosed(mac.env, alloc);
    foreach (i, p: mac.parameters) {
        extended.set(p.value, &args[i]);
    }
    return extended;
}

fn bool is_macro(Statement node)
{
    switch (node.type) {
        case LetStatement: return ((LetStatement*) node).value.type == ast::Macro.typeid;
        case StrStmt: return ((StrStmt*) node).value.type == ast::Macro.typeid;
        case I32Stmt: return ((I32Stmt*) node).value.type == ast::Macro.typeid;
    }
    return false;
}

fn void add_macro(Statement stmt, Environment* env, Allocator alloc)
{
    LetStatement* let = (LetStatement*) stmt;
    ast::Macro* am = (ast::Macro*) let.value;
    object::Macro* om = allocator::new(alloc, object::Macro, {
        .parameters = am.parameters,
        .env = env,
        .body = am.body,
    });
    env.set(let.name.value, om);
}
