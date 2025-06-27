#!/bin/bash

set -ex

c3c compile-run scripts/repl.c3 src/lexer.c3 src/parser.c3 src/ast.c3

