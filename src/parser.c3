module parser;

import std::io;
import std::collections::anylist;
import std::collections::list;
import std::collections::map;
import ast;
import lexer;

const DEBUG = false;
alias ParsePrefix = fn Expression(Parser*);
alias ParseInfix = fn Expression(Parser*, Expression);

struct Parser
{
    Allocator allocator;
    Lexer lexer;
    Token cur;
    Token peek;
    List{String} errors;
    HashMap{TokenType, Presendence} presendences;
    HashMap{TokenType, ParsePrefix} prefixes;
    HashMap{TokenType, ParseInfix} infixes;
}

macro uint TokenType.hash(TokenType type) => string::tformat("%s", type).hash();

fn Parser new(Lexer lexer, Allocator allocator) 
{ 
    HashMap{TokenType, ParsePrefix} prefixes;
    prefixes.init(allocator);
    HashMap{TokenType, ParseInfix} infixes;
    infixes.init(allocator);

    HashMap{TokenType, Presendence} presendences;
    presendences.init(allocator);
    presendences[EQ]        = EQUALS;
    presendences[NEQ]       = EQUALS;
    presendences[LT]        = LESS_GREATER;
    presendences[GT]        = LESS_GREATER;
    presendences[PLUS]      = SUM;
    presendences[MINUS]     = SUM;
    presendences[SLASH]     = PRODUCT;
    presendences[ASTERISK]  = PRODUCT;
    presendences[DOT]       = DOT;
    presendences[L_PAREN]   = CALL;
    presendences[L_BRACKET] = INDEX;

    Parser p = { 
        .allocator = allocator,
        .lexer = lexer, 
        .presendences = presendences,
        .prefixes = prefixes,
        .infixes = infixes,
    };

    p.next_token();
    p.next_token();

    p.register_prefix(IDENTIFIER,  (ParsePrefix) &Parser.parse_identifier);
    p.register_prefix(INT_LITERAL, (ParsePrefix) &Parser.parse_int_literal);
    p.register_prefix(BANG,        (ParsePrefix) &Parser.parse_prefix_expression);
    p.register_prefix(MINUS,       (ParsePrefix) &Parser.parse_prefix_expression);
    p.register_prefix(TRUE,        (ParsePrefix) &Parser.parse_bool);
    p.register_prefix(FALSE,       (ParsePrefix) &Parser.parse_bool);
    p.register_prefix(L_PAREN,     (ParsePrefix) &Parser.parse_grouped_expression);
    p.register_prefix(IF,          (ParsePrefix) &Parser.parse_if_expression);
    p.register_prefix(ELSE,        (ParsePrefix) &Parser.parse_if_expression);
    p.register_prefix(FN,          (ParsePrefix) &Parser.parse_fn_expression);
    p.register_prefix(STR_LITERAL, (ParsePrefix) &Parser.parse_str_literal);
    p.register_prefix(L_BRACKET,   (ParsePrefix) &Parser.parse_array_literal);
    p.register_prefix(L_BRACE,     (ParsePrefix) &Parser.parse_hash_literal);
    p.register_prefix(MACRO,       (ParsePrefix) &Parser.parse_macro_literal);

    p.register_infix(PLUS,      (ParseInfix) &Parser.parse_infix_expression);
    p.register_infix(MINUS,     (ParseInfix) &Parser.parse_infix_expression);
    p.register_infix(SLASH,     (ParseInfix) &Parser.parse_infix_expression);
    p.register_infix(ASTERISK,  (ParseInfix) &Parser.parse_infix_expression);
    p.register_infix(EQ,        (ParseInfix) &Parser.parse_infix_expression);
    p.register_infix(NEQ,       (ParseInfix) &Parser.parse_infix_expression);
    p.register_infix(LT,        (ParseInfix) &Parser.parse_infix_expression);
    p.register_infix(GT,        (ParseInfix) &Parser.parse_infix_expression);
    p.register_infix(L_PAREN,   (ParseInfix) &Parser.parse_call_expression);
    p.register_infix(L_BRACKET, (ParseInfix) &Parser.parse_index_expression);
    p.register_infix(DOT,       (ParseInfix) &Parser.parse_dot_expression);

    return p;
}

fn void Parser.register_prefix(&self, TokenType type, ParsePrefix prefix)
{
    self.prefixes[type] = prefix;
}

fn void Parser.register_infix(&self, TokenType type, ParseInfix infix)
{
    self.infixes[type] = infix;
}

fn void Parser.next_token(&self)
{
    self.cur = self.peek;
    self.peek = self.lexer.next();
}

