module test::evaluator;

import std::io;
import std::collections::list;
import evaluator, object, ast, parser, lexer, environment;

fn void eval_expression_i32() @test {
    i32_eq(test_eval("5"), 5);
    i32_eq(test_eval("10"), 10);
    i32_eq(test_eval("-5"), -5);
    i32_eq(test_eval("-10"), -10);
    i32_eq(test_eval("5 + 5 + 5 + 5 - 10"), 10);
    i32_eq(test_eval("2 * 2 * 2 * 2 * 2"), 32);
    i32_eq(test_eval("-50 + 100 + -50"), 0);
    i32_eq(test_eval("5 * 2 + 10"), 20);
    i32_eq(test_eval("5 + 2 * 10"), 25);
    i32_eq(test_eval("20 + 2 * -10"), 0);
    i32_eq(test_eval("50 / 2 * 2 + 10"), 60);
    i32_eq(test_eval("2 * (5 + 10)"), 30);
    i32_eq(test_eval("3 * 3 * 3 + 10"), 37);
    i32_eq(test_eval("3 * (3 * 3) + 10"), 37);
    i32_eq(test_eval("(5 + 10 * 2 + 15 / 3) * 2 + -10"), 50);
}

fn void eval_expression_bool() @test {
    bool_eq(test_eval("true"), true);
    bool_eq(test_eval("false"), false);
    bool_eq(test_eval("1 < 2"), true);
    bool_eq(test_eval("1 > 2"), false);
    bool_eq(test_eval("1 < 1"), false);
    bool_eq(test_eval("1 > 1"), false);
    bool_eq(test_eval("1 == 1"), true);
    bool_eq(test_eval("1 != 1"), false);
    bool_eq(test_eval("1 == 2"), false);
    bool_eq(test_eval("1 != 2"), true);
    bool_eq(test_eval("true == true"), true);
    bool_eq(test_eval("false == false"), true);
    bool_eq(test_eval("true == false"), false);
    bool_eq(test_eval("true != false"), true);
    bool_eq(test_eval("false != true"), true);
    bool_eq(test_eval("(1 < 2) == true"), true);
    bool_eq(test_eval("(1 < 2) == false"), false);
    bool_eq(test_eval("(1 > 2) == true"), false);
    bool_eq(test_eval("(1 > 2) == false"), true);
    bool_eq(test_eval("(1 > 2) == (1 > 2)"), true);
    bool_eq(test_eval("(1 > 2) == (1 < 2)"), false);
    bool_eq(test_eval("(1 > 2) != (1 > 2)"), false);
    bool_eq(test_eval("(1 > 2) != (1 < 2)"), true);

}

fn void operator_bang() @test {
    bool_eq(test_eval("!true"), false);
    bool_eq(test_eval("!false"), true);
    bool_eq(test_eval("!5"), false);
    bool_eq(test_eval("!!true"), true);
    bool_eq(test_eval("!!false"), false);
    bool_eq(test_eval("!!5"), true);
}

fn void eval_expression_if_else() @test {
    if_else_eq(test_eval("if (true) { 10 }"), 10);
    if_else_eq(test_eval("if (true) { 10 }"), 10);
    if_else_eq(test_eval("if (false) { 10 }"), null);
    if_else_eq(test_eval("if (1) { 10 }"), 10);
    if_else_eq(test_eval("if (1 < 2) { 10 }"), 10);
    if_else_eq(test_eval("if (1 > 2) { 10 }"), null);
    if_else_eq(test_eval("if (1 < 2) { 10 } else { 20 }"), 10);
    if_else_eq(test_eval("if (1 > 2) { 10 } else { 20 }"), 20);
}

fn void eval_stmt_return() @test {
    i32_eq(test_eval("return 10;"), 10);
    i32_eq(test_eval("return 10; 9;"), 10);
    i32_eq(test_eval("return 2 * 5; 9;"), 10);
    i32_eq(test_eval("9; return 2 * 5; 9;"), 10);
    i32_eq(test_eval(`
        if (10 > 1) {
            if (10 > 1) {
                return 10;
            }
            return 1;
        }
    `), 10);
}

fn void eval_stmt_i32() @test {
    i32_eq(test_eval("i32 a = 5; a;"), 5);
    i32_eq(test_eval("i32 a = 5 * 5; a;"), 25);
    i32_eq(test_eval("i32 a = 5; i32 b = a; b;"), 5);
    i32_eq(test_eval("i32 a = 5; i32 b = a; i32 c = a + b + 5; c;"), 15);
}

fn void error_handling() @test {
    err_eq(test_eval("5 + true;"), "type mismatch: i32 + bool");
    err_eq(test_eval("5 + true; 5;"), "type mismatch: i32 + bool");
    err_eq(test_eval("-true"), "unknown operator: -bool");
    err_eq(test_eval("true + false;"), "unknown operator: bool + bool");
    err_eq(test_eval("5; true + false; 5"), "unknown operator: bool + bool");
    err_eq(test_eval("if (10 > 1) { true + false; }"), "unknown operator: bool + bool");
    err_eq(test_eval(`
        if (10 > 1) {
            if (10 > 1) {
                return true + false;
            }
            return 1;
        }
    `), "unknown operator: bool + bool");
    err_eq(test_eval("foobar"), "identifier not found: foobar");
    err_eq(test_eval(`"Hello" - "World"`), "unknown operator: str - str");
}

fn void function_object() @test {
    Object e = test_eval("fn(x) { x + 2; };");
    object::Fn* fun = (object::Fn*) e;
    test::eq(1, fun.parameters.len());
    test::eq(string::tformat("%s", fun.parameters[0]), "x");
    test::eq(string::tformat("%s", fun.body), "(x + 2)");
}

