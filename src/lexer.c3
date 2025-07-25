module lexer;

import std::io;
import std::collections::list;

struct Lexer
{
    char[] input;
    usz pos;
    char ch;
}

fn Lexer new(char[] input) { 
    Lexer l = {
        .input = input,
        .ch = '\0',
        .pos = 0,
    };
    l.read_char();
    return l;
}


fn bool Lexer.has_next(&self) => self.ch != '\0';
fn char Lexer.peek(&self) => self.input[self.pos];

fn Token Lexer.next(&self)
{
    self.skip_spaces();

    Token token;
    switch(self.ch)
    {
        case '{': token = { L_BRACE, "{" };
        case '}': token = { R_BRACE, "}" };
        case '(': token = { L_PAREN, "(" };
        case ')': token = { R_PAREN, ")" };
        case ';': token = { SEMICOLON, ";" };
        case ',': token = { COMMA, "," };
        case '.': token = { DOT, "." };
        case '!': 
            switch(self.peek()) {
                case '=':
                    token = { NEQ, "!=" };
                    self.read_char();
                default:
                    token = { BANG, "!" };
            }
        case '-': token = { MINUS, "-" };
        case '+': token = { PLUS, "+" };
        case '/': 
            if (self.peek() == '/') {
                self.skip_comment();
                return self.next();
            } else {
                token = { SLASH, "/" };
            }
        case '*': token = { ASTERISK, "*" };
        case '<': token = { LT, "<" };
        case '>': token = { GT, ">" };
        case '=': 
            switch (self.peek()) {
                case '=': 
                    token = { EQ, "==" };
                    self.read_char();
                default: token = { ASSIGN, "=" };
            }
        case '\'': token = { QUOTE, "\"" };
        case '"': token = { STR_LITERAL, self.read_string() };
        case '\0': token = { EOF, "" };
        case '[': token = { L_BRACKET, "[" };
        case ']': token = { R_BRACKET, "]" };
        case ':':
            switch (self.peek()) {
                // case ':':  
                //     token = { NAMESPACE, "::"};
                //     self.read_char();
                default: token = { COLON, ":" };
            }

        default:
            switch {
                case self.ch.is_alpha(): token = self.read_identifier();
                case self.ch.is_digit(): token = self.read_number();
                default: token = { ILLEGAL, string::tformat("%c", self.ch) };
            }
    }
    switch (token.type) {
        case FN:
        case LET: 
        case TRUE:
        case FALSE:
        case RETURN:
        case IF:
        case ELSE:
        case STR_LITERAL:
        case MACRO:
        case IDENTIFIER:
        case INT_LITERAL:
        case I32: 
        case STR:
            break; 
        default: self.read_char(); // needed for single-char tokens
    }
    return token;
}

fn void Lexer.skip_spaces(&self)
{
    while (self.ch.is_space()) {
        self.read_char();
    }
}

fn void Lexer.skip_comment(&self)
{
    while (self.ch != '\n' && self.ch != '\0') {
        self.read_char();
    }
}

fn void Lexer.read_char(&self)
{
    if (self.pos >= self.input.len) {
        self.ch = '\0';
    } else {
        self.ch = self.input[self.pos++];
    }
}

fn Token Lexer.read_number(&self)
{
    DString str;
    str.tinit();
    str.append(self.ch); // first is already a number

    self.read_char();
    while(self.ch.is_digit()) {
        str.append(self.ch);
        self.read_char();
    }

    return { INT_LITERAL, str.str_view() };
}

fn String Lexer.read_string(&self)
{
    DString str;
    str.tinit();
    // str.append(self.ch);

    self.read_char();
    while(self.ch != '"' && self.has_next()) {
        str.append(self.ch);
        self.read_char();
    }
    if (self.has_next()) { // get the ending quote
        // str.append(self.ch);
        self.read_char();
    }
    return str.str_view();
}

fn Token Lexer.read_identifier(&self)
{
    DString str;
    str.tinit();
    str.append(self.ch);

    self.read_char();
    while(self.ch.is_alnum() || self.ch == '_') {
        str.append(self.ch);
        self.read_char();
    }

    String identifier = str.str_view();

    switch (identifier)
    {
        case "fn": return {FN, identifier};  
        case "let": return {LET, identifier};  
        case "true": return {TRUE, identifier};  
        case "false": return {FALSE, identifier};  
        case "return": return {RETURN, identifier};  
        // case "::": return {NAMESPACE, identifier};  
        case "if": return {IF, identifier};  
        case "else": return {ELSE, identifier};  
        case "macro": return {MACRO, identifier};  
        case "i32": return {I32, identifier};  
        case "str": return {STR, identifier};  
        case "struct": return {STRUCT, identifier};  
        default: return {IDENTIFIER, identifier};
    }
}

struct Token
{
    TokenType type;
    String literal;
}

fn usz? Token.to_format(&self, Formatter* f) @dynamic => f.printf(" %-10s : %s", self.type, self.literal);

enum TokenType : (String literal) 
{
    EOF            = "",
    L_BRACE        = "{",
    R_BRACE        = "}",
    L_PAREN        = "(",
    R_PAREN        = ")",
    L_BRACKET      = "[",
    R_BRACKET      = "]",
    QUOTE          = "'",
    SEMICOLON      = ";",
    COLON          = ":",
    COMMA          = ",",
    DOT            = ".",

    MINUS          = "-",   // prefix/infix operator
    PLUS           = "+",   // infix operator
    ASTERISK       = "*",   // infix operator
    LT             = "<",   // infix operator
    GT             = ">",   // infix operator
    SLASH          = "/",   // infix operator
    BANG           = "!",   // prefix operator
    ASSIGN         = "=",

    EQ             = "==",
    NEQ            = "!=",

    LET            = "let",    // keyword 
    I32            = "i32",    // keyword 
    STR            = "str",    // keyword 
    STRUCT         = "struct", // keyword

    STR_LITERAL    = "",    // string literal like "hello"
    INT_LITERAL    = "",    // interger literal like 42

    FN             = "fn",
    IF             = "if",
    ELSE           = "else",
    TRUE           = "true",
    FALSE          = "false",
    // NAMESPACE      = "::",
    RETURN         = "return",
    MACRO          = "macro",
    IDENTIFIER     = "",
    ILLEGAL        = "",
}

