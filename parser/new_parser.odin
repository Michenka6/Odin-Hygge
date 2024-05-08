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
        ME  ::= AE ( ";" AE )*
        AE  ::= TE ( ( "<-" + "-=" + "*=" + "/=" + "%=" ) TE )?
        TE  ::=
            |   E ( ":" PRETYPE )?
        E   ::=
            |   "readInt"   "("   ")"
            |   "readFloat" "("   ")"
            |   "print"     "(" AE ")"
            |   "println"   "(" AE ")"
            |   "assert"    "(" AE ")"
            |   "if" D
            |   "let" C
            |   "type" F
            |   "while" B "do" E
            |   "do" AE "while" B
            |   "for" G
            |   "struct" "{" H "}"
          //|   "match" I
            |   "fun" K
            |   B
            |   A
        C   ::=
            |   ( "mutable" )? IDENT ":" PRETYPE "=" AE ";" AE
        D   ::=
            |   B "then" AE "else" AE
        F   ::=
            |   IDENT "=" PRETYPE ";" AE
        G   ::=
            |   "(" AE "," B "," AE ")" AE
        H   ::=
            |   HH ( ";" HH)*
        HH  ::=
            |   ( IDENT "=" AE )?
        I   ::=
            |   AE "with" "{" J "}"
        J   ::=
            |   IDENT "{" IDENT "}" "-" ">" AE ( ";" J )*
        K   ::=
            |   "(" L ")" "-" ">" AE
            |   IDENT "(" L ")" ":" PRETYPE "=" AE ";" AE
        L   ::=
            |   ( IDENT ":" PRETYPE ( "," L )* )?
*/
// PARSER_TRACING :: true
PARSER_TRACING :: false

parse_src :: proc(source: []u8) -> (expr: ^AST.Expr, ok: bool) {
    lexer := Lexer.lexer_make(source)
    defer Lexer.lexer_delete(lexer)

    Lexer.tokenize(lexer)

    p := parser_make(lexer)
    return parse_ME(p)
}

parse_ME :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING ME") }
    //|   AE ( ";" AE )*
    expr = parse_AE(p) or_return
    for eat_tk(p, .Semi_Colon) {
        e1 := parse_AE(p) or_return
        expr = AST.sequence_make(expr, e1)
    }
    return expr, true
}


parse_AE :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING AE") }
    //|   TE ( ( "<-" + "-=" + "*=" + "/=" + "%=" ) TE )?
    lhs := parse_TE(p) or_return
    if eat_tk(p, .Less) {
        eat_tk(p, .Minus) or_return
        rhs := parse_TE(p) or_return
        expr = AST.assignment_make(lhs, rhs)
        return expr, true
    }
    if eat_tk(p, .Minus) {
        eat_tk(p, .Eq) or_return
        rhs := parse_TE(p) or_return
        lhs_p := AST.expr_clone(lhs)
        e2 := AST.binary_make(.Minus, lhs_p, rhs)
        expr = AST.assignment_make(lhs, e2)
        return expr, true
    }
    if eat_tk(p, .Plus) {
        eat_tk(p, .Eq) or_return
        rhs := parse_TE(p) or_return
        lhs_p := AST.expr_clone(lhs)
        e2 := AST.binary_make(.Plus, lhs_p, rhs)
        expr = AST.assignment_make(lhs, e2)
        return expr, true
    }
    if eat_tk(p, .Div) {
        eat_tk(p, .Eq) or_return
        rhs := parse_TE(p) or_return
        lhs_p := AST.expr_clone(lhs)
        e2 := AST.binary_make(.Divide, lhs_p, rhs)
        expr = AST.assignment_make(lhs, e2)
        return expr, true
    }
    if eat_tk(p, .Times) {
        eat_tk(p, .Eq) or_return
        rhs := parse_TE(p) or_return
        lhs_p := AST.expr_clone(lhs)
        e2 := AST.binary_make(.Times, lhs_p, rhs)
        expr = AST.assignment_make(lhs, e2)
        return expr, true
    }
    if eat_tk(p, .Mod) {
        eat_tk(p, .Eq) or_return
        rhs := parse_TE(p) or_return
        lhs_p := AST.expr_clone(lhs)
        e2 := AST.binary_make(.Modulus, lhs_p, rhs)
        expr = AST.assignment_make(lhs, e2)
        return expr, true
    }
    return lhs, true
}

