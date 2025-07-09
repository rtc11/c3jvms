module test::parser;

import std::io;
import std::collections::list;
import std::collections::map;
import parser, lexer, ast;

alias StrTuple = String[2];

fn void statement_i32() @test
{
    LetStatement* stmt = stmt_let("let num = 10;");
    let_eq(stmt, "num", 10);
}

fn void statement_return() @test
{
    Lexer lexer = lexer::new(`return 5;`);
    Parser parser = parser::new(lexer, allocator::temp());
    Program prog = parser.parse_program();
    any stmt = prog.statements[0];
    test::eq(((ReturnStatement*) stmt).token_literal(), "return");
}

fn void expression_identifier() @test
{
    expr_eq(expression(`foobar;`), "foobar");
}

fn void expression_int() @test
{
    expr_eq(expression(`5;`), 5);
}

fn void expression_bool() @test
{
    expr_eq(expression(`true;`), true);
    expr_eq(expression(`false;`), false);
}

fn void expression_str() @test
{
    Expression expr = expression(`"hello world";`);
    StrLiteral* lit = (StrLiteral*) expr;
    test::eq(lit.value, "hello world");
}

fn void expression_if() @test
{
    If* expr = (If*) expression(`if (x < y) { x }`);;
    test_expression_infix(expr.condition, "x", "<", "y");
    test::eq(1, expr.consequence.statements.len());
    ExpressionStatement* cons = (ExpressionStatement*) expr.consequence.statements[0];
    identifier_eq(cons.expression, "x");
    test::eq(null, expr.alternative);
}

fn void expression_if_else() @test
{
    If* expr = (If*) expression(`if (x < y) { x } else { y }`);
    test_expression_infix(expr.condition, "x", "<", "y");
    test::eq(1, expr.consequence.statements.len());
    ExpressionStatement* cons = (ExpressionStatement*) expr.consequence.statements[0];
    identifier_eq(cons.expression, "x");
    test::eq(1, expr.alternative.statements.len());
    ExpressionStatement* alt = (ExpressionStatement*) expr.alternative.statements[0];
    identifier_eq(alt.expression, "y");
}

fn void expression_fn0() @test
{
    Fn* expr = (Fn*) expression(`fn () {}`);
    test::eq(0, expr.parameters.len());
    test::eq(0, expr.body.statements.len());
}

fn void expression_fn1() @test
{
    Fn* expr = (Fn*) expression(`fn (x) {}`);
    fn_eq(expr, "x");
    test::eq(0, expr.body.statements.len());
}

fn void expression_fn2() @test
{
    Fn* expr = (Fn*) expression(`fn(x, y) { x + y };`);
    fn_eq(expr, "x", "y");
    test::eq(1, expr.body.statements.len());
    ExpressionStatement* body_stmt = (ExpressionStatement*) expr.body.statements[0];
    test_expression_infix(body_stmt.expression, "x", "+", "y");
}

fn void expression_fn3() @test
{
    Fn* expr = (Fn*) expression(`fn (x, y, z) {};`); 
    fn_eq(expr, "x", "y", "z");
    test::eq(0, expr.body.statements.len());
}

fn void expression_call() @test
{
    Call* expr = (Call*) expression(`add(1, 2 * 3, 4 + 5);`);
    identifier_eq(expr.function, "add");
    test::eq(3, expr.arguments.len());
    expr_eq(expr.arguments[0], 1);
    test_expression_infix(expr.arguments[1], 2, "*", 3);
    test_expression_infix(expr.arguments[2], 4, "+", 5);
}

fn void expression_prefix() @test
{
    test_expression_prefix(expression("!69;"), "!", 69);
    test_expression_prefix(expression("-69;"), "-", 69);
    test_expression_prefix(expression("!true"), "!", true);
    test_expression_prefix(expression("!false"), "!", false);
}

