module ascii;

import std::io;
import std::collections::list;
import std::net;
import std::math::random;
import ast;

const String RESET_COLOR = "\x1b[0m";

fn String randomize(String str)
{
    return string::tformat("\x1b[38;2;%d;%d;%d;m%s%s", rand(150)+50, rand(150)+50, rand(150)+50, str, RESET_COLOR);
} 

struct AsciiNode
{
    List{String} lines;
    usz width;
    usz height;
    usz mid;
}

fn void print_expr_stmt(Program p)
{
    ExpressionStatement* stmt = (ExpressionStatement*) p.statements[0];
    io::printfn("%s\n%s", p, randomize(from_expr(stmt.expression)));
}

fn void print_logo(String name = "compiler", String version = "v0.1", bool linebreak = true)
{
    String header = colorize_chars(string::tformat("  __ %s", name));
    String footer = colorize_chars(string::tformat(`       \/ %s`, version));
    String logo = colorize_chars(string::tformat(
`_/  |_ ___.__.
\   __<   |  |
 |  |  \___  |
 |__|  / ____|`));
    io::printfn("%s", header);
    io::printfn("%s", logo);
    if (linebreak) {
        io::printfn("%s", footer);
    } else {
        io::printf("%s", footer);
    }
}

macro print_err(String message, ...)
{
    String e = string::tformat("%s: %s", colorize(RED, "ERROR"), message);
    io::printfn("%s", e, $vasplat);
}

fn String colorize_chars(String str)
{
    DString out;
    out.tinit();
    foreach(ch: str) {
        out.append(string::tformat("\x1b[38;2;%d;%d;%d;m%c%s", rand(150)+50, rand(150)+50, rand(150)+50, ch, RESET_COLOR));
    }
    return out.str_view();
} 

enum Color : (int r, int g, int b) {
    RED         = {180,  50,  70},   // #B43246 - Error
    ORANGE      = {220, 120,  40},   // #DC7828 - Warning
    GREEN       = { 80, 170,  80},   // #50AA50 - Success
    BLUE        = { 70, 130, 200},   // #4682C8 - Info
    GRAY        = {128, 128, 128},   // #808080 - Debug
    GOLD        = {200, 180,  60},   // #C8B43C - Prompt/Accent
    PURPLE      = {120,  60, 180},   // #783CB4 - Keyword
    PINK        = {255, 105, 180},   // #FF69B4 - File Path
}
macro colorize(Color color, input)
{
    return string::tformat("\x1b[38;2;%d;%d;%d;m%s%s", color.r, color.g, color.b, input, RESET_COLOR);
}

macro str(input, Color c = GREEN) => string::tformat("\x1b[38;2;%d;%d;%d;m'%s'%s", c.r, c.g, c.b, input, RESET_COLOR);

fn String from_expr(Expression expr)
{
    AsciiNode node = render(expr);
    return join(node.lines, "\n");
}

fn AsciiNode render(Expression expr)
{
    if (expr == null) return { .width = 7, .height = 1, .mid = 3 };
    String label;
    Expression left_expr = null;
    Expression right_expr = null;

    switch (expr.type) {
        case Identifier:
            label = ((Identifier*) expr).value;
        case ast::IntegerLiteral:
            label = string::tformat("%d", ((ast::IntegerLiteral*) expr).value);
        case Prefix:
            label = ((Prefix*) expr).operator;
            right_expr = ((Prefix*) expr).right;
        case Infix:
            label = ((Infix*) expr).operator;
            left_expr = ((Infix*) expr).left;
            right_expr = ((Infix*) expr).right;
        default:
            label = "<unknown>";
    }

    usz label_width = label.len;
    usz label_mid = label_width / 2;

    if (left_expr == null && right_expr == null) {
        List{String} lines;
        lines.tinit();
        lines.push(label);
        return {
            .lines = lines,
            .width = label_width,
            .height = 1,
            .mid = label_mid,
        };
    }

    if (expr.type == Prefix.typeid) {
        AsciiNode right = render(((Prefix*)expr).right);
        List{String} lines;
        lines.tinit();
        lines.push(label);
        lines.push(" \\");
        foreach (line: right.lines) lines.push(string::tformat("  %s", line));

        return {
            .lines = lines,
            .width = 2 + right.width,
            .height = lines.len(),
            .mid = label.len / 2,
        };
    }

    AsciiNode left = render(left_expr);
    AsciiNode right = render(right_expr);

    usz min_gap = 2;
    usz total_width = left.width + min_gap + right.width;
    usz root_pos = (total_width) / 2;
    List{String} lines;
    lines.tinit();
    lines.push(string::tformat("%*s%s", root_pos - label_mid, " ", label));

    if (left_expr != null && right_expr != null) {
        usz left_branch = root_pos - 1;
        usz right_branch = root_pos + 1;
        lines.push(string::tformat("%*s/%*s\\", left.mid, " ", right.mid + left.width - left.mid, " "));
    } else if (left_expr != null) {
        lines.push(string::tformat("%*s/", root_pos - 1, " "));
    } else if (right_expr != null) {
        lines.push(string::tformat("%*s\\", root_pos + 1, " "));
    }

    while (left.lines.len() < right.lines.len()) {
        left.lines.push(string::tformat("%*s", left.width, " "));
    }
    while (right.lines.len() < left.lines.len()) {
        right.lines.push(string::tformat("%*s", right.width, " "));
    }

    List{String} merged;
    merged.tinit();

    usz maxh = left.height > right.height ? left.height : right.height;
    for (int i = 0; i< maxh; i++) {
        String l = i < left.lines.len() ? left.lines[i] : string::tformat("%*s", left.width, " ");
        String r = i < right.lines.len() ? right.lines[i] : string::tformat("%*s", right.width, " ");
        merged.push(string::tformat("%-*s%*s", left.width, l, right.width + min_gap, r));
    }

    foreach (line: merged) lines.push(line);
    return {
        .lines = lines,
        .width = total_width,
        .height = lines.len(),
        .mid = root_pos,
    };
}

fn String join(List{String} parts, String delim)
{
    if (parts.len() == 0) return "";
    DString res;
    res.tinit();
    res.append(randomize(parts[0]));
    for (int i = 1; i < parts.len(); i++) {
        res.append(delim);
        res.append(randomize(parts[i]));
    }
    return res.str_view();
}

