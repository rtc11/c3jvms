module ascii;

import std::io;
import std::collections::list;
import std::net;
import std::math::random;
import ast;

const String RESET_COLOR = "\x1b[0m";
alias Color = int[3];

fn String colorize(String str) {
    Color color = { rand(150)+50, rand(150)+50,rand(150)+50 };
    return string::tformat("\x1b[38;2;%d;%d;%d;m%s%s", color[0], color[1], color[2], str, RESET_COLOR);
} 

struct AsciiNode {
    List{String} lines;
    usz width;
    usz height;
    usz mid;
}

fn void print_expr_stmt(Program p) {
    ExpressionStatement* stmt = (ExpressionStatement*) p.statements[0];
    io::printfn("%s\n%s", p, colorize(from_expr(stmt.expression)));
}

fn String colorize_red(String str) {
    return string::tformat("\x1b[38;2;%d;%d;%d;m%s%s", 220, 20, 60, str, RESET_COLOR);
}

fn String from_expr(Expression expr) {
    AsciiNode node = render(expr);
    return join(node.lines, "\n");
}

fn AsciiNode render(Expression expr) {
    if (expr == null) return { .width = 7, .height = 1, .mid = 3 };
    String label;
    Expression left_expr = null;
    Expression right_expr = null;

    switch (expr.type) {
        case Identifier:
            label = ((Identifier*) expr).value;
        case ast::Int32:
            label = string::tformat("%d", ((ast::Int32*) expr).value);
        case PrefixExpression:
            label = ((PrefixExpression*) expr).operator;
            right_expr = ((PrefixExpression*) expr).right;
        case InfixExpression:
            label = ((InfixExpression*) expr).operator;
            left_expr = ((InfixExpression*) expr).left;
            right_expr = ((InfixExpression*) expr).right;
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

    if (expr.type == PrefixExpression.typeid) {
        AsciiNode right = render(((PrefixExpression*)expr).right);
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

fn String join(List{String} parts, String delim) {
    if (parts.len() == 0) return "";
    DString res;
    res.tinit();
    res.append(colorize(parts[0]));
    for (int i = 1; i < parts.len(); i++) {
        res.append(delim);
        res.append(colorize(parts[i]));
    }
    return res.str_view();
}