fn void expression_infix() @test
{
    test_expression_infix(expression("true == true"), true, "==", true);
    test_expression_infix(expression("true != false"), true, "!=", false);
    test_expression_infix(expression("false == false"), false, "==", false);
    test_expression_infix(expression("5 + 5;"), 5, "+", 5);
    test_expression_infix(expression("5 - 5;"), 5, "-", 5);
    test_expression_infix(expression("5 * 5;"), 5, "*", 5);
    test_expression_infix(expression("5 / 5;"), 5, "/", 5);
    test_expression_infix(expression("5 > 5;"), 5, ">", 5);
    test_expression_infix(expression("5 < 5;"), 5, "<", 5);
    test_expression_infix(expression("5 == 5;"),5, "==", 5);
    test_expression_infix(expression("5 != 5;"),5, "!=", 5);
}

fn void operator_presendence() @test
{
    StrTuple[26] cases = { 
        {"-a * b",  "((-a) * b)"},
        {"!-a",  "(!(-a))"},
        {"a + b + c",  "((a + b) + c)"},
        {"a + b - c",  "((a + b) - c)"},
        {"a * b * c",  "((a * b) * c)"},
        {"a * b / c",  "((a * b) / c)"},
        {"a + b / c",  "(a + (b / c))"},
        {"a + b * c + d / e - f",  "(((a + (b * c)) + (d / e)) - f)"},
        {"3 + 4; -5 * 5",  "(3 + 4)((-5) * 5)"},
        {"5 > 4 == 3 < 4",  "((5 > 4) == (3 < 4))"},
        {"5 < 4 != 3 > 4",  "((5 < 4) != (3 > 4))"},
        {"3 + 4 * 5 == 3 * 1 + 4 * 5",  "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"},
        { "true", "true" },
        { "false", "false" },
        { "3 > 5 == false", "((3 > 5) == false)" },
        { "3 < 5 == true", "((3 < 5) == true)" },
        { "1 + (2 + 3) + 4", "((1 + (2 + 3)) + 4)" },
        { "(5 + 5) * 2", "((5 + 5) * 2)" },
        { "2 / (5 + 5)", "(2 / (5 + 5))" },
        { "-(5 + 5)", "(-(5 + 5))" },
        { "!(true == true)", "(!(true == true))" },
        { "a + add(b * c) + d", "((a + add((b * c))) + d)" },
        { "add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))", "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))" },
        { "add(a + b + c * d / f + g)", "add((((a + b) + ((c * d) / f)) + g))" },
        {"a * [1, 2, 3, 4][b * c] * d",  "((a * ([1, 2, 3, 4][(b * c)])) * d)"},
        {"add(a * b[2], b[1], 2 * [1, 2][1])",  "add((a * (b[2])), (b[1]), (2 * ([1, 2][1])))"},
    };
    for(int i = 0; i < cases.len; i++) {
        Lexer lexer = lexer::new(cases[i][0]);
        Parser parser = parser::new(lexer, allocator::temp());
        Program prog = parser.parse_program();
        check_parser_errors(&parser);
        test::eq(string::tformat("%s", prog), cases[i][1]);
    }
}

fn void expression_array() @test
{
    Array* array = (Array*) expression("[1, 2 * 2, 3 + 3]");
    test::eq(3, array.elements.len());
    intlit_eq(array.elements[0], 1);
    test_expression_infix(array.elements[1], 2, "*", 2);
    test_expression_infix(array.elements[2], 3, "+", 3);

}

fn void expression_hash_str_keys() @test
{
    ast::HashMap* hash = (ast::HashMap*) expression(`{"one": 1, "two": 2, "three": 3}`);
    test::eq(3, hash.pairs.len());

    map::HashMap{String, int} expected;
    expected.tinit();
    expected["one"] = 1;
    expected["two"] = 2;
    expected["three"] = 3;

    hash.pairs.@each(; Expression k, Expression v) {
        StrLiteral* key = (StrLiteral*)k;
        ast::Int32* value = (ast::Int32*)v;
        intlit_eq(value, expected[key.value]!!);
    };
}

fn void expression_hash_empty() @test
{
    ast::HashMap* hash = (ast::HashMap*) expression(`{}`);
    test::eq(0, hash.pairs.len());
}

alias FunExpr = fn void (Expression);
fn void hash_expression_keys_one(Expression e) => test_expression_infix(e, 0, "+", 1); 
fn void hash_expression_keys_two(Expression e) => test_expression_infix(e, 10, "-", 8);
fn void hash_expression_keys_three(Expression e) => test_expression_infix(e, 15, "/", 5);

