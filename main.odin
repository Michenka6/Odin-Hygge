package main

import AST "./ast"
import Lexer "./lexer"
import Parser "./parser"
import Typechecker "./typechecker"
import "core:fmt"
import "core:os"

main :: proc() {
    file_path :: "input.hyg"
    data, ok := os.read_entire_file(file_path)
    if !ok { fmt.eprintf("ERROR: Couldn't read file - %s\n", file_path); return }

    fmt.println("Source: ")
    // fmt.println(string(data))
    // fmt.println(data)

    lexer := Lexer.lexer_make(data)
    defer Lexer.lexer_delete(lexer)

    Lexer.tokenize(lexer)
    // fmt.println(lexer.tokens)

    p := Parser.parser_make(lexer)
    var, owk := Parser.parse_E(p)
    if owk {
        fmt.println()
        fmt.println("AST: ")
        fmt.println(AST.expr_to_string(var, ""))

        fmt.println("----------")
        env := Typechecker.type_env_make()
        t, t_ok := Typechecker.type_checking_judgement(env, var)
        fmt.printf("Typechecker - %v\n", t_ok)
        fmt.printf("Typechecked to %v\n", t)

        // AST.propogate_pretype_subst("", nil, var)
        // fmt.println(AST.expr_to_string(var, ""))
        // AST.expr_subst("x", expr, var) 
        // fmt.println(AST.expr_to_string(var, ""))
    }
}