fn void function_application() @test {
    i32_eq(test_eval("i32 identity = fn(x) { x; }; identity(5);"), 5);
    i32_eq(test_eval("i32 identity = fn(x) { return x; }; identity(5);"), 5);
    i32_eq(test_eval("i32 double = fn(x) { x * 2; }; double(5);"), 10);
    i32_eq(test_eval("i32 add = fn(x, y) { x + y; }; add(5, 5);"), 10);
    i32_eq(test_eval("i32 add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));"), 20);
}

fn void closures() @test {
    i32_eq(test_eval(`
        i32 new_adder = fn(x) {
            fn(y) { x + y };
        };
        i32 add_two = new_adder(2);
        add_two(2);
    `), 4);

    i32_eq(test_eval(`
        i32 add = fn (a, b) { a + b };
        i32 apply = fn (a, b, fun) { fun(a, b) };
        apply(2, 2, add);
    `), 4);
}

fn void str_concat() @test {
    str_eq(test_eval(`"Hello" + " " + "World";`), "Hello World");
}

fn void builtin_fn() @test {
    builtin_eq(test_eval(`len("")`), 0);
    builtin_eq(test_eval(`len("abc")`), 3);

    builtin_eq(test_eval(`first([1, 2, 3])`), 1);
    builtin_eq(test_eval(`i32 a = [4,5,6]; first(a);`), 4);
    builtin_eq(test_eval(`last([1, 2, 3])`), 3);
    builtin_eq(test_eval(`i32 a = [4,5,6]; last(a);`), 6);
}

fn void builtin_slice() @test {
    builtin_slice_eq(test_eval(`slice([1, 2, 3, 4, 5], 0, 0)`), 1);
    builtin_slice_eq(test_eval(`slice([1, 2, 3, 4, 5], 1, 1)`), 2);
    builtin_slice_eq(test_eval(`slice([1, 2, 3, 4, 5], 2, 2)`), 3);
    builtin_slice_eq(test_eval(`slice([1, 2, 3, 4, 5], 0, 4)`), 1, 2, 3, 4, 5);
    builtin_slice_eq(test_eval(`slice([1, 2, 3, 4, 5], 1, 3)`), 2, 3, 4);
    builtin_slice_eq(test_eval(`slice([1, 2, 3, 4, 5], 2, 3)`), 3, 4);
    builtin_slice_eq(test_eval(`slice([1, 2, 3, 4, 5], 2, 4)`), 3, 4, 5);
    builtin_slice_eq(test_eval(`slice([1, 2, 3, 4, 5], 2, 5)`), 3, 4, 5);
    builtin_slice_eq(test_eval(`slice([1, 2, 3, 4, 5], 2, 6)`), 3, 4, 5);
    builtin_slice_eq(test_eval(`slice([1, 2, 3, 4, 5], -2, 2)`), 1, 2, 3);
}

macro builtin_slice_eq(Object obj, ...)
{
    object::Array* array = (object::Array*) obj;
    int[*] expected = { $vasplat };
    test::eq(expected.len, array.elements.len());
    foreach(i, elem: array.elements) i32_eq(elem, expected[i]);
}

fn void array() @test {
    object::Array* array = (object::Array*) test_eval("[1, 2 * 2, 3 + 3]");
    test::eq(3, array.elements.len());
    i32_eq(array.elements[0], 1);
    i32_eq(array.elements[1], 4);
    i32_eq(array.elements[2], 6);
}

fn void array_index() @test {
    i32_eq(test_eval("[1, 2, 3][0]"), 1);
    i32_eq(test_eval("[1, 2, 3][1]"), 2);
    i32_eq(test_eval("[1, 2, 3][2]"), 3);
    i32_eq(test_eval("i32 i = 0; [1][i];"), 1);
    i32_eq(test_eval("[1, 2, 3][1 + 1]"), 3);
    i32_eq(test_eval("i32 arr = [1, 2, 3]; arr[2];"), 3);
    i32_eq(test_eval("i32 arr = [1, 2, 3]; arr[0] + arr[1] + arr[2];"), 6);
    i32_eq(test_eval("i32 arr = [1, 2, 3]; i32 i = arr[0]; arr[i]"), 2);
    null_eq(test_eval("[1, 2, 3][3]"));
    null_eq(test_eval("[1, 2, 3][-1]"));
}

macro void builtin_eq(Object obj, expected) {
    $switch $typeof(expected).typeid:
        $case int: i32_eq(obj, expected);
        $case String: err_eq(obj, expected);
    $endswitch
}

fn void str_eq(Object obj, String expected) {
    object::Str* res = (object::Str*) obj;
    test::eq(expected, res.value);
}

fn void err_eq(Object obj, String err_msg){
    Error* err_obj = (Error*) obj;
    test::eq(err_msg, err_obj.message);
}

macro if_else_eq(Object obj, expected) {
    $switch $typeof(expected).typeid:
        $case int: i32_eq(obj, expected);
        $default: null_eq(obj);
    $endswitch
}

fn void null_eq(Object obj) {
    test::eq(obj.type, Null.typeid);
}

fn Object test_eval(String input) {
    Lexer lexer = lexer::new(input);
    Parser parser = parser::new(lexer, allocator::temp());
    Program prog = parser.parse_program();
    Environment* env = environment::new(allocator::temp());
    return evaluator::eval(&prog, env, allocator::temp())!!;
}

fn void i32_eq(Object obj, int expected) {
    object::Int32* res = (object::Int32*) obj;
    test::eq(expected, res.value);
}

fn void bool_eq(Object obj, bool expected) {
    object::Bool* res = (object::Bool*) obj;
    test::eq(expected, res.value);
}
