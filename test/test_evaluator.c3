module test::evaluator;

import std::io;
import std::collections::list;
import std::collections::map;
import evaluator, object, ast, parser, lexer, environment, ascii;

fn void eval_expression_i32() @test
{
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

fn void eval_expression_bool() @test
{
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

fn void operator_bang() @test
{
    bool_eq(test_eval("!true"), false);
    bool_eq(test_eval("!false"), true);
    bool_eq(test_eval("!5"), false);
    bool_eq(test_eval("!!true"), true);
    bool_eq(test_eval("!!false"), false);
    bool_eq(test_eval("!!5"), true);
}

fn void eval_expression_if_else() @test
{
    if_else_eq(test_eval("if (true) { 10 }"), 10);
    if_else_eq(test_eval("if (true) { 10 }"), 10);
    if_else_eq(test_eval("if (false) { 10 }"), null);
    if_else_eq(test_eval("if (1) { 10 }"), 10);
    if_else_eq(test_eval("if (1 < 2) { 10 }"), 10);
    if_else_eq(test_eval("if (1 > 2) { 10 }"), null);
    if_else_eq(test_eval("if (1 < 2) { 10 } else { 20 }"), 10);
    if_else_eq(test_eval("if (1 > 2) { 10 } else { 20 }"), 20);
}

fn void eval_stmt_return() @test
{
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

fn void eval_stmt_let() @test
{
    i32_eq(test_eval("let a = 5; a;"), 5);
    i32_eq(test_eval("let a = 5 * 5; a;"), 25);
    i32_eq(test_eval("let a = 5; let b = a; b;"), 5);
    i32_eq(test_eval("let a = 5; let b = a; let c = a + b + 5; c;"), 15);
}

fn void eval_stmt_i32() @test
{
    i32_eq(test_eval("i32 a = 5; a;"), 5);
    i32_eq(test_eval("i32 a = 5 * 5; a;"), 25);
    i32_eq(test_eval("i32 a = 5; i32 b = a; b;"), 5);
    i32_eq(test_eval("i32 a = 5; i32 b = a; i32 c = a + b + 5; c;"), 15);
    err_eq(test_eval(`i32 a = "hello"; a;`), "cannot assign value of str to variable of i32");
}

fn void eval_err() @test
{
    Error* err = (Error*) test_eval(`i32 a = "hello"; a;`);
    test::eq(
        string::tformat("%s%s", ascii::red("ERROR"), 
            ": cannot assign value of str to variable of i32 in evaluator.c3:43 eval()"),
        err.inspect());
}

fn void error_handling() @test
{
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
    err_eq(test_eval(`{"name": "Monkey"}[fn(x) { x }]`), "unusable as hash key: fn");
}

fn void function_object() @test
{
    Object e = test_eval("fn(x) { x + 2; };");
    object::Fn* fun = (object::Fn*) e;
    test::eq(1, fun.parameters.len());
    test::eq(string::tformat("%s", fun.parameters[0]), "x");
    test::eq(string::tformat("%s", fun.body), "(x + 2)");
}

fn void function_application() @test
{
    i32_eq(test_eval("let identity = fn(x) { x; }; identity(5);"), 5);
    i32_eq(test_eval("let identity = fn(x) { return x; }; identity(5);"), 5);
    i32_eq(test_eval("let double = fn(x) { x * 2; }; double(5);"), 10);
    i32_eq(test_eval("let add = fn(x, y) { x + y; }; add(5, 5);"), 10);
    i32_eq(test_eval("let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));"), 20);
}

fn void closures() @test
{
    i32_eq(test_eval(`
        let new_adder = fn(x) {
            fn(y) { x + y };
        };
        let add_two = new_adder(2);
        add_two(2);
    `), 4);

    i32_eq(test_eval(`
        let add = fn (a, b) { a + b };
        let apply = fn (a, b, fun) { fun(a, b) };
        apply(2, 2, add);
    `), 4);
}

fn void str_concat() @test
{
    str_eq(test_eval(`"Hello" + " " + "World";`), "Hello World");
}

fn void builtin_fn() @test
{
    builtin_eq(test_eval(`len("")`), 0);
    builtin_eq(test_eval(`len("abc")`), 3);
    builtin_eq(test_eval(`first([1, 2, 3])`), 1);
    builtin_eq(test_eval(`let a = [4,5,6]; first(a);`), 4);
    builtin_eq(test_eval(`last([1, 2, 3])`), 3);
    builtin_eq(test_eval(`let a = [4,5,6]; last(a);`), 6);
}

fn void builtin_slice() @test
{
    builtin_array_eq(test_eval(`slice([1, 2, 3, 4, 5], 0, 0)`), 1);
    builtin_array_eq(test_eval(`slice([1, 2, 3, 4, 5], 1, 1)`), 2);
    builtin_array_eq(test_eval(`slice([1, 2, 3, 4, 5], 2, 2)`), 3);
    builtin_array_eq(test_eval(`slice([1, 2, 3, 4, 5], 0, 4)`), 1, 2, 3, 4, 5);
    builtin_array_eq(test_eval(`slice([1, 2, 3, 4, 5], 1, 3)`), 2, 3, 4);
    builtin_array_eq(test_eval(`slice([1, 2, 3, 4, 5], 2, 3)`), 3, 4);
    builtin_array_eq(test_eval(`slice([1, 2, 3, 4, 5], 2, 4)`), 3, 4, 5);
    builtin_array_eq(test_eval(`slice([1, 2, 3, 4, 5], 2, 5)`), 3, 4, 5);
    builtin_array_eq(test_eval(`slice([1, 2, 3, 4, 5], 2, 6)`), 3, 4, 5);
    builtin_array_eq(test_eval(`slice([1, 2, 3, 4, 5], -2, 2)`), 1, 2, 3);
}

fn void builtin_rest() @test
{
    builtin_array_eq(test_eval(`rest([1, 2, 3])`), 2, 3 );
    builtin_array_eq(test_eval(`rest(rest([1, 2, 3]))`), 3 );
    builtin_array_eq(test_eval(`rest(rest(rest([1, 2, 3])))`));
    null_eq(test_eval(`rest(rest(rest(rest([1, 2, 3]))))`));
}

fn void builtin_push() @test
{
    builtin_array_eq(test_eval(`let a = [1]; push(a, 2);`), 1, 2);
    builtin_array_eq(test_eval(`let a = []; push(a, 1);`), 1);
}

// TODO: move to stdlib
fn void map() @test
{
    builtin_array_eq(test_eval(`
        let map = fn(arr, f) {
            let iter = fn(arr, acc) {
                if (len(arr) == 0) {
                    acc
                } else {
                    iter(rest(arr), push(acc, f(first(arr))));
                }
            };
            iter(arr, []);
        };
        let a = [1, 2, 3, 4];
        let double = fn(x) { x * 2 };
        map(a, double);
    `), 2, 4, 6, 8);
}

// TODO: move to stdlib
fn void reduce() @test
{
    i32_eq(test_eval(`
        let reduce = fn(arr, init, f) {
            let iter = fn(arr, acc) {
                if (len(arr) == 0) {
                    acc
                } else {
                    iter(rest(arr), f(acc, first(arr)));
                }
            };
            iter(arr, init);
        };
        let sum = fn(arr) {
            reduce(arr, 0, fn(init, el) { init + el });
        };
        sum([1, 2, 3, 4, 5]);
    `), 15);
}

fn void array() @test
{
    builtin_array_eq(test_eval("[]"));
    builtin_array_eq(test_eval("[1, 2 * 2, 3 + 3]"), 1, 4, 6);
}

fn void array_index() @test
{
    i32_eq(test_eval("[1, 2, 3][0]"), 1);
    i32_eq(test_eval("[1, 2, 3][1]"), 2);
    i32_eq(test_eval("[1, 2, 3][2]"), 3);
    i32_eq(test_eval("let i = 0; [1][i];"), 1);
    i32_eq(test_eval("[1, 2, 3][1 + 1]"), 3);
    i32_eq(test_eval("let arr = [1, 2, 3]; arr[2];"), 3);
    i32_eq(test_eval("let arr = [1, 2, 3]; arr[0] + arr[1] + arr[2];"), 6);
    i32_eq(test_eval("let arr = [1, 2, 3]; let i = arr[0]; arr[i]"), 2);
    null_eq(test_eval("[1, 2, 3][3]"));
    null_eq(test_eval("[1, 2, 3][-1]"));
}

fn void hash() @test
{
    Object obj = test_eval(`
        let two = "two";
        {
            "one": 10 - 9,
            two: 1 + 1,
            "thr" + "ee": 6 / 2,
            4: 4,
            true: 5,
            false: 6
        }
    `);
    if (obj.is_err()) io::printfn("%s", ((Error*) obj).message);
    test::eq(obj.name(), "hash");
    object::HashMap* hm = (object::HashMap*) obj;
    map::HashMap{Hash, int} expected;
    expected.tinit();
    expected[(Str){"one"}.hash()] = 1;
    expected[(Str){"two"}.hash()] = 2;
    expected[(Str){"three"}.hash()] = 3;
    expected[(object::Int32){4}.hash()] = 4;
    expected[(object::Bool){true}.hash()] = 5;
    expected[(object::Bool){false}.hash()] = 6;
    test::eq(expected.len(), hm.pairs.len());
    expected.@each(; Hash expected_key, int expected_value) {
        HashPair pair = hm.pairs[expected_key]!!;
        i32_eq(pair.value, expected_value);
    };
}

fn void hash_index() @test
{
    eq(test_eval(`{"foo": 5}["foo"]`), 5);
    eq(test_eval(`{"foo": 5}["bar"]`), null);
    eq(test_eval(`{}["bar"]`), null);
    eq(test_eval(`{5: 5}[5]`), 5);
    eq(test_eval(`{true: 5}[true]`), 5);
}

macro builtin_array_eq(Object obj, ...)
{
    object::Array* array = (object::Array*) obj;
    int[*] expected = { $vasplat, 0 };
    if (expected.len == 1) return;
    test::eq(expected.len - 1, array.elements.len());
    for (int i = 0; i< array.elements.len() -1; i++) {
        i32_eq(array.elements[i], expected[i]);
    }
}

macro void eq(Object obj, expected)
{
    $switch $typeof(expected).typeid:
        $case int: i32_eq(obj, expected);
        $case String: str_eq(obj, expected);
        $default: null_eq(obj);
    $endswitch
}

macro void builtin_eq(Object obj, expected)
{
    $switch $typeof(expected).typeid:
        $case int: i32_eq(obj, expected);
        $case String: err_eq(obj, expected);
    $endswitch
}

fn void str_eq(Object obj, String expected)
{
    if (obj.is_err()) err_eq(obj, expected);
    object::Str* res = (object::Str*) obj;
    test::eq(expected, res.value);
}

fn void err_eq(Object obj, String err_msg
               ){
    Error* err_obj = (Error*) obj;
    test::eq(err_msg, err_obj.message);
}

macro if_else_eq(Object obj, expected)
{
    $switch $typeof(expected).typeid:
        $case int: i32_eq(obj, expected);
        $default: null_eq(obj);
    $endswitch
}

fn void null_eq(Object obj)
{
    test::eq(obj.type, Null.typeid);
}

fn Object test_eval(String input)
{
    Lexer lexer = lexer::new(input);
    Parser parser = parser::new(lexer, allocator::temp());
    Program prog = parser.parse_program();
    Environment* env = environment::new(allocator::temp());
    return evaluator::eval(&prog, env, allocator::temp());
}

fn void i32_eq(Object obj, int expected)
{
    object::Int32* res = (object::Int32*) obj;
    test::eq(expected, res.value);
}

fn void bool_eq(Object obj, bool expected)
{
    object::Bool* res = (object::Bool*) obj;
    test::eq(expected, res.value);
}

