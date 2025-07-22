module ast;

import std::collections::map;
import environment;

alias Modifier = fn Node(Node, Environment*, Allocator);

fn Node modify(Node node, Modifier modifier, Environment* env, Allocator alloc)
{
    switch (node.type)
    {
        case Program:
            Program* prog = (Program*)node;
            foreach(i, stmt: prog.statements) prog.statements[i] = (Statement) modify(stmt, modifier, env, alloc);

        case ExpressionStatement:
            ExpressionStatement* expr_stmt = (ExpressionStatement*) node;
            expr_stmt.expression = (Expression) modify(expr_stmt.expression, modifier, env, alloc);

        case Infix:
            Infix* infix = (Infix*) node;
            infix.left = (Expression) modify(infix.left, modifier, env, alloc);
            infix.right = (Expression) modify(infix.right, modifier, env, alloc);

        case Prefix:
            Prefix* infix = (Prefix*) node;
            infix.right = (Expression) modify(infix.right, modifier, env, alloc);

        case Index:
            Index* expr = (Index*) node;
            expr.left = (Expression) modify(expr.left, modifier, env, alloc);
            expr.index = (Expression) modify(expr.index, modifier, env, alloc);

        case If:
            If* expr = (If*) node;
            expr.condition = (Expression) modify(expr.condition, modifier, env, alloc);
            expr.consequence = (Block*) modify(expr.consequence, modifier, env, alloc);
            if (expr.alternative != null) expr.alternative = (Block*) modify(expr.alternative, modifier, env, alloc);

        case Block:
            Block* expr = (Block*) node;
            foreach(i, stmt: expr.statements) stmt = (Statement) modify(stmt, modifier, env, alloc);

        case Return:
            Return* expr = (Return*) node;
            expr.return_value = (Expression) modify(expr.return_value, modifier, env, alloc);

        case Let:
            Let* expr = (Let*) node;
            expr.value = (Expression) modify(expr.value, modifier, env, alloc);

        case Integer:
            Integer* expr = (Integer*) node;
            expr.value = (IntegerLiteral*) modify(expr.value, modifier, env, alloc);

        case ast::String:
            ast::String* expr = (ast::String*) node;
            expr.value = (StringLiteral*) modify(expr.value, modifier, env, alloc);

        case Fn:
            Fn* expr = (Fn*) node;
            foreach(i, param: expr.parameters) param = *(Identifier*) modify(&param, modifier, env, alloc);
            expr.body = (Block*) modify(expr.body, modifier, env, alloc);

        case Array:
            Array* expr = (Array*) node;
            foreach(i, elem: expr.elements) elem = (Expression) modify(elem, modifier, env, alloc);

        case ast::HashMap:
            ast::HashMap* expr = (ast::HashMap*) node;
            map::HashMap{Expression, Expression} new;
            new.tinit();
            expr.pairs.@each(; Expression key, Expression val) {
                new[(Expression) modify(key, modifier, env, alloc)] = (Expression) modify(val, modifier, env, alloc);
            };
            expr.pairs = new;
    }

    return modifier(node, env, alloc);
}
