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
                |   FIELD "=" E8
                |   FIELD "=" E8 ";" FIELDS
        MATCH_CASES :=
                    |   LABEL "{" VARIABLE "}" "-" ">" E-1
                    |   LABEL "{" VARIABLE "}" "-" ">" E-1 ";" MATCH_CASES
        E1  :=
            |   "-" E1
            |   VALUE
            |   VARIABLE "." FIELD
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
            |   VARIABLE "(" FUN_PARAMS ")"
            |   E19




        E16 :=
            |   E10 ":" PRETYPE

        "fun" VARIABLE "(" ARGUMENTS ")" "-" ">" E
        "fun" "(" ARGUMENTS ")" "-" ">" E

            |   E15

        E   :=  E12 | E12 ";" E
    */

parse_E :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    e1 := parse_E_minus(p) or_return
    tk, got_tk := get_tk(p)
    if got_tk && tk.kind == .Semi_Colon {
         p.tk_advanced += 1
         e2 := parse_E(p) or_return

         node = AST.sequence_make(e1, e2)
         return node, true
    }
    return e1, true
}

parse_E_minus :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    return parse_E19(p)
}

parse_fun_app_params :: proc(p: ^Parser, params: ^[dynamic]^AST.Node) -> (ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind == .Right_Par { return true }

    e := parse_E8(p) or_return
    append_elem(params, e)

    tk = get_tk(p) or_return
    if tk.kind == .Right_Par { return true }

    if tk.kind == .Comma {
        p.tk_advanced += 1
        return parse_fun_app_params(p, params)
    }
    return true 
}

parse_E20 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    tk, got_tk := get_tk(p)

    if got_tk && tk.kind == .Ident {
        pos := tk.pos
        p.tk_advanced += 1
        fun_name := tk.payload.(string)

        tk, got_tk = get_tk(p)
        if !got_tk || tk.kind != .Left_Par { p.tk_advanced -= 1; return parse_E19(p)}
        p.tk_advanced += 1

        params := make([dynamic]^AST.Node)
        parse_fun_app_params(p, &params) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        node = AST.fun_app_make(fun_name, params)
        node.pos = pos
        return node, true
    }

    return parse_E19(p)
}

