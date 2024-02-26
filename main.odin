package main

import "core:fmt"
import "core:os"
import AST "./ast"
import Lexer "./lexer"
import Parser "./parser"

main :: proc() {
    fmt.println("Hello, World!")

    file_path :: "input.hyg"
    data, ok := os.read_entire_file(file_path)
    if !ok { fmt.eprintf("ERROR: Couldn't read file - %s\n", file_path); return }

    fmt.println("Source: ")
    fmt.println(string(data))
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
        // fmt.println(AST.pretype_to_string(var))
        fmt.println(AST.expr_to_string(var, ""))
        // fmt.println(var.expr)
    }


}
