package parser

import "core:fmt"
import AST "../ast"
import Lexer "../lexer"

Parser :: struct {
    cursor      : u64,
    tk_advanced : u64,
    tokens      : [dynamic]Lexer.Token,
}

parser_make :: proc(l: ^Lexer.Lexer) -> (p: ^Parser) {
    p = new(Parser)
    p.tokens = l.tokens
    return
}

/*
        FIELDS  := 
                |   FIELD "=" E-1
                |   FIELD "=" E-1 ";" FIELDS
        MATCH_CASES :=
                    |   LABEL "{" VARIABLE "}" "-" ">" E-1
                    |   LABEL "{" VARIABLE "}" "-" ">" E-1 ";" MATCH_CASES
        ARGUMENTS   :=
                    |   VARIABLE ":" PRETYPE
                    |   VARIABLE ":" PRETYPE "," ARGUMENTS
        E1  :=
            |   "-" E1
            |   VALUE
            |   VARIABLE "." FIELD
            |   VARIABLE "(" FUN_PARAMS ")"
            |   VARIABLE
            |   "(" E ")"
            |   "{" E "}"
        E2  :=
            |   E1 "%" E2
            |   E1 "/" E2
            |   E1 "*" E2
            |   E1
        E3  :=
            |   E2 "+" E3
            |   E2 "-" E3
            |   E2
        E4  :=
            |   "max" "(" E4 "," E4 ")"
            |   "min" "("E4 "," E4 ")"
            |   "sqrt" "(" E4 ")"
            |   E3
        E5  :=
            |   E4 "<"  E4
            |   E4 ">"  E4
            |   E4 "="  E4
            |   E4 "<=" E4
            |   E4 ">=" E4
            |   E4
        E6  :=
            |   "not" E6
            |   E4
        E7  :=  E6 "or" E7
            |   E6
        E8  :=  E7 "and" E8
            |   E7
        E9  :=
            |   "readInt"   "("    ")"
            |   "readFloat" "("    ")"
            |   "print"     "(" E8 ")"
            |   "println"   "(" E8 ")"
            |   "assert"    "(" E8 ")"
            |   E8
        E10 :=
            |   VARIABLE "<" "-" E8
            |   VARIABLE "-" "=" E8
            |   VARIABLE "*" "=" E8
            |   VARIABLE "/" "=" E8
            |   VARIABLE "%" "=" E8
            |   E9
        E11 :=
            |   "if" E8 "then" E "else" E-1
            |   E10
        E12 :=
            |   "let" "mutable" VARIABLE ":" PRETYPE "=" E-1 ";" E
            |   "let"           VARIABLE ":" PRETYPE "=" E-1 ";" E
            |   E11
        E13 :=
            |   "type" VARIABLE "=" PRETYPE "; E
            |   E12
        E14 :=
            |   "while" E8 "do" E-1
            |   E13
        E15 :=
            |   "do" E-1 "while" E8
            |   E14
        E16 :=
            |   "for" "(" E "," E8 "," E ")" "{" E "}"
            |   E15
        E17 :=
            |   "struct" "{" FIELDS "}"
            |   E16
        E18 :=
            |   LABEL "{" E "}"
            |   E17
        E19 :=
            |   "match" E "with" "{" MATCH_CASES "}"
            |   E18
        E20 :=
            |   "fun" VARIABLE "(" ARGUMENTS ")" ":" PRETYPE "=" E-1 ";" E
            |   E19
        E21 :=
            |   "fun" "(" ARGUMENTS ")" "-" ">" E
            |   E20
        E22 :=
            |   E21 ":" PRETYPE
            |   E21
        E   :=  E23 | E23 ";" E
    */

PARSER_TRACING :: false

parse_E :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E")}
    e1 := parse_E_minus(p) or_return
    tk, got_tk := get_tk(p)
    if got_tk && tk.kind == .Semi_Colon {
         p.tk_advanced += 1
         e2 := parse_E(p) or_return

         expr = AST.sequence_make(e1, e2)
         return expr, true
    }
    return e1, true
}

parse_E_minus :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    return parse_E22(p)
}

parse_E22 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E22")}
    e1 := parse_E21(p) or_return

    tk, got_tk := get_tk(p)
    if got_tk && tk.kind == .Colon {
        p.tk_advanced += 1
        pt := parse_pretype(p) or_return

        expr = AST.type_ascription_make(e1, pt)
        return expr, true
    }
    return e1, true
}

