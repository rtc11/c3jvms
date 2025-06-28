module test::evaluator;

import std::io;
import std::collections::list;
import evaluator, object, ast, parser, lexer;

fn void eval_expression_i32() @test {
    i32_obj_eq(test_eval("5")!!, 5);
    i32_obj_eq(test_eval("10")!!, 10);
    i32_obj_eq(test_eval("-5")!!, -5);
    i32_obj_eq(test_eval("-10")!!, -10);
}

fn void eval_expression_bool() @test {
    bool_obj_eq(test_eval("true")!!, true);
    bool_obj_eq(test_eval("false")!!, false);
}

fn void operator_bang() @test {
    bool_obj_eq(test_eval("!true")!!, false);
    bool_obj_eq(test_eval("!false")!!, true);
    bool_obj_eq(test_eval("!5")!!, false);
    bool_obj_eq(test_eval("!!true")!!, true);
    bool_obj_eq(test_eval("!!false")!!, false);
    bool_obj_eq(test_eval("!!5")!!, true);
}

fn Object? test_eval(String input) {
    Lexer lexer = lexer::new(input);
    Parser parser = parser::new(lexer, allocator::temp());
    Program prog = parser.parse_program();
    return evaluator::eval(&prog, allocator::temp())!;
}

fn void i32_obj_eq(Object obj, int expected) {
    I32Obj* res = (I32Obj*) obj;
    test::eq(expected, res.value);
}

fn void bool_obj_eq(Object obj, bool expected) {
    BoolObj* res = (BoolObj*) obj;
    test::eq(expected, res.value);
}