parse_match_patterns :: proc(p: ^Parser, patterns: ^map[AST.Match_Pattern]^AST.Node) -> (ok: bool) {
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

parse_E19 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    tk := get_tk(p) or_return

    if tk.kind == .Match {
        pos := tk.pos
        p.tk_advanced += 1

        e1 := parse_E(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .With { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1
        fmt.println(AST.node_to_string(e1, ""))

        tk = get_tk(p) or_return
        if tk.kind != .Left_Cur { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        patterns := make(map[AST.Match_Pattern]^AST.Node)
        parse_match_patterns(p, &patterns) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Cur { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        node = AST.match_cases_make(e1, patterns)
        node.pos = pos
        return node, true
    }

    return parse_E18(p)
}

parse_E18 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    tk, got_tk := get_tk(p)

    if got_tk && tk.kind == .Ident {
        pos := tk.pos
        p.tk_advanced += 1
        label := tk.payload.(string)

        tk, got_tk = get_tk(p)
        if !got_tk || tk.kind != .Left_Cur { p.tk_advanced -= 1; return parse_E17(p)}
        p.tk_advanced += 1

        e1, e1_parsed := parse_E8(p)
        // fmt.println(AST.node_to_string(e1, ""))
        if !e1_parsed { p.tk_advanced -= 2; return parse_E17(p) }

        tk = get_tk(p) or_return
        if tk.kind != .Right_Cur { p.tk_advanced = p.cursor; return parse_E17(p) }
        p.tk_advanced += 1

        node = AST.union_constructor_make(label, e1)
        node.pos = pos
        return node, true
    }

    return parse_E17(p)
}

parse_fields :: proc(p: ^Parser, fields: ^map[string]^AST.Node) -> (ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind == .Right_Cur { return true }

    field := parse_ident(p) or_return

    tk = get_tk(p) or_return
    if tk.kind != .Eq { p.tk_advanced -= 1; return }
    p.tk_advanced += 1

    e := parse_E8(p) or_return

    fields[field] = e

    tk = get_tk(p) or_return
    if tk.kind == .Semi_Colon {
        p.tk_advanced += 1
        return parse_fields(p, fields)
    }
    return true 
}

parse_E17 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    tk := get_tk(p) or_return

    if tk.kind == .Struct {
        pos := tk.pos
        p.tk_advanced += 1

        tk = get_tk(p) or_return
        if tk.kind != .Left_Cur { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        fields := make(map[string]^AST.Node) 
        parse_fields(p, &fields) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Cur { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        node = AST.struct_make(fields)
        node.pos = pos
        return node, true
    }

    return parse_E16(p)
}

parse_E16 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    tk := get_tk(p) or_return

    if tk.kind == .For {
        pos := tk.pos
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
        e2 := AST.while_make(e2_e1, e2_e2)

        node = AST.sequence_make(e1, e2)
        node.pos = pos
        return node, true
    }

    return parse_E15(p)
}

parse_E15 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    tk := get_tk(p) or_return

    if tk.kind == .Do {
        pos := tk.pos
        p.tk_advanced += 1

        e1 := parse_E_minus(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .While { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        e2_e1 := parse_E8(p) or_return

        e2 := AST.while_make(e2_e1, e1)

        node = AST.sequence_make(e1, e2)
        node.pos = pos
        return node, true
    }

    return parse_E14(p)
}

parse_E14 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    tk := get_tk(p) or_return

    if tk.kind == .While {
        pos := tk.pos
        p.tk_advanced += 1

        e1 := parse_E8(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Do { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1

        e2 := parse_E_minus(p) or_return

        node = AST.while_make(e1, e2)
        node.pos = pos
        return node, true
    }

    return parse_E13(p)
}

parse_E13 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    tk := get_tk(p) or_return

    if tk.kind == .Type {
        pos := tk.pos
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

        node = AST.type_decl_make(x, pt, e1)
        node.pos = pos
        return node, true
    }

    return parse_E12(p)
}

parse_E12 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    tk := get_tk(p) or_return

    if tk.kind == .Let {
        pos := tk.pos
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
        node = AST.let_make(is_mut, x, pt, e1, e2)
        node.pos = pos
        return node, true
    }

    return parse_E11(p)
}

parse_E11 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    tk := get_tk(p) or_return

    if tk.kind == .If {
        pos := tk.pos
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

        node = AST.if_else_make(e1, e2, e3)
        node.pos = pos
        return node, true
    }

    return parse_E10(p)
}

parse_E10 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    x, x_parsed := parse_ident(p)
    if x_parsed {
        tk := get_tk(p) or_return
        pos := tk.pos
        if tk.kind == .Less {
            p.tk_advanced += 1
            tk, got_tk := get_tk(p)
            if !got_tk || tk.kind != .Minus { p.tk_advanced -= 2; return }
            p.tk_advanced += 1

            e1 := parse_E8(p) or_return

            node = AST.assignment_make(x, e1)
            node.pos = pos
            return node, true
        }

        if tk.kind == .Plus {
            p.tk_advanced += 1
            tk, got_tk := get_tk(p)
            if !got_tk || tk.kind != .Eq { p.tk_advanced -= 2; return }
            p.tk_advanced += 1

            e1_e2 := parse_E8(p) or_return

            e1_e1 := AST.variable_make(x)
            e1_e1.pos = pos

            e1 := AST.binary_make(.Plus, e1_e1, e1_e2)
            e1.pos = pos
            node = AST.assignment_make(x, e1)
            node.pos = pos
            return node, true
        }

        if tk.kind == .Minus {
            p.tk_advanced += 1
            tk, got_tk := get_tk(p)
            if !got_tk || tk.kind != .Eq { p.tk_advanced -= 2; return }
            p.tk_advanced += 1

            e1_e2 := parse_E8(p) or_return

            e1_e1 := AST.variable_make(x)
            e1_e1.pos = pos

            e1 := AST.binary_make(.Minus, e1_e1, e1_e2)
            e1.pos = pos
            node = AST.assignment_make(x, e1)
            node.pos = pos
            return node, true
        }

        if tk.kind == .Times {
            p.tk_advanced += 1
            tk, got_tk := get_tk(p)
            if !got_tk || tk.kind != .Eq { p.tk_advanced -= 2; return }
            p.tk_advanced += 1

            e1_e2 := parse_E8(p) or_return

            e1_e1 := AST.variable_make(x)
            e1_e1.pos = pos

            e1 := AST.binary_make(.Times, e1_e1, e1_e2)
            e1.pos = pos
            node = AST.assignment_make(x, e1)
            node.pos = pos
            return node, true
        }

        if tk.kind == .Div {
            p.tk_advanced += 1
            tk, got_tk := get_tk(p)
            if !got_tk || tk.kind != .Eq { p.tk_advanced -= 2; return }
            p.tk_advanced += 1

            e1_e2 := parse_E8(p) or_return

            e1_e1 := AST.variable_make(x)
            e1_e1.pos = pos

            e1 := AST.binary_make(.Divide, e1_e1, e1_e2)
            e1.pos = pos
            node = AST.assignment_make(x, e1)
            node.pos = pos
            return node, true
        }

        p.tk_advanced -= 1
    }
    return parse_E9(p)
}

parse_E9 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    tk, got_tk := get_tk(p)

    if got_tk && tk.kind == .Read_Float {
        pos := tk.pos
        p.tk_advanced += 1
        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { return }
        p.tk_advanced += 1

        node = AST.unary_make(.Read_Float, nil)
        node.pos = pos
        return node, true
    }
    if got_tk && tk.kind == .Read_Int {
        pos := tk.pos
        p.tk_advanced += 1
        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { return }
        p.tk_advanced += 1

        node = AST.unary_make(.Read_Int, nil)
        node.pos = pos
        return node, true
    }
    if got_tk && tk.kind == .Print {
        pos := tk.pos
        p.tk_advanced += 1
        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        e1 := parse_E8(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { return }
        p.tk_advanced += 1

        node = AST.unary_make(.Print, e1)
        node.pos = pos
        return node, true
    }

    if got_tk && tk.kind == .PrintLn {
        pos := tk.pos
        p.tk_advanced += 1
        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        e1 := parse_E8(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { return }
        p.tk_advanced += 1

        node = AST.unary_make(.Println, e1)
        node.pos = pos
        return node, true
    }

    if got_tk && tk.kind == .Assert {
        pos := tk.pos
        p.tk_advanced += 1
        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        e1 := parse_E8(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { return }
        p.tk_advanced += 1

        node = AST.unary_make(.Assert, e1)
        node.pos = pos
        return node, true
    }

    return parse_E8(p)
}

parse_E8 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    e1 := parse_E7(p) or_return

    tk, got_tk := get_tk(p)
    if !got_tk { return e1, true }

    if tk.kind == .And {
        pos := tk.pos
        p.tk_advanced += 1
        e2, e2_parsed := parse_E7(p)
        if !e2_parsed { p.tk_advanced -= 1; return }

        node = AST.binary_make(.And, e1, e2)
        node.pos = pos
        return node, true
    }
    return e1, true
}

parse_E7 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    e1 := parse_E6(p) or_return

    tk, got_tk := get_tk(p)
    if !got_tk { return e1, true }

    if tk.kind == .Or {
        pos := tk.pos
        p.tk_advanced += 1
        e2, e2_parsed := parse_E7(p)
        if !e2_parsed { p.tk_advanced -= 1; return }

        node = AST.binary_make(.Or, e1, e2)
        node.pos = pos
        return node, true
    }
    return e1, true
}

parse_E6 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind == .Not {
        pos := tk.pos
        p.tk_advanced += 1

        e1 := parse_E6(p) or_return

        node = AST.unary_make(.Not, e1)
        node.pos = pos
        return node, true
    }
    return parse_E5(p)
}

