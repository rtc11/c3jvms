module test::evaluator;

import std::io;
import evaluator, object, parser, lexer, environment;

fn void quote() @test
{
    quote_eq(test_eval("quote(5)"), "5");
    quote_eq(test_eval("quote(5 + 8)"), "(5 + 8)");
    quote_eq(test_eval("quote(foobar)"), "foobar");
    quote_eq(test_eval("quote(foobar + barfoo)"), "(foobar + barfoo)");
    quote_eq(test_eval("quote(unquote(4))"), "4");
    quote_eq(test_eval("quote(unquote(4 + 4))"), "8");
    quote_eq(test_eval("quote(8 + unquote(4 + 4))"), "(8 + 8)");
    quote_eq(test_eval("quote(unquote(4 + 4) + 8)"), "(8 + 8)");
    quote_eq(test_eval("let foobar = 8; quote(foobar)"), "foobar");
    quote_eq(test_eval("let foobar = 8; quote(unquote(foobar))"), "8");
    quote_eq(test_eval("quote(unquote(true))"), "true");
    quote_eq(test_eval("quote(unquote(true == false))"), "false");
    quote_eq(test_eval("quote(unquote(quote(4 + 4)))"), "(4 + 4)");
    quote_eq(test_eval(`let quotedInfixExpr = quote(4 + 4); quote(unquote(4 + 4) + unquote(quotedInfixExpr))`), "(8 + (4 + 4))");
    quote_eq(test_eval("i32 foobar = 8; quote(foobar)"), "foobar");
    quote_eq(test_eval(`str foobar = "8"; quote(unquote(foobar))`), "8");
}

macro quote_eq(Object obj, expected)
{
    switch (obj.type) {
        case Quote:
            object::Quote* res = (object::Quote*) obj;
            test::eq(expected, string::tformat("%s", res.node));
        default: 
            test::eq(string::tformat("%s", obj.name()), "not a quote");
    }
}