parse_TE :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING TE") }
    //|   E ( ":" PRETYPE )?
    expr = parse_E(p) or_return
    if eat_tk(p, .Colon) {
        pt := parse_pretype(p) or_return
        expr = AST.type_ascription_make(expr, pt)
    }
    return expr, true
}
parse_E :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING E") }
    //|   "readInt"   "("   ")"
    if eat_tk(p, .Read_Int) {
        eat_tk(p, .Left_Par) or_return
        eat_tk(p, .Right_Par) or_return
        expr = AST.unary_make(.Read_Int, nil)
        return expr, true
    }
    //|   "readFloat" "("   ")"
    if eat_tk(p, .Read_Float) {
        eat_tk(p, .Left_Par) or_return
        eat_tk(p, .Right_Par) or_return
        expr = AST.unary_make(.Read_Float, nil)
        return expr, true
    }
    //|   "print"     "(" AE ")"
    if eat_tk(p, .Print) {
        eat_tk(p, .Left_Par) or_return
        e1 := parse_AE(p) or_return
        eat_tk(p, .Right_Par) or_return
        expr = AST.unary_make(.Print, e1)
        return expr, true
    }
    //|   "println"   "(" AE ")"
    if eat_tk(p, .PrintLn) {
        eat_tk(p, .Left_Par) or_return
        e1 := parse_AE(p) or_return
        eat_tk(p, .Right_Par) or_return
        expr_e1 := AST.unary_make(.Print, e1)

        expr_e2_e1 := AST.value_make(.String, "\\n")
        expr_e2 := AST.unary_make(.Print, expr_e2_e1)
        expr = AST.sequence_make(expr_e1, expr_e2)
        return expr, true
    }
    //|   "assert"    "(" AE ")"
    if eat_tk(p, .Assert) {
        eat_tk(p, .Left_Par) or_return
        e1 := parse_AE(p) or_return
        eat_tk(p, .Right_Par) or_return
        expr = AST.unary_make(.Assert, e1)
        return expr, true
    }
    //|   "if" D
    if eat_tk(p, .If) { return parse_D(p) }
    //|   "let" C
    if eat_tk(p, .Let) { return parse_C(p) }
    //|   "type" F
    if eat_tk(p, .Type) { return parse_F(p) }
    //|   "while" B "do" AE
    if eat_tk(p, .While) {
        cond := parse_B(p) or_return
        eat_tk(p, .Do) or_return
        e1 := parse_AE(p) or_return
        expr = AST.while_make(cond, e1)
        return expr, true
    }
    //|   "do" AE "while" B
    if eat_tk(p, .Do) {
        e1 := parse_AE(p) or_return
        eat_tk(p, .While) or_return
        cond := parse_B(p) or_return
        init := AST.expr_clone(e1)
        loop := AST.while_make(cond, e1)
        expr = AST.sequence_make(init, loop)
        return expr, true
    }
    //|   "for" G
    if eat_tk(p, .For) { return parse_G(p) }
    //|   "struct" "{" H "}"
    if eat_tk(p, .Struct) {
        eat_tk(p, .Left_Cur) or_return
        fields := make(map[string]^AST.Expr)
        parse_H(p, &fields) or_return
        eat_tk(p, .Right_Cur) or_return
        expr = AST.struct_make(fields)
        return expr, true
    }
    //|   "match" I
    // if eat_tk(p, .Match) { return parse_I(p) }
    //|   "fun" K
    if eat_tk(p, .Fun) { return parse_K(p) }
    //|   B
    if expr, ok = parse_B(p); ok { return }
    //|   A
    if expr, ok = parse_A(p); ok { return }
    return nil, false
}

parse_C :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING C") }
    //|   ( "mutable" )? IDENT ":" PRETYPE "=" AE ";" AE
    is_mut := false
    if eat_tk(p, .Mutable) { is_mut = true }
    ident := parse_ident(p) or_return
    eat_tk(p, .Colon) or_return
    pt := parse_pretype(p) or_return
    eat_tk(p, .Eq) or_return
    e1 := parse_AE(p) or_return
    eat_tk(p, .Semi_Colon) or_return
    e2 := parse_AE(p) or_return
    expr = AST.let_make(is_mut, ident, pt, e1, e2)
    return expr, true
}

parse_D :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING D") }
    //|   B "then" E "else" E
    cond := parse_B(p) or_return
    eat_tk(p, .Then) or_return
    e1 := parse_AE(p) or_return
    eat_tk(p, .Else) or_return
    e2 := parse_AE(p) or_return
    expr = AST.if_else_make(cond, e1, e2)
    return expr, true
}

