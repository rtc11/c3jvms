module repl;

import std::io;
import std::math::random;
import lexer, parser, ast, evaluator, environment, object;

fn void main()
{
    print_logo();

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
                io::printfn("\t%s", colorize_red(string::tformat("%s", err)));
            }
        }

        evaluator::define_macro(&program, macro_env, alloc);
        Node expanded = evaluator::expand_macro(&program, macro_env, alloc);
        Object evaluated = evaluator::eval(expanded, macro_env, alloc);

        io::printfn("%s", colorize_str(string::tformat("%s", evaluated.inspect())));
    }
}

fn void print_logo() {
    String logo = colorize_chars(
`  __  repl
_/  |_ ___.__.
\   __<   |  |
 |  |  \___  |
 |__|  / ____|
       \/ v 0.1`);
    io::printfn("%s", logo);
}

const String RESET_COLOR = "\x1b[0m";
alias Color = int[3];

fn String colorize_chars(String str) {
    DString out;
    out.tinit();
    foreach(ch: str) {
        Color color = { rand(150)+50, rand(150)+50,rand(150)+50 };
        out.append(string::tformat("\x1b[38;2;%d;%d;%d;m%c%s", color[0], color[1], color[2], ch, RESET_COLOR));
    }
    return out.str_view();
} 

fn String colorize_red(String str) {
    return string::tformat("\x1b[38;2;%d;%d;%d;m%s%s", 220, 20, 60, str, RESET_COLOR);
}

fn String colorize_str(String str) {
    Color color = { rand(150)+50, rand(150)+50,rand(150)+50 };
    return string::tformat("\x1b[38;2;%d;%d;%d;m%s%s", color[0], color[1], color[2], str, RESET_COLOR);
} 

