package ast

import "core:fmt"

value_to_string :: proc(v: Value_Payload) -> (s: string) {
    if v == nil { return "()" }
    switch payload in v {
        case int:    s = fmt.aprintf("%i", payload)
        case f64:    s = fmt.aprintf("%f", payload)
        case bool:   s = fmt.aprintf("%v", payload)
        case string: s = fmt.aprintf("\"%s\"", payload)
    }
    return 
}

unary_to_string :: proc(expr: Unary_Fun) -> (s: string) {
    switch expr.op {
        case .U_Minus:      s = fmt.aprintf("(-%s)",       expr_to_string(expr.e1, ""))
        case .Not:          s = fmt.aprintf("(not %s)",    expr_to_string(expr.e1, ""))
        case .Sqrt:         s = fmt.aprintf("sqrt(%s)",    expr_to_string(expr.e1, ""))
        case .Print:        s = fmt.aprintf("print(%s)",   expr_to_string(expr.e1, ""))
        case .Println:      s = fmt.aprintf("println(%s)", expr_to_string(expr.e1, ""))
        case .Assert:       s = fmt.aprintf("assert(%s)",  expr_to_string(expr.e1, ""))
        case .Read_Float:   s = fmt.aprintf("readFloat()")
        case .Read_Int:     s = fmt.aprintf("readInt()")
    }
    return
}

binary_to_string :: proc(expr: Binary_Fun) -> (s: string) {
    switch expr.op {
        case .Modulus:          s = fmt.aprintf("%s %% %s",    expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Divide:           s = fmt.aprintf("(%s / %s)",   expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Times:            s = fmt.aprintf("(%s * %s)",   expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Minus:            s = fmt.aprintf("%s - %s",     expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Plus:             s = fmt.aprintf("%s + %s",     expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Max:              s = fmt.aprintf("max(%s, %s)", expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Min:              s = fmt.aprintf("min(%s, %s)", expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Less:             s = fmt.aprintf("%s < %s",     expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Greater:          s = fmt.aprintf("%s > %s",     expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Equals:           s = fmt.aprintf("%s = %s",     expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Less_Equals:      s = fmt.aprintf("%s <= %s",    expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Greater_Equals:   s = fmt.aprintf("%s >= %s",    expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .Or:               s = fmt.aprintf("(%s or %s)",  expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
        case .And:              s = fmt.aprintf("%s and %s",   expr_to_string(expr.e1, ""), expr_to_string(expr.e2, ""))
    }
    return
}

fields_to_string :: proc(fields: map[string]^Expr) -> (s: string) {
    for k,v in fields {
        s = fmt.aprintf("%s; %v = %v", s, k, expr_to_string(v, ""))
    }
    if len(fields) == 0 { return "" }
    return s[2:]
}

match_patterns_to_string :: proc(patterns: map[Match_Pattern]^Expr) -> (s: string) {
    for k,v in patterns {
        s = fmt.aprintf("%s; %s {{ %s }} = %v", s, k.label, k.var, expr_to_string(v, ""))
    }
    if len(patterns) == 0 { return "" }
    return s[2:]
}

fun_app_params_to_string :: proc(params: [dynamic]^Expr) -> (s: string) {
    for p in params {
        s = fmt.aprintf("%s,  %s", s, expr_to_string(p, ""))
    }
    if len(params) == 0 { return "" }
    return s[3:]
}

fun_decl_params_to_string :: proc(params: map[string]^Pretype) -> (s: string) {
    for k,v in params {
        s = fmt.aprintf("%s, %s : %s", s, k, pretype_to_string(v))
    }
    if len(params) == 0 { return "" }
    return s[2:]
}

expr_to_string :: proc(expr: ^Expr, indent: string) -> (s: string) {
    if expr == nil { return }

    s0 := indent

    switch e in expr {
        case Sequence:
            s0 = ""
            s = fmt.aprintf("%s;\n%s", expr_to_string(e.e1, indent), expr_to_string(e.e2, indent))
        case Type_Ascription:
            s = fmt.aprintf("%s : %s", expr_to_string(e.e1, ""), pretype_to_string(e.pt))
        case Fun_Decl:
            s = fmt.aprintf("fun (%s) -> %s", fun_decl_params_to_string(e.params), expr_to_string(e.e1, ""))
        case Fun_App:
            s = fmt.aprintf("%s(%s)", expr_to_string(e.fun, ""), fun_app_params_to_string(e.params))
        case Match_Case:
            s = fmt.aprintf("match %s with {{ %s }}", expr_to_string(e.e1, ""), match_patterns_to_string(e.patterns))
        case Union_Constructor:
            s = fmt.aprintf("%s {{ %s }}", e.label, expr_to_string(e.e1, ""))
        case Struct:
            s0 = ""
            s = fmt.aprintf("struct {{ %s }}", fields_to_string(e.fields))
        case While:
            s = fmt.aprintf("while %s do %s", expr_to_string(e.e1, ""), expr_to_string(e.e2, ""))
        case Type_Decl:
            s = fmt.aprintf("type %s = %s;\n%s", e.x, pretype_to_string(e.pt), expr_to_string(e.e1, indent))
        case Let:
            if e.is_mut {
                s = fmt.aprintf("let mutable %s : %s = %s;\n%s", e.x, pretype_to_string(e.pt), expr_to_string(e.e1, ""), expr_to_string(e.e2, indent))
            } else {
                s = fmt.aprintf("let %s : %s = %s;\n%s", e.x, pretype_to_string(e.pt), expr_to_string(e.e1, ""), expr_to_string(e.e2, indent))
            }
        case If_Else:
            s = fmt.aprintf("if %s\n  then %s\n  else %s", expr_to_string(e.e1, indent), expr_to_string(e.e2, indent), expr_to_string(e.e3, indent))
        case Assignment:
            s = fmt.aprintf("%s <- %s", e.x, expr_to_string(e.e1, ""))
        case Unary_Fun:
            s = fmt.aprintf("%s", unary_to_string(e))
        case Binary_Fun:
            s = fmt.aprintf("%s", binary_to_string(e))
        case Variable:
            s = fmt.aprintf("%s", e.x)
        case Field_Access:
            s = fmt.aprintf("%s.%s", e.x, e.field)
        case Value:
            s = fmt.aprintf("%s", value_to_string(e.v))
        case Parens:
            s = fmt.aprintf("(%s)", expr_to_string(e.e1, ""))
        case Scope:
            s = fmt.aprintf("{{ %s }}", expr_to_string(e.e1, ""))
    }
    return fmt.aprintf("%s%s", s0, s)
}

types_to_string :: proc(params: [dynamic]^Pretype) -> (s: string) {
    for p in params {
        s = fmt.aprintf("%s, %s", s, pretype_to_string(p))
    }
    if len(params) == 0 { return "" }
    return s[2:]
}

labels_to_string :: proc(labels: map[string]^Pretype) -> (s: string) {
    for k,v in labels {
        s = fmt.aprintf("%s; %v : %v", s, k, pretype_to_string(v))
    }
    if len(labels) == 0 { return "" }
    return s[2:]
}

pretype_to_string :: proc(pretype: ^Pretype) -> (s: string) {
    if pretype == nil { return }

    switch pt in pretype {
        case Single:
            s = pt.t
        case Fun_Sign:
            s = fmt.aprintf("(%s) -> %s", types_to_string(pt.params), pretype_to_string(pt.res))
        case Struct_Type:
            s = fmt.aprintf("struct {{ %s }}", labels_to_string(pt.fields))
        case Union_Type:
            s = fmt.aprintf("union {{ %s }}", labels_to_string(pt.labels))
    }
    return
}