module repl;

import std::io;
import std::math::random;
import lexer, parser, ast, evaluator, environment, object, ascii;

fn void main()
{
    ascii::print_logo("repl");

    Allocator alloc = allocator::heap();
    Environment* env = environment::new(alloc);
    Environment* macro_env = environment::new(alloc);

    while (true)
    {
        io::printf("$ ");
        String input = io::readline(alloc)!!;
        Lexer lexer = lexer::new(input);
        Parser parser = parser::new(lexer, alloc);
        Program program = parser.parse_program();

        if (parser.errors.len() != 0) {
            foreach (err: parser.errors) {
                io::printfn("\t%s", ascii::red(string::tformat("%s", err)));
            }
        }

        evaluator::define_macro(&program, macro_env, alloc);
        Node expanded = evaluator::expand_macro(&program, macro_env, alloc);
        Object evaluated = evaluator::eval(expanded, macro_env, alloc);

        io::printfn("%s", ascii::colorize_str(string::tformat("%s", evaluated.inspect())));
    }
}