parse_E5 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    e1 := parse_E4(p) or_return

    tk, got_tk := get_tk(p)
    if !got_tk { return e1, true }

    if tk.kind == .Less {
        pos := tk.pos
        op : AST.Binary_Op = .Less
        p.tk_advanced += 1

        tk, got_tk = get_tk(p)
        if got_tk && tk.kind == .Eq {
            p.tk_advanced += 1
            op = .Less_Equals
        }

        e2, e2_parsed := parse_E4(p)
        if !e2_parsed { p.tk_advanced -= 1; return }
        
        node = AST.binary_make(op, e1, e2)
        node.pos = pos
        return node, true
    }

    if tk.kind == .Greater {
        pos := tk.pos
        op : AST.Binary_Op = .Greater
        p.tk_advanced += 1

        tk, got_tk = get_tk(p)
        if got_tk && tk.kind == .Eq {
            p.tk_advanced += 1
            op = .Greater_Equals
        }

        e2, e2_parsed := parse_E4(p)
        if !e2_parsed { p.tk_advanced -= 1; return }
        node = AST.binary_make(.Greater, e1, e2)
        node.pos = pos
        return node, true
    }

    if tk.kind == .Eq {
        pos := tk.pos
        p.tk_advanced += 1
        e2, e2_parsed := parse_E4(p)
        if !e2_parsed { p.tk_advanced -= 1; return }
        
        node = AST.binary_make(.Equals, e1, e2)
        node.pos = pos
        return node, true
    }

    return e1, true
}

