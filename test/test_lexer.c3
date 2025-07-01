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
    String code = `i32`;
    Lexer lexer = lexer::new(code);
    test::eq(lexer.next().type, TokenType.I32);
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

typedef Tuple = String[2];
fn void literal_string()
{
    Tuple[2] cases = {
        {`"foobar"`, "foobar"},
        {`"foo bar"`, "foo bar"},
    };
    for (int i = 0; i< cases.len; i++) {
        Lexer lexer = lexer::new(cases[i][0]);
        Token token = lexer.next();
        test::eq(token.type, TokenType.STR_LITERAL);
        test::eq(token.literal, cases[i][1]);
    }
}
