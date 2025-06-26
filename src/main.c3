import std::io;
import std::collections::list;
import std::collections::anylist;
import std::net;
import classfile; 
import assembler;
import ast;
import lexer;
import parser;
import ascii;

fn void main(String[] args)
{
    @pool() {
        // read_ty(args);
        // read_class(args);
        read_input();
    };
}

fn void read_input()
{
    Lexer lexer = lexer::new(`5 < 4 != 3 > 4`);
    Parser parser = parser::new(lexer, allocator::heap());
    Program prog = parser.parse_program();
    ExpressionStatement* stmt = (ExpressionStatement*) prog.statements[0];
    ascii::print_expr_stmt(prog);
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
