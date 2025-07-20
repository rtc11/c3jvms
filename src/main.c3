import std::io;
import std::collections::list;
import std::collections::anylist;
import std::net;
import std::time;
import classfile, assembler; 
import ast, lexer, parser, ascii, object, evaluator, environment;

fn void main(String[] args)
{
    @pool() {
        // read_ty(args);
        // read_class(args);
        Clock c = clock::now();
        compile(args)!!;
        // io::printfn("%s", output);
        io::printfn(" - %s", c.mark());
    };
}

faultdef COMPILATION_ERROR;
fn void? compile(String[] args)
{
    ascii::print_logo(linebreak: true);
    if (args.len != 2) {
        ascii::print_err("compiler require a file to compile, e.g. 'ty main.ty'");
        return COMPILATION_ERROR?;
    }
    String filename = args[1];
    char[] input = file::load_temp(filename)!!;
    Lexer lexer = lexer::new(input);
    Environment* env = environment::new(allocator::temp());
    Parser parser = parser::new(lexer, allocator::temp());
    Program prog = parser.parse_program();
    if (parser.errors.len() != 0) {
        foreach (err: parser.errors) {
            io::printfn("\t%s", ascii::colorize(RED, string::tformat("%s", err)));
        }
    }
    Object evaluated = evaluator::eval(&prog, env, allocator::temp());
    if (evaluated.is_err()) {
        io::printfn("%s", ascii::randomize(string::tformat("%s", evaluated.inspect())));
    }
}

fn void read_ty(String[] args)
{
    if (args.len != 2) {
        io::printfn("require .ty name as the program arg");
        return;
    }

    String filename = args[1];
    io::printfn("lexing %s", filename);

    char[] input = file::load_temp(filename)!!;

    Lexer lexer = lexer::new(input);
    while (lexer.has_next()) {
        Token t = lexer.next();
        io::printfn("%s", t);
        if (t.type == ILLEGAL) break;
    }

    // Lexer lexer = lexer::new(input);
    // Parser parser = parser::new(lexer, allocator::heap());
    // Program prog = parser.parse_program();
    // foreach(stmt: prog.statements) {
    //     switch (stmt.type) {
    //         case IntStatement: 
    //             io::printfn("stmt:%s", ((IntStatement*) stmt).token_literal());
    //     }
    // }
    // foreach(err: parser.errors) {
    //     io::printfn(err);
    // }
}

fn void read_class(String[] args)
{
    if (args.len != 2) {
        io::printfn("require .class name as the program arg");
        return;
    }

    String filename = args[1];
    io::printfn("disassemble %s", filename);

    File f = file::open(filename, "r")!!;
    defer (void) f.close();

    Reader r = reader::new(&f);
    Class? class = classfile::new(&r);
    if (catch error = class) {
        io::printfn("Failed to read classfile: %s", error);
        return;
    }

    // io::printfn("Pool: \n%s", class.cp);
    // io::printfn("interfaces: %s", class.interfaces);
    // io::printfn("fields: %s", class.fields);
    // io::printfn("methods: %s", class.methods);
    // io::printfn("attrs: %s", class.attrs);

    assembler::disassemble(&class);
}
