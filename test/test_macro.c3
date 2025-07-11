module test::evaluator;

import ast, lexer, object, parser, environment, evaluator;

fn void define() @test
{
    Environment* env = environment::new(allocator::temp());
    Program prog = program(`
        let number = 1;
        let function = fn(x, y) { x + y };
        let mymacro = macro(x, y) { x + y };
        i32 mymacro = macro(x, y) { x + y };
        str mymacro = macro(x, y) { x + y };
    `);

    evaluator::define_macro(&prog, env, allocator::temp());

    test::eq(2, prog.statements.len());
    if (try env.get("number")) test::eq("number should not be defined", "");
    if (try env.get("function")) test::eq("function should not be defined", "");
    Object? obj = env.get("mymacro");
    if (catch obj) test::eq("macro not in environment.", "");
    object::Macro* m = (object::Macro*) obj!!;
    test::eq(2, m.parameters.len());
    test::eq("x", string::tformat("%s", m.parameters[0]));
    test::eq("y", string::tformat("%s", m.parameters[1]));
    test::eq("(x + y)", string::tformat("%s", m.body));
}

struct Test
{
    String input;
    String expect;
}

fn void expand() @test
{
    Test[*] tests = {
        { 
            .input = `
                let infixexpr = macro() { 
                    quote(1 + 2);
                }; 
                infixexpr();`,
            .expect = `(1 + 2)`
        },
        { 
            .input = `
                let reverse = macro(a, b) { 
                    quote(unquote(b) - unquote(a));
                }; 
                reverse(2 + 2, 10 - 5);`,
            .expect = `(10 - 5) - (2 + 2)`
        },
        {
            .input = `
                let unless = macro(cond, cons, alt) {
                    quote(if (!(unquote(cond))) {
                        unquote(cons);
                    } else {
                        unquote(alt);
                    });
                };
                unless(10 > 5, print("not greater"), print("greater"));
            `,
            .expect = `
                if (!(10 > 5)) {
                    print("not greater")
                } else {
                    print("greater")
                }
            `
        },
    };
    Environment* env = environment::new(allocator::temp());

    foreach(test: tests) {
        Program prog = program(test.input);
        Program expected = program(test.expect);
        evaluator::define_macro(&prog, env, allocator::temp());
        Node actual = evaluator::expand_macro(&prog, env, allocator::temp());
        test::eq(string::tformat("%s", expected), string::tformat("%s", actual));
    }
}

fn Program program(String input)
{
    Lexer lexer = lexer::new(input);
    Parser parser = parser::new(lexer, allocator::temp());
    return parser.parse_program();
}
