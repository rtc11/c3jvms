module test::evaluator;

import std::io;
import std::collections::list;
import evaluator, object, ast, parser, lexer;

fn void eval_expression_i32() @test {
    i32_obj_eq(test_eval("5"), 5);
    i32_obj_eq(test_eval("10"), 10);
    i32_obj_eq(test_eval("-5"), -5);
    i32_obj_eq(test_eval("-10"), -10);
    i32_obj_eq(test_eval("5 + 5 + 5 + 5 - 10"), 10);
    i32_obj_eq(test_eval("2 * 2 * 2 * 2 * 2"), 32);
    i32_obj_eq(test_eval("-50 + 100 + -50"), 0);
    i32_obj_eq(test_eval("5 * 2 + 10"), 20);
    i32_obj_eq(test_eval("5 + 2 * 10"), 25);
    i32_obj_eq(test_eval("20 + 2 * -10"), 0);
    i32_obj_eq(test_eval("50 / 2 * 2 + 10"), 60);
    i32_obj_eq(test_eval("2 * (5 + 10)"), 30);
    i32_obj_eq(test_eval("3 * 3 * 3 + 10"), 37);
    i32_obj_eq(test_eval("3 * (3 * 3) + 10"), 37);
    i32_obj_eq(test_eval("(5 + 10 * 2 + 15 / 3) * 2 + -10"), 50);
}

fn void eval_expression_bool() @test {
    bool_obj_eq(test_eval("true"), true);
    bool_obj_eq(test_eval("false"), false);
    bool_obj_eq(test_eval("1 < 2"), true);
    bool_obj_eq(test_eval("1 > 2"), false);
    bool_obj_eq(test_eval("1 < 1"), false);
    bool_obj_eq(test_eval("1 > 1"), false);
    bool_obj_eq(test_eval("1 == 1"), true);
    bool_obj_eq(test_eval("1 != 1"), false);
    bool_obj_eq(test_eval("1 == 2"), false);
    bool_obj_eq(test_eval("1 != 2"), true);
    bool_obj_eq(test_eval("true == true"), true);
    bool_obj_eq(test_eval("false == false"), true);
    bool_obj_eq(test_eval("true == false"), false);
    bool_obj_eq(test_eval("true != false"), true);
    bool_obj_eq(test_eval("false != true"), true);
    bool_obj_eq(test_eval("(1 < 2) == true"), true);
    bool_obj_eq(test_eval("(1 < 2) == false"), false);
    bool_obj_eq(test_eval("(1 > 2) == true"), false);
    bool_obj_eq(test_eval("(1 > 2) == false"), true);
    bool_obj_eq(test_eval("(1 > 2) == (1 > 2)"), true);
    bool_obj_eq(test_eval("(1 > 2) == (1 < 2)"), false);
    bool_obj_eq(test_eval("(1 > 2) != (1 > 2)"), false);
    bool_obj_eq(test_eval("(1 > 2) != (1 < 2)"), true);

}

fn void operator_bang() @test {
    bool_obj_eq(test_eval("!true"), false);
    bool_obj_eq(test_eval("!false"), true);
    bool_obj_eq(test_eval("!5"), false);
    bool_obj_eq(test_eval("!!true"), true);
    bool_obj_eq(test_eval("!!false"), false);
    bool_obj_eq(test_eval("!!5"), true);
}

fn Object test_eval(String input) {
    Lexer lexer = lexer::new(input);
    Parser parser = parser::new(lexer, allocator::temp());
    Program prog = parser.parse_program();
    return evaluator::eval(&prog, allocator::temp())!!;
}

fn void i32_obj_eq(Object obj, int expected) {
    I32Obj* res = (I32Obj*) obj;
    test::eq(expected, res.value);
}

fn void bool_obj_eq(Object obj, bool expected) {
    BoolObj* res = (BoolObj*) obj;
    test::eq(expected, res.value);
}