parse_fun_decl_params :: proc(p: ^Parser, params: ^map[string]^AST.Pretype) -> (ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind == .Right_Par { return true }

    param := parse_ident(p) or_return

    tk = get_tk(p) or_return
    if tk.kind != .Colon { p.tk_advanced -= 1; return }
    p.tk_advanced += 1

    pt := parse_pretype(p) or_return

    params[param] = pt

    tk = get_tk(p) or_return
    if tk.kind == .Comma {
        p.tk_advanced += 1
        return parse_fun_decl_params(p, params)
    }
    return true 
}

parse_E21 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E21")}
    tk := get_tk(p) or_return

    if tk.kind == .Fun {
        p.tk_advanced += 1

        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced -= 1; return parse_E20(p)}
        p.tk_advanced += 1

        params := make(map[string]^AST.Pretype)
        parse_fun_decl_params(p, &params) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        tk = get_tk(p) or_return
        if tk.kind != .Minus { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        tk = get_tk(p) or_return
        if tk.kind != .Greater { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        e1 := parse_E_minus(p) or_return

        expr = AST.fun_decl_make(params, e1)
        return expr, true
    }

    return parse_E20(p)
}

parse_E20 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E20")}
    tk := get_tk(p) or_return

    if tk.kind == .Fun {
        fun_name := ""
        p.tk_advanced += 1

        tk = get_tk(p) or_return
        if tk.kind == .Ident {
            fun_name = tk.payload.(string)
            p.tk_advanced += 1
        }
        
        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        params := make(map[string]^AST.Pretype)
        parse_fun_decl_params(p, &params) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        tk = get_tk(p) or_return
        if tk.kind != .Colon { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        pt := parse_pretype(p) or_return
        
        tk = get_tk(p) or_return
        if tk.kind != .Eq { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        e1_e1 := parse_E_minus(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Semi_Colon { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        e2 := parse_E(p) or_return

        e1 := AST.fun_decl_make(params, e1_e1)
        expr = AST.let_make(false, fun_name, pt, e1, e2)
        return expr, true
    }

    return parse_E19(p)
}

parse_fun_app_params :: proc(p: ^Parser, params: ^[dynamic]^AST.Expr) -> (ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind == .Right_Par { return true }

    e := parse_E(p) or_return
    append_elem(params, e)

    tk = get_tk(p) or_return
    if tk.kind == .Right_Par { return true }

    if tk.kind == .Comma {
        p.tk_advanced += 1
        return parse_fun_app_params(p, params)
    }
    return true 
}

parse_match_patterns :: proc(p: ^Parser, patterns: ^map[AST.Match_Pattern]^AST.Expr) -> (ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind == .Right_Cur { return true }

    label := parse_ident(p) or_return

    tk = get_tk(p) or_return
    if tk.kind != .Left_Cur { p.tk_advanced -= 1; return }
    p.tk_advanced += 1

    var := parse_ident(p) or_return

    tk = get_tk(p) or_return
    if tk.kind != .Right_Cur { p.tk_advanced -= 1; return }
    p.tk_advanced += 1

    tk = get_tk(p) or_return
    if tk.kind != .Minus { p.tk_advanced -= 1; return }
    p.tk_advanced += 1

    tk = get_tk(p) or_return
    if tk.kind != .Greater { p.tk_advanced -= 1; return }
    p.tk_advanced += 1

    e1 := parse_E_minus(p) or_return

    match_pattern := AST.Match_Pattern { label, var }
    patterns[match_pattern] = e1

    tk = get_tk(p) or_return
    if tk.kind == .Semi_Colon {
        p.tk_advanced += 1
        return parse_match_patterns(p, patterns)
    }
    return true 
}

parse_E19 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E19")}
    tk := get_tk(p) or_return

    if tk.kind == .Match {
        p.tk_advanced += 1

        e1 := parse_E(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .With { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        tk = get_tk(p) or_return
        if tk.kind != .Left_Cur { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        patterns := make(map[AST.Match_Pattern]^AST.Expr)
        parse_match_patterns(p, &patterns) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Cur { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        expr = AST.match_cases_make(e1, patterns)
        return expr, true
    }

    return parse_E18(p)
}

parse_E18 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E18")}
    tk, got_tk := get_tk(p)

    if got_tk && tk.kind == .Ident {
        p.tk_advanced += 1
        label := tk.payload.(string)

        tk, got_tk = get_tk(p)
        if !got_tk || tk.kind != .Left_Cur { p.tk_advanced -= 1; return parse_E17(p)}
        p.tk_advanced += 1

        e1, e1_parsed := parse_E(p)
        if !e1_parsed { p.tk_advanced -= 2; return parse_E17(p) }

        tk = get_tk(p) or_return
        if tk.kind != .Right_Cur { p.tk_advanced = p.cursor; return parse_E17(p) }
        p.tk_advanced += 1

        expr = AST.union_constructor_make(label, e1)
        return expr, true
    }

    return parse_E17(p)
}

parse_fields :: proc(p: ^Parser, fields: ^map[string]^AST.Expr) -> (ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind == .Right_Cur { return true }

    field := parse_ident(p) or_return

    tk = get_tk(p) or_return
    if tk.kind != .Eq { p.tk_advanced -= 1; return }
    p.tk_advanced += 1

    e := parse_E_minus(p) or_return

    fields[field] = e

    tk = get_tk(p) or_return
    if tk.kind == .Semi_Colon {
        p.tk_advanced += 1
        return parse_fields(p, fields)
    }
    return true 
}

parse_E17 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E17")}
    tk := get_tk(p) or_return

    if tk.kind == .Struct {
        p.tk_advanced += 1

        tk = get_tk(p) or_return
        if tk.kind != .Left_Cur { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        fields := make(map[string]^AST.Expr) 
        parse_fields(p, &fields) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Cur { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        expr = AST.struct_make(fields)
        return expr, true
    }

    return parse_E16(p)
}

parse_E16 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E16")}
    tk := get_tk(p) or_return

    if tk.kind == .For {
        p.tk_advanced += 1

        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        e1 := parse_E_minus(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Comma { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        e2_e1 := parse_E8(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Comma { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        e2_e2_e2 := parse_E(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        e2_e2_e1 := parse_E_minus(p) or_return

        e2_e2 := AST.sequence_make(e2_e2_e1, e2_e2_e2)
        e2_e2_r := AST.scope_make(e2_e2)
        e2 := AST.while_make(e2_e1, e2_e2_r)

        expr = AST.sequence_make(e1, e2)
        return expr, true
    }

    return parse_E15(p)
}

parse_E15 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E15")}
    tk := get_tk(p) or_return

    if tk.kind == .Do {
        p.tk_advanced += 1

        e1 := parse_E_minus(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .While { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        e2_e1 := parse_E8(p) or_return

        e2 := AST.while_make(e2_e1, e1)

        expr = AST.sequence_make(e1, e2)
        return expr, true
    }

    return parse_E14(p)
}

parse_E14 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E14")}
    tk := get_tk(p) or_return

    if tk.kind == .While {
        p.tk_advanced += 1

        e1 := parse_E8(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Do { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        e2 := parse_E_minus(p) or_return

        expr = AST.while_make(e1, e2)
        return expr, true
    }

    return parse_E13(p)
}

parse_E13 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E13")}
    tk := get_tk(p) or_return

    if tk.kind == .Type {
        p.tk_advanced += 1

        x := parse_ident(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Eq { 
            p.tk_advanced -= 2
            return
        }
        p.tk_advanced += 1

        pt := parse_pretype(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Semi_Colon { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        e1 := parse_E(p) or_return

        expr = AST.type_decl_make(x, pt, e1)
        return expr, true
    }

    return parse_E12(p)
}

parse_E12 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E12")}
    tk := get_tk(p) or_return

    if tk.kind == .Let {
        p.tk_advanced += 1
        is_mut := false

        tk = get_tk(p) or_return
        if tk.kind == .Mutable {
            is_mut = true
            p.tk_advanced += 1
        }

        x := parse_ident(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Colon { 
            if is_mut { p.tk_advanced -= 1 }
            p.tk_advanced -= 2
            return
        }
        p.tk_advanced += 1

        pt := parse_pretype(p) or_return
        // fmt.println(AST.pretype_to_string(pt))

        tk = get_tk(p) or_return
        if tk.kind != .Eq { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        e1 := parse_E_minus(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Semi_Colon { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        e2 := parse_E(p) or_return
        expr = AST.let_make(is_mut, x, pt, e1, e2)
        return expr, true
    }

    return parse_E11(p)
}

parse_E11 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E11")}
    tk := get_tk(p) or_return

    if tk.kind == .If {
        p.tk_advanced += 1
        e1, e1_parsed := parse_E8(p)
        if !e1_parsed { p.tk_advanced -= 1; return }

        tk = get_tk(p) or_return
        if tk.kind != .Then { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        e2, e2_parsed := parse_E(p)
        if !e2_parsed { p.tk_advanced = p.cursor; return }

        tk = get_tk(p) or_return
        if tk.kind != .Else { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        e3, e3_parsed := parse_E_minus(p)
        if !e3_parsed { p.tk_advanced = p.cursor; return }

        expr = AST.if_else_make(e1, e2, e3)
        return expr, true
    }

    return parse_E10(p)
}

parse_E10 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E10")}
    x, x_parsed := parse_ident(p)
    if x_parsed {
        tk, got_tk := get_tk(p)
        if !got_tk { expr = AST.variable_make(x); return expr, true }

        if tk.kind == .Less {
            p.tk_advanced += 1
            tk, got_tk := get_tk(p)
            if !got_tk || tk.kind != .Minus { p.tk_advanced -= 2; return parse_E9(p) }
            p.tk_advanced += 1

            e1 := parse_E8(p) or_return

            expr = AST.assignment_make(x, e1)
            return expr, true
        }

        if tk.kind == .Plus {
            p.tk_advanced += 1
            tk, got_tk := get_tk(p)
            if !got_tk || tk.kind != .Eq { p.tk_advanced -= 2; return parse_E9(p) }
            p.tk_advanced += 1

            e1_e2 := parse_E8(p) or_return

            e1_e1 := AST.variable_make(x)

            e1 := AST.binary_make(.Plus, e1_e1, e1_e2)

            expr = AST.assignment_make(x, e1)
            return expr, true
        }

        if tk.kind == .Minus {
            p.tk_advanced += 1
            tk, got_tk := get_tk(p)
            if !got_tk || tk.kind != .Eq { p.tk_advanced -= 2; return parse_E9(p) }
            p.tk_advanced += 1

            e1_e2 := parse_E8(p) or_return

            e1_e1 := AST.variable_make(x)

            e1 := AST.binary_make(.Minus, e1_e1, e1_e2)
            expr = AST.assignment_make(x, e1)
            return expr, true
        }

        if tk.kind == .Times {
            p.tk_advanced += 1
            tk, got_tk := get_tk(p)
            if !got_tk || tk.kind != .Eq { p.tk_advanced -= 2; return parse_E9(p) }
            p.tk_advanced += 1

            e1_e2 := parse_E8(p) or_return

            e1_e1 := AST.variable_make(x)

            e1 := AST.binary_make(.Times, e1_e1, e1_e2)
            expr = AST.assignment_make(x, e1)
            return expr, true
        }

        if tk.kind == .Div {
            p.tk_advanced += 1
            tk, got_tk := get_tk(p)
            if !got_tk || tk.kind != .Eq { p.tk_advanced -= 2; return parse_E9(p) }
            p.tk_advanced += 1

            e1_e2 := parse_E8(p) or_return

            e1_e1 := AST.variable_make(x)

            e1 := AST.binary_make(.Divide, e1_e1, e1_e2)
            expr = AST.assignment_make(x, e1)
            return expr, true
        }
        p.tk_advanced -= 1
    }
    return parse_E9(p)
}

parse_E9 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E9")}
    tk, got_tk := get_tk(p)

    if got_tk && tk.kind == .Read_Float {
        p.tk_advanced += 1
        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { return }
        p.tk_advanced += 1

        expr = AST.unary_make(.Read_Float, nil)
        return expr, true
    }
    if got_tk && tk.kind == .Read_Int {
        p.tk_advanced += 1
        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { return }
        p.tk_advanced += 1

        expr = AST.unary_make(.Read_Int, nil)
        return expr, true
    }
    if got_tk && tk.kind == .Print {
        p.tk_advanced += 1
        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        e1 := parse_E8(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { return }
        p.tk_advanced += 1

        expr = AST.unary_make(.Print, e1)
        return expr, true
    }

    if got_tk && tk.kind == .PrintLn {
        p.tk_advanced += 1
        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        e1 := parse_E8(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { return }
        p.tk_advanced += 1

        expr = AST.unary_make(.Println, e1)
        return expr, true
    }

    if got_tk && tk.kind == .Assert {
        p.tk_advanced += 1
        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        e1 := parse_E8(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { return }
        p.tk_advanced += 1

        expr = AST.unary_make(.Assert, e1)
        return expr, true
    }

    return parse_E8(p)
}

parse_E8 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E8")}
    e1 := parse_E7(p) or_return

    tk, got_tk := get_tk(p)
    if !got_tk { return e1, true }

    if tk.kind == .And {
        p.tk_advanced += 1
        e2, e2_parsed := parse_E7(p)
        if !e2_parsed { p.tk_advanced -= 1; return }

        expr = AST.binary_make(.And, e1, e2)
        return expr, true
    }
    return e1, true
}

parse_E7 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E7")}
    e1 := parse_E6(p) or_return

    tk, got_tk := get_tk(p)
    if !got_tk { return e1, true }

    if tk.kind == .Or {
        p.tk_advanced += 1
        e2, e2_parsed := parse_E7(p)
        if !e2_parsed { p.tk_advanced -= 1; return }

        expr = AST.binary_make(.Or, e1, e2)
        return expr, true
    }
    return e1, true
}

parse_E6 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E6")}
    tk := get_tk(p) or_return
    if tk.kind == .Not {
        p.tk_advanced += 1

        e1 := parse_E6(p) or_return

        expr = AST.unary_make(.Not, e1)
        return expr, true
    }
    return parse_E5(p)
}

parse_E5 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E5")}
    e1 := parse_E4(p) or_return

    tk, got_tk := get_tk(p)
    if !got_tk { return e1, true }

    if tk.kind == .Less {
        op : AST.Binary_Op = .Less
        p.tk_advanced += 1

        tk, got_tk = get_tk(p)
        if got_tk && tk.kind == .Eq {
            p.tk_advanced += 1
            op = .Less_Equals
        }

        e2, e2_parsed := parse_E4(p)
        if !e2_parsed { p.tk_advanced -= 1; return }
        
        expr = AST.binary_make(op, e1, e2)
        return expr, true
    }

    if tk.kind == .Greater {
        op : AST.Binary_Op = .Greater
        p.tk_advanced += 1

        tk, got_tk = get_tk(p)
        if got_tk && tk.kind == .Eq {
            p.tk_advanced += 1
            op = .Greater_Equals
        }

        e2, e2_parsed := parse_E4(p)
        if !e2_parsed { p.tk_advanced -= 1; return }
        expr = AST.binary_make(.Greater, e1, e2)
        return expr, true
    }

    if tk.kind == .Eq {
        p.tk_advanced += 1
        e2, e2_parsed := parse_E4(p)
        if !e2_parsed { p.tk_advanced -= 1; return }
        
        expr = AST.binary_make(.Equals, e1, e2)
        return expr, true
    }

    return e1, true
}

parse_E4 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E4")}
    tk, got_tk := get_tk(p)

    if got_tk && tk.kind == .Max {
        p.tk_advanced += 1
        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        e1 := parse_E4(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Comma { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        e2 := parse_E4(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { return }
        p.tk_advanced += 1

        expr = AST.binary_make(.Max, e1, e2)
        return expr, true
    }

    if got_tk && tk.kind == .Min {
        p.tk_advanced += 1
        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        e1 := parse_E4(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Comma { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        e2 := parse_E4(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { return }
        p.tk_advanced += 1

        expr = AST.binary_make(.Min, e1, e2)
        return expr, true
    }

    if got_tk && tk.kind == .Sqrt {
        p.tk_advanced += 1
        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        e1 := parse_E4(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { return }
        p.tk_advanced += 1

        expr = AST.unary_make(.Sqrt, e1)
        return expr, true
    }
    return parse_E3(p)
}

parse_E3 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E3")}
    e1 := parse_E2(p) or_return

    tk, got_tk := get_tk(p)
    if !got_tk { return e1, true }

    if tk.kind == .Plus {
        p.tk_advanced += 1
        e2, e2_parsed := parse_E3(p)
        if !e2_parsed { p.tk_advanced -= 1; return }
        expr = AST.binary_make(.Plus, e1, e2)
        return expr, true
    }

    if tk.kind == .Minus {
        p.tk_advanced += 1
        e2, e2_parsed := parse_E3(p)
        if !e2_parsed { p.tk_advanced -= 1; return }
        expr = AST.binary_make(.Minus, e1, e2)
        return expr, true
    }
    return e1, true
}

parse_E2 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E2")}
    e1 := parse_E1(p) or_return

    tk, got_tk := get_tk(p)
    if !got_tk { return e1, true }

    if tk.kind == .Mod {
        p.tk_advanced += 1
        e2, e2_parsed := parse_E2(p)
        if !e2_parsed { p.tk_advanced -= 1; return }
        expr = AST.binary_make(.Modulus, e1, e2)
        return expr, true
    }

    if tk.kind == .Times {
        p.tk_advanced += 1
        e2, e2_parsed := parse_E2(p)
        if !e2_parsed { p.tk_advanced -= 1; return }
        expr = AST.binary_make(.Times, e1, e2)
        return expr, true
    }

    if tk.kind == .Div {
        p.tk_advanced += 1
        e2, e2_parsed := parse_E2(p)
        if !e2_parsed { p.tk_advanced -= 1; return }
        expr = AST.binary_make(.Divide, e1, e2)
        return expr, true
    }

    return e1, true
}

parse_E1 :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING RULE E1")}
    expr, ok = parse_value(p)
    if ok { return }

    expr, ok = parse_variable(p)

    tk, got_tk := get_tk(p)
    if ok {
        if got_tk && tk.kind == .Left_Par {
            p.tk_advanced += 1
            tk, got_tk = get_tk(p)

            params := make([dynamic]^AST.Expr)
            parse_fun_app_params(p, &params) or_return

            tk = get_tk(p) or_return
            if tk.kind != .Right_Par { p.tk_advanced = p.cursor; return }
            p.tk_advanced += 1

            expr = AST.fun_app_make(expr, params)
            return expr, true
        }

        if got_tk && tk.kind == .Period {
            p.tk_advanced += 1
            field, got_field := parse_ident(p)
            if !got_field { p.tk_advanced -= 1; return }
            expr = AST.field_access_make(expr.(AST.Variable).x, field)
            return expr, true
        }
    }

    if got_tk && tk.kind == .Minus {
        p.tk_advanced += 1
        e1, e1_parsed := parse_E1(p)
        if !e1_parsed { p.tk_advanced -= 1; return }
        expr = AST.unary_make(.U_Minus, e1)
        return expr, true
    }

    if got_tk && tk.kind == .Left_Par {
        p.tk_advanced += 1
        e1 := parse_E(p) or_return
        tk, got_tk = get_tk(p)
        if !got_tk || tk.kind != .Right_Par { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1
        expr = AST.parens_make(e1)
        return expr, true
    }

    if got_tk && tk.kind == .Left_Cur {
        p.tk_advanced += 1

        e1 := parse_E(p) or_return

        tk, got_tk = get_tk(p)
        if !got_tk || tk.kind != .Right_Cur { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1
        expr = AST.scope_make(e1)
        return expr, true
    }
    return
}

parse_variable :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind == .Ident {
        expr = AST.variable_make(tk.payload.(string))
        p.tk_advanced += 1
        return expr, true
    }
    return expr, true
}

parse_ident :: proc(p: ^Parser) -> (s: string, ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind == .Ident {
        s = tk.payload.(string)
        p.tk_advanced += 1
        return s, true
    }
    return
}

parse_value :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    tk := get_tk(p) or_return

    type: AST.Value_Type
    payload: AST.Value_Payload
    #partial switch tk.kind {
        case .True:
            type = .Bool
            payload = true
        case .False:
            type = .Bool
            payload = false
        case .Int:
            type = .Int
            payload = tk.payload.(int)
        case .Float:
            type = .Float
            payload = tk.payload.(f64)
        case .Left_Par:
            p.tk_advanced += 1
            tk = get_tk(p) or_return
            if tk.kind != .Right_Par { p.tk_advanced -= 1; return }
            type = .Unit
        case .String_Lit:
            type = .String
            payload = tk.payload.(string)
        case: return
    }
    p.tk_advanced += 1

    expr = AST.value_make(type, payload)

    return expr, true
}

get_tk :: proc(p: ^Parser) -> (tk: Lexer.Token, ok: bool) {
    if p.tk_advanced >= u64(len(p.tokens)) { return }
    return p.tokens[p.tk_advanced], true
}