parse_E4 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    tk, got_tk := get_tk(p)

    if got_tk && tk.kind == .Max {
        pos := tk.pos
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

        node = AST.binary_make(.Max, e1, e2)
        return node, true
    }

    if got_tk && tk.kind == .Min {
        pos := tk.pos
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

        node = AST.binary_make(.Min, e1, e2)
        return node, true
    }

    if got_tk && tk.kind == .Sqrt {
        pos := tk.pos
        p.tk_advanced += 1
        tk = get_tk(p) or_return
        if tk.kind != .Left_Par { p.tk_advanced -= 1; return }
        p.tk_advanced += 1

        e1 := parse_E4(p) or_return

        tk = get_tk(p) or_return
        if tk.kind != .Right_Par { return }
        p.tk_advanced += 1

        node = AST.unary_make(.Sqrt, e1)
        return node, true
    }
    return parse_E3(p)
}

parse_E3 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    e1 := parse_E2(p) or_return

    tk, got_tk := get_tk(p)
    if !got_tk { return e1, true }

    if tk.kind == .Plus {
        pos := tk.pos
        p.tk_advanced += 1
        e2, e2_parsed := parse_E3(p)
        if !e2_parsed { p.tk_advanced -= 1; return }
        node = AST.binary_make(.Plus, e1, e2)
        node.pos = pos
        return node, true
    }

    if tk.kind == .Minus {
        pos := tk.pos
        p.tk_advanced += 1
        e2, e2_parsed := parse_E3(p)
        if !e2_parsed { p.tk_advanced -= 1; return }
        node = AST.binary_make(.Minus, e1, e2)
        node.pos = pos
        return node, true
    }
    return e1, true
}

parse_E2 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    e1 := parse_E1(p) or_return

    tk, got_tk := get_tk(p)
    if !got_tk { return e1, true }

    if tk.kind == .Mod {
        pos := tk.pos
        p.tk_advanced += 1
        e2, e2_parsed := parse_E2(p)
        if !e2_parsed { p.tk_advanced -= 1; return }
        node = AST.binary_make(.Modulus, e1, e2)
        node.pos = pos
        return node, true
    }

    if tk.kind == .Times {
        pos := tk.pos
        p.tk_advanced += 1
        e2, e2_parsed := parse_E2(p)
        if !e2_parsed { p.tk_advanced -= 1; return }
        node = AST.binary_make(.Times, e1, e2)
        node.pos = pos
        return node, true
    }

    if tk.kind == .Div {
        pos := tk.pos
        p.tk_advanced += 1
        e2, e2_parsed := parse_E2(p)
        if !e2_parsed { p.tk_advanced -= 1; return }
        node = AST.binary_make(.Divide, e1, e2)
        node.pos = pos
        return node, true
    }

    return e1, true
}

parse_E1 :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    node, ok = parse_value(p)
    if ok { return }

    node, ok = parse_variable(p)
    tk, got_tk := get_tk(p)
    if got_tk && tk.kind == .Minus {
        pos := tk.pos
        p.tk_advanced += 1
        e1, e1_parsed := parse_E1(p)
        if !e1_parsed { p.tk_advanced -= 1; return }
        node = AST.unary_make(.U_Minus, e1)
        node.pos = pos
        return node, true
    }

    if got_tk && tk.kind == .Period {
        p.tk_advanced += 1
        field, got_field := parse_ident(p)
        if !got_field { p.tk_advanced -= 1; return }
        node = AST.field_access_make(node.expr.(AST.Variable).x, field)
        return node, true
    }

    if got_tk && tk.kind == .Left_Par {
        pos := tk.pos
        p.tk_advanced += 1
        e1 := parse_E(p) or_return
        tk, got_tk = get_tk(p)
        if !got_tk || tk.kind != .Right_Par { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1
        node = AST.parens_make(e1)
        node.pos = pos
        return node, true
    }

    if got_tk && tk.kind == .Left_Cur {
        pos := tk.pos
        p.tk_advanced += 1
        e1 := parse_E(p) or_return
        tk, got_tk = get_tk(p)
        if !got_tk || tk.kind != .Right_Cur { p.tk_advanced = p.cursor; return }
        p.tk_advanced += 1
        node = AST.scope_make(e1)
        node.pos = pos
        return node, true
    }
    return
}

parse_variable :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind == .Ident {
        node = AST.variable_make(tk.payload.(string))
        node.pos = tk.pos
        p.tk_advanced += 1
        return node, true
    }
    return node, true
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

parse_value :: proc(p: ^Parser) -> (node: ^AST.Node, ok: bool) {
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

    node = AST.value_make(type, payload)
    node.pos = tk.pos

    return node, true
}

get_tk :: proc(p: ^Parser) -> (tk: Lexer.Token, ok: bool) {
    if p.tk_advanced >= u64(len(p.tokens)) { return }
    return p.tokens[p.tk_advanced], true
}
