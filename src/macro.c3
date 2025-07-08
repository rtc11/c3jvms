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

fn bool is_macro(Statement node)
{
    if (node.type != LetStmt.typeid) return false;
    LetStmt* let = (LetStmt*) node;
    if (let.value.type != ast::Macro.typeid) return false;
    return true;
}

fn void add_macro(Statement stmt, Environment* env, Allocator alloc)
{
    LetStmt* let = (LetStmt*) stmt;
    ast::Macro* am = (ast::Macro*) let.value;
    object::Macro* om = allocator::new(alloc, object::Macro, {
        .parameters = am.parameters,
        .env = env,
        .body = am.body,
    });
    env.set(let.name.value, om);
}