fn Program Parser.parse_program(&self)
{
    List{Statement} stmts;
    stmts.init(self.allocator);

    while (self.cur.type != EOF) {
        Statement stmt = self.parse_statement();
        if (stmt != null) stmts.push(stmt);
        self.next_token();
    }
    return { stmts };
}

fn Statement Parser.parse_statement(&self)
{
    switch (self.cur.type) {
        case I32:    return (Statement) self.parse_typed_let(INTEGER);
        case STR:    return (Statement) self.parse_typed_let(STRING);
        case LET:    return (Statement) self.parse_let();
        case STRUCT: return (Statement) self.parse_struct_definition();
        case RETURN: return (Statement) self.parse_return_stmt();
        default:     return (Statement) self.parse_expression_stmt();
    }
}

fn Let* Parser.parse_let(&self)
{
    if (DEBUG) io::printfn("parse_let");
    Let* stmt = allocator::new(self.allocator, Let, { .token = self.cur });
    if (!self.expect_peek(IDENTIFIER)) return null;
    stmt.name = { self.cur, self.cur.literal };
    switch (self.peek.type) {
        case ASSIGN:
            self.next_token(); // consume =
            self.next_token(); // advance to expression
            stmt.value = self.parse_expression(LOWEST);
            if (self.peek_token_is(SEMICOLON)) self.next_token();
        case SEMICOLON:
            self.next_token(); // consume ;
        default:
            self.peek_error(ASSIGN);
            self.peek_error(SEMICOLON);
    }
    if (DEBUG) io::printfn("parse_let OK");
    return stmt;
}

fn Let* Parser.parse_typed_let(&self, TypeAnnotation type)
{
    Token token = self.cur;
    self.next_token(); // move to identifier
    if (self.cur.type != IDENTIFIER) {
        self.errors.push("expected identifier after type annotation");
        return null;
    }
    Identifier* name = (Identifier*) self.parse_identifier();
    Expression value;
    if (self.peek_token_is(ASSIGN)) {
        self.next_token(); // consume =
        self.next_token(); // move to value expression
        value = self.parse_expression(LOWEST);
    }
    if (self.peek_token_is(SEMICOLON)) self.next_token();
    return allocator::new(self.allocator, Let, {
        .token = token,
        .type = type,
        .name = *name,
        .value = value,
    });
}

fn Struct* Parser.parse_struct_definition(&self)
{
    Token token = self.cur;
    if(!self.expect_peek(IDENTIFIER)) return null;
    Identifier* name = (Identifier*) self.parse_identifier();

    if (!self.expect_peek(L_BRACE)) return null;

    List{Statement} fields;
    fields.tinit();

    while(!self.peek_token_is(R_BRACE)) {
        self.next_token();
        switch (self.cur.type) {
            case I32: 
                Let* stmt = self.parse_typed_let(INTEGER);
                if (stmt != null) fields.push(stmt);
            case STR: 
                Let* stmt = self.parse_typed_let(STRING);
                if (stmt != null) fields.push(stmt);
            case SEMICOLON:
                break; // skip semicolons between fields
            default: 
                io::printfn("%s not valid in struct definitions", self.cur.literal);
        }
    }
    if (!self.expect_peek(R_BRACE)) return null;
    Struct* stmt = allocator::new(self.allocator, Struct, {
        .token = token,
        .name = *name,
        .fields = fields,
    });
    return stmt;
}

fn StructLiteral* Parser.parse_struct_literal(&self, Identifier* struct_name)
{
    self.next_token(); // advance to L_BRACE
    Token token = self.cur;
    map::HashMap{Identifier, Expression} fields;
    fields.tinit();
    while(!self.peek_token_is(R_BRACE)) {
        self.next_token();
        if (self.cur.type != IDENTIFIER) {
            self.errors.push(string::tformat("expected identifier as struct field key, got %s", self.cur.literal));
            return null;
        }
        Identifier* field = (Identifier*) self.parse_identifier();
        if (!self.expect_peek(COLON)) return null;
        self.next_token(); // move to expression value
        Expression value = self.parse_expression(LOWEST);
        fields[*field] = value;
        if (self.peek_token_is(COMMA)) self.next_token();
    }
    if (!self.expect_peek(R_BRACE)) return null;

    StructLiteral* lit = allocator::new(self.allocator, StructLiteral, {
        .token = token,
        .struct_name = *struct_name,
        .field_values = fields,
    });
    return lit;
}

fn Return* Parser.parse_return_stmt(&self)
{
    Return* stmt = allocator::new(self.allocator, Return, { .token = self.cur });
    self.next_token();
    stmt.return_value = self.parse_expression(LOWEST);
    if (self.peek_token_is(SEMICOLON)) self.next_token();
    return stmt;
}

