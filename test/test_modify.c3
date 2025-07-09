module ast;

import std::io;
import std::collections::list;
import std::collections::map;
import environment;

alias TestCase = Node[2]; // [input, expected]

fn void node() @test
{
    TestCase[*] cases = {
        { one(), two() },
        { program(one()), program(two()) },
        { infix(one(), "+", two()), infix(two(), "+", two()) },
        { infix(two(), "+", one()), infix(two(), "+", two()) },
        { prefix("-", one()), prefix("-", two()) },
        { index(one(), one()), index(two(), two()) },
        { if_expr(one(), one(), one()), if_expr(two(), two(), two()) },
        { return_stmt(one()), return_stmt(two()) },
        { let(one()), let(two()) },
        { fun(one()), fun(two())},
        { array(one(), one()), array(two(), two()) },
    };
    Environment* env = environment::new(allocator::temp());
    foreach(test: cases) {
        Node actual = modify(test[0], &turn_one_into_two, env, allocator::temp());
        deep_eq(test[1], actual);
    }
}

fn void hash() @test
{
    
    map::HashMap{Expression, Expression} pairs;
    pairs.tinit();
    pairs[one()] = one();
    pairs[one()] = one();

    ast::HashMap* hm = allocator::new(allocator::temp(), ast::HashMap, { 
        .pairs = pairs,
    });

    Environment* env = environment::new(allocator::temp());
    modify(hm, &turn_one_into_two, env, allocator::temp());

    hm.pairs.@each(; Expression k, Expression v) {
        ast::Int32* key = (ast::Int32*) k;
        test::eq(2, key.value);
        ast::Int32* value = (ast::Int32*) v;
        test::eq(2, value.value);
    };
}

fn Expression one() => allocator::new(allocator::temp(), ast::Int32, { .value = 1 });
fn Expression two() => allocator::new(allocator::temp(), ast::Int32, { .value = 2 });

fn Node turn_one_into_two(Node node, Environment* env, Allocator alloc)
{
    switch(node.type) {
        case ast::Int32:  
            ast::Int32* integer = (ast::Int32*) node;
            if (integer.value != 1) return node;
            integer.value = 2;
            return integer;
        default: 
            return node;
    }
}

fn Node program(Expression expr)
{
    return allocator::new(allocator::temp(), Program, { 
        .statements = statements(expr) 
    });
}

macro statements(Expression...)
{
    Expression[*] exprs = { $vasplat };
    List{Statement} stmts;
    stmts.tinit();
    foreach(expr: exprs) {
        stmts.push(allocator::new(allocator::temp(), ExpressionStatement, { .expression = expr }));
    }
    return stmts;
}

macro expressions(Expression...)
{
    Expression[*] varargs = { $vasplat };
    List{Expression} exprs;
    exprs.tinit_with_array(&varargs);
    return exprs;
}

fn Node infix(Expression left, String operator, Expression right)
{
    return allocator::new(allocator::temp(), InfixExpression, {
        .left = left,
        .operator = operator,
        .right = right,
    });
}

fn Node prefix(String operator, Expression right)
{
    return allocator::new(allocator::temp(), PrefixExpression, {
        .operator = operator,
        .right = right,
    });
}

fn Node index(Expression left, Expression index)
{
    return allocator::new(allocator::temp(), Index, {
        .left = left,
        .index = index,
    });
}

fn Node if_expr(Expression cond, Expression cons, Expression alt)
{
    return allocator::new(allocator::temp(), If, {
        .condition = cond,
        .consequence = allocator::new(allocator::temp(), BlockStatement, {
            .statements = statements(cons),
        }),
        .alternative = allocator::new(allocator::temp(), BlockStatement, {
            .statements = statements(alt),
        }),
    });
}

fn Node return_stmt(Expression value)
{
    return allocator::new(allocator::temp(), ReturnStatement, {
        .return_value = value,
    });
}

fn Node let(Expression value)
{
    return allocator::new(allocator::temp(), LetStatement, {
        .value = value,
    });
}

fn Node fun(Expression body)
{
    return allocator::new(allocator::temp(), Fn, {
        .parameters = {},
        .body = allocator::new(allocator::temp(), BlockStatement, {
            .statements = statements(body),
        }),
    });
}

macro Node array(Expression...)
{
    return allocator::new(allocator::temp(), Array, {
        .elements = expressions($vasplat), 
    });
}

fn void deep_eq(Node expected, Node actual)
{
    test::eq(expected.type, actual.type);

    switch (expected.type)
    {
        case Program:
            Program* exp = (Program*) expected;
            Program* act = (Program*) actual;
            test::eq(exp.statements.len(), act.statements.len());
            foreach(i, stmt: exp.statements) deep_eq(stmt, act.statements[i]);
        case ExpressionStatement:
            ExpressionStatement* exp = (ExpressionStatement*) expected;
            ExpressionStatement* act = (ExpressionStatement*) actual;
            deep_eq(exp.expression, act.expression);
        case ast::Int32:
            ast::Int32* exp = (ast::Int32*) expected;
            ast::Int32* act = (ast::Int32*) actual;
            test::eq(exp.value, act.value);
        case InfixExpression:
            InfixExpression* exp = (InfixExpression*) expected;
            InfixExpression* act = (InfixExpression*) actual;
            test::eq(exp.operator, act.operator);
            deep_eq(exp.left, act.left);
            deep_eq(exp.right, act.right);
        case PrefixExpression:
            PrefixExpression* exp = (PrefixExpression*) expected;
            PrefixExpression* act = (PrefixExpression*) actual;
            test::eq(exp.operator, act.operator);
            deep_eq(exp.right, act.right);
        case Index:
            Index* exp = (Index*) expected;
            Index* act = (Index*) actual;
            deep_eq(exp.left, act.left);
            deep_eq(exp.index, act.index);
        case If:
            If* exp = (If*) expected;
            If* act = (If*) actual;
            deep_eq(exp.condition, act.condition);
            deep_eq(exp.consequence, act.consequence);
            deep_eq(exp.alternative, act.alternative);
        case BlockStatement:
            BlockStatement* exp = (BlockStatement*) expected;
            BlockStatement* act = (BlockStatement*) actual;
            test::eq(exp.statements.len(), act.statements.len());
            foreach(i, stmt: exp.statements) deep_eq(stmt, act.statements[i]);
        case ReturnStatement:
            ReturnStatement* exp = (ReturnStatement*) expected;
            ReturnStatement* act = (ReturnStatement*) actual;
            deep_eq(exp.return_value, act.return_value);
        case LetStatement:
            LetStatement* exp = (LetStatement*) expected;
            LetStatement* act = (LetStatement*) actual;
            deep_eq(exp.value, act.value);
        case Fn:
            Fn* exp = (Fn*) expected;
            Fn* act = (Fn*) actual;
            foreach(i, param: exp.parameters) deep_eq(&param, &act.parameters[i]);
            deep_eq(exp.body, act.body);
        case Identifier:
            Identifier* exp = (Identifier*) expected;
            Identifier* act = (Identifier*) actual;
            test::eq(exp.value, act.value);
        case Array:
            Array* exp = (Array*) expected;
            Array* act = (Array*) actual;
            foreach(i, elem: exp.elements) deep_eq(elem, act.elements[i]);

        default:
            io::printfn("deep_eq for %s not implemented", actual);
            test::eq(true, false);
    }
}
