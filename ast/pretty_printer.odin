package ast

import "core:fmt"

value_to_string :: proc(v: Value_Payload) -> (s: string) {
    if v == nil { return "(UNIT)" }
    switch payload in v {
        case int:    s = fmt.aprintf("(%i :: int)", payload)
        case f64:    s = fmt.aprintf("(%f :: float)", payload)
        case bool:   s = fmt.aprintf("(%v :: bool)", payload)
        case string: s = fmt.aprintf("(%s :: string)", payload)
    }
    return 
}

pos_to_string :: proc(pos: Position) -> string {
    return fmt.aprintf("(%i:%i)", pos.line, pos.column)
}

unary_to_string :: proc(expr: Unary_Fun, indent: string) -> (s: string) {
    switch expr.op {
        case .U_Minus:
            s = fmt.aprintf("-\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)))
        case .Not:
            s = fmt.aprintf("not\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)))
        case .Sqrt:
            s = fmt.aprintf("sqrt\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)))
        case .Print:
            s = fmt.aprintf("print\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)))
        case .Println:
            s = fmt.aprintf("println\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)))
        case .Assert:
            s = fmt.aprintf("assert\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)))
        case .Read_Float:
            s = fmt.aprintf("readFloat")
        case .Read_Int:
            s = fmt.aprintf("readInt")
    }
    return
}

binary_to_string :: proc(expr: Binary_Fun, indent: string) -> (s: string) {
    switch expr.op {
        case .Modulus:
            s = fmt.aprintf("%%\n%s\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)), node_to_string(expr.e2, fmt.aprintf("  %s", indent)))
        case .Divide:
            s = fmt.aprintf("/\n%s\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)), node_to_string(expr.e2, fmt.aprintf("  %s", indent)))
        case .Times:
            s = fmt.aprintf("*\n%s\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)), node_to_string(expr.e2, fmt.aprintf("  %s", indent)))
        case .Minus:
            s = fmt.aprintf("-\n%s\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)), node_to_string(expr.e2, fmt.aprintf("  %s", indent)))
        case .Plus:
            s = fmt.aprintf("+\n%s\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)), node_to_string(expr.e2, fmt.aprintf("  %s", indent)))
        case .Max:
            s = fmt.aprintf("max\n%s\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)), node_to_string(expr.e2, fmt.aprintf("  %s", indent)))
        case .Min:
            s = fmt.aprintf("min\n%s\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)), node_to_string(expr.e2, fmt.aprintf("  %s", indent)))
        case .Less:
            s = fmt.aprintf("<\n%s\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)), node_to_string(expr.e2, fmt.aprintf("  %s", indent)))
        case .Greater:
            s = fmt.aprintf(">\n%s\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)), node_to_string(expr.e2, fmt.aprintf("  %s", indent)))
        case .Equals:
            s = fmt.aprintf("=\n%s\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)), node_to_string(expr.e2, fmt.aprintf("  %s", indent)))
        case .Less_Equals:
            s = fmt.aprintf("<=\n%s\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)), node_to_string(expr.e2, fmt.aprintf("  %s", indent)))
        case .Greater_Equals:
            s = fmt.aprintf(">=\n%s\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)), node_to_string(expr.e2, fmt.aprintf("  %s", indent)))
        case .Or:
            s = fmt.aprintf("or\n%s\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)), node_to_string(expr.e2, fmt.aprintf("  %s", indent)))
        case .And:
            s = fmt.aprintf("and\n%s\n%s", node_to_string(expr.e1, fmt.aprintf("  %s", indent)), node_to_string(expr.e2, fmt.aprintf("  %s", indent)))
    }
    return
}

fields_to_string :: proc(fields: map[string]^Node) -> (s: string) {
    for k,v in fields {
        s = fmt.aprintf("%s; %v = %v", s, k, node_to_string(v, ""))
    }
    if len(fields) == 0 { return "" }
    return
}

match_patterns_to_string :: proc(patterns: map[Match_Pattern]^Node) -> (s: string) {
    for k,v in patterns {
        s = fmt.aprintf("%s;\n%s {{ %s }} = %v", s, k.label, k.var, node_to_string(v, ""))
    }
    if len(patterns) == 0 { return "" }
    return
}

fun_app_params_to_string :: proc(params: [dynamic]^Node) -> (s: string) {
    for p in params {
        s = fmt.aprintf("%s,  %s", s, node_to_string(p, ""))
    }
    if len(params) == 0 { return "" }
    return s[3:]
}

node_to_string :: proc(node: ^Node, indent: string) -> (s: string) {
    if node == nil || node.expr == nil { return }
    s = fmt.aprintf("%s%s", indent, pos_to_string(node.pos))
    switch e in node.expr^ {
        case Sequence:
            s = fmt.aprintf("%s;\n%s", node_to_string(e.e1, indent), node_to_string(e.e2, indent))
        case Fun_App:
            s = fmt.aprintf("%s %s(%s)", s, e.fun_name, fun_app_params_to_string(e.params))
        case Match_Case:
            s = fmt.aprintf("%s match %s with {{ %s }}", s, node_to_string(e.e1, indent), match_patterns_to_string(e.patterns))
        case Union_Constructor:
            s = fmt.aprintf("%s %s {{ %s }}", s, e.label, node_to_string(e.e1, ""))
        case Struct:
            s = fmt.aprintf("%s struct %s", s, fields_to_string(e.fields))
        case While:
            s = fmt.aprintf("%s while %s do\n%s", s, node_to_string(e.e1, indent), node_to_string(e.e2, fmt.aprintf("  %s", indent)))
        case Type_Decl:
            s = fmt.aprintf("%s type %s = %s;\n%s", s, e.x, pretype_to_string(e.pt), node_to_string(e.e1, indent))
        case Let:
            if e.is_mut {
                s = fmt.aprintf("%s let mutable %s : %s =\n%s;\n%s", s, e.x, pretype_to_string(e.pt), node_to_string(e.e1, fmt.aprintf("  %s", indent)), node_to_string(e.e2, fmt.aprintf("  %s", indent)))
            } else {
                s = fmt.aprintf("%s let %s : %s =\n%s;\n%s", s, e.x, pretype_to_string(e.pt), node_to_string(e.e1, fmt.aprintf("  %s", indent)), node_to_string(e.e2, fmt.aprintf("  %s", indent)))
            }
        case If_Else:
            s = fmt.aprintf("%s if %s\n  then %s\n  else %s", s, node_to_string(e.e1, indent), node_to_string(e.e2, indent), node_to_string(e.e3, indent))
        case Assignment:
            s = fmt.aprintf("%s <-\n  %s\n%s", s, e.x, node_to_string(e.e1, fmt.aprintf("  %s", indent)))
        case Unary_Fun:
            s = fmt.aprintf("%s %s", s, unary_to_string(e, indent))
        case Binary_Fun:
            s = fmt.aprintf("%s %s", s, binary_to_string(e, indent))
        case Variable:
            s = fmt.aprintf("%s %s", s, e.x)
        case Field_Access:
            s = fmt.aprintf("%s %s.%s", s, e.x, e.field)
        case Value:
            s = fmt.aprintf("%s %s", s, value_to_string(e.v))
        case Parens:
            s = fmt.aprintf("%s (\n%s\n%s)", s, node_to_string(e.e1, indent), indent)
        case Scope:
            s = fmt.aprintf("%s {{\n%s\n%s}}", s, node_to_string(e.e1, indent), indent)
    }
    return
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