fn ExpressionStatement* Parser.parse_expression_stmt(&self)
{
    ExpressionStatement* stmt = allocator::new(self.allocator, ExpressionStatement, { .token = self.cur }); 
    stmt.expression = self.parse_expression(LOWEST);
    while(self.peek_token_is(SEMICOLON)) self.next_token();
    return stmt;
}

fn Expression Parser.parse_expression(&self, Presendence presendence)
{
    if (try fn_parse_prefix = self.prefixes[self.cur.type]) {
        Expression left_expr = fn_parse_prefix(self);

        if (left_expr.type == Identifier.typeid && self.peek_token_is(L_BRACE)) {
            return self.parse_struct_literal((Identifier*) left_expr);
        }

        while(!self.peek_token_is(SEMICOLON) && presendence.ordinal < self.peek_presendence().ordinal) {
            if (try fn_parse_infix = self.infixes[self.peek.type]) {
                self.next_token();
                left_expr = fn_parse_infix(self, left_expr);
            } else {
                return left_expr;
            }
        }
        return left_expr;
    } 
    self.no_parse_prefix_error(self.cur.type);
    return null; 
}

fn Expression Parser.parse_identifier(&self)
{
    Identifier* ident = allocator::new(self.allocator, Identifier, {
        .token = self.cur, 
        .value = self.cur.literal,
    });
    return (Expression) ident;
}

fn Expression Parser.parse_int_literal(&self)
{
    ast::IntegerLiteral* i32 = allocator::new(self.allocator, ast::IntegerLiteral, {
        .token = self.cur, 
        .value = self.cur.literal.to_int()!!,
    });
    return (Expression) i32;
}

fn Expression Parser.parse_bool(&self)
{
    Bool* expr = allocator::new(self.allocator, Bool, {
        .token = self.cur,
        .value = self.cur_token_is(TRUE),
    });
    return (Expression) expr;
}

fn Expression Parser.parse_prefix_expression(&self)
{
    Prefix* prefix = allocator::new(self.allocator, Prefix, {
        .token = self.cur, 
        .operator = self.cur.literal,
    });
    self.next_token();
    prefix.right = self.parse_expression(PREFIX);
    return (Expression) prefix;
}

fn Expression Parser.parse_infix_expression(&self, Expression left_expr)
{
    if (DEBUG) io::printfn("parse_infix_expression");
    Infix* infix = allocator::new(self.allocator, Infix, {
        .token = self.cur, 
        .operator = self.cur.literal,
        .left = left_expr,
    });
    Presendence pres = self.cur_presendence();
    self.next_token();
    infix.right = self.parse_expression(pres);
    if (DEBUG) io::printfn("parse_infix_expression OK");
    return (Expression) infix;
}

fn Expression Parser.parse_call_expression(&self, Expression function)
{
    Call* call = allocator::new(self.allocator, Call, {
        .token = self.cur, 
        .function = function,
        .arguments = self.parse_expression_list(R_PAREN),
    });
    return (Expression) call;
}

fn Expression Parser.parse_index_expression(&self, Expression left)
{
    Index* index = allocator::new(self.allocator, Index, { .token = self.cur, .left = left });
    self.next_token();
    index.index = self.parse_expression(LOWEST);
    if (!self.expect_peek(R_BRACKET)) return null;
    return (Expression) index;
}

fn Expression Parser.parse_dot_expression(&self, Expression left)
{
    Dot* dot = allocator::new(self.allocator, Dot, { .token = self.cur, .left = left });
    if(!self.expect_peek(IDENTIFIER)) return null;
    dot.name = { self.cur, self.cur.literal };
    return (Expression) dot;
}

fn Expression Parser.parse_grouped_expression(&self)
{
    self.next_token();
    Expression expr = self.parse_expression(LOWEST);
    if (!self.expect_peek(R_PAREN)) return null;
    return expr;
}

fn Expression Parser.parse_if_expression(&self)
{
    If* expr = allocator::new(self.allocator, If, {
        .token = self.cur, 
    });
    if (!self.expect_peek(L_PAREN)) return null;
    self.next_token();
    expr.condition = self.parse_expression(LOWEST);
    if (!self.expect_peek(R_PAREN)) return null;
    if (!self.expect_peek(L_BRACE)) return null;
    expr.consequence = self.parse_block_statement();
    if (self.peek_token_is(ELSE)) {
        self.next_token();
        if (!self.expect_peek(L_BRACE)) return null;
        expr.alternative = self.parse_block_statement();
    }
    return (Expression) expr;
}

fn Expression Parser.parse_fn_expression(&self)
{
    Fn* expr = allocator::new(self.allocator, Fn, {
        .token = self.cur,
    });
    if (!self.expect_peek(L_PAREN)) return null;
    expr.parameters = self.parse_fn_parameters();
    if (!self.expect_peek(L_BRACE)) return null;
    expr.body = self.parse_block_statement();
    return (Expression) expr;
}