parse_F :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING F") }
    //|   IDENT "=" PRETYPE ";" AE
    ident := parse_ident(p) or_return
    eat_tk(p, .Eq) or_return
    pt := parse_pretype(p) or_return
    eat_tk(p, .Semi_Colon) or_return
    e1 := parse_AE(p) or_return
    expr = AST.type_decl_make(ident, pt, e1)
    return expr, true
}

parse_G :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING G") }
    //|   "(" AE "," B "," AE ")" AE
    eat_tk(p, .Left_Par) or_return
    init := parse_AE(p) or_return
    eat_tk(p, .Comma) or_return
    cond := parse_B(p) or_return
    eat_tk(p, .Comma) or_return
    step := parse_AE(p) or_return
    eat_tk(p, .Right_Par) or_return
    action := parse_AE(p) or_return

    loop_body := AST.sequence_make(action, step)
    loop := AST.while_make(cond, loop_body)
    expr = AST.sequence_make(init, loop)
    return expr, true
}

parse_H :: proc(p: ^Parser, fields: ^map[string]^AST.Expr) -> (ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING H") }
    //|   HH ( ";" HH)*
    parse_HH(p, fields) or_return
    for eat_tk(p, .Semi_Colon) {
        parse_HH(p, fields) or_return
    }
    return true
}

parse_HH :: proc(p: ^Parser, fields: ^map[string]^AST.Expr) -> (ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING HH") }
    //|   ( IDENT "=" AE )*
    ident, got_ident := parse_ident(p)
    if got_ident {
        eat_tk(p, .Eq) or_return
        expr := parse_AE(p) or_return
        fields[ident] = expr
    }
    return true
}

// parse_I :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
//     when PARSER_TRACING { fmt.println("PARSING I") }
//     //|   AE "with" "{" J "}"
//     e1 := parse_AE(p) or_return
//     eat_tk(p, .With) or_return
//     eat_tk(p, .Left_Cur) or_return
//     patterns := make(map[AST.Match_Pattern]^AST.Expr)
//     parse_J(p, &patterns) or_return
//     eat_tk(p, .Right_Cur) or_return
//     expr = AST.match_cases_make(e1, patterns)
//     return expr, true
// }

// parse_J :: proc(p: ^Parser, patterns: ^map[AST.Match_Pattern]^AST.Expr) -> (ok: bool) {
//     when PARSER_TRACING { fmt.println("PARSING J") }
//     //|   IDENT "{" IDENT "}" "-" ">" AE ( ";" J )*
//     label := parse_ident(p) or_return
//     eat_tk(p, .Left_Cur) or_return
//     var := parse_ident(p) or_return
//     eat_tk(p, .Right_Cur) or_return
//     eat_tk(p, .Minus) or_return
//     eat_tk(p, .Greater) or_return
//     expr := parse_AE(p) or_return
//     pattern := AST.Match_Pattern {label, var}
//     patterns[pattern] = expr
//
//     for eat_tk(p, .Semi_Colon) { parse_J(p, patterns) }
//     return true
// }

parse_K :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING K") }
    if eat_tk(p, .Left_Par) {
        //|   "(" L ")" "-" ">" E
        params := make(map[string]^AST.Pretype)
        parse_L(p, &params) or_return
        eat_tk(p, .Right_Par) or_return
        eat_tk(p, .Minus) or_return
        eat_tk(p, .Greater) or_return
        res := parse_AE(p) or_return
        expr = AST.fun_decl_make(params, res)
        return expr, true
    }

    //|   IDENT "(" L ")" ":" PRETYPE "=" E ";" E
    ident, got_ident := parse_ident(p)
    if got_ident {
        eat_tk(p, .Left_Par) or_return
        params := make(map[string]^AST.Pretype)
        parse_L(p, &params) or_return

        eat_tk(p, .Right_Par) or_return
        eat_tk(p, .Colon) or_return

        pt := parse_pretype(p) or_return

        eat_tk(p, .Eq) or_return

        res := parse_AE(p) or_return
        e1 := AST.fun_decl_make(params, res)

        eat_tk(p, .Semi_Colon) or_return

        e2 := parse_AE(p) or_return

        pt_params := make(AST.Pretypes)
        for k,v in params {
            append_elem(&pt_params, v)
        }
        pt = AST.fun_sign_make(pt_params, pt)

        expr = AST.let_make(false, ident, pt, e1, e2)

        for k,v in params {
            AST.expr_ident_subst(k, fmt.aprintf("%s%s", ident, k), e1, ident)
        }
        return expr, true
    }

    return
}

