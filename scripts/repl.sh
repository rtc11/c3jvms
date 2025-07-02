#!/bin/bash

set -ex

c3c compile-run scripts/repl.c3 src/lexer.c3 src/parser.c3 src/ast.c3 src/evaluator.c3 src/object.c3 src/environment.c3 src/ascii.c3 src/builtins.c3

