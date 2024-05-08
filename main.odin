package main

import "core:fmt"
import "core:os"
import AST "./ast"
import Lexer "./lexer"
import Parser "./parser"
import Typechecker "./typechecker"


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
    if owk {
        fmt.println()
        fmt.println("AST: ")
        fmt.println(AST.expr_to_string(var, ""))
    } else { 
        fmt.println("Failed to parse")
        return
    }

    fmt.println("-----------------")
    fmt.println("#################")
    fmt.println("-----------------")

    // fmt.println("Typechecking")
    type_env := Typechecker.type_env_make()

    if Typechecker.type_checking_judgement(type_env, var) {
        fmt.println("TYPECHECKED")
        // fmt.println(var.type)
    } else {
        fmt.println("DID NOT TYPECHECK")
    }

    fmt.println("-----------------")
    fmt.println("#################")
    fmt.println("-----------------")

    fmt.println("RISC-V Assembly")

    program := AST.program_make()
    got_ir := AST.expr_to_ir_command(var, program, "t1")
    if got_ir {
        fmt.println(AST.program_to_string(program))
    } else {
        fmt.println("Failed to convert into IR")
    }
}