parse_L :: proc(p: ^Parser, params: ^map[string]^AST.Pretype) -> ( ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING L") }
    //|   ( IDENT ":" PRETYPE ( "," L )* )?
    ident, got_ident := parse_ident(p)
    if got_ident {
        eat_tk(p, .Colon) or_return

        pt := parse_pretype(p) or_return
        params[ident] = pt

        if eat_tk(p, .Comma) { parse_L(p, params) }
    }

    return true
}

/*
        B   ::=
            |   BOR ( ( "and" + "sand") B )*
        BOR ::=
            |   BNT ( ("or" + "sor" + "xor" ) BOR)*
        BNT ::=
            |   ( "not" )? ARL
        ARL ::=
            | A ( ( "<=" + "<" + "=" + ">=" + ">") A )?
            | V

*/

parse_B :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING B") }
    expr = parse_BOR(p) or_return

    op_to_bop := map[Lexer.Token_Kind]AST.Binary_Op { .And = .And, .S_And = .And }

    tk, got_tk := get_tk(p)
    for got_tk && (tk.kind in op_to_bop) {
        p.tk_advanced += 1
        v := parse_B(p) or_return
        if tk.kind == .S_And {
            expr = AST.if_else_make(expr, v, AST.value_make(.Bool, false))
        } else {
            expr = AST.binary_make(op_to_bop[tk.kind], expr, v)
        }
        tk, got_tk = get_tk(p)
    }
    return expr, true
}

parse_BOR :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING BOR") }
    expr = parse_BNT(p) or_return

    op_to_bop := map[Lexer.Token_Kind]AST.Binary_Op { .Or = .Or, .Xor = .Xor, .S_Or = .Or }

    tk, got_tk := get_tk(p)
    for got_tk && (tk.kind in op_to_bop) {
        p.tk_advanced += 1
        v := parse_BOR(p) or_return
        if tk.kind == .S_Or {
            expr = AST.if_else_make(expr, AST.value_make(.Bool, true), v)
        } else {
            expr = AST.binary_make(op_to_bop[tk.kind], expr, v)
        }
        tk, got_tk = get_tk(p)
    }
    return expr, true
}

parse_BNT :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok:bool) {
    when PARSER_TRACING { fmt.println("PARSING BNT") }
    if eat_tk(p, .Not) {
        e1 := parse_ARL(p) or_return
        expr = AST.unary_make(.Not, e1)
        return expr, true
    }

    expr, ok = parse_ARL(p)
    return
}

parse_ARL :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING ARL") }
    op: AST.Binary_Op
    expr = parse_A(p) or_return

    if eat_tk(p, .Less) {
        op = .Less
        if eat_tk(p, .Eq) { op = .Less_Equals }
        if eat_tk(p, .Minus) {
            e2 := parse_TE(p) or_return
            expr = AST.assignment_make(expr, e2)
            return expr, true
        }
    } else if eat_tk(p, .Greater) {
        op = .Greater
        if eat_tk(p, .Eq) { op = .Greater_Equals }
    } else if eat_tk(p, .Eq) {
        op = .Equals
    } else {
        return expr, true
    }
    e2 := parse_A(p) or_return
    expr = AST.binary_make(op, expr, e2)

    return expr, true
}
/*
        A   ::=
            |   "max"  "(" A "," A ")"
            |   "min"  "(" A "," A ")"
            |   "sqrt" "(" A ")"
            |   MDT ( ( "+" + "-" ) MDT )*
        MDT ::=
            |   V (( "%" + "*" + "/" ) V )*
        V   ::=
            |   "{" ME "}"
            |   "(" ME ")"
            |   "-" V
            |   VALUE
            |   IDENT ( "(" PARAMS ")" + ( "." IDENT )* + "{" AE "}" )?
        PARAMS ::=
            |   AE ( "," AE )* 
*/

