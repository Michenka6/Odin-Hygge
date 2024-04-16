package main

import "core:fmt"
import "core:os"
import AST "./ast"
import Lexer "./lexer"
import Parser "./parser"
import Typechecker "./typechecker"
import Simplifier "./semantic_simplifier"
import Interpreter "./interpreter"
import Code_Generator "./code_generator"


/*
    SOURCE_CODE
    |> Lexer        ==> Token Stream ([dynamic]Token)
    |> Parser       ==> AST.Expr
    |> Typechecker  ==> Primary Type (T)
    |> Simplifier   ==> AST.IR
        ||> Interpreter    ==> Intepreting IR
        ||> Code_Generator ==> RISC-V Assembly
*/

main :: proc() {
    file_path :: "input.hyg"
    data, ok := os.read_entire_file(file_path)
    if !ok { fmt.eprintf("ERROR: Couldn't read file - %s\n", file_path); return }

    fmt.println("Source: ")
    fmt.println(string(data))

    var, owk := Parser.parse_src(data)
    // if false {
    if owk {
    // if Parser.parse_H(p, &fields) {
        fmt.println()
        fmt.println("AST: ")
        // fmt.println(fields)
        fmt.println(AST.expr_to_string(var, ""))
    //
    //     // fmt.println("----------")
    //     // env := Typechecker.type_env_make()
    //     // t, t_ok := Typechecker.type_checking_judgement(env, var)
    //     // fmt.printf("Typechecker - %v\n", t_ok)
    //     // fmt.printf("Typechecked to %v\n", t)
    //
    //     // AST.propogate_pretype_subst("", nil, var)
    //     // fmt.println(AST.expr_to_string(var, ""))
    //     // AST.expr_subst("x", expr, var) 
    //     // fmt.println(AST.expr_to_string(var, ""))
    }
}
