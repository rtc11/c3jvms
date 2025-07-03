module test::lexer;

import lexer;
import std::io;
import std::collections::list;

fn void next_token() @test
{
    Lexer lexer = lexer::new(`
        let ten = 10;

        let add = fn(x, y) {
            x + y;
        };

        let result = add(five, ten);
        !-/*5;
        5 < 10 > 5;

        if (5 < 10) {
            return true;
        } else {
            return false;
        }

        10 == 10;
        10 != 9;
        "foobar"
        "foo bar"
        [1, 2];
        {"foo": "bar"}
    `);

    token_eq(lexer.next(), { LET, "let"});
    token_eq(lexer.next(), { IDENTIFIER, "ten"});
    token_eq(lexer.next(), { ASSIGN, "="});
    token_eq(lexer.next(), { INT_LITERAL, "10"});
    token_eq(lexer.next(), { SEMICOLON, ";"});

    token_eq(lexer.next(), { LET, "let"});
    token_eq(lexer.next(), { IDENTIFIER, "add"});
    token_eq(lexer.next(), { ASSIGN, "="});
    token_eq(lexer.next(), { FN, "fn"});
    token_eq(lexer.next(), { L_PAREN, "("});
    token_eq(lexer.next(), { IDENTIFIER, "x"});
    token_eq(lexer.next(), { COMMA, ","});
    token_eq(lexer.next(), { IDENTIFIER, "y"});
    token_eq(lexer.next(), { R_PAREN, ")"});
    token_eq(lexer.next(), { L_BRACE, "{"});
    token_eq(lexer.next(), { IDENTIFIER, "x"});
    token_eq(lexer.next(), { PLUS, "+"});
    token_eq(lexer.next(), { IDENTIFIER, "y"});
    token_eq(lexer.next(), { SEMICOLON, ";"});
    token_eq(lexer.next(), { R_BRACE, "}"});
    token_eq(lexer.next(), { SEMICOLON, ";"});

    token_eq(lexer.next(), { LET, "let"});
    token_eq(lexer.next(), { IDENTIFIER, "result"});
    token_eq(lexer.next(), { ASSIGN, "="});
    token_eq(lexer.next(), { IDENTIFIER, "add"});
    token_eq(lexer.next(), { L_PAREN, "("});
    token_eq(lexer.next(), { IDENTIFIER, "five"});
    token_eq(lexer.next(), { COMMA, ","});
    token_eq(lexer.next(), { IDENTIFIER, "ten"});
    token_eq(lexer.next(), { R_PAREN, ")"});
    token_eq(lexer.next(), { SEMICOLON, ";"});

    token_eq(lexer.next(), { BANG, "!"});
    token_eq(lexer.next(), { MINUS, "-"});
    token_eq(lexer.next(), { SLASH, "/"});
    token_eq(lexer.next(), { ASTERISK, "*"});
    token_eq(lexer.next(), { INT_LITERAL, "5"});
    token_eq(lexer.next(), { SEMICOLON, ";"});

    token_eq(lexer.next(), { INT_LITERAL, "5"});
    token_eq(lexer.next(), { LT, "<"});
    token_eq(lexer.next(), { INT_LITERAL, "10"});
    token_eq(lexer.next(), { GT, ">"});
    token_eq(lexer.next(), { INT_LITERAL, "5"});
    token_eq(lexer.next(), { SEMICOLON, ";"});

    token_eq(lexer.next(), { IF, "if"});
    token_eq(lexer.next(), { L_PAREN, "("});
    token_eq(lexer.next(), { INT_LITERAL, "5"});
    token_eq(lexer.next(), { LT, "<"});
    token_eq(lexer.next(), { INT_LITERAL, "10"});
    token_eq(lexer.next(), { R_PAREN, ")"});
    token_eq(lexer.next(), { L_BRACE, "{"});
    token_eq(lexer.next(), { RETURN, "return"});
    token_eq(lexer.next(), { TRUE, "true"});
    token_eq(lexer.next(), { SEMICOLON, ";"});
    token_eq(lexer.next(), { R_BRACE, "}"});
    token_eq(lexer.next(), { ELSE, "else"});
    token_eq(lexer.next(), { L_BRACE, "{"});
    token_eq(lexer.next(), { RETURN, "return"});
    token_eq(lexer.next(), { FALSE, "false"});
    token_eq(lexer.next(), { SEMICOLON, ";"});
    token_eq(lexer.next(), { R_BRACE, "}"});

    token_eq(lexer.next(), { INT_LITERAL, "10"});
    token_eq(lexer.next(), { EQ, "=="});
    token_eq(lexer.next(), { INT_LITERAL, "10"});
    token_eq(lexer.next(), { SEMICOLON, ";"});

    token_eq(lexer.next(), { INT_LITERAL, "10"});
    token_eq(lexer.next(), { NEQ, "!="});
    token_eq(lexer.next(), { INT_LITERAL, "9"});
    token_eq(lexer.next(), { SEMICOLON, ";"});
    token_eq(lexer.next(), { STR_LITERAL, "foobar"});
    token_eq(lexer.next(), { STR_LITERAL, "foo bar"});

    token_eq(lexer.next(), { L_BRACKET, "["});
    token_eq(lexer.next(), { INT_LITERAL, "1"});
    token_eq(lexer.next(), { COMMA, ","});
    token_eq(lexer.next(), { INT_LITERAL, "2"});
    token_eq(lexer.next(), { R_BRACKET, "]"});
    token_eq(lexer.next(), { SEMICOLON, ";"});

    token_eq(lexer.next(), { L_BRACE, "{"});
    token_eq(lexer.next(), { STR_LITERAL, "foo"});
    token_eq(lexer.next(), { COLON, ":"});
    token_eq(lexer.next(), { STR_LITERAL, "bar"});
    token_eq(lexer.next(), { R_BRACE, "}"});

    token_eq(lexer.next(), { EOF, ""});
    test::eq(false, lexer.has_next());
}

fn void token_eq(Token left, Token right)
{
    test::eq(left.type, right.type);
    test::eq(left.literal, right.literal);
}