parse_A :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING A") }
    tk, got_tk := get_tk(p)
    got_tk or_return

    if eat_tk(p, .Max) {
        eat_tk(p, .Left_Par) or_return
        e1 := parse_A(p) or_return
        eat_tk(p, .Comma) or_return
        e2 := parse_A(p) or_return
        eat_tk(p, .Right_Par) or_return
        cond := AST.binary_make(.Less, e1, e2)
        expr = AST.if_else_make(cond, e2, e1)
        return expr, true
    }

    if eat_tk(p, .Min) {
        eat_tk(p, .Left_Par) or_return
        e1 := parse_A(p) or_return
        eat_tk(p, .Comma) or_return
        e2 := parse_A(p) or_return
        eat_tk(p, .Right_Par) or_return
        cond := AST.binary_make(.Greater, e1, e2)
        expr = AST.if_else_make(cond, e2, e1)
        return expr, true
    }

    // if eat_tk(p, .Sqrt) {
    //     eat_tk(p, .Left_Par) or_return
    //     e1 := parse_A(p) or_return
    //     eat_tk(p, .Right_Par) or_return
    //     expr = AST.unary_make(.Sqrt, e1)
    //     return expr, true
    // }

    expr = parse_MDT(p) or_return
    tk, got_tk = get_tk(p)

    op_to_bop := map[Lexer.Token_Kind]AST.Binary_Op { .Plus = .Plus, .Minus = .Minus }

    for got_tk && (tk.kind in op_to_bop) {
        p.tk_advanced += 1
        v := parse_MDT(p) or_return
        expr = AST.binary_make(op_to_bop[tk.kind], expr, v)
        tk, got_tk = get_tk(p)
    }

    return expr, true
}

parse_MDT :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING MDT") }
    expr, ok = parse_V(p)

    op_to_bop := map[Lexer.Token_Kind]AST.Binary_Op { .Mod = .Modulus, .Div = .Divide, .Times = .Times }

    tk, got_tk := get_tk(p)
    for got_tk && (tk.kind in op_to_bop) {
        p.tk_advanced += 1
        v := parse_V(p) or_return
        expr = AST.binary_make(op_to_bop[tk.kind], expr, v)
        tk, got_tk = get_tk(p)
    }
    return
}

parse_V :: proc(p: ^Parser) -> (expr: ^AST.Expr, ok: bool) {
    when PARSER_TRACING { fmt.println("PARSING V") }
    if eat_tk(p, .Minus) {
        e1 := parse_V(p) or_return
        expr = AST.unary_make(.U_Minus, e1)
        return expr, true
    }

    if eat_tk(p, .Left_Cur) {
        e1 := parse_ME(p) or_return
        eat_tk(p, .Right_Cur) or_return
        expr = AST.scope_make(e1)
        return expr, true
    }

    if eat_tk(p, .Left_Par) {
        e1, got_e1 := parse_ME(p)
        if got_e1 {
            eat_tk(p, .Right_Par) or_return
            expr = AST.parens_make(e1)
            return expr, true
        }
        p.tk_advanced -= 1
    }

    if expr, ok = parse_value(p); ok { return }

    ident := parse_ident(p) or_return
    expr = AST.variable_make(ident)

    tk, got_tk := get_tk(p)
    for got_tk && eat_tk(p, .Period) {
        field := parse_ident(p) or_return
        expr = AST.field_access_make(expr, field)
        tk, got_tk = get_tk(p)
    }

    if got_tk && eat_tk(p, .Left_Par) {
        params := parse_params(p) or_return
        eat_tk(p, .Right_Par) or_return
        expr = AST.fun_app_make(ident, params)
    }

    // if got_tk && eat_tk(p, .Left_Cur) {
    //     e1 := parse_AE(p) or_return
    //     eat_tk(p, .Right_Cur) or_return
    //     expr = AST.union_constructor_make(ident, e1)
    //     return expr, true
    // }

    return expr, true
}

parse_params :: proc(p: ^Parser) -> (params: AST.Exprs, ok: bool) {
    params = make(AST.Exprs)
    if at_tk(p, .Right_Par) { return params, true }

    expr := parse_AE(p) or_return
    append_elem(&params, expr)

    for eat_tk(p, .Comma) {
        param := parse_AE(p) or_return
        append_elem(&params, param)
    }
    return params, true
}

parse_ident :: proc(p: ^Parser) -> (s: string, ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind == .Ident {
        p.tk_advanced += 1
        return tk.payload.(string), true
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
            payload = tk.payload.(f32)
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

eat_tk :: proc(p: ^Parser, kind: Lexer.Token_Kind) -> (ok: bool) {
    tk := get_tk(p) or_return
    if tk.kind == kind {
        p.tk_advanced += 1
        return true
    }
    return
}

at_tk :: proc(p: ^Parser, kind: Lexer.Token_Kind) -> (ok: bool) {
    tk := get_tk(p) or_return
    return  tk.kind == kind
}

get_tk :: proc(p: ^Parser) -> (tk: Lexer.Token, ok: bool) {
    if p.tk_advanced >= u64(len(p.tokens)) { return }
    return p.tokens[p.tk_advanced], true
}
