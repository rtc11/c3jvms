#!/bin/bash

set -ex

c3c compile-run scripts/repl.c3 src/lexer.c3 src/parser.c3 src/ast.c3 src/evaluator.c3 src/object.c3 src/environment.c3 src/ascii.c3 src/builtins.c3 src/quote_unquote.c3 src/macro.c3 src/modify.c3
# c3c compile-only scripts/repl.c3 src/lexer.c3 src/parser.c3 src/ast.c3 src/evaluator.c3 src/object.c3 src/environment.c3 src/ascii.c3 src/builtins.c3 src/quote_unquote.c3 src/macro.c3 src/modify.c3

