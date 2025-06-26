module test::lexer @test;

import lexer;
import std::io;
import std::collections::list;

fn void literal_fn()
{
    String code = `fn`;
    Lexer lexer = lexer::new(code);
    test::eq(lexer.next().type, TokenType.FN);
}

fn void literal_int()
{
    String code = `int`;
    Lexer lexer = lexer::new(code);
    test::eq(lexer.next().type, TokenType.INT);
}

fn void literal_semicolon()
{
    String code = `;`;
    Lexer lexer = lexer::new(code);
    test::eq(lexer.next().type, TokenType.SEMICOLON);
}

fn void literal_namespace()
{
    String code = `::`;
    Lexer lexer = lexer::new(code);
    test::eq(lexer.next().type, TokenType.NAMESPACE);
}