fn Expression Parser.parse_str_literal(&self)
{
    StringLiteral* expr = allocator::new(self.allocator, StringLiteral, {
        .token = self.cur,
        .value = self.cur.literal,
    });
    return (Expression) expr;
}

fn Expression Parser.parse_array_literal(&self)
{
    Array* expr = allocator::new(self.allocator, Array, {
        .token = self.cur,
        .elements = self.parse_expression_list(R_BRACKET),
    });
    return (Expression) expr;
}

fn Expression Parser.parse_hash_literal(&self)
{
    Token token = self.cur;
    map::HashMap{Expression, Expression} pairs;
    pairs.tinit();
    while(!self.peek_token_is(R_BRACE)) {
        self.next_token();
        Expression key = self.parse_expression(LOWEST);
        if (!self.expect_peek(COLON)) return null;
        self.next_token();
        Expression value = self.parse_expression(LOWEST);
        pairs[key] = value;
        if (!self.peek_token_is(R_BRACE) && !self.expect_peek(COMMA)) return null;
    }
    if (!self.expect_peek(R_BRACE)) return null;
    ast::HashMap* expr = allocator::new(self.allocator, ast::HashMap, {
        .token = token,
        .pairs = pairs,
    });
    return (Expression) expr;
}

fn Expression Parser.parse_macro_literal(&self)
{
    Macro* expr = allocator::new(self.allocator, Macro, {
        .token = self.cur,
    });
    if (!self.expect_peek(L_PAREN)) return null;
    expr.parameters = self.parse_fn_parameters();
    if (!self.expect_peek(L_BRACE)) return null;
    expr.body = self.parse_block_statement();
    return (Expression) expr;
}

fn List{Expression} Parser.parse_expression_list(&self, TokenType end)
{
    List{Expression} list;
    list.tinit();

    if (self.peek_token_is(end)) {
        self.next_token();
        return list;
    }

    self.next_token();
    list.push(self.parse_expression(LOWEST));

    while(self.peek_token_is(COMMA)) {
        self.next_token();
        self.next_token();
        list.push(self.parse_expression(LOWEST));
    }

    if (!self.expect_peek(end)) return {};
    return list;
}

fn List{Identifier} Parser.parse_fn_parameters(&self)
{
    List{Identifier} idents;
    idents.tinit();

    if (self.peek_token_is(R_PAREN)) {
        self.next_token();
        return idents;
    }

    self.next_token();

    idents.push(*(Identifier*) self.parse_identifier());

    while (self.peek_token_is(COMMA)) {
        self.next_token();
        self.next_token();
        idents.push(*(Identifier*) self.parse_identifier());
    }

    if (!self.expect_peek(R_PAREN)) return {};
    return idents;
}

fn Block* Parser.parse_block_statement(&self)
{
    Token token = self.cur;
    List{Statement} stmts;
    stmts.init(self.allocator);
    self.next_token();
    while(!self.cur_token_is(R_BRACE) && !self.cur_token_is(EOF)) {
        Statement stmt = self.parse_statement();
        if (stmt != null) stmts.push(stmt);
        self.next_token();
    }
    return allocator::new(self.allocator, Block, {
        .token = token,
        .statements = stmts,
    });
}

fn bool Parser.expect_peek(&self, TokenType type)
{
    if (self.peek_token_is(type)) {
        self.next_token();
        return true;
    }
    self.peek_error(type);
    return false;
}

fn Presendence Parser.peek_presendence(&self)
{
    if (try pres = self.presendences[self.peek.type]) return pres;
    return LOWEST;
}

fn Presendence Parser.cur_presendence(&self)
{
    if (try pres = self.presendences[self.cur.type]) return pres;
    return LOWEST;
}

fn bool Parser.peek_token_is(&self, TokenType type) => self.peek.type == type;
fn bool Parser.cur_token_is(&self, TokenType type) => self.cur.type == type;

fn void Parser.peek_error(&self, TokenType type)
{
    self.errors.push(string::tformat("expected next token to be %s, but got %s", type, self.peek.type));
}

fn void Parser.no_parse_prefix_error(&self, TokenType type)
{
    self.errors.push(string::tformat("no PrefixParse function for %s found", type.literal));
}

enum Presendence {
    LOWEST,
    EQUALS,       // ==
    LESS_GREATER, // > or <
    SUM,          // +
    PRODUCT,      // *
    PREFIX,       // -X or !X
    DOT,
    CALL,         // myFunction(X)
    INDEX,        // array[index]
}
