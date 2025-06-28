module test::evaluator;

import std::io;
import std::collections::list;
import evaluator, object, ast, parser, lexer;

fn void expression_eval_i32() @test {
    Object obj = test_eval("5")!!;
    i32_obj_eq(obj, 5);
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