fn void expression_hash_expression_keys() @test
{
    ast::HashMap* hash = (ast::HashMap*) expression(`{"one": 0 + 1, "two": 10 - 8, "three": 15 / 5 }`);
    test::eq(3, hash.pairs.len());

    map::HashMap{String, FunExpr} expected;
    expected.tinit();
    expected["one"] = &hash_expression_keys_one;
    expected["two"] = &hash_expression_keys_two;
    expected["three"] = &hash_expression_keys_three;

    hash.pairs.@each(; Expression k, Expression v) {
        StrLiteral* key = (StrLiteral*)k;
        FunExpr test_expr = expected[key.value]!!;
        test_expr(v);
    };
}

fn void expression_macro() @test
{
    Macro* expr = (Macro*) expression(`macro(x, y) { x + y; };`);
    test::eq(2, expr.parameters.len());
    identifier_eq(&expr.parameters[0], "x");
    identifier_eq(&expr.parameters[1], "y");
    test::eq(1, expr.body.statements.len());
    ExpressionStatement* body_stmt = (ExpressionStatement*) expr.body.statements[0];
    test_expression_infix(body_stmt.expression, "x", "+", "y"); 
}

fn LetStatement* stmt_let(String input)
{
    Lexer lexer = lexer::new(input);
    Parser parser = parser::new(lexer, allocator::temp());
    Program prog = parser.parse_program();
    return (LetStatement*) prog.statements[0];
}

macro let_eq(LetStatement* stmt, String expect_name, expect_expr)
{
    test::eq(stmt.token_literal(), "let");
    test::eq(stmt.name.value, expect_name);
    expr_eq(stmt.value, expect_expr);
}

fn Expression expression(String input)
{
    Lexer lexer = lexer::new(input);
    Parser parser = parser::new(lexer, allocator::temp());
    Program prog = parser.parse_program();
    check_parser_errors(&parser);
    test::eq(1, prog.statements.len());
    Statement stmt = prog.statements[0];
    ExpressionStatement* expr_stmt = (ExpressionStatement*) stmt;
    return expr_stmt.expression;
}

macro fn_eq(Expression expr, ...)
{
    Fn* fn_expr = (Fn*) expr;
    String[*] args = { $vasplat };
    foreach(i, arg: args) identifier_eq(&fn_expr.parameters[i], arg);
}

macro test_expression_prefix(Expression expr, operator, right)
{
    PrefixExpression* prefix_expr = (PrefixExpression*) expr;
    test::eq(prefix_expr.operator, operator);
    expr_eq(prefix_expr.right, right);
}

macro test_expression_infix(Expression expr, left, operator, right)
{
    InfixExpression* infix_expr = (InfixExpression*) expr;
    expr_eq(infix_expr.left, left);
    test::eq(infix_expr.operator, operator);
    expr_eq(infix_expr.right, right);
}

macro expr_eq(Expression expr, expected)
{
    $switch $typeof(expected).typeid:
        $case bool: bool_eq(expr, expected);
        $case int: intlit_eq(expr, expected);
        $case String: identifier_eq(expr, expected);
        $default: $error @sprintf("Invalid type %s", $typeof(expected).nameof);
    $endswitch
}

fn void identifier_eq(Expression expr, String expected)
{
    Identifier* ident = (Identifier*) expr;
    test::eq(ident.value, expected);
    test::eq(ident.token_literal(), expected);
}

fn void intlit_eq(Expression expr, int expected)
{
    ast::Int32* int_lit= (ast::Int32*) expr;
    test::eq(int_lit.value, expected);
    test::eq(int_lit.token_literal(), string::tformat("%s", expected));
}

fn void bool_eq(Expression expr, bool expected)
{
    Bool* bool_expr = (Bool*) expr;
    test::eq(bool_expr.value, expected);
    test::eq(bool_expr.token_literal(), string::tformat("%s", expected));
}

fn void check_parser_errors(Parser* parser)
{
    if (parser.errors.len() == 0) return;
    foreach(err: parser.errors) {
        io::printfn("ERROR: %s", err);
    }
}

