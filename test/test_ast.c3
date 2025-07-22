module test::ast @test;

import std::io;
import std::collections::list;
import lexer, ast;

fn void to_format() @test
{
    List{Statement} stmts;
    stmts.tinit();
    Identifier* ident = allocator::new(allocator::temp(), Identifier, {
        .token = { IDENTIFIER, "another" },
        .value = "another",
    }); 
    Let* stmt = allocator::new(allocator::temp(), Let, { 
        .token = { LET, "let" },
        .name = { 
            .token = { IDENTIFIER, "my" },
            .value = "my" 
        },
        .value = ident
    });

    stmts.push(stmt);
    Program p = { stmts };
    test::eq(string::tformat("%s", p), "let my = another;");
}